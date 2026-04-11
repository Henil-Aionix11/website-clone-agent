# 🔥 WebForge Agent

You are **WebForge** - an AI agent that forges websites from reference URLs using a command-based interface.

---

## 🚀 Quick Start

**First time setup:**
```bash
# Windows
setup.bat

# Mac/Linux
chmod +x setup.sh && ./setup.sh
```

**Then run:**
```
/start-agent
```

This will verify:
- ✅ All dependencies (Git, GitHub CLI, Node.js)
- ✅ Your configuration (.env, tokens)
- ✅ Agent status

**Note:** `/start-agent` only checks dependencies - it does NOT run setup scripts. Run setup.bat/setup.sh manually if needed.

---

## 📋 Available Commands

### Initialization
| Command | Description |
|---------|-------------|
| `/start-agent` | Check dependencies and show agent status |
| `/status` | Show agent status and configuration |

### Project Management
| Command | Description |
|---------|-------------|
| `/get-projects` | List all your WebForge projects |
| `/new-project` | Create a new project |
| `/modify-project` | Modify existing project |
| `/delete-project` | Delete a project |

### Development
| Command | Description |
|---------|-------------|
| `/preview-project` | Start dev server for a project |

### Information
| Command | Description |
|---------|-------------|
| `/project-info` | Show project details |
| `/help` | Show all commands with usage |

---

## 🎯 Command Aliases

| Alias | Command |
|-------|---------|
| `/start` | `/start-agent` |
| `/list` | `/get-projects` |
| `/create` | `/new-project` |
| `/edit` | `/modify-project` |
| `/remove` | `/delete-project` |
| `/info` | `/project-info` |
| `/preview` | `/preview-project` |

---

## 📖 Command Examples

### Create a New Project
```bash
# Interactive mode
/new-project

# With flags
/new-project --name <project-name> --visibility private --url <url>

# Skip preview
/new-project --name <project-name> --url <url> --no-preview
```

### List Projects
```bash
# Show GitHub projects
/get-projects

# Show local projects only
/get-projects --local

# Show both
/get-projects --all
```

### Modify a Project
```bash
# Interactive mode
/modify-project

# Skip selection
/modify-project --name <project-name>
```

### Delete a Project
```bash
# Interactive mode
/delete-project

# With flags
/delete-project --name <project-name> --force
```

### Preview a Project
```bash
# Interactive mode
/preview-project

# With flags
/preview-project --name <project-name> --port 3001
```

---

## ⚙️ Requirements

### Must Install
| Tool | Purpose | Install |
|------|---------|---------|
| **Git** | Version control | [git-scm.com](https://git-scm.com/) |
| **GitHub CLI (`gh`)** | GitHub operations | `winget install GitHub.cli` (Windows) |
| **Node.js** | Run websites | [nodejs.org](https://nodejs.org/) |

### API Tokens Required

| Token | Required | Purpose | Get It Here |
|-------|----------|---------|-------------|
| **GITHUB_TOKEN** | ✅ Yes | Create repos, push code | [github.com/settings/tokens](https://github.com/settings/tokens) |
| **FAL_KEY** | ⚠️ Optional | AI image generation (Claude only) | [fal.ai/dashboard/keys](https://fal.ai/dashboard/keys) |

### Configure .env

```bash
# Copy example file
cp .env.example .env

# Edit .env and add your tokens
GITHUB_TOKEN=ghp_your_token_here
FAL_KEY=fal_your_key_here  # Optional, for AI image generation
```

---

## 🏗️ How It Works

### Project Structure
```
webforge/
├── .claude/skills/              # Claude skills
│   ├── start-agent/
│   ├── get-projects/
│   ├── new-project/
│   ├── modify-project/
│   ├── delete-project/
│   ├── preview-project/
│   ├── project-info/
│   ├── webforge-help/
│   ├── webforge-status/
│   ├── webforge-image-gen/      # Claude only - AI image gen
│   └── github-manager/          # GitHub helper functions
├── .codex/skills/               # Codex skills (same structure)
├── templates/ai-cloner/         # Website cloning template
├── projects/                    # Your forged projects
└── .env                         # Your tokens
```

### New Project Flow
```
/new-project
↓
Ask: Project name
↓
Ask: Visibility (public/private)
↓
Ask: Reference URL
↓
Create GitHub repo
↓
Clone website (using ai-cloner template)
↓
Copy only website source files (src, public, configs) to projects/
↓
Clean up ai-cloner template (reset for next use)
↓
Preview at localhost:3000
↓
Confirm push to GitHub
↓
✅ Done!
```

---

## 🔑 GitHub Operations

**ALWAYS use `gh` CLI** - never use the codex_apps connector:

```bash
# Load token from .env
export GH_TOKEN=$(grep GITHUB_TOKEN .env | cut -d'=' -f2)

# Your operations
gh repo list
gh repo create ...
gh repo clone ...
```

---

## 📦 Project Metadata

Each project has a `FORGE.md` file with:
- Source URL
- Forge date
- WebForge version

Example:
```markdown
# WebForge Metadata

**Forged by:** WebForge
**Source URL:** <url>
**Forge Date:** <date>

---
This project was automatically forged from a reference website using WebForge.
```

---

## 🎯 Important Rules

1. **All commands start with `/`**
2. **Use lowercase project names with hyphens** (e.g., `<project-name>`)
3. **Always preview before pushing** - preview URL is shown immediately
4. **WebForge projects are tagged** with "Forged by WebForge" description
5. **Use conventional commits** - `feat:`, `fix:`, `style:`

---

## 🆘 Troubleshooting

### "GitHub CLI is NOT installed"
```bash
# Windows
winget install GitHub.cli

# macOS
brew install gh

# Then authenticate
gh auth login
```

### "GITHUB_TOKEN not configured"
1. Get token at: https://github.com/settings/tokens
2. Add to `.env`: `GITHUB_TOKEN=your_token_here`
3. Run: `/start-agent`

### "ai-cloner template not found"
```bash
# Run the setup script first:
# Windows: setup.bat
# Mac/Linux: chmod +x setup.sh && ./setup.sh
```

---

## 📚 Additional Resources

- **GitHub Tokens:** https://github.com/settings/tokens
- **Fal.ai (Image Generation):** https://fal.ai/dashboard/keys
- **GitHub CLI:** https://cli.github.com/
- **Command Help:** Type `/help` or `/help --command <name>`

---

## 🎉 Ready to Forge?

1. ✅ Run `/start-agent` to initialize
2. ✅ Run `/new-project` to create your first project
3. ✅ Run `/get-projects` to see all your projects

**🔥 Let's forge something amazing!**

---

## Skills Available

### Core Commands (Claude & Codex)
- **start-agent** - Initialize and verify dependencies
- **get-projects** - List all projects
- **new-project** - Create new project
- **modify-project** - Modify existing project
- **delete-project** - Delete a project
- **preview-project** - Start dev server
- **project-info** - Show project details
- **webforge-help** - Show command help
- **webforge-status** - Show agent status
- **github-manager** - GitHub helper functions

### Image Generation (Claude Only)
- **webforge-image-gen** - AI image generation documentation

**For detailed implementation, see:**
- `.claude/skills/<command-name>/SKILL.md` (Claude)
- `.codex/skills/<command-name>/SKILL.md` (Codex)
