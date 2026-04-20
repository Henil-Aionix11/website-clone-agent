---
name: rebrand-project
description: Rebrand an existing WebForge project with content from a reference website (preserves layout 100%)
user-invocable: true
---

# /rebrand-project

Replace ALL text and images in a WebForge project with content from a PDP reference site. Layout stays 100% unchanged.

> All tools pre-approved in `settings.json` — sub-agents run Bash, Edit, Read, MCP tools freely.

## Writing Rules (applies to ALL agents that write or replace text)

Read `.claude/skills/humanizer/SKILL.md` before writing anything. Follow every rule in it without exception.

**Role:** Expert blog copywriter. Advertorials, listicles, product roundups. Conversational, specific, opinionated. Not a marketing bot.

**Mindset:** Write as a real person who tried this product. You are the author. No PDP, no source, no template. Just your story.

**Hard banned patterns — fix before submitting:**
- Em dashes (—): replace with comma, period, or rewrite
- Three short fragments in a row: merge into one sentence
- Ending with "no X, no Y, no Z": rewrite as one positive sentence
- "It's not X, it's Y" / "Not X. X." structures: just say the thing directly
- Grand summary closers ("X disrupts the cycle at the source"): cut or replace with a specific detail
- Two consecutive sentences with the same structure: vary them
- AI words: additionally, crucial, pivotal, enhance, foster, highlight, underscore, showcase, testament, tapestry, delve, align with, garner, vibrant, groundbreaking, seamless, intuitive
- Source references ("According to the PDP...", "As listed on the reference site...", "Based on the product page..."): never. Write as if you know this product firsthand.
- Process language ("The product features include...", "Key benefits are...", "The following testimonials..."): never. Just write the content.

**Voice check (every paragraph):** Does it sound like a real person or a brochure? Are sentences varied in length? Is there a specific detail every few sentences? Any trace of the writing process? If yes to the last one, delete and rewrite.

**Angle:** If `REBRAND_ANGLE` is set, emphasize that angle above all else. If empty, use all PDP content equally.

**Custom instructions:** If `CUSTOM_INSTRUCTIONS` is set, apply as mandatory rules to every piece of text.

**Zero verbatim copy:** Reword everything from the PDP. Same facts, new sentences. No exact matches.

**Offers/pricing:** Copy exact numbers and deal structure from the PDP. Never invent prices or discounts. If no pricing on PDP, add none.

**Competitor reviews:** Write balanced reviews. Competitors get fair pros and cons. PDP product can edge ahead slightly, but not by a landslide. Reads like a real reviewer, not an ad.

---

## Phase 1 — Setup (main agent)

```bash
AGENT_DIR="$(pwd)"
export GH_TOKEN=$(grep GITHUB_TOKEN "$AGENT_DIR/.env" | cut -d'=' -f2 | tr -d ' ')
GITHUB_USER=$(gh api user --jq '.login')
GITHUB_EMAIL=$(gh api user --jq '.email // empty')
GITHUB_EMAIL="${GITHUB_EMAIL:-${GITHUB_USER}@users.noreply.github.com}"
```

1. List local projects: `ls projects/` → ask user to select one → set `PROJECT_NAME`, `PROJECT_DIR="$AGENT_DIR/projects/$PROJECT_NAME"`
2. Clone if not local: `gh repo clone "$GITHUB_USER/$PROJECT_NAME" "$PROJECT_DIR"`
3. Ask for PDP reference URL → validate starts with `http`
4. Ask: **"Do you want to focus on a specific angle?"**
   - If the product has multiple benefits, the user can pick one angle to emphasize across the entire site
   - If user provides an angle → set `REBRAND_ANGLE`
   - If user says no/skip → set `REBRAND_ANGLE=""` (use all PDP content equally)
5. Ask: **"Any custom instructions for the rebrand?"**
   - The user can provide any specific rules for how the site should be written — word preferences, target audience, tone adjustments, things to avoid or include, etc.
   - If user provides instructions → set `CUSTOM_INSTRUCTIONS` (store exact text)
   - If user says no/skip → set `CUSTOM_INSTRUCTIONS=""` (none)
6. Run Playwright extraction:

