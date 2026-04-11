# 🔥 WebForge

**AI-driven agent that forges websites from references** - Works on Claude Code and Codex/Cursor with NO hardcoded code!

<!-- Agent Instructions -->
@AGENT.md

---

## ⚡ Quick Start

### Prerequisites (Install Once)

| Tool | Required For | Install |
|------|--------------|---------|
| **Claude Desktop/Code** | Run WebForge | [Download](https://claude.ai/download) |
| **GitHub CLI (`gh`)** | GitHub operations | `winget install GitHub.cli` (Windows) |
| **Git** | Clone repository | [git-scm.com](https://git-scm.com/) |
| **Node.js** (optional) | Run cloned websites | [nodejs.org](https://nodejs.org/) |

### Setup (2 Minutes)

**Windows:**
```bash
# Clone the repository
git clone https://github.com/your-org/webforge.git
cd webforge

# Run setup (clones ai-cloner template)
setup.bat

# Edit .env and add your tokens
notepad .env
```

**Mac/Linux:**
```bash
# Clone the repository
git clone https://github.com/your-org/webforge.git
cd webforge

# Run setup (clones ai-cloner template)
chmod +x setup.sh && ./setup.sh

# Edit .env and add your tokens
nano .env
```

### Add Your Tokens

Edit `.env` and add:

```bash
# Required: Get from https://github.com/settings/tokens (scopes: repo, workflow)
GITHUB_TOKEN=ghp_your_token_here

# Optional: For AI image generation (Claude only) - Get from https://fal.ai/dashboard/keys
FAL_KEY=fal_your_key_here
```

### Start WebForge

1. Open **Claude Desktop** or **Claude Code**
2. Navigate to this folder
3. Type: `/start-agent`

---

## 🚀 Command-Based Interface

WebForge uses a command-based system. All commands start with `/`.

### Available Commands

| Command | Description |
|---------|-------------|
| `/start-agent` | Initialize agent, verify dependencies |
| `/get-projects` | List all your WebForge projects |
| `/new-project` | Create a new project |
| `/modify-project` | Modify existing project |
| `/delete-project` | Delete a project |
| `/preview-project` | Start dev server for a project |
| `/project-info` | Show project details |
| `/status` | Show agent status |
| `/help` | Show all commands with usage |

### Command Aliases

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

## 🎯 What WebForge Does

- 🌐 **Forge websites** - Clone any website using ai-website-cloner-template
- 📦 **GitHub integration** - Create repos, push code, manage everything
- 🔄 **Auto-sync** - Smart commits and automatic pushes
- ✏️ **Make changes** - Edit projects and keep them in sync

---

## 📁 Project Structure

```
webforge/
├── .claude/
│   └── skills/
│       ├── start-agent/           # Initialize and verify dependencies
│       ├── get-projects/          # List all projects
│       ├── new-project/           # Create new project
│       ├── modify-project/        # Modify existing project
│       ├── delete-project/        # Delete a project
│       ├── preview-project/       # Start dev server
│       ├── project-info/          # Show project details
│       ├── webforge-help/         # Show command help
│       ├── webforge-status/       # Show agent status
│       ├── webforge-image-gen/    # (Claude only) AI image generation
│       └── github-manager/        # GitHub helper functions
│
├── .codex/
│   └── skills/                    # Same structure for Codex
│
├── templates/
│   └── ai-cloner/                 # Website cloning template (auto-cloned)
│
├── projects/                       # Your forged projects
│
├── .env.example                    # Example environment variables
├── .gitignore
├── AGENT.md                        # Agent documentation
├── README.md
├── setup.bat                       # Windows setup script
└── setup.sh                        # Mac/Linux setup script
```

**Both platforms use the SAME command-based approach!**

---

## 🚀 Usage Examples

### Initialize WebForge
```
/start-agent
```

### Create a New Project
```bash
# Interactive mode - will prompt for name, visibility, and URL
/new-project

# With flags - skip prompts
/new-project --name <project-name> --visibility private --url <url>

# Skip preview
/new-project --name <project-name> --url <url> --no-preview
```

### List Projects
```bash
# Show all GitHub projects
/get-projects

# Show local projects only
/get-projects --local

# Show both local and remote
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
# Interactive mode - shows all GitHub projects
/delete-project

# With flags - skip confirmation
/delete-project --name <project-name> --force
```

### Preview a Project
```bash
# Interactive mode
/preview-project

# With custom port
/preview-project --name <project-name> --port 3001
```

### Get Project Info
```bash
/project-info --name <project-name>
```

### Get Help
```bash
# Show all commands
/help

# Show help for specific command
/help --command new-project
```

---

## 🔐 Authentication

WebForge needs a **GitHub Personal Access Token** to:
- Create repositories
- Clone websites
- Push code to GitHub

### Get Your Token

1. Go to: https://github.com/settings/tokens
2. Click "Generate new token" → "Generate new token (classic)"
3. Select scopes: `repo`, `workflow`
4. Generate and copy the token

### Add Token to WebForge

**Option 1: .env file (Recommended)**
```bash
# Copy example file
cp .env.example .env

# Edit .env and add your token
GITHUB_TOKEN=ghp_your_token_here
```

**Option 2: Provide when prompted**
- WebForge will ask for your token on first use
- You can choose to save it to .env for future use

---

## 💬 Example Conversations

### First Time User
```
You: /start-agent

WebForge: 🔥 WebForge Agent Status
          ✅ Git: installed (v2.43.0)
          ✅ GitHub CLI: installed (v2.52.0)
          ✅ GITHUB_TOKEN: configured
          ✅ ai-cloner: ready
          📊 GitHub Projects: 0

          🚀 All systems ready! Type /help to see all commands.

You: /new-project

WebForge: 🔨 Project name: _
You: <project-name>

WebForge: 🔒 Visibility (public/private): _
You: private

WebForge: 🌐 Reference URL: _
You: <url>

WebForge: ✅ Creating repository...
          ✅ Repository created: github.com/<user>/<project-name>
          🔨 Cloning <url>...
          ✅ Clone complete!
          ✅ Project created: projects/<project-name>

          🔥 Preview running at: http://localhost:3000
          Open the URL above in your browser to see the forged website.

          📤 Ready to push to GitHub? Say 'push' or 'yes' to continue.

You: push

WebForge: ✅ Pushed to GitHub!

          🔥 Project forged successfully!

          ┌─────────────────────────────────────┐
          │ 📦 Project: <project-name>          │
          │ 🔗 GitHub: github.com/<user>/<project-name> │
          │ 🌐 Forged from: <url>               │
          └─────────────────────────────────────┘
```

### Making Changes
```
You: /modify-project

WebForge: 🔥 Available Projects
          1. <project-name> ● Local

          📍 Select project (name/number): _

You: 1

WebForge: 📍 Working on: <project-name>
          🔗 GitHub: https://github.com/<user>/<project-name>

          💬 What changes would you like to make?

You: Change the hero to dark blue

WebForge: 🔨 Applying changes...
          🔥 Preview running at: http://localhost:3000

          📤 Ready to push to GitHub? Say 'push' or 'yes' to continue.

You: push

WebForge: 📝 Commit message (or press Enter for default):
          Default: 'feat: update website'
You: style: change hero to dark blue

WebForge: ✅ Changes pushed to GitHub!
          🔗 View: https://github.com/<user>/<project-name>/commits
```

---

## 🎨 Why WebForge?

| Traditional Code | WebForge AI-Driven |
|-----------------|-------------------|
| Hardcoded functions | AI interprets intent |
| Limited variations | Handles anything |
| Break on edge cases | AI adapts |
| Learn commands | Natural language |

---

## 🛠️ How It Works

WebForge uses a **command-based system** with AI instructions:

1. **You type a command** → `/new-project --name <project-name> --url <url>`
2. **AI reads command handler** → Reads `.claude/skills/<command>/SKILL.md`
3. **AI executes the steps** → Creates repo, clones site, pushes to GitHub
4. **No hardcoded code** → AI adapts to any request via skill files

---

## 📦 Requirements

### ✅ Included in Repository (No Install Needed)

- All WebForge skills and instructions
- GitHub management logic
- Documentation
- **ai-cloner template** - Auto-cloned on setup (~200MB)

### ⚠️ Must Install Manually

| Tool | Why | How to Install |
|------|-----|----------------|
| **Claude Desktop/Code** | Required to run the agent | [claude.ai/download](https://claude.ai/download) |
| **GitHub CLI (`gh`)** | For GitHub operations | `winget install GitHub.cli` (Windows) |
| **Git** | To clone the repo | [git-scm.com](https://git-scm.com/) |
| **Node.js** | To run forged websites | [nodejs.org](https://nodejs.org/) (optional) |

### 🔑 API Tokens Required

| Token | Required | Purpose | Get It Here |
|-------|----------|---------|-------------|
| **GITHUB_TOKEN** | ✅ Yes | Create repos, push code | [github.com/settings/tokens](https://github.com/settings/tokens) |
| **FAL_KEY** | ⚠️ Optional | AI image generation (Claude) | [fal.ai/dashboard/keys](https://fal.ai/dashboard/keys) |

> 💡 Run `setup.bat` (Windows) or `./setup.sh` (Mac/Linux) to verify everything is configured!

---

## 🔄 Updating

To get the latest updates:

```bash
git pull origin main
cd templates/ai-cloner
git pull origin main
npm install
```

---

## 🤝 Contributing

WebForge works through **AI instructions**, not code. To add capabilities:

1. Edit `.claude/skills/<command-name>/SKILL.md`
2. Edit `.codex/skills/<command-name>/SKILL.md` (keep them in sync!)
3. Test by chatting with Claude

---

## 📄 License

MIT

---

## 🎉 Ready to Forge?

### How to Access WebForge

After setup, use the command-based interface:

#### Method 1: Initialize and Start
```
Open Claude → Navigate to this folder → Type: /start-agent
```

#### Method 2: Create Your First Project
```
/new-project --name <project-name> --url <url>
```

#### Method 3: See All Commands
```
/help
```

### Quick Checklist

1. ✅ Clone this repo
2. ✅ Run `setup.bat` or `./setup.sh`
3. ✅ Add tokens to `.env` file
4. ✅ Open Claude Desktop/Code in this folder
5. ✅ Type: `/start-agent`
6. ✅ Type: `/new-project` to create your first project

**🔥 Let's forge something amazing!**
