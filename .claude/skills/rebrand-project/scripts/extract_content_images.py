#!/usr/bin/env python3
"""
Rebrand Content Extractor - Extract ONLY content and images from reference sites
Simplified version of extract_page.py for rebrand-project workflow.

Usage:
    python extract_content_images.py <URL> --output <output_dir>

Extracts:
    - Text content (headings, paragraphs, buttons, links, etc.)
    - Images (downloaded and saved locally)

Output:
    - content.json - Text content organized by semantic sections
    - images/ - All images saved locally
"""

import asyncio
import argparse
import base64
import json
import logging
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, List, Optional
from urllib.parse import urljoin, urlparse

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


class RebrandExtractor:
    """Simple extractor for rebranding - only content and images."""

    def __init__(self, viewport_width: int = 1920, viewport_height: int = 1080):
        self.viewport_width = viewport_width
        self.viewport_height = viewport_height
        self._browser = None
        self._playwright = None

    async def __aenter__(self):
        from playwright.async_api import async_playwright
        self._playwright = await async_playwright().start()
        self._browser = await self._playwright.chromium.launch(
            headless=True,
            args=['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage']
        )
        return self

    async def __aexit__(self, *args):
        if self._browser:
            await self._browser.close()
        if self._playwright:
            await self._playwright.stop()

    async def extract(self, url: str, output_dir: str, wait_time: int = 3000) -> Dict[str, Any]:
        """Extract content and images from reference site."""
        start_time = datetime.now()

        # Create output directory
        out_path = Path(output_dir)
        out_path.mkdir(parents=True, exist_ok=True)
        images_dir = out_path / "images"
        images_dir.mkdir(exist_ok=True)

        page = await self._browser.new_page(
            viewport={'width': self.viewport_width, 'height': self.viewport_height}
        )

        try:
            logger.info(f"Loading reference site: {url}")
            await page.goto(url, wait_until='load', timeout=60000)
            await asyncio.sleep(wait_time / 1000)

            # Scroll to load lazy content
            await self._scroll_page(page)

            # Extract content and images in parallel
            logger.info("Extracting content and images...")

            results = await asyncio.gather(
                self._extract_text_content(page),
                self._extract_and_download_images(page, images_dir),
                self._get_page_metadata(page, url),
                return_exceptions=True
            )

            # Parse results
            content = results[0] if not isinstance(results[0], Exception) else {}
            images_info = results[1] if not isinstance(results[1], Exception) else {}
            metadata = results[2] if not isinstance(results[2], Exception) else {}

            # Combine into final JSON
            output_data = {
                'success': True,
                'url': url,
                'extracted_at': datetime.now().isoformat(),
                'metadata': metadata,
                'content': content,
                'images': images_info
            }

            # Save content.json
            content_file = out_path / "content.json"
            with open(content_file, 'w', encoding='utf-8') as f:
                json.dump(output_data, f, indent=2, ensure_ascii=False)

            logger.info(f"✅ Extraction complete!")
            logger.info(f"   Content: {content_file}")
            logger.info(f"   Images: {images_dir} ({images_info.get('total_images', 0)} images)")

            return output_data

        except Exception as e:
            logger.error(f"Extraction failed: {e}")
            return {
                'success': False,
                'url': url,
                'error': str(e)
            }
        finally:
            await page.close()

    async def _scroll_page(self, page, max_scrolls: int = 30, scroll_delay: float = 0.3):
        """Scroll page to trigger lazy loading."""
        try:
            dimensions = await page.evaluate('''() => ({
                viewportHeight: window.innerHeight,
                scrollHeight: document.body.scrollHeight
            })''')

            viewport_height = dimensions['viewportHeight']
            current_position = 0
            scroll_count = 0
            last_height = dimensions['scrollHeight']

            while scroll_count < max_scrolls:
                current_position += viewport_height
                await page.evaluate(f'window.scrollTo(0, {current_position})')
                await asyncio.sleep(scroll_delay)

                new_height = await page.evaluate('document.body.scrollHeight')
                scroll_count += 1

                if current_position >= new_height:
                    if new_height <= last_height:
                        break
                    last_height = new_height

            await page.evaluate('window.scrollTo(0, 0)')
            await asyncio.sleep(0.5)

        except Exception as e:
            logger.warning(f"Scroll failed: {e}")
            try:
                await page.evaluate('window.scrollTo(0, 0)')
            except:
                pass

    async def _extract_text_content(self, page) -> Dict[str, Any]:
        """Extract ALL text content from the page - comprehensive approach."""
        content_data = await page.evaluate('''() => {
            const result = {
                page_title: document.title,
                meta_description: '',
                full_text: [],  // All visible text
                headings: [],   // All h1-h6
                paragraphs: [], // All p tags
                buttons: [],    // All buttons and links
                lists: [],      // All list items
                forms: [],      // Form labels and inputs
                tables: [],     // Table data
                sections: {}    // Organized by semantic sections
            };

            // Helper to get clean text
            function getText(element, maxLength = 1000) {
                if (!element) return '';
                let text = element.textContent.trim();
                if (text.length > maxLength) text = text.slice(0, maxLength) + '...';
                return text;
            }

            // Helper to check if element is visible
            function isVisible(el) {
                if (!el) return false;
                const style = window.getComputedStyle(el);
                return style.display !== 'none' &&
                       style.visibility !== 'hidden' &&
                       style.opacity !== '0' &&
                       el.offsetParent !== null;
            }

            // Get meta description
            const metaDesc = document.querySelector('meta[name="description"]');
            if (metaDesc) {
                result.meta_description = metaDesc.getAttribute('content') || '';
            }

            // Extract ALL headings (h1-h6)
            document.querySelectorAll('h1, h2, h3, h4, h5, h6').forEach(h => {
                if (isVisible(h)) {
                    result.headings.push({
                        tag: h.tagName.toLowerCase(),
                        text: getText(h),
                        id: h.id || ''
                    });
                    result.full_text.push({
                        type: 'heading',
                        tag: h.tagName.toLowerCase(),
                        text: getText(h)
                    });
                }
            });

            // Extract ALL paragraphs
            document.querySelectorAll('p').forEach(p => {
                if (isVisible(p)) {
                    const text = getText(p);
                    if (text.length > 5) {
                        result.paragraphs.push(text);
                        result.full_text.push({
                            type: 'paragraph',
                            text: text
                        });
                    }
                }
            });

            // Extract ALL buttons and links with text
            document.querySelectorAll('button, a[href], [role="button"]').forEach(btn => {
                if (isVisible(btn)) {
                    const text = getText(btn, 200);
                    if (text.length > 0 && text.length < 200) {
                        result.buttons.push({
                            text: text,
                            tag: btn.tagName.toLowerCase(),
                            href: btn.getAttribute('href') || '',
                            class: btn.className || ''
                        });
                    }
                }
            });

            // Extract ALL list items
            document.querySelectorAll('li').forEach(li => {
                if (isVisible(li)) {
                    const text = getText(li, 500);
                    if (text.length > 2) {
                        result.lists.push(text);
                        result.full_text.push({
                            type: 'list_item',
                            text: text
                        });
                    }
                }
            });

            // Extract form elements
            document.querySelectorAll('label, input[placeholder], textarea[placeholder]').forEach(el => {
                if (isVisible(el)) {
                    let text = '';
                    if (el.tagName === 'LABEL') {
                        text = getText(el);
                    } else {
                        text = el.getAttribute('placeholder') || '';
                    }
                    if (text) {
                        result.forms.push({
                            type: el.tagName.toLowerCase(),
                            text: text
                        });
                    }
                }
            });

            // Extract table data
            document.querySelectorAll('table').forEach(table => {
                if (isVisible(table)) {
                    const rows = [];
                    table.querySelectorAll('tr').forEach(tr => {
                        const cells = [];
                        tr.querySelectorAll('td, th').forEach(cell => {
                            const text = getText(cell, 200);
                            if (text) cells.push(text);
                        });
                        if (cells.length > 0) rows.push(cells);
                    });
                    if (rows.length > 0) {
                        result.tables.push(rows);
                    }
                }
            });

            // Extract spans and divs with significant text (catch-all)
            document.querySelectorAll('span, div').forEach(el => {
                if (isVisible(el)) {
                    const text = getText(el, 500);
                    // Only capture if:
                    // - Has meaningful length (10-500 chars)
                    // - Doesn't contain child block elements
                    // - Is likely standalone content
                    const hasBlockChildren = el.querySelector('p, div, h1, h2, h3, h4, h5, h6, li, table');
                    if (text.length >= 10 && text.length <= 500 && !hasBlockChildren) {
                        result.full_text.push({
                            type: 'inline',
                            tag: el.tagName.toLowerCase(),
                            class: el.className || '',
                            text: text
                        });
                    }
                }
            });

            // Organize by semantic sections (best effort)
            const heroH1 = document.querySelector('h1');
            if (heroH1) {
                result.sections.hero = {
                    heading: getText(heroH1)
                };

                // Get nearby content
                let current = heroH1.nextElementSibling;
                let contentCount = 0;
                const nearbyContent = [];
                while (current && contentCount < 10) {
                    if (current.tagName === 'H2') break;
                    const text = getText(current);
                    if (text.length > 5 && text.length < 500) {
                        nearbyContent.push(text);
                        contentCount++;
                    }
                    current = current.nextElementSibling;
                }
                if (nearbyContent.length > 0) {
                    result.sections.hero.content = nearbyContent;
                }
            }

            // Navigation
            const nav = document.querySelector('nav');
            if (nav) {
                result.sections.navigation = {
                    items: []
                };
                nav.querySelectorAll('a, button').forEach(item => {
                    const text = getText(item, 100);
                    if (text && text.length < 100) {
                        result.sections.navigation.items.push(text);
                    }
                });
            }

            // Footer
            const footer = document.querySelector('footer');
            if (footer) {
                result.sections.footer = {
                    text: getText(footer, 2000)
                };
            }

            return result;
        }''')

        return content_data

    async def _extract_and_download_images(self, page, images_dir: Path) -> Dict[str, Any]:
        """Extract and download all images from the page."""
        images_data = await page.evaluate('''() => {
            const images = [];

            // Get all img tags
            document.querySelectorAll('img').forEach((img, index) => {
                if (img.src) {
                    const rect = img.getBoundingClientRect();
                    images.push({
                        src: img.src,
                        alt: img.alt || '',
                        width: rect.width || img.getAttribute('width') || img.naturalWidth || 0,
                        height: rect.height || img.getAttribute('height') || img.naturalHeight || 0,
                        data_src: img.getAttribute('data-src') || '',
                        class_name: img.className || '',
                        id: img.id || '',
                        index: index
                    });
                }
            });

            // Get background images
            document.querySelectorAll('*').forEach((el, index) => {
                const styles = window.getComputedStyle(el);
                const bg = styles.backgroundImage;

                if (bg && bg !== 'none' && bg.includes('url(')) {
                    const match = bg.match(/url\\(["']?([^"')]+)["']?\\)/);
                    if (match && match[1]) {
                        const rect = el.getBoundingClientRect();
                        images.push({
                            src: match[1],
                            alt: '',
                            width: rect.width || 0,
                            height: rect.height || 0,
                            is_background: true,
                            element_class: el.className || '',
                            element_id: el.id || ''
                        });
                    }
                }
            });

            return images;
        }''')

        # Deduplicate by URL
        seen_urls = set()
        unique_images = []
        for img in images_data:
            if img['src'] not in seen_urls:
                seen_urls.add(img['src'])
                unique_images.append(img)

        # Download images
        downloaded_images = []
        img_index = 1

        for img_info in unique_images:
            if img_info.get('is_background', False):
                continue  # Skip background images for now

            img_url = img_info['src']

            # Determine file extension
            parsed_url = urlparse(img_url)
            ext = '.png'
            if '.jpg' in parsed_url.path or '.jpeg' in parsed_url.path:
                ext = '.jpg'
            elif '.webp' in parsed_url.path:
                ext = '.webp'
            elif '.svg' in parsed_url.path:
                ext = '.svg'
            elif '.gif' in parsed_url.path:
                ext = '.gif'
            elif '.avif' in parsed_url.path:
                ext = '.avif'

            # Generate filename
            filename = f"img-{img_index}{ext}"
            img_path = images_dir / filename

            try:
                # Download image
                logger.info(f"Downloading: {filename}")

                # Use page's download method
                async def download_image(url, path):
                    try:
                        response = await page.context.request.get(url)
                        buffer = await response.body()

                        # Save image
                        with open(path, 'wb') as f:
                            f.write(buffer)

                        return True, None
                    except Exception as e:
                        return False, str(e)

                success, error = await download_image(img_url, img_path)

                if success:
                    downloaded_images.append({
                        'original_url': img_url,
                        'local_file': filename,
                        'relative_path': f"images/{filename}",
                        'width': img_info.get('width', 0),
                        'height': img_info.get('height', 0),
                        'alt': img_info.get('alt', ''),
                        'class': img_info.get('class_name', ''),
                        'id': img_info.get('id', ''),
                        'context': self._detect_image_context(img_info)
                    })
                    img_index += 1
                else:
                    logger.warning(f"Failed to download {img_url}: {error}")

            except Exception as e:
                logger.warning(f"Error processing image {img_url}: {e}")

        return {
            'total_images': len(downloaded_images),
            'images': downloaded_images
        }

    def _detect_image_context(self, img_info: Dict) -> str:
        """Detect the usage context of an image."""
        url_lower = img_info.get('src', '').lower()
        class_name = img_info.get('class_name', '').lower()

        # Detect by class name
        if 'logo' in class_name or 'logo' in url_lower:
            return 'logo'
        elif 'hero' in class_name or 'banner' in class_name:
            return 'hero'
        elif 'feature' in class_name or 'card' in class_name:
            return 'feature'
        elif 'avatar' in class_name or 'profile' in class_name:
            return 'avatar'
        elif 'testimonial' in class_name or 'review' in class_name:
            return 'testimonial'
        elif 'cta' in class_name or 'button' in class_name:
            return 'cta'
        elif 'background' in class_name or 'bg' in class_name:
            return 'background'

        # Detect by size - ensure we have numbers
        try:
            width = float(img_info.get('width', 0))
            height = float(img_info.get('height', 0))
        except (ValueError, TypeError):
            return 'unknown'

        if width == 0 or height == 0:
            return 'unknown'

        aspect_ratio = width / height if height > 0 else 1

        if aspect_ratio > 4:  # Very wide
            return 'banner'
        elif aspect_ratio < 0.8:  # Tall/portrait
            return 'avatar' if width < 200 else 'feature'
        elif width > 1500:  # Large images
            return 'hero'
        elif width < 400:  # Small images
            return 'icon'
        else:
            return 'feature'

    async def _get_page_metadata(self, page, url: str) -> Dict:
        """Get basic page metadata."""
        metadata = await page.evaluate('''() => ({
            title: document.title,
            url: window.location.href,
            viewport_width: window.innerWidth,
            viewport_height: window.innerHeight,
            page_width: document.documentElement.scrollWidth,
            page_height: document.documentElement.scrollHeight
        })''')

        metadata['source_url'] = url
        return metadata


async def main():
    parser = argparse.ArgumentParser(description='Extract content and images for rebranding')
    parser.add_argument('url', help='Reference site URL')
    parser.add_argument('--output', '-o', default='rebrand-source', help='Output directory')

    args = parser.parse_args()

    logger.info(f"🔍 Starting extraction: {args.url}")
    logger.info(f"📁 Output directory: {args.output}")

    async with RebrandExtractor() as extractor:
        result = await extractor.extract(args.url, args.output)

    if result['success']:
        logger.info(f"✅ Extraction complete!")
        logger.info(f"   Output: {args.output}/")
        logger.info(f"   - content.json")
        logger.info(f"   - images/ ({result['images']['total_images']} images)")
    else:
        logger.error(f"❌ Extraction failed: {result.get('error')}")
        sys.exit(1)


if __name__ == '__main__':
    asyncio.run(main())