```bash
REBRAND_SOURCE_DIR="$PROJECT_DIR/rebrand-source"
mkdir -p "$REBRAND_SOURCE_DIR"
cd "$AGENT_DIR/.claude/skills/rebrand-project/scripts"
python extract_content_images.py "$REFERENCE_URL" --output "$REBRAND_SOURCE_DIR"
cd "$AGENT_DIR"
```

7. Create backup: `cp "$PROJECT_DIR/index.html" "$PROJECT_DIR/index.html.backup"`

---

## Phase 2 — Parallel Analysis (2 agents simultaneously)

Send ONE message launching BOTH agents at the same time.

---

### Analysis Agent 1: PDP Content + Logo Identification

```
You are extracting ALL content from a PDP site for a rebrand. You have full Read, Bash, and MCP permissions.

FILE: {REBRAND_SOURCE_DIR}/content.json
REFERENCE URL: {REFERENCE_URL}

TASK A — Read content.json (use Read with limit/offset if large) and extract:

PRODUCT INFO:
- product_name, brand_name, page_title, meta_description

ALL TEXT CONTENT (copy exact text — every word matters):
- h1 heading
- ALL h2/h3 subheadings
- hero paragraphs (all of them)
- features/benefits (every item with description)
- how-it-works steps (every step)
- pros list, cons list
- testimonials: name, role, quote (all 3+)
- FAQ: every question + full answer
- CTA button text(s)
- promo/discount text, stats/numbers
- brand tagline, footer copyright text
- ANY other text sections on the page

IMAGES:
- List every image in {REBRAND_SOURCE_DIR}/images/ with its context from content.json
- Note which has context "logo", "banner", or smallest wide-aspect image

TASK B — Visual logo verification using Chrome DevTools:
1. mcp__chrome-devtools__navigate_page → {REFERENCE_URL}
2. mcp__chrome-devtools__take_screenshot — look at the header/navigation area
3. Find which image from rebrand-source/images/ matches the VISIBLE logo in the screenshot
4. Report: PDP_LOGO_FILE = exact filename (e.g., img-2.png)
5. Report: PDP_PRODUCT_FILE = main product image filename (largest, hero/feature context)

Return a COMPLETE structured report with every text element and confirmed PDP_LOGO_FILE.
```

---

### Analysis Agent 2: HTML Audit + Dynamic Agent Plan

```
You are auditing an HTML file to build a complete rebrand execution plan. Full Read and Bash permissions.

FILE: {PROJECT_DIR}/index.html

TASK 1 — Count total lines:
wc -l "{PROJECT_DIR}/index.html"

TASK 2 — Calculate how many text agents to launch (one per ~300 lines):
node -e "
const lines = parseInt(require('child_process').execSync('wc -l < \"{PROJECT_DIR}/index.html\"').toString().trim());
const agents = Math.min(8, Math.max(2, Math.ceil(lines / 300)));
const size = Math.ceil(lines / agents);
console.log('TOTAL_LINES=' + lines);
console.log('AGENTS_NEEDED=' + agents);
for(let i=0;i<agents;i++){
  const s=i*size+1, e=Math.min((i+1)*size,lines);
  console.log('Section'+(i+1)+': lines '+s+' to '+e);
}
"

TASK 3 — Extract EVERY visible text string (minimum 5 chars):
node -e "
const fs=require('fs');
const h=fs.readFileSync('{PROJECT_DIR}/index.html','utf8');
const tags='h[1-6]|p|li|button|span|label|title|a|td|th|blockquote|figcaption|div|strong|em|b|i';
const m=[...h.matchAll(new RegExp('<(?:'+tags+')[^>]*>\\s*([^<]{5,})\\s*<\/',''+'g'))];
const s=new Set();
m.forEach(x=>{const t=x[1].replace(/&[a-z#0-9]+;/g,' ').trim();if(t.length>4&&!/^\s*$/.test(t))s.add(t.substring(0,200));});
[...s].forEach((t,i)=>console.log(i+': '+t));
" 2>/dev/null

TASK 4 — Find every image + context (read 20 lines before/after each <img>):
grep -n "<img" "{PROJECT_DIR}/index.html"
For each img line, show surrounding HTML: sed -n '{line-20},{line+20}p' "{PROJECT_DIR}/index.html"

TASK 5 — Extract original brand/product name for stale sweep:
grep -o "<title>[^<]*</title>" "{PROJECT_DIR}/index.html" | head -1
grep -o 'name="description" content="[^"]*"' "{PROJECT_DIR}/index.html" | head -1

Return:
A) AGENTS_NEEDED + exact line ranges for each section
B) FULL TEXT INVENTORY — numbered list, EVERY visible text string, grouped by which section (line range) it falls in
C) IMAGE MAP — each img filename + dimensions + surrounding section context (what product/content is near it)
D) ORIGINAL_BRAND_NAME — from title/meta (used for stale sweep grep)
```

