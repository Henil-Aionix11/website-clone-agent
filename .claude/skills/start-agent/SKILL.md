---
name: start-agent
description: Initialize WebForge agent and verify all dependencies
user-invocable: true
---

# /start-agent

Initialize the WebForge agent and verify all dependencies are available.

**Note:** This command only checks dependencies - it does NOT run setup scripts. Run `setup.bat` (Windows) or `./setup.sh` (Mac/Linux) manually if needed.

## What It Checks

1. **Git installation**
2. **GitHub CLI installation**
3. **Node.js installation**
4. **GITHUB_TOKEN in .env**
5. **FAL_KEY in .env** (optional)
6. **Fal.ai skills exist** (optional)

## Flags

| Flag | Description |
|------|-------------|
| `--verbose` | Show detailed output |

## Implementation

### Step 1: Show Header

```bash
echo "🔥 WebForge Agent Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
```

### Step 2: Check Git

```bash
# Check Git
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version 2>/dev/null | awk '{print $3}' || echo "installed")
    echo "✅ Git:           $GIT_VERSION"
    GIT_OK=true
else
    echo "❌ Git:           not installed"
    echo "   Install: https://git-scm.com/"
    GIT_OK=false
fi
```

### Step 3: Check GitHub CLI

```bash
# Check GitHub CLI
if command -v gh &> /dev/null; then
    GH_VERSION=$(gh --version 2>/dev/null | head -1 | awk '{print $3}' || echo "installed")
    echo "✅ GitHub CLI:    $GH_VERSION"
    GH_OK=true
else
    echo "❌ GitHub CLI:    not installed"
    echo "   Windows: winget install GitHub.cli"
    echo "   macOS: brew install gh"
    echo "   Linux: Visit https://cli.github.com/"
    GH_OK=false
fi
```

### Step 4: Check Node.js

```bash
# Check Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version 2>/dev/null || echo "installed")
    echo "✅ Node.js:       $NODE_VERSION"
    NODE_OK=true
else
    echo "⚠️  Node.js:       not installed (optional, for running websites)"
    echo "   Install: https://nodejs.org/"
    NODE_OK=false
fi
```

### Step 5: Verify GITHUB_TOKEN

```bash
echo ""
# Check .env file exists
if [ ! -f .env ]; then
    echo "❌ .env file:     not found"
    echo "   Create .env file with your tokens:"
    echo "   GITHUB_TOKEN=ghp_your_token_here"
    echo "   FAL_KEY=fal_your_key_here"
    TOKEN_OK=false
else
    # Check GITHUB_TOKEN
    GITHUB_TOKEN=$(grep GITHUB_TOKEN .env | cut -d'=' -f2 | tr -d ' ')
    if [ -n "$GITHUB_TOKEN" ] && [ "$GITHUB_TOKEN" != "ghp_your_token_here" ]; then
        echo "✅ GITHUB_TOKEN:  configured"
        export GH_TOKEN="$GITHUB_TOKEN"
        TOKEN_OK=true
    else
        echo "❌ GITHUB_TOKEN:  not configured"
        echo "   Get token at: https://github.com/settings/tokens"
        echo "   Required scopes: repo, workflow"
        echo "   Add to .env: GITHUB_TOKEN=your_token_here"
        TOKEN_OK=false
    fi

    # Check FAL_KEY (optional)
    FAL_KEY=$(grep FAL_KEY .env | cut -d'=' -f2 | tr -d ' ')
    if [ -n "$FAL_KEY" ] && [ "$FAL_KEY" != "fal_your_key_here" ]; then
        echo "✅ FAL_KEY:       configured (AI image generation)"
    else
        echo "⚠️  FAL_KEY:       not configured (optional, for AI image generation)"
        echo "   Get key at: https://fal.ai/dashboard/keys"
    fi
fi
```

### Step 6: Verify Fal.ai Skills (optional)

