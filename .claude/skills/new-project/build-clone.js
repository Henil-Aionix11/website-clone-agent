#!/usr/bin/env node
/**
 * build-clone.js — Pixel-perfect static site cloner
 * Usage: node build-clone.js <playwright-extract.json> [output-dir]
 *
 * Handles all JSON formats:
 *   • downloaded_resources.images[] with base64 content (Format A)
 *   • assets.images[] with just URLs to fetch (Format B)
 *   • css_data.stylesheets[] with CSS text
 *   • Inline <style> tags in raw_html head + body
 *   • External font faces in head styles
 */

'use strict';

const fs    = require('fs');
const path  = require('path');
const https = require('https');
const http  = require('http');

// ─── CLI ─────────────────────────────────────────────────────────────────────
const [,, jsonFile, outDirArg] = process.argv;
if (!jsonFile) { console.error('Usage: node build-clone.js <extract.json> [output-dir]'); process.exit(1); }

const jsonPath = path.resolve(jsonFile);
if (!fs.existsSync(jsonPath)) { console.error('File not found:', jsonPath); process.exit(1); }

const raw  = fs.readFileSync(jsonPath, 'utf8');
const data = JSON.parse(raw);

// ─── Normalise (some files wrap everything under .data) ───────────────────────
const D = data.data || data;

const metadata = D.metadata   || {};
const rawHtml  = D.raw_html   || '';
const cssData  = D.css_data   || {};
const assets   = D.assets     || {};
const dlRes    = D.downloaded_resources || {};

const siteTitle = metadata.title || 'Clone';
const siteUrl   = metadata.url   || '';

// ─── Output directory ─────────────────────────────────────────────────────────
function slugify(s) {
  return s.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 50);
}
const outDir  = outDirArg ? path.resolve(outDirArg) : path.join(path.dirname(jsonPath), slugify(siteTitle));
const imgDir  = path.join(outDir, 'images');
const fontDir = path.join(outDir, 'fonts');
fs.mkdirSync(imgDir,  { recursive: true });
fs.mkdirSync(fontDir, { recursive: true });

console.log(`\n📦 Building clone: ${siteTitle}`);
console.log(`   Source : ${siteUrl}`);
console.log(`   Output : ${outDir}\n`);

// ─── MIME detection ───────────────────────────────────────────────────────────
function detectMime(b64, urlStr, declared) {
  if (b64) {
    const buf = Buffer.from(b64.slice(0, 16), 'base64');
    if (buf[0] === 0xFF && buf[1] === 0xD8)                      return 'image/jpeg';
    if (buf[0] === 0x89 && buf.toString('ascii', 1, 4) === 'PNG') return 'image/png';
    if (buf.toString('ascii', 0, 4) === 'RIFF')                  return 'image/webp';
    if (buf.toString('ascii', 0, 4) === 'GIF8')                  return 'image/gif';
    if (buf.toString('ascii', 0, 4) === 'wOF2')                  return 'font/woff2';
    if (buf.toString('ascii', 0, 4) === 'wOFF')                  return 'font/woff';
    if (buf.toString('ascii', 0, 5).toLowerCase() === '<?xml' ||
        buf.toString('ascii', 0, 4) === '<svg')                  return 'image/svg+xml';
  }
  const extMap = { jpg:'image/jpeg', jpeg:'image/jpeg', png:'image/png', gif:'image/gif',
                   webp:'image/webp', svg:'image/svg+xml', avif:'image/avif',
                   ico:'image/x-icon', woff:'font/woff', woff2:'font/woff2',
                   ttf:'font/ttf', otf:'font/otf' };
  const ext = (urlStr || '').split('?')[0].split('.').pop().toLowerCase();
  return declared || extMap[ext] || 'application/octet-stream';
}
function mimeToExt(mime) {
  return { 'image/jpeg':'jpg','image/png':'png','image/gif':'gif','image/webp':'webp',
           'image/svg+xml':'svg','image/avif':'avif','image/x-icon':'ico',
           'font/woff':'woff','font/woff2':'woff2','font/ttf':'ttf','font/otf':'otf',
           'application/octet-stream':'bin' }[mime] || 'bin';
}

