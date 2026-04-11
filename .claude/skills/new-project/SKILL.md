---
name: new-project
description: Create a new WebForge project by cloning a reference website
user-invocable: true
argument-hint: "--name <name> --url <url>"
---

# /new-project

Create a new WebForge project by cloning a reference website.

## What It Does

1. **Get project name** (any name accepted)
2. **Get reference website URL** (asked separately, after name)
3. **GitHub repo is always created as private**
4. **Create GitHub repository**
5. **Copy scaffold template** to project folder
6. **Clone the website directly** in the project folder (isolated workspace)
7. **Create FORGE.md** with metadata
8. **Run preview** at localhost:3000
9. **Push to GitHub** (auto-push, no confirmation needed)

## Key Design: Concurrent-Safe Workspace

Each project gets its own isolated workspace. No shared root directories = true parallel execution.

```
projects/
├── test-1/              # Person A's clone
│   ├── src/
│   ├── public/
│   └── docs/
├── test-2/              # Person B's clone (simultaneous)
│   ├── src/
│   ├── public/
│   └── docs/
└── test-3/              # Person C's clone (simultaneous)
    ├── src/
    ├── public/
    └── docs/
```

**Multiple users can clone simultaneously without conflicts.**

## Flags

| Flag | Description |
|------|-------------|
| `--name <name>` | Skip project name prompt |
| `--url <url>` | Skip URL prompt |
| `--no-preview` | Skip preview, push directly |
| `--no-push` | Don't push to GitHub |

> GitHub repos are **always created as private**. There is no visibility flag.

## Interactive Flow

```
/new-project
↓
🔨 What is the project name?
(user answers)
↓
🌐 What is the reference website URL?
(user answers)
↓
[GitHub repo auto-created as private]
↓
✅ Creating repository...
📁 Copying scaffold template...
🔨 Cloning website directly in project folder...
✅ Setting up project...
↓
🔥 Preview: http://localhost:3000
↓
[Auto-push to GitHub — no confirmation needed]
↓
✅ Done!
```

## Implementation

### Step 1: Parse Flags

```bash
PROJECT_NAME=""
REFERENCE_URL=""
NO_PREVIEW=false
NO_PUSH=false

for arg in "$@"; do
    case $arg in
        --name=*)
            PROJECT_NAME="${arg#*=}"
            ;;
        --name)
            shift
            PROJECT_NAME="$1"
            ;;
        --url=*)
            REFERENCE_URL="${arg#*=}"
            ;;
        --url)
            shift
            REFERENCE_URL="$1"
            ;;
        --no-preview)
            NO_PREVIEW=true
            ;;
        --no-push)
            NO_PUSH=true
            ;;
    esac
done

# Visibility is always private
VISIBILITY="private"
```

### Step 2: Get Project Name

```bash
if [ -z "$PROJECT_NAME" ]; then
    echo "🔨 What is the project name?"
    read PROJECT_NAME
fi

# Only check that name is not empty
if [ -z "$PROJECT_NAME" ]; then
    echo "❌ Project name cannot be empty"
    exit 1
fi

# Check if project already exists locally
if [ -d "projects/$PROJECT_NAME" ]; then
    echo "❌ Project '$PROJECT_NAME' already exists locally"
    exit 1
fi
```

### Step 3: Get Reference URL

```bash
if [ -z "$REFERENCE_URL" ]; then
    echo "🌐 What is the reference website URL?"
    read REFERENCE_URL
fi

# Validate URL
if ! echo "$REFERENCE_URL" | grep -qE '^https?://'; then
    echo "❌ Invalid URL. Must start with http:// or https://"
    exit 1
fi
```

### Step 4: Create GitHub Repository (use github-manager skill)

```bash
# Get absolute path to .env file
AGENT_DIR="$(pwd)"

# Use github-manager skill to create repo
create_webforge_repo "$PROJECT_NAME" "$VISIBILITY"

# Get username using github-manager
GITHUB_USER=$(get_github_username)

echo ""
echo "✅ Repository created: github.com/$GITHUB_USER/$PROJECT_NAME"
```

### Step 5: Set Up Project Directory