---

## Phase 3 — Parallel Rebrand (ALL agents in ONE message)

Wait for BOTH analysis agents to complete. Then send ONE message launching ALL of these simultaneously:
- **N text agents** (N = AGENTS_NEEDED from Analysis Agent 2)
- **1 logo agent**
- **2–3 image agents** (split image map into batches of 3–4)

---

### Text Agent Template — launch ONE per section (repeat N times)

Replace `{S}` with section number, `{S_START}` and `{S_END}` with line ranges.

```
You are an expert blog copywriter replacing ALL text in a section of an HTML file for a rebrand. Full Edit, Read, Bash permissions.

Follow the Writing Rules defined at the top of this skill file (HUMANIZER, ROLE, ANGLE, CUSTOM INSTRUCTIONS).

FILE: {PROJECT_DIR}/index.html
YOUR SECTION: lines {S_START} to {S_END}
PRODUCT: {PRODUCT_NAME} by {BRAND_NAME}
REFERENCE URL: {REFERENCE_URL}
ANGLE: {REBRAND_ANGLE}
CUSTOM INSTRUCTIONS: {CUSTOM_INSTRUCTIONS}

PDP CONTENT (from Analysis Agent 1 — paste the FULL report here):
{FULL_CONTENT_REPORT}

YOUR TEXT INVENTORY (strings in lines {S_START}-{S_END} from Analysis Agent 2):
{TEXT_STRINGS_FOR_THIS_SECTION}

INSTRUCTIONS:
1. Read your section: Read tool with offset={S_START-1} limit={S_END-S_START+1}
2. Read the humanizer skill: Read `.claude/skills/humanizer/SKILL.md` — every word you write must comply with every rule in that file. Do NOT skip this Read. Do NOT rely on any inline summary. The file is the single source of truth for writing quality.
3. For EVERY string in your text inventory, replace it using Edit tool (one call per string)
4. Matching rules by purpose:
   - h1 slot → use PDP h1 heading (reword in your copywriter voice)
   - h2/h3 slots → use PDP subheadings in order (reword naturally)
   - hero paragraph slots → use PDP hero paragraphs (rewrite as advertorial intro)
   - feature/benefit slots → use PDP features list items (rewrite as listicle-style bullet points)
   - how-it-works → use PDP steps (rewrite as casual explainer)
   - testimonial slots → use PDP testimonials (name/role/quote — keep quotes feeling real and specific)
   - FAQ slots → use PDP FAQ pairs (rewrite answers conversationally)
   - CTA button → use PDP CTA text (keep short and direct)
   - footer → use PDP footer/copyright text
   - newsletter/email capture → rewrite as "{BRAND_NAME} signup" or similar PDP-relevant text
   - template placeholders → replace with the most relevant PDP content for that slot type
   - pricing/offers/bundles/discounts → use EXACT numbers and deal structure from PDP (never invent prices or offers). If PDP has no offers, remove or repurpose the slot with non-pricing content
5. If no exact PDP content exists for a slot, WRITE NEW CONTENT based on the PDP product and brand — do NOT leave old text
6. REWORD EVERYTHING — never copy-paste exact sentences from the PDP. Use PDP as source of facts but always rewrite in your own words

RULES:
- Use Edit tool ONLY — no scripts, no node commands for text changes
- Change ONLY text between tags and alt/aria-label/placeholder values
- NEVER touch: HTML tags, classes, IDs, styles, src/href, scripts
- Every string in your inventory MUST be replaced — zero old text remains
- ANGLE and CUSTOM_INSTRUCTIONS take priority over default content choices
- Prices, offers, and deals are FACTS — copy exact numbers from PDP, never hallucinate
- All other text is COPY — reword it, never paste verbatim from PDP

FINAL CHECK (MANDATORY — run after all edits, before reporting done):
7. Re-read your section and grep for banned patterns. Fix every hit before finishing:

grep -n "—" "{PROJECT_DIR}/index.html" | awk -F: '$1>={S_START}&&$1<={S_END}'
grep -in "additionally\|crucial\|pivotal\|enhance\|foster\|highlight\|underscore\|showcase\|testament\|tapestry\|delve\|vibrant\|groundbreaking\|seamless\|intuitive\|garner\|landscape\|interplay\|intricate" "{PROJECT_DIR}/index.html" | awk -F: '$1>={S_START}&&$1<={S_END}'
grep -in "serves as\|stands as\|boasts\|nestled\|breathtaking\|renowned\|stunning" "{PROJECT_DIR}/index.html" | awk -F: '$1>={S_START}&&$1<={S_END}'

For EACH match: Edit to fix. Replace em dashes with commas or periods. Replace AI words with plain English. Then re-grep until zero matches in your section.
Do NOT report done until all three greps return zero results.
```