// ─── HTTP fetch ───────────────────────────────────────────────────────────────
function fetchBinary(rawUrl, maxRedirects = 5) {
  return new Promise((resolve, reject) => {
    if (!rawUrl || rawUrl.startsWith('data:')) { reject(new Error('skip:' + rawUrl?.slice(0,20))); return; }
    const fullUrl = rawUrl.startsWith('//') ? 'https:' + rawUrl : rawUrl;
    const parsed  = new URL(fullUrl);
    const proto   = parsed.protocol === 'https:' ? https : http;
    const req = proto.get(fullUrl, { headers: { 'User-Agent': 'Mozilla/5.0' }, timeout: 15000 }, res => {
      if ([301,302,303,307,308].includes(res.statusCode) && res.headers.location && maxRedirects > 0) {
        let loc = res.headers.location;
        if (!loc.startsWith('http')) loc = `${parsed.protocol}//${parsed.host}${loc}`;
        resolve(fetchBinary(loc, maxRedirects - 1));
        return;
      }
      if (res.statusCode !== 200) { reject(new Error(`HTTP ${res.statusCode} for ${fullUrl}`)); return; }
      const chunks = [];
      res.on('data', c => chunks.push(c));
      res.on('end',  () => resolve({ buffer: Buffer.concat(chunks), contentType: res.headers['content-type'] || '' }));
    });
    req.on('error',   reject);
    req.on('timeout', () => { req.destroy(); reject(new Error('Timeout: ' + fullUrl)); });
  });
}

// ─── URL key helpers ──────────────────────────────────────────────────────────
function urlKeys(u) {
  const keys = new Set();
  if (!u) return keys;
  const n = u.trim();
  keys.add(n);
  if (n.startsWith('https://'))      { keys.add('http://' + n.slice(8));  keys.add('//' + n.slice(8)); keys.add(n.slice(8)); }
  else if (n.startsWith('http://'))  { keys.add('https://' + n.slice(7)); keys.add('//' + n.slice(7)); keys.add(n.slice(7)); }
  else if (n.startsWith('//'))       { keys.add('https://' + n.slice(2)); keys.add('http://' + n.slice(2)); keys.add(n.slice(2)); }
  try { const dec = decodeURIComponent(n); if (dec !== n) urlKeys(dec).forEach(k => keys.add(k)); } catch(_){}
  const noQ = n.split('?')[0]; if (noQ !== n) keys.add(noQ);
  return keys;
}

// ─── Image map ────────────────────────────────────────────────────────────────
const imageMap = {};
let   imgCount = 0;
function registerImage(origUrl, localRel) { urlKeys(origUrl).forEach(k => { imageMap[k] = localRel; }); }

async function saveImage(origUrl, b64Content, mimeHint) {
  imgCount++;
  const mime    = detectMime(b64Content, origUrl, mimeHint);
  const ext     = mimeToExt(mime);
  const fname   = `img-${imgCount}.${ext}`;
  const absPath = path.join(imgDir, fname);
  const relPath = `images/${fname}`;
  if (b64Content) {
    fs.writeFileSync(absPath, Buffer.from(b64Content, 'base64'));
  } else {
    const { buffer } = await fetchBinary(origUrl);
    fs.writeFileSync(absPath, buffer);
  }
  registerImage(origUrl, relPath);
  return relPath;
}

// ─── Font map ─────────────────────────────────────────────────────────────────
const fontMap  = {};
let   fontCount = 0;
function registerFont(origUrl, localRel) { urlKeys(origUrl).forEach(k => { fontMap[k] = localRel; }); }

async function saveFont(origUrl, b64Content, mimeHint) {
  fontCount++;
  const mime    = detectMime(b64Content, origUrl, mimeHint);
  const ext     = mimeToExt(mime);
  const fname   = `font-${fontCount}.${ext}`;
  const absPath = path.join(fontDir, fname);
  const relPath = `fonts/${fname}`;
  if (b64Content) {
    fs.writeFileSync(absPath, Buffer.from(b64Content, 'base64'));
  } else {
    const { buffer } = await fetchBinary(origUrl);
    fs.writeFileSync(absPath, buffer);
  }
  registerFont(origUrl, relPath);
  return relPath;
}

