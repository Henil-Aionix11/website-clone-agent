---
name: modify-project
description: Modify an existing WebForge project (automatically clones if not local)
user-invocable: true
argument-hint: "--name <name>"
---

# /modify-project

Modify an existing WebForge project. Automatically clones if not available locally.

## What It Does

1. **List available projects** (local + GitHub)
2. **Ask to select a project**
3. **Clone if not local** (replaces /clone-project)
4. **Ask what changes to make**
5. **Apply changes**
6. **Run preview** at localhost:3000
7. **Auto-push changes** (no confirmation needed)

## Flags

| Flag | Description |
|------|-------------|
| `--name <name>` | Skip project selection |
| `--skip-preview` | Skip preview, push directly |

## Interactive Flow

```
/modify-project
↓
🔥 Your GitHub Projects
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  • project-1
  • project-2
  • project-3
↓
📍 Select project (name): _
↓
📍 Working on: <selected-project>
↓
💬 What changes would you like to make?
↓
[User describes changes]
↓
🔥 Preview: http://localhost:3000
↓
[Auto-push to GitHub — no confirmation needed]
↓
✅ Changes pushed!
```

## Implementation

### Step 1: Parse Flags

```bash
PROJECT_NAME=""
SKIP_PREVIEW=false

for arg in "$@"; do
    case $arg in
        --name=*)
            PROJECT_NAME="${arg#*=}"
            ;;
        --name)
            shift
            PROJECT_NAME="$1"
            ;;
        --skip-preview)
            SKIP_PREVIEW=true
            ;;
    esac
done
```

### Step 2: List Available Projects

```bash
# Store agent directory
AGENT_DIR="$(pwd)"

# Use github-manager to get username
GITHUB_USER=$(get_github_username)

if [ -z "$PROJECT_NAME" ]; then
    echo "🔥 Your GitHub Projects"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Show only GitHub projects
    get_webforge_repos_list | while read -r line; do
        repo_name=$(echo "$line" | awk '{print $1}')
        echo "  • $repo_name"
    done

    echo ""
    echo "📍 Select project (name): "
    read PROJECT_NAME
fi

# Set project directory
PROJECT_DIR="$AGENT_DIR/projects/$PROJECT_NAME"
```

### Step 3: Clone if Not Local

```bash
if [ ! -d "$PROJECT_DIR" ]; then
    echo "📥 Cloning $PROJECT_NAME from GitHub..."
    clone_webforge_repo "$PROJECT_NAME" "$PROJECT_DIR"
    echo "✅ Cloned successfully"
fi

cd "$PROJECT_DIR"

echo ""
echo "📍 Working on: $PROJECT_NAME"
echo "🔗 GitHub: https://github.com/$GITHUB_USER/$PROJECT_NAME"
echo ""
```

### Step 4: Ask for Changes

```bash
echo "💬 What changes would you like to make?"
echo "   Describe your changes (e.g., 'Change hero to dark blue', 'Add contact form')"
echo ""
read user_changes

echo ""
echo "🔨 Applying changes..."
```

### Step 5: Preview (unless --skip-preview)

```bash
if [ "$SKIP_PREVIEW" != "true" ]; then
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        echo "📦 Installing dependencies..."
        npm install > /dev/null 2>&1
    fi

    # Kill any existing dev servers on port 3000 first
    echo "🧹 Cleaning up port 3000..."
    if command -v powershell &> /dev/null; then
        # Windows - use PowerShell (more reliable in Git Bash)
        powershell.exe -NoProfile -Command "Get-NetTCPConnection -LocalPort 3000 -State Listen -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id \$_.OwningProcess -Force }" || true
    else
        # Mac/Linux - kill processes on port 3000
        lsof -ti:3000 | xargs kill -9 2>/dev/null || true
    fi

    # Also kill any npm/next dev processes as backup
    pkill -f "npm run dev" 2>/dev/null || true
    pkill -f "next dev" 2>/dev/null || true

    # Wait and verify port is free before starting new preview
    sleep 3

    # CRITICAL: Check if port 3000 is still in use, if yes kill again before starting
    if command -v powershell &> /dev/null; then
        while powershell.exe -NoProfile -Command "Get-NetTCPConnection -LocalPort 3000 -State Listen -ErrorAction SilentlyContinue" 2>/dev/null | grep -q "3000"; do
            echo "⚠️  Port still in use, killing again..."
            powershell.exe -NoProfile -Command "Get-NetTCPConnection -LocalPort 3000 -State Listen -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id \$_.OwningProcess -Force }" || true
            sleep 2
        done
    else
        while lsof -ti:3000 &>/dev/null; do
            echo "⚠️  Port still in use, killing again..."
            lsof -ti:3000 | xargs kill -9 2>/dev/null || true
            sleep 2
        done
    fi
    echo "✅ Port 3000 confirmed free"

    # Start dev server in background
    echo "🔥 Starting preview server..."
    npm run dev > /dev/null 2>&1 &

    # Show preview URL immediately
    echo ""
    echo "🔥 Preview running at: http://localhost:3000"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Open the URL above in your browser to see the changes."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    cd "$AGENT_DIR"
fi
```

### Step 6: Push to GitHub

```bash
# Auto-push without asking for confirmation
commit_message="feat: update website"

# Use github-manager skill to commit and push changes
commit_and_push_changes "$PROJECT_DIR" "$commit_message"

echo ""
echo "✅ Changes pushed to GitHub!"
echo "🔗 View: https://github.com/$GITHUB_USER/$PROJECT_NAME/commits"

cd "$AGENT_DIR"
```

## Output Format

```
/modify-project

🔥 Your GitHub Projects
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  • <project-name>
  • <project-name>
  • <project-name>

📍 Select project (name): <project-name>

📍 Working on: <project-name>
🔗 GitHub: https://github.com/<user>/<project-name>

💬 What changes would you like to make?
   <your changes description>

🔨 Applying changes...

🔥 Preview running at: http://localhost:3000
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Open the URL above in your browser to see the changes.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Pushing to GitHub automatically...

✅ Changes pushed to GitHub!
🔗 View: https://github.com/<user>/<project-name>/commits
```