---

### Logo Agent

```
You are replacing the logo image with correct sizing. Full Bash permissions.

SOURCE (PDP logo): {REBRAND_SOURCE_DIR}/images/{PDP_LOGO_FILE}
TARGET (project logo): {PROJECT_DIR}/images/{LOGO_FILE}
CSS SLOT: {W}x{H}px (the container size in HTML)

CRITICAL: Read the ORIGINAL logo dimensions FIRST — before overwriting anything.

STEP 1 — Get original logo natural size:
node -e "require('sharp')('{PROJECT_DIR}/images/{LOGO_FILE}').metadata().then(m=>console.log('ORIG:'+m.width+'x'+m.height)).catch(()=>console.log('ORIG:unknown'))"

Note the ORIGINAL_HEIGHT (e.g., 28px, 35px, 40px). This is the TARGET render height.

STEP 2 — Get PDP logo dimensions:
node -e "require('sharp')('{REBRAND_SOURCE_DIR}/images/{PDP_LOGO_FILE}').metadata().then(m=>console.log('PDP:'+m.width+'x'+m.height))"

STEP 3 — Copy PDP logo to target (replaces file, keeping same filename + extension):
cp "{REBRAND_SOURCE_DIR}/images/{PDP_LOGO_FILE}" "{PROJECT_DIR}/images/{LOGO_FILE}"

STEP 4 — Resize to ORIGINAL_HEIGHT only (preserve aspect ratio — do NOT force-fill width):
TARGET_H={ORIGINAL_HEIGHT}

# Height-only resize — width auto-calculated from aspect ratio:
convert "{PROJECT_DIR}/images/{LOGO_FILE}" -resize x${TARGET_H} "{PROJECT_DIR}/images/{LOGO_FILE}" 2>/dev/null || \
  node -e "require('sharp')('{PROJECT_DIR}/images/{LOGO_FILE}').resize(null,${TARGET_H},{fit:'inside'}).toBuffer().then(b=>require('fs').writeFileSync('{PROJECT_DIR}/images/{LOGO_FILE}',b))"

STEP 5 — Verify final dimensions:
node -e "require('sharp')('{PROJECT_DIR}/images/{LOGO_FILE}').metadata().then(m=>console.log('Final:'+m.width+'x'+m.height))"

If the CSS slot uses object-fit:scale-down or object-fit:contain, the logo will display at its natural size (not stretched). That is correct behavior — the goal is proportional logo, not filled slot.
```

---

### Image Agent 1 — first batch ({IMG_LIST_1})

