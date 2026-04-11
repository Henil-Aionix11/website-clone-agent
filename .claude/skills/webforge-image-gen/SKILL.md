---
name: webforge-image-gen
description: Generate style-matched replacement images for cloned websites using Fal.ai skills. Documents how to use fal-generate skill within WebForge workflow.
---

# WebForge Image Generation

Generate AI-powered replacement images that match the style and theme of original website images using Fal.ai.

---

## Prerequisites

**Fal.ai API Key Required:** `FAL_KEY` in `.env` file

Get your key at: https://fal.ai/dashboard/keys

### Setup FAL_KEY

```bash
# Option 1: Add via fal-generate script
bash skills/fal/skills/claude.ai/fal-generate/scripts/generate.sh --add-fal-key

# Option 2: Add manually to .env
echo "FAL_KEY=your_actual_key_here" >> .env
```

---

## What This Does

When cloning a website, original images are copyrighted. This generates unique replacements that:
- **Match the color palette** of original images
- **Preserve the mood and style** (dark, light, vibrant, professional, etc.)
- **Maintain the subject category** (classroom, office, product, abstract, etc.)
- **Keep similar dimensions** for seamless replacement

**Images are searched recursively** throughout the entire `public/` folder, not just in `public/images/`. Small files (<10KB) like icons and favicons are automatically skipped.

---

## How to Generate Images

### Step 1: Find Images in the Project

```bash
# Find ALL images in the public folder (recursively)
find projects/PROJECT_NAME/public -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \)

# Skip small images (icons/logos) - only larger than 10KB
find projects/PROJECT_NAME/public -type f -size +10k \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \)
```

### Step 2: Generate Replacement Using fal-generate

The **fal-generate** skill is located at `skills/fal/skills/claude.ai/fal-generate/`

```bash
cd skills/fal/skills/claude.ai/fal-generate/scripts

# Basic image generation
bash generate.sh --prompt "modern classroom in dark grey tones, professional, educational" \
  --model "fal-ai/nano-banana-pro" \
  --size "landscape_4_3"
```

### Step 3: Download and Replace

The `generate.sh` script returns an image URL. Download it and replace the original:

```bash
# Download the generated image
curl -o "projects/PROJECT_NAME/public/images/new-image.jpg" "https://v3.fal.media/files/..."

# Or replace original
curl -o "projects/PROJECT_NAME/public/images/classroom.jpg" "https://v3.fal.media/files/..."
```

---

## Available Fal Skills

| Skill | Location | Purpose |
|-------|----------|---------|
| **fal-generate** | `skills/fal/skills/claude.ai/fal-generate/` | Generate images/videos |
| **fal-vision** | `skills/fal/skills/claude.ai/fal-vision/` | Analyze images (extract colors, style) |
| **fal-image-edit** | `skills/fal/skills/claude.ai/fal-image-edit/` | Edit existing images |

---

## fal-generate Options

```bash
bash skills/fal/skills/claude.ai/fal-generate/scripts/generate.sh \
  --prompt "your description here" \
  --model "fal-ai/nano-banana-pro" \
  --size "landscape_4_3" \
  --num-images 1
```

| Option | Values | Default |
|--------|--------|---------|
| `--prompt`, `-p` | Text description | (required) |
| `--model`, `-m` | Model ID | `fal-ai/nano-banana-pro` |
| `--size` | `square`, `portrait`, `landscape` | `landscape_4_3` |
| `--num-images` | Number of images | 1 |

### Recommended Models

| Model | Best For |
|-------|----------|
| `fal-ai/nano-banana-pro` | General purpose, fast |
| `fal-ai/flux-pro` | Photorealistic images |
| `fal-ai/stable-cascade` | Illustrations |

---

## Style Matching Strategy

### Analyze Original Image Style

Use filename and context to determine style:

| Filename Pattern | Detected Style | Prompt Keywords |
|------------------|----------------|-----------------|
| `*classroom*dark*` | Dark classroom | `classroom, dark grey tones, professional, muted lighting, educational` |
| `*hero*bright*` | Bright hero | `hero section, vibrant colors, modern, energetic, clean background` |
| `*office*minimal*` | Minimalist office | `office space, minimalist, light tones, clean, professional` |
| `*product*` | Product shot | `product photography, white background, studio lighting, professional` |

### Prompt Template

```
[subject_category] [context], [style_keywords] style, [color_description] color palette,
[mood] mood, professional, high quality
```

---

## Example Workflow

### Generating Multiple Images

```bash
# Set FAL_KEY first
export FAL_KEY=$(grep FAL_KEY .env | cut -d'=' -f2)

cd skills/fal/skills/claude.ai/fal-generate/scripts

# Generate hero image
bash generate.sh \
  --prompt "hero section, modern tech company, dark blue gradient, professional" \
  --model "fal-ai/nano-banana-pro" \
  --size "landscape_4_3"

# Generate feature image
bash generate.sh \
  --prompt "feature showcase, classroom setting, warm lighting, educational" \
  --model "fal-ai/nano-banana-pro" \
  --size "square"

# Generate about team image
bash generate.sh \
  --prompt "team collaboration, office environment, natural lighting, professional" \
  --model "fal-ai/nano-banana-pro" \
  --size "landscape_4_3"
```

---

## When FAL_KEY is Missing

### Display This Warning

```
┌─────────────────────────────────────────────────────────────┐
│  ⚠️  IMAGE GENERATION SKIPPED                                │
├─────────────────────────────────────────────────────────────┤
│  Reason: FAL_KEY not found in .env file                     │
│                                                              │
│  Using original images from cloned website.                 │
│                                                              │
│  To enable AI image generation:                             │
│  1. Get your API key: https://fal.ai/dashboard/keys         │
│  2. Run: bash skills/fal/skills/claude.ai/fal-generate/     │
│          scripts/generate.sh --add-fal-key                  │
│  3. Or add to .env: FAL_KEY=your_key_here                   │
│                                                              │
│  For more info: https://github.com/fal-ai-community/skills  │
└─────────────────────────────────────────────────────────────┘
```

### Check for FAL_KEY

```bash
# Check if FAL_KEY exists in .env
if [ -f ".env" ] && grep -q "^FAL_KEY=" .env && [ -n "$(grep FAL_KEY .env | cut -d'=' -f2)" ]; then
    echo "FAL_KEY found - image generation available"
else
    echo "FAL_KEY not found - using original images"
fi
```

---

## Integration with WebForge Workflow

This is used during the website forging process:

1. **After cloning** - Images are downloaded to `public/images/`
2. **Check for FAL_KEY** - If present, offer to generate replacements
3. **Generate images** - Use fal-generate with style-matched prompts
4. **Replace originals** - Backup and replace with generated images
5. **Continue preview** - Show the website with new images

If `FAL_KEY` is missing, show the warning above and continue with original images — **do not fail or halt**.

---

## Troubleshooting

### "FAL_KEY not set" error

Run:
```bash
bash skills/fal/skills/claude.ai/fal-generate/scripts/generate.sh --add-fal-key
```

### Generation takes too long

Use the `--async` flag to get a request ID immediately:
```bash
bash generate.sh --prompt "..." --async
```

Then check status later:
```bash
bash generate.sh --status "REQUEST_ID" --model "fal-ai/nano-banana-pro"
bash generate.sh --result "REQUEST_ID" --model "fal-ai/nano-banana-pro"
```

---

## Costs

Fal.ai pricing (approximate):
- `fal-ai/nano-banana-pro`: ~$0.0001 per image
- `fal-ai/flux-pro`: ~$0.003 per image

Check current pricing: https://fal.ai/pricing

---

## References

- Fal.ai Community Skills: https://github.com/fal-ai-community/skills
- Fal.ai Dashboard: https://fal.ai/dashboard
- Model Documentation: https://fal.ai/models
