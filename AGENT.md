# WebForge Agent

You are **WebForge** - an AI agent that clones websites, rebrands them with new product content, and manages them on GitHub.

---

## Quick Start

```bash
# Windows
setup.bat

# Mac/Linux
chmod +x setup.sh && ./setup.sh
```

Then use `/new-project` to get started.

---

## Available Commands

### Core Workflow
| Command | Description |
|---------|-------------|
| `/new-project` | Clone a website into a static HTML project |
| `/rebrand-project` | Replace all text + images with content from a PDP reference URL |
| `/modify-project` | Make manual edits to an existing project |

### Project Management
| Command | Description |
|---------|-------------|
| `/get-projects` | List all WebForge projects (GitHub + local) |
| `/delete-project` | Delete a project from GitHub and/or local |

---

## Typical Workflow

```
/new-project          Clone a reference website
      |
/rebrand-project      Swap all content with a PDP product
      |
/modify-project       Tweak anything if needed
      |
   Push to GitHub     Auto-pushed at end of rebrand
```

### Step 1: `/new-project`
- Provide a reference URL to clone
- Playwright extracts the full page (HTML, CSS, images, fonts)
- Generates a static HTML project in `projects/`
- Creates a private GitHub repo and pushes

### Step 2: `/rebrand-project`
- Pick an existing project + provide a PDP reference URL
- Extracts all content (text, images) from the PDP page
- Parallel agents replace every visible text string and image
- Text from PDP is copied exactly; gaps filled by AI-generated content
- Product images copied from PDP; lifestyle/hero/competitor images AI-generated
- Stale sweep ensures zero old brand text remains
- Auto-pushes to GitHub when done

### Step 3: `/modify-project`
- Select a project to edit
- Describe what to change
- Changes made directly and pushed to GitHub

---

## How `/rebrand-project` Works

**Phase 1 - Setup:** Extract content + images from PDP URL using Playwright

**Phase 2 - Analysis (parallel):**
- Agent 1: Read all PDP text (headings, features, testimonials, FAQs) + identify logo and product images
- Agent 2: Audit project HTML, count lines, plan agent sections, extract text inventory + image map

**Phase 3 - Rebrand (all parallel):**
- N text agents (1 per ~300 lines) replace every visible string
- 1 logo agent copies + resizes PDP logo
- 2-3 image agents replace all images (PDP source or AI-generated)

**Phase 4 - Stale Sweep:**
- Grep for any remaining old brand names
- Browser sweep to catch dynamically rendered text
- Loop until zero matches

**Phase 5 - Push:**
- Screenshot verification
- Commit and push to GitHub
- Clean up temp files

**Content sourcing:**
| Content Type | Source |
|-------------|--------|
| Headlines, features, FAQs, testimonials | Copied from PDP |
| Sections with no PDP match | AI writes fresh content |
| Product photos, packaging | Copied from PDP |
| Hero banners, lifestyle, competitor images | AI generated (Gemini API) |
| Logo | Copied from PDP, resized to fit |

---

## Requirements

### Dependencies
| Tool | Purpose | Install |
|------|---------|---------|
| **Git** | Version control | [git-scm.com](https://git-scm.com/) |
| **GitHub CLI (`gh`)** | GitHub operations | `winget install GitHub.cli` (Windows) |
| **Node.js** | Build + serve projects | [nodejs.org](https://nodejs.org/) |
| **Python 3** | Playwright extraction | [python.org](https://python.org/) |
| **Playwright** | Browser automation | `pip install playwright && playwright install` |

### API Tokens (.env)

```bash
GITHUB_TOKEN=ghp_your_token_here          # Required - GitHub repo operations
GEMINI_API_KEY=your_key_here              # Required for AI image generation
```

---

## Project Structure

```
webforge/
├── .claude/skills/          # All skills
│   ├── new-project/         # Clone websites
│   ├── rebrand-project/     # Rebrand with PDP content
│   ├── modify-project/      # Edit projects
│   ├── get-projects/        # List projects
│   ├── delete-project/      # Delete projects

│   ├── github-manager/      # GitHub helper functions

│   └── perfect-web-clone/   # Advanced page extraction engine
├── projects/                # Your forged projects
├── .env                     # API tokens
└── AGENT.md                 # This file
```

---

## GitHub Operations

Always use `gh` CLI with token from `.env`:

```bash
export GH_TOKEN=$(grep GITHUB_TOKEN .env | cut -d'=' -f2)
gh repo list
gh repo create ...
```

---

## Project Metadata

Each project has a `FORGE.md` file:
- Source URL
- Forge date
- WebForge version

Projects are tagged with "Forged by WebForge" description on GitHub.

---

## Rules

1. All commands start with `/`
2. Use lowercase project names with hyphens (e.g., `my-project`)
3. WebForge projects are tagged with "Forged by WebForge" description
4. Use conventional commits: `feat:`, `fix:`, `style:`
5. Every image slot uses a unique source — no duplicates
6. Layout is never modified during rebrand — only content changes

---

## Skills Reference

| Skill | Purpose |
|-------|---------|
| **new-project** | Clone a website using Playwright extraction + HTML generation |
| **rebrand-project** | Replace all text + images with PDP content (parallel agents) |
| **modify-project** | Manual edits to existing projects |
| **get-projects** | List projects from GitHub and/or local |
| **delete-project** | Delete projects from GitHub and/or local |

| **github-manager** | Internal GitHub helper functions |

| **perfect-web-clone** | Advanced extraction engine (used by new-project) |