```
You are placing images for a rebranded website. Full Bash, Read permissions.

AGENT_DIR: {AGENT_DIR}
PROJECT_DIR: {PROJECT_DIR}
PRODUCT: {PRODUCT_NAME}
GENERATE SCRIPT: {AGENT_DIR}/.claude/skills/rebrand-project/scripts/generate_image.py
PDP IMAGES DIR: {REBRAND_SOURCE_DIR}/images/
REFERENCE PRODUCT IMAGE: {REBRAND_SOURCE_DIR}/images/{PDP_PRODUCT_FILE}

SETUP:
export GEMINI_API_KEY=$(grep -E "NANOBANANA_GEMINI_API_KEY|GEMINI_API_KEY" "{AGENT_DIR}/.env" | head -1 | cut -d'=' -f2)

First READ the reference product image to understand the product visually.

IMAGES TO PROCESS (from image map):
[For each image in batch:]
- File: {img_filename} | Dimensions: {W}x{H}px | Context: {surrounding text}

For each image slot:
1. Get original dimensions: node -e "require('sharp')('{PROJECT_DIR}/images/{img_filename}').metadata().then(m=>console.log(m.width+'x'+m.height))"
2. Decide: COPY a PDP image or GENERATE a new one
3. Read the surrounding HTML text to understand what this image section is about
4. Build a prompt based on the surrounding content and image role

COPY — when a PDP image fits the slot:
cp "{source_pdp_image}" "{PROJECT_DIR}/images/{img_filename}"
node -e "require('sharp')('{PROJECT_DIR}/images/{img_filename}').resize({W},{H},{fit:'cover'}).toBuffer().then(b=>require('fs').writeFileSync('{PROJECT_DIR}/images/{img_filename}',b))"

GENERATE — for hero, lifestyle, feature, avatar, background, competitor, or when no PDP image fits:
python "{AGENT_DIR}/.claude/skills/rebrand-project/scripts/generate_image.py" \
  --reference "{REBRAND_SOURCE_DIR}/images/{PDP_PRODUCT_FILE}" \
  --prompt "{prompt based on surrounding text and image role}" \
  --output "{PROJECT_DIR}/images/{img_filename}" \
  --width {W} --height {H}

For non-product images (avatar, background), omit --reference:
python "{AGENT_DIR}/.claude/skills/rebrand-project/scripts/generate_image.py" \
  --prompt "{prompt}" \
  --output "{PROJECT_DIR}/images/{img_filename}" \
  --width {W} --height {H}

SKIP: .bin files (1x1 tracking pixels), SVG icon files (arrows, checkmarks, stars)
```

### Image Agent 2 — second batch
*(Same prompt as Image Agent 1, next batch of images)*

### Image Agent 3 — third batch (only if 9+ images total)
*(Same prompt, remaining images)*

---

## Phase 4 — Stale Text Sweep (main agent, REQUIRED — run immediately after Phase 3)

This catches any text the agents missed. Run BOTH passes.

> **CRITICAL — Loop Until Zero:** Every grep and browser check MUST be repeated in a loop until ZERO matches remain. Finding a match, fixing it once, and moving on is NOT enough. After each Edit fix, re-run the same grep immediately. Only move to the next check when the grep returns zero results. Do not proceed to Phase 5 until both Pass 1 and Pass 2 are completely clean.

### Pass 1: Grep sweep (no server needed — run first, fast)

You have ORIGINAL_BRAND_NAME from Analysis Agent 2 and BRAND_NAME from Analysis Agent 1.

```bash
# 1. Check for original brand name still in HTML
grep -in "{ORIGINAL_BRAND_NAME}" "$PROJECT_DIR/index.html" | grep -v "style=\|<script\|class=" | head -20

# 2. Check for common Shopify/template placeholder text
grep -in "Summer 20[0-9][0-9]\|flagship store\|Shop dresses\|breezy\|Encinitas\|email a month\|biggest and best sales\|favourite looks\|fun in the sun" "$PROJECT_DIR/index.html" | grep -v "style=\|<script" | head -20

# 3. Check for old product/competitor names
grep -in "{OLD_PRODUCT_NAME}" "$PROJECT_DIR/index.html" | grep -v "style=\|<script\|class=" | head -20

# 4. Full paragraph text check — verify NO sentence from the original site remains verbatim
# Sample 20 visible paragraph strings from the current HTML and check each against the original
node -e "
const fs=require('fs');
const h=fs.readFileSync('$PROJECT_DIR/index.html','utf8');
const m=[...h.matchAll(/<p>([^<]{30,})<\/p>/g)];
const s=new Set(m.map(x=>x[1].trim().substring(0,120)));
[...s].slice(0,20).forEach(t=>console.log(t));
" 2>/dev/null

# 5. QA: Verbatim PDP copy check — verify NO text was copied word-for-word from the PDP reference
# Read content.json from rebrand-source, extract key text strings (headings, paragraphs, features)
# Then grep for each in the rebranded HTML — any exact match (8+ words) must be reworded
node -e "
const fs=require('fs');
try {
  const c=JSON.parse(fs.readFileSync('$REBRAND_SOURCE_DIR/content.json','utf8'));
  const texts=[];
  const extract=(o)=>{if(typeof o==='string'&&o.trim().length>40)texts.push(o.trim().substring(0,100));if(Array.isArray(o))o.forEach(extract);if(o&&typeof o==='object'&&!Array.isArray(o))Object.values(o).forEach(extract);};
  extract(c);
  const h=fs.readFileSync('$PROJECT_DIR/index.html','utf8').toLowerCase();
  texts.forEach(t=>{if(h.includes(t.toLowerCase().substring(0,60)))console.log('VERBATIM_MATCH: '+t);});
} catch(e){}
" 2>/dev/null

# 6. AI writing pattern check — catch em dashes and banned AI words
grep -n "—" "$PROJECT_DIR/index.html" | grep -v "<script\|<style\|class=\|style=" | head -20
grep -in "additionally\|crucial\|pivotal\|enhance\|foster\|highlight\|underscore\|showcase\|testament\|tapestry\|delve\|vibrant\|groundbreaking\|seamless\|intuitive\|garner" "$PROJECT_DIR/index.html" | grep -v "<script\|<style\|class=\|style=" | head -20
grep -in "serves as\|stands as\|boasts\|nestled\|breathtaking\|renowned\|stunning\|interplay\|intricate" "$PROJECT_DIR/index.html" | grep -v "<script\|<style\|class=\|style=" | head -20
```

