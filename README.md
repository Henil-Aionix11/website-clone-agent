# WebForge

AI agent that clones websites, rebrands them with product content, and manages them on GitHub.

@AGENT.md

---

## Quick Start

### Prerequisites

| Tool | Purpose | Install |
|------|---------|---------|
| **Claude Code** | Run WebForge | [Download](https://claude.ai/download) |
| **Git** | Version control | [git-scm.com](https://git-scm.com/) |
| **GitHub CLI (`gh`)** | GitHub operations | `winget install GitHub.cli` (Windows) |
| **Node.js** | HTML generation + preview | [nodejs.org](https://nodejs.org/) |
| **Python 3** | Playwright extraction + image generation | [python.org](https://python.org/) |

### Setup

```bash
# Windows
setup.bat

# Mac/Linux
chmod +x setup.sh && ./setup.sh
```

### Add Your Tokens

Edit `.env`:

```bash
# Required — GitHub repo operations
GITHUB_TOKEN=ghp_your_token_here

# Required — AI image generation
GEMINI_API_KEY=your_key_here
```

### Start

```
Open Claude Code → Navigate to this folder → Type: /new-project
```

---

## Commands

| Command | Description |
|---------|-------------|
| `/new-project` | Clone a website into a static HTML project |
| `/rebrand-project` | Replace all text + images with PDP product content |
| `/modify-project` | Make manual edits to a project |
| `/get-projects` | List all WebForge projects |
| `/delete-project` | Delete a project |

---

## Workflow

```
/new-project          Clone a reference website
      |
/rebrand-project      Swap all content with a PDP product
      |
/modify-project       Tweak anything if needed
      |
   Pushed to GitHub   Auto-pushed at end of each step
```

### `/new-project` — Clone a Website
1. Provide a reference URL
2. Playwright extracts the full page (HTML, CSS, images, fonts)
3. Generates a static HTML project in `projects/`
4. Creates a private GitHub repo and pushes

### `/rebrand-project` — Replace All Content
1. Pick an existing project + provide a PDP reference URL
2. Extracts all text + images from the PDP page
3. Parallel agents replace every visible text string and image
4. Text from PDP copied exactly; gaps filled by AI
5. Product images from PDP; hero/lifestyle/competitor images AI-generated
6. Stale sweep ensures zero old text remains
7. Auto-pushes to GitHub

### `/modify-project` — Edit a Project
1. Select a project and describe what to change
2. Changes applied directly and pushed

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
│   ├── github-manager/      # GitHub reference patterns
│   ├── humanizer/           # AI writing quality rules
│   └── perfect-web-clone/   # Playwright extraction engine
├── projects/                # Your forged projects
├── .env                     # API tokens
├── AGENT.md                 # Agent instructions
├── setup.bat                # Windows setup
└── setup.sh                 # Mac/Linux setup
```

---

## Authentication

### GitHub Token
1. Go to: https://github.com/settings/tokens
2. Generate new token (classic) with scopes: `repo`, `delete_repo`
3. Add to `.env`: `GITHUB_TOKEN=ghp_your_token`

### Gemini API Key
1. Get key from [Google AI Studio](https://aistudio.google.com/apikey)
2. Add to `.env`: `GEMINI_API_KEY=your_key`

---

## Usage Examples

### Clone + Rebrand a Website
```
/new-project
> Project name: my-product-page
> Reference URL: https://example.com/some-product

/rebrand-project
> Select project: my-product-page
> PDP URL: https://newbrand.com/products/their-product
```

### List and Manage Projects
```
/get-projects           # See all GitHub projects
/delete-project         # Interactive deletion (removes GitHub + local)
```

### Modify a Project
```
/modify-project
> Select project: my-product-page
> What to change: Update the hero heading to "New Title Here"
```

---

## How It Works

WebForge uses AI skill files — no hardcoded logic:

1. You type a command (e.g., `/new-project`)
2. Claude reads the skill file (`.claude/skills/new-project/SKILL.md`)
3. Claude executes the steps using tools (Bash, Edit, MCP)
4. Results pushed to GitHub automatically

Each skill is a markdown file with step-by-step instructions that Claude follows.

---

## License

MIT
