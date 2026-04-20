---
name: modify-project
description: Modify an existing static HTML WebForge project (automatically clones if not local)
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
6. **Run preview** at localhost:3000 using `npx serve`
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

# Setup GitHub auth
export GH_TOKEN=$(grep GITHUB_TOKEN "$AGENT_DIR/.env" | cut -d'=' -f2 | tr -d ' ')
GITHUB_USER=$(gh api user --jq '.login')
GITHUB_EMAIL=$(gh api user --jq '.email // empty')
GITHUB_EMAIL="${GITHUB_EMAIL:-${GITHUB_USER}@users.noreply.github.com}"

if [ -z "$PROJECT_NAME" ]; then
    echo "🔥 Your GitHub Projects"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # List WebForge repos directly with gh
    gh repo list --limit 100 --json name,description \
      --jq '.[] | select(.description | test("Forged by WebForge"; "i")) | .name' | while read -r repo_name; do
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
    gh repo clone "$GITHUB_USER/$PROJECT_NAME" "$PROJECT_DIR"
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
    # Kill any existing servers on port 3000 first
    echo "🧹 Cleaning up port 3000..."
    if command -v powershell &> /dev/null; then
        # Windows - use PowerShell
        powershell.exe -NoProfile -Command "Get-NetTCPConnection -LocalPort 3000 -State Listen -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id \$_.OwningProcess -Force }" || true
    else
        # Mac/Linux
        lsof -ti:3000 | xargs kill -9 2>/dev/null || true
    fi

    # Also kill any npx serve processes
    pkill -f "npx serve" 2>/dev/null || true
    pkill -f "serve" 2>/dev/null || true

    # Wait and verify port is free
    sleep 3

    # Check if port is still in use
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

    # Check if npx is available
    if ! command -v npx &> /dev/null; then
        echo "⚠️  npx not found. Please install Node.js to use preview."
        echo "   Preview manually with: npx serve \"$PROJECT_DIR\" --listen 3000"
    else
        # Start npx serve in background
        echo "🔥 Starting preview server..."
        cd "$PROJECT_DIR"
        npx serve --listen 3000 > /dev/null 2>&1 &
        SERVE_PID=$!

        # Store PID for cleanup
        echo $SERVE_PID > .serve.pid

        cd "$AGENT_DIR"

        # Show preview URL immediately
        echo ""
        echo "🔥 Preview running at: http://localhost:3000"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Open the URL above in your browser to see the changes."
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
    fi
fi
```

### Step 6: Push to GitHub

```bash
cd "$PROJECT_DIR"

# Set git identity from token owner
git config user.name "$GITHUB_USER"
git config user.email "$GITHUB_EMAIL"

git pull origin main --no-edit 2>/dev/null || true
git add .
git commit -m "feat: update website"
git push

cd "$AGENT_DIR"

echo ""
echo "✅ Changes pushed to GitHub!"
echo "🔗 View: https://github.com/$GITHUB_USER/$PROJECT_NAME/commits"
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