For EACH match found in any check above:
1. Read surrounding HTML to understand the element
2. Use Edit tool to replace with fresh content. Follow the Writing Rules at the top of this skill (humanizer, role, angle, custom instructions).
3. **Immediately re-run the same grep** — do NOT move on until it returns zero matches
4. If the same string appears multiple times in the file, replace ALL occurrences (use replace_all=true or loop)

**Loop rule:** Run all 4 checks repeatedly until every single one returns zero matches. Only then proceed to Pass 2.

### Pass 2: Browser sweep (catches dynamically rendered text)

Start preview server:
```bash
cd "$PROJECT_DIR" && npx serve --listen 3000 > /dev/null 2>&1 & sleep 3 && cd "$AGENT_DIR"
```

Extract all visible text via Chrome DevTools:
```javascript
// mcp__chrome-devtools__navigate_page → http://localhost:3000
// mcp__chrome-devtools__evaluate_script:
() => {
  const w = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
  const out = []; let n;
  while (n = w.nextNode()) {
    const t = n.textContent.trim();
    const p = n.parentElement;
    if (t.length > 15 && p.tagName !== 'SCRIPT' && p.tagName !== 'STYLE') out.push(t.substring(0,200));
  }
  return [...new Set(out)];
}
```

Flag any string that:
- Contains old brand or product name
- Is clearly a template placeholder (unrelated to PDP product)
- References wrong category or wrong product
- Is the same sentence as the original source site (verbatim carry-over)

For each flagged string:
```bash
grep -n "flagged text fragment" "$PROJECT_DIR/index.html"
```
Then Edit tool to fix. Follow the Writing Rules at the top of this skill (humanizer, role, angle, custom instructions). **Re-run the browser text extraction after every batch of fixes** and repeat the flagging process.

### Pass 3: Duplicate image check (visual via MCP)

Take screenshots section by section — scroll through the entire page:
```javascript
// mcp__chrome-devtools__take_screenshot fullPage:false → check hero section
// mcp__chrome-devtools__evaluate_script: () => window.scrollBy(0, 800)
// mcp__chrome-devtools__take_screenshot → next section
// Repeat until bottom of page
```

While reviewing each screenshot, check if any two image slots show the **same photo** (even with different filenames — PDP source can have duplicates under different names). If duplicates found:
1. Identify which image file to replace (keep the one in the more prominent slot)
2. Generate a new unique image:
```bash
export GEMINI_API_KEY=$(grep -E "NANOBANANA_GEMINI_API_KEY|GEMINI_API_KEY" "$AGENT_DIR/.env" | head -1 | cut -d'=' -f2)
python "$AGENT_DIR/.claude/skills/rebrand-project/scripts/generate_image.py" \
  --reference "{REBRAND_SOURCE_DIR}/images/{PDP_PRODUCT_FILE}" \
  --prompt "{new prompt based on the surrounding section text}" \
  --output "{PROJECT_DIR}/images/{duplicate_img_filename}" \
  --width {W} --height {H}
```
3. Re-screenshot that section to verify the duplicate is gone