// ─── CSS rewriting ────────────────────────────────────────────────────────────
function rewriteCssUrls(css) {
  return css.replace(/url\(\s*(['"]?)([^)'"]+)\1\s*\)/g, (match, q, u) => {
    const clean = u.trim();
    if (clean.startsWith('data:') || clean.startsWith('#') || clean === '') return match;
    for (const k of urlKeys(clean)) {
      if (imageMap[k]) return `url("${imageMap[k]}")`;
      if (fontMap[k])  return `url("${fontMap[k]}")`;
    }
    return match;
  });
}

// ─── HTML attribute rewriting ─────────────────────────────────────────────────
function rewriteAttr(html, attrName) {
  return html.replace(new RegExp(`(${attrName}=["'])([^"']+)(["'])`, 'g'), (match, pre, val, post) => {
    for (const k of urlKeys(val)) { if (imageMap[k]) return `${pre}${imageMap[k]}${post}`; }
    return match;
  });
}
function rewriteSrcset(html, attrName = 'srcset') {
  return html.replace(new RegExp(`(${attrName}=["'])([^"']+)(["'])`, 'g'), (match, pre, val, post) => {
    const parts = val.split(',').map(part => {
      const t = part.trim();
      const si = t.search(/\s/);
      const imgUrl = si === -1 ? t : t.slice(0, si);
      const rest   = si === -1 ? '' : t.slice(si);
      for (const k of urlKeys(imgUrl)) { if (imageMap[k]) return imageMap[k] + rest; }
      return part;
    });
    return pre + parts.join(', ') + post;
  });
}
function rewriteStyleAttrs(html) {
  return html.replace(/(style=["'])([^"']*)(["'])/g, (match, pre, styleVal, post) => {
    return pre + rewriteCssUrls(styleVal) + post;
  });
}
function rewriteStyleTags(html) {
  return html.replace(/(<style[^>]*>)([\s\S]*?)(<\/style>)/gi, (match, open, css, close) => {
    return open + rewriteCssUrls(css.split('base64, ').join('base64,')) + close;
  });
}

// ─── Extract all <style> blocks from HTML (head + body) ──────────────────────
function extractAllStyleBlocks(html) {
  const blocks = [];
  const re = /<style[^>]*>([\s\S]*?)<\/style>/gi;
  let m;
  while ((m = re.exec(html)) !== null) {
    const content = m[1].trim();
    if (content) blocks.push(content);
  }
  return blocks;
}

// ─── MAIN ─────────────────────────────────────────────────────────────────────
(async () => {

  // ── Step 1: Save downloaded images (Format A — pre-fetched with base64) ─────
  const dlImages = dlRes.images || [];
  const dlFonts  = dlRes.fonts  || [];
  console.log(`📥 Pre-downloaded: ${dlImages.length} images, ${dlFonts.length} fonts`);

  for (const img of dlImages) {
    if (!img.url) continue;
    try { await saveImage(img.url, img.content || null, img.mime_type || img.mime || null); }
    catch(e) { console.warn(`  ⚠ skip image ${img.url?.slice(0,60)}: ${e.message}`); }
  }
  for (const font of dlFonts) {
    if (!font.url) continue;
    try { await saveFont(font.url, font.content || null, font.mime_type || font.mime || null); }
    catch(e) { console.warn(`  ⚠ skip font ${font.url?.slice(0,60)}: ${e.message}`); }
  }

  // ── Step 2: Fetch missing images from assets.images (Format B or extras) ────
  const SKIP_IMG = ['bat.bing','google-analytics','facebook.net','doubleclick',
                    'twitter.com/i/adsct','googletagmanager','1x1','pixel','beacon'];
  const assetImgs = (assets.images || []).filter(img => {
    const u = img.url || '';
    if (!u || SKIP_IMG.some(t => u.includes(t))) return false;
    for (const k of urlKeys(u)) { if (imageMap[k]) return false; }
    return true;
  });
  if (assetImgs.length) {
    console.log(`🌐 Fetching ${assetImgs.length} remote images...`);
    await Promise.allSettled(assetImgs.map(async img => {
      try { await saveImage(img.url, null, null); }
      catch(e) { console.warn(`  ⚠ fetch failed ${img.url?.slice(0,60)}: ${e.message}`); }
    }));
  }

  // ── Step 3: Fetch missing fonts from assets.fonts ────────────────────────────
  const assetFonts = (assets.fonts || []).filter(f => {
    const u = f.url || '';
    if (!u) return false;
    for (const k of urlKeys(u)) { if (fontMap[k]) return false; }
    return true;
  });
  if (assetFonts.length) {
    console.log(`🔤 Fetching ${assetFonts.length} remote fonts...`);
    await Promise.allSettled(assetFonts.map(async font => {
      try { await saveFont(font.url, null, null); }
      catch(e) { console.warn(`  ⚠ font fetch failed ${font.url?.slice(0,60)}: ${e.message}`); }
    }));
  }

  console.log(`✅ Saved: ${imgCount} images, ${fontCount} fonts`);

  // ── Step 4: Build combined CSS ─────────────────────────────────────────────
  // Priority: css_data.stylesheets (includes external CSS content) + head styles from raw_html
  const cssChunks = [];

  // 4a. External CSS from css_data.stylesheets (these have the fetched external file content)
  const cssSheets = cssData.stylesheets || [];
  const externalSheets = cssSheets.filter(s => s.content && s.content.trim() &&
    !s.is_inline && s.url && !s.url.startsWith('inline'));
  if (externalSheets.length > 0) {
    console.log(`🎨 Embedding ${externalSheets.length} external CSS files...`);
    for (const sheet of externalSheets) {
      let css = sheet.content;
      css = css.replace(/@import\s+url\([^)]*fonts\.googleapis\.com[^)]*\)[^;]*;/gi, '');
      css = css.replace(/@import\s+["'][^"']*fonts\.googleapis\.com[^"']*["'][^;]*;/gi, '');
      cssChunks.push(`/* ${sheet.url} */\n${css}`);
    }
  } else if (assets.stylesheets?.length) {
    // Format B: fetch external CSS from URLs
    console.log(`🎨 Fetching ${assets.stylesheets.length} external CSS files...`);
    await Promise.allSettled(assets.stylesheets.map(async s => {
      const u = s.url || '';
      if (!u) return;
      const absUrl = u.startsWith('http') ? u : u.startsWith('//') ? 'https:' + u
        : siteUrl.replace(/\/$/, '') + (u.startsWith('/') ? u : '/' + u);
      try {
        const { buffer } = await fetchBinary(absUrl);
        cssChunks.push(`/* ${u} */\n${buffer.toString('utf8')}`);
      } catch(e) { console.warn(`  ⚠ CSS fetch failed ${absUrl}: ${e.message}`); }
    }));
  }

  // 4b. Inline CSS from css_data.stylesheets (element-level styles captured by playwright)
  const inlineSheets = cssSheets.filter(s => s.content && s.content.trim() &&
    (s.is_inline || !s.url || s.url.startsWith('inline')));
  if (inlineSheets.length > 0) {
    console.log(`🎨 Consolidating ${inlineSheets.length} inline CSS blocks...`);
    cssChunks.push(inlineSheets.map(s => s.content).join('\n'));
  }

  // 4c. Extract <style> tags from raw_html HEAD (critical layout overrides)
  const headMatch = rawHtml.match(/<head[^>]*>([\s\S]*?)<\/head>/i);
  const headContent = headMatch ? headMatch[1] : '';
  if (headContent) {
    const headStyleBlocks = extractAllStyleBlocks(headContent);
    if (headStyleBlocks.length > 0) {
      console.log(`🎨 Preserving ${headStyleBlocks.length} head <style> blocks...`);
      cssChunks.push(headStyleBlocks.join('\n'));
    }
  }

  // Combine, fix base64 spaces, first-pass URL rewrite
  let combinedCss = cssChunks.join('\n').split('base64, ').join('base64,');
  combinedCss = rewriteCssUrls(combinedCss);

  // ── Step 4d: Fetch any remaining external url() in CSS not yet in imageMap ──
  const CSS_SKIP = ['fonts.googleapis.com','fonts.gstatic.com','data:'];
  const cssExternalUrls = new Set();
  const cssUrlRe = /url\(\s*['"]?((?:https?:|\/\/)[^'")\s]+)['"]?\s*\)/gi;
  let csm;
  while ((csm = cssUrlRe.exec(combinedCss)) !== null) {
    const u = csm[1].trim();
    if (!CSS_SKIP.some(s => u.includes(s))) {
      // Check if already in imageMap or fontMap
      let found = false;
      for (const k of urlKeys(u)) {
        if (imageMap[k] || fontMap[k]) { found = true; break; }
      }
      if (!found) cssExternalUrls.add(u);
    }
  }
  if (cssExternalUrls.size > 0) {
    console.log(`🖼️  Fetching ${cssExternalUrls.size} CSS background/font URLs...`);
    await Promise.allSettled(Array.from(cssExternalUrls).map(async u => {
      try {
        const ext = u.split('?')[0].split('.').pop().toLowerCase();
        const fontExts = ['woff','woff2','ttf','otf','eot'];
        if (fontExts.includes(ext)) {
          await saveFont(u, null, null);
        } else {
          await saveImage(u, null, null);
        }
      } catch(e) { console.warn(`  ⚠ CSS url fetch failed ${u.slice(0,60)}: ${e.message}`); }
    }));
    // Second-pass rewrite now that new URLs are in imageMap/fontMap
    combinedCss = rewriteCssUrls(combinedCss);
  }

  // ── Step 5: Extract and clean body HTML ────────────────────────────────────
  let bodyHtml = rawHtml;

  // Extract <body> contents
  const bodyTagMatch = bodyHtml.match(/<body[^>]*>([\s\S]*)<\/body>/i);
  if (bodyTagMatch) bodyHtml = bodyTagMatch[1];

  // Strip scripts
  bodyHtml = bodyHtml.replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, '');
  bodyHtml = bodyHtml.replace(/<script\b[^>]*\/?>/gi, '');

  // Strip external stylesheet links (we've embedded the CSS)
  bodyHtml = bodyHtml.replace(/<link[^>]+rel=["']?stylesheet["']?[^>]*\/?>/gi, '');
  bodyHtml = bodyHtml.replace(/<link[^>]+stylesheet[^>]*\/?>/gi, '');

  // Strip noscript
  bodyHtml = bodyHtml.replace(/<noscript\b[^>]*>[\s\S]*?<\/noscript>/gi, '');

  // Fix base64 space bug
  bodyHtml = bodyHtml.split('base64, ').join('base64,');

  // Remove lazy loading — static clones have no JS lazy-loader, so images stay blank until
  // scrolled; force eager loading so everything appears immediately
  bodyHtml = bodyHtml.replace(/\s+loading=["']lazy["']/gi, '');
  bodyHtml = bodyHtml.replace(/\s+data-sizes=["']auto["']/gi, '');
  // Swap data-src → src when src is a placeholder (1px gif or blob)
  bodyHtml = bodyHtml.replace(
    /(<img\b[^>]*?)\s+data-src=(["'])([^"']+)\2([^>]*?>)/gi,
    (match, before, q, dataSrc, after) => {
      // If there's a proper local imageMap path already in src= keep it, otherwise use data-src
      const hasSrc = /\bsrc=/.test(before + after);
      if (!hasSrc) return `${before} src=${q}${dataSrc}${q}${after}`;
      return match;
    }
  );

  // Rewrite image URLs in all relevant attributes
  bodyHtml = rewriteAttr(bodyHtml, 'src');
  bodyHtml = rewriteAttr(bodyHtml, 'data-src');
  bodyHtml = rewriteAttr(bodyHtml, 'data-lazy-src');
  bodyHtml = rewriteAttr(bodyHtml, 'data-original');
  bodyHtml = rewriteAttr(bodyHtml, 'data-bg');
  bodyHtml = rewriteSrcset(bodyHtml, 'srcset');
  bodyHtml = rewriteSrcset(bodyHtml, 'data-srcset');

  // Rewrite inline style= attributes
  bodyHtml = rewriteStyleAttrs(bodyHtml);

  // Rewrite inline <style> tags remaining in body
  // (only if css_data.stylesheets captured them already — if so strip them to avoid duplication)
  if (inlineSheets.length > 0) {
    // CSS already captured in css_data.stylesheets → strip body <style> tags (avoid duplication + improves perf)
    bodyHtml = bodyHtml.replace(/<style[^>]*>[\s\S]*?<\/style>/gi, '');
  } else {
    // Not captured → rewrite URLs in body <style> tags and keep them
    bodyHtml = rewriteStyleTags(bodyHtml);
  }

  // ── Step 6: Build meta tags from original head ─────────────────────────────
  // Preserve important meta tags (viewport, charset, description)
  const metaTags = [];
  const viewportMeta = headContent.match(/<meta[^>]+name=["']viewport["'][^>]*>/i);
  if (viewportMeta) metaTags.push(viewportMeta[0]);
  else metaTags.push(`<meta name="viewport" content="width=${metadata.viewport_width || 1920}, initial-scale=1.0">`);

  // ── Step 7: Write index.html ───────────────────────────────────────────────
  const extSrcCount = (bodyHtml.match(/src=["'](https?:|\/\/)/g) || []).length;

  const indexHtml = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  ${metaTags.join('\n  ')}
  <title>${siteTitle.replace(/</g, '&lt;').replace(/>/g, '&gt;')}</title>
  <style>
${combinedCss}
  </style>
</head>
<body>
${bodyHtml}
</body>
</html>`;

  const outFile = path.join(outDir, 'index.html');
  fs.writeFileSync(outFile, indexHtml, 'utf8');

  const sizeKb = (fs.statSync(outFile).size / 1024).toFixed(1);

  console.log('\n' + '─'.repeat(55));
  console.log(`✅  Clone built successfully!`);
  console.log(`📄  Site   : ${siteTitle}`);
  console.log(`🌐  Source : ${siteUrl}`);
  console.log(`📁  Output : ${outDir}`);
  console.log(`🖼️   Images : ${imgCount} saved to /images/`);
  console.log(`🔤  Fonts  : ${fontCount} saved to /fonts/`);
  console.log(`📦  HTML   : ${sizeKb} KB`);
  if (extSrcCount > 0) console.log(`⚠️   Remaining external src= : ${extSrcCount}`);
  console.log('─'.repeat(55) + '\n');

})().catch(err => {
  console.error('❌ Build failed:', err.stack || err);
  process.exit(1);
});