```bash
# Check if Fal skills exist
if [ -d "skills/fal" ] && [ -f "skills/fal/skills/claude.ai/fal-generate/scripts/generate.sh" ]; then
    echo "✅ Fal skills:    ready (AI image generation)"
else
    echo "⚠️  Fal skills:    not found (optional, for AI image generation)"
    echo "   The setup script will clone these skills"
fi
```

### Step 8: Count GitHub Projects

```bash
echo ""
# Count remote projects using github-manager
if [ "$TOKEN_OK" = true ] && [ "$GH_OK" = true ]; then
    REPO_COUNT=$(count_webforge_repos)
    echo "📊 GitHub Projects: $REPO_COUNT"
fi
```

### Step 9: Check GitHub Authentication

```bash
echo ""
if [ "$TOKEN_OK" = true ] && [ "$GH_OK" = true ]; then
    GITHUB_USER=$(get_github_username)
    echo "✅ GitHub:        authenticated as $GITHUB_USER"
else
    echo "❌ GitHub:        not authenticated"
fi
```

### Step 10: Show Issues and Next Steps

```bash
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if there are any critical issues
if [ "$GIT_OK" = false ] || [ "$GH_OK" = false ] || [ "$TOKEN_OK" = false ]; then
    echo ""
    echo "⚠️  Issues detected. To fix:"
    echo ""

    if [ "$GIT_OK" = false ]; then
        echo "   1. Install Git: https://git-scm.com/"
    fi

    if [ "$GH_OK" = false ]; then
        echo "   2. Install GitHub CLI:"
        echo "      Windows: winget install GitHub.cli"
        echo "      macOS: brew install gh"
        echo "      Then run: gh auth login"
    fi

    if [ "$TOKEN_OK" = false ]; then
        echo "   3. Get GitHub token: https://github.com/settings/tokens"
        echo "      Required scopes: repo, workflow"
        echo "      Add to .env: GITHUB_TOKEN=your_token_here"
    fi

    echo ""
    echo "After fixing, run /start-agent again to verify."
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
    echo ""
    echo "🚀 All systems ready! You can now use WebForge commands."
    echo ""
    echo "Available commands:"
    echo "  /get-projects     - List all your projects"
    echo "  /new-project      - Create a new project"
    echo "  /modify-project   - Modify existing project"
    echo "  /delete-project   - Delete a project"
    echo "  /help             - Show all commands"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi
```

## Output Format

### All Systems Ready

```
🔥 WebForge Agent Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Git:           v2.43.0
✅ GitHub CLI:    v2.52.0
✅ Node.js:       v20.11.0

✅ GITHUB_TOKEN:  configured
✅ FAL_KEY:       configured (AI image generation)

✅ Fal skills:    ready (AI image generation)
📊 GitHub Projects: 5
✅ GitHub:        authenticated as username

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚀 All systems ready! You can now use WebForge commands.

Available commands:
  /get-projects     - List all your projects
  /new-project      - Create a new project
  /modify-project   - Modify existing project
  /delete-project   - Delete a project
  /help             - Show all commands

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Issues Detected

```
🔥 WebForge Agent Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Git:           v2.43.0
❌ GitHub CLI:    not installed
   Windows: winget install GitHub.cli
   macOS: brew install gh
   Linux: Visit https://cli.github.com/

✅ Node.js:       v20.11.0

❌ GITHUB_TOKEN:  not configured
   Get token at: https://github.com/settings/tokens
   Required scopes: repo, workflow
   Add to .env: GITHUB_TOKEN=your_token_here

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  Issues detected. To fix:

   1. Install GitHub CLI:
      Windows: winget install GitHub.cli
      macOS: brew install gh
      Then run: gh auth login

   2. Get GitHub token: https://github.com/settings/tokens
      Required scopes: repo, workflow
      Add to .env: GITHUB_TOKEN=your_token_here

After fixing, run /start-agent again to verify.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