Only proceed to Phase 5 when: zero flagged text strings AND zero duplicate images remain.

---

## Phase 5 — Verify + Push

Take a final full-page screenshot to confirm everything looks correct. Fix any visual issues, then push:

```bash
cd "$PROJECT_DIR"
git config user.name "$GITHUB_USER"
git config user.email "$GITHUB_EMAIL"
git add index.html images/
git commit -m "feat: rebrand with content from $REFERENCE_URL"
git push origin main
cd "$AGENT_DIR"
rm -rf "$REBRAND_SOURCE_DIR"
rm -f "$PROJECT_DIR/index.html.backup"
echo "Done: https://github.com/${GITHUB_USER}/${PROJECT_NAME}"
```

---

## Rules

**Change:** text between tags · `alt` · `aria-label` · `placeholder` · `<title>` · `<meta content>` · image files (overwrite + resize to slot dimensions)

**Never touch:** HTML tags · class/ID/data-* attributes · style blocks · CSS · src/href/srcset paths · script blocks · layout/colors/fonts/spacing

**Agent count formula:** `ceil(total_lines / 300)` — min 2, max 8
- ~600 lines → 2 agents
- ~900 lines → 3 agents
- ~1200 lines → 4 agents
- ~1800 lines → 6 agents
- ~2400+ lines → 8 agents

**Logo sizing rule:** ALWAYS read original logo height FIRST (before overwriting). Resize PDP logo to that SAME height using `convert -resize x{H}` (height-only, width auto). NEVER use `convert -resize WxH!` (the `!` forces distortion). With `object-fit:scale-down` in CSS, a smaller logo renders naturally — that is correct, not a bug.

**Images:** Copy from PDP source when a suitable image exists. Generate new images using `generate_image.py` for everything else. Duplicate images are caught in Phase 4 Pass 3 (browser screenshot check) and replaced with newly generated ones.

**Image generation script:** `.claude/skills/rebrand-project/scripts/generate_image.py` — accepts `--reference` (PDP product image), `--prompt`, `--output`, `--width`, `--height`. Always pass `--width` and `--height` matching the original image dimensions so layout is preserved. For product-related images, pass `--reference` so the generated image matches the real product. For avatars/backgrounds, omit `--reference`.

**Layout preservation via image sizing (CRITICAL):** Every replacement image MUST be resized to the exact pixel dimensions of the original project image it replaces. Get original dimensions first: `node -e "require('sharp')('PROJECT_IMAGE').metadata().then(m=>console.log(m.width+'x'+m.height))"` — then resize the PDP source to that exact `WxH` using `{fit:'cover'}`. This ensures the layout is 100% identical to the original site. Hero images must be landscape (wider than tall) — a portrait or square image in a landscape slot expands the page height and breaks the above-the-fold layout.

**Agent speed:** All Phase 3 agents (text + logo + image) MUST launch in a single parallel message. Text agents must edit HTML directly using the Edit tool — no node scripts, no intermediate files, no analysis loops. Read the section once, then fire all Edit calls. Parallel execution is mandatory — never run agents sequentially.

**Text generation rule:** If PDP content has no direct match for a slot, write NEW content relevant to the PDP product and brand. Follow the Writing Rules at the top of this skill. Never leave old/unrelated text — every visible string must reflect the PDP brand.

**Full rewrite rule (CRITICAL):** Every visible text string MUST be reworded in fresh language — even if the original site already promoted the same product (e.g., an affiliate article). Keeping the same sentences makes the rebranded site look identical to the source site. Use the PDP content as the source of truth but always paraphrase: new sentence structure, different word choices, same meaning. Zero original phrasing should survive in the output. This applies to ALL text — not just headings. Every paragraph sentence, every bullet point, every step description, every testimonial, every FAQ answer must be rewritten.

**Human writing rule (CRITICAL):** All text MUST follow the Writing Rules at the top of this skill. The humanizer skill is the single source of truth for writing quality — every agent reads it once, follows it everywhere. No duplicated rules needed.