```bash
# Create projects directory if it doesn't exist
mkdir -p "$AGENT_DIR/projects"

# Create new project directory
mkdir -p "$AGENT_DIR/projects/$PROJECT_NAME"
PROJECT_DIR="$AGENT_DIR/projects/$PROJECT_NAME"

echo ""
echo "📁 Setting up project directory..."
```

### Step 6: Copy Scaffold to Project Folder

```bash
# Copy scaffold template to project folder FIRST
# This provides the base Next.js + shadcn/ui structure
cp -r "$AGENT_DIR/templates/scaffold/"* "$PROJECT_DIR/"

echo "✅ Scaffold copied to $PROJECT_DIR"
```

### Step 7: Clone Website Directly in Project Folder

```bash
echo ""
echo "🔨 Cloning $REFERENCE_URL..."
echo ""

# Navigate to project directory and clone there
# This ensures complete isolation - no shared workspace
cd "$PROJECT_DIR"
/clone-website "$REFERENCE_URL"

echo ""
echo "✅ Clone complete!"

# Remove any build artifacts created during cloning
rm -rf "$PROJECT_DIR/.next" 2>/dev/null || true
rm -f "$PROJECT_DIR/tsconfig.tsbuildinfo" 2>/dev/null || true

# Return to agent directory
cd "$AGENT_DIR"
```

### Step 8: Create FORGE.md with Metadata

```bash
cat > "$PROJECT_DIR/FORGE.md" << EOF
# WebForge Metadata

**Forged by:** WebForge
**Source URL:** $REFERENCE_URL
**Forge Date:** $(date +%Y-%m-%d)

---
This project was automatically forged from a reference website using WebForge.
EOF

echo "✅ FORGE.md created"
```

### Step 9: Preview (unless --no-preview)

```bash
if [ "$NO_PREVIEW" != "true" ]; then
    cd "$PROJECT_DIR"

    # Install dependencies
    echo ""
    echo "📦 Installing dependencies..."
    npm install > /dev/null 2>&1

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
    echo "Open the URL above in your browser to see the forged website."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    cd "$AGENT_DIR"
fi
```

### Step 10: Push to GitHub (unless --no-push)

```bash
if [ "$NO_PUSH" != "true" ]; then

    # Commit message without Claude co-author tag
    COMMIT_MESSAGE="feat: initial forge

Forged from: $REFERENCE_URL"

    # Use github-manager skill to initialize and push
    init_and_push "$PROJECT_DIR" "$GITHUB_USER" "$PROJECT_NAME" "$COMMIT_MESSAGE"

    cd "$AGENT_DIR"

    echo ""
    echo "🔥 Project forged successfully!"
    echo ""
    echo "┌─────────────────────────────────────┐"
    echo "│ 📦 Project: $PROJECT_NAME            │"
    echo "│ 🔗 GitHub: github.com/$GITHUB_USER/$PROJECT_NAME │"
    echo "│ 🌐 Forged from: $REFERENCE_URL       │"
    echo "└─────────────────────────────────────┘"
fi
```

## Output Format

```
/new-project

🔨 What is the project name?
<project-name>

🌐 What is the reference website URL?
<url>

[GitHub repo auto-created as private]

✅ Creating repository...
✅ Repository created: github.com/<user>/<project-name>

📁 Setting up project directory...
✅ Scaffold copied to projects/<project-name>

🔨 Cloning <url>...
[ /clone-website skill runs and does its work... ]

✅ Clone complete!
✅ FORGE.md created

📦 Installing dependencies...
🔥 Starting preview server...

🔥 Preview running at: http://localhost:3000
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Open the URL above in your browser to see the forged website.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Pushing to GitHub automatically...

🔥 Project forged successfully!

┌─────────────────────────────────────┐
│ 📦 Project: <project-name>          │
│ 🔗 GitHub: github.com/<user>/<project-name> │
│ 🌐 Forged from: <url>               │
└─────────────────────────────────────┘
```

## Key Design Decision

This skill **delegates** the actual website cloning to the `/clone-website` skill, which runs **directly in the project directory**. This ensures:
- ✅ Concurrent-safe (each project is isolated)
- ✅ No shared workspace conflicts
- ✅ No cleanup needed (root never modified)
- ✅ True parallel execution for multiple users
- ✅ The /clone-website skill handles browser automation, asset extraction, etc.
- ✅ We only handle WebForge-specific concerns (GitHub repo, metadata, etc.)
