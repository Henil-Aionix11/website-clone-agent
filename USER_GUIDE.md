# 🔥 WebForge Agent - User Guide

Complete step-by-step guide to use WebForge for cloning websites with AI.

---

## 🚀 Quick Start (3 Steps)

### Step 1: Run Setup

**Windows:**
```bash
setup.bat
```

**Mac/Linux:**
```bash
chmod +x setup.sh
./setup.sh
```

This will install all dependencies automatically.

---

### Step 2: Configure GitHub Token

1. Go to: https://github.com/settings/tokens
2. Click **"Generate new token"** → **"Generate new token (classic)"**
3. Name it: `WebForge`
4. Select scopes: ✅ **repo** (full control)
5. Click **"Generate token"** and copy the token (starts with `ghp_`)

Open the `.env` file in your WebForge folder and add your token:

```env
GITHUB_TOKEN=ghp_your_actual_token_here
```

---

### Step 3: Start Using WebForge

1. **Open Claude Desktop** or **Claude Code**
2. **File → Open Folder** → Select your WebForge folder
3. **Type in the chat:** `/start-agent`

That's it! You're ready to forge websites.

---

## 📖 Available Commands

| Command | Description |
|---------|-------------|
| `/start-agent` | Check if everything is ready |
| `/get-projects` | List all your projects |
| `/new-project` | Create a new project |
| `/modify-project` | Modify existing project |
| `/delete-project` | Delete a project |
| `/preview-project` | Start dev server for a project |
| `/project-info` | Show project details |

---

## 🔨 Creating Your First Project

```
/new-project
```

**WebForge will ask:**
```
🔨 Project name: _
```

**Type a name:** `my-portfolio`

```
🔒 Visibility (public/private): _
```

**Type:** `private` or `public`

```
🌐 Reference URL: _
```

**Paste a website URL:** `https://example.com`

WebForge will:
- ✅ Create GitHub repository
- ✅ Clone the website
- ✅ Start preview at http://localhost:3000
- 📤 Ask to push to GitHub

**Type:** `push` to confirm!

---

## 🔧 Modifying Projects

```
/modify-project
```

**Select a project** from the list

```
💬 What changes would you like to make?
```

**Describe your changes:** `Change the navbar to sticky`

WebForge will:
- 🔨 Apply changes
- 🔥 Start preview
- 📤 Ask to push

**Type:** `push` to confirm!

---

## ❓ Troubleshooting

**"GitHub CLI is NOT installed"**
```bash
# Windows
winget install GitHub.cli

# Mac
brew install gh
```

**"GITHUB_TOKEN not configured"**
1. Get token at: https://github.com/settings/tokens
2. Add to `.env`: `GITHUB_TOKEN=your_token_here`
3. Run: `/start-agent`

**"Port 3000 already in use"**
- WebForge automatically handles this
- If issues persist, restart your terminal

---

## 💡 Tips

1. **Start with simple websites** - Landing pages work best
2. **Use lowercase names** with hyphens: `my-portfolio`
3. **Always preview before pushing** - Check in your browser first

---

**Happy Forging!** 🔥🔨⚡
