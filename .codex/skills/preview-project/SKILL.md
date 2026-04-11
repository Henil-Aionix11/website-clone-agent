---
name: preview-project
description: Start development server for a WebForge project
user-invocable: true
argument-hint: "--name <name> --port <port> --no-deps"
---

# /preview-project

Start the development server for a WebForge project.

## What It Does

1. **Select project** (or use --name flag)
2. **Navigate to project directory**
3. **Install dependencies** (unless --no-deps)
4. **Start dev server** in background
5. **Show preview URL**

## Flags

| Flag | Description |
|------|-------------|
| `--name <name>` | Skip project selection |
| `--port <port>` | Custom port (default: 3000) |
| `--no-deps` | Skip npm install |

## Implementation

### Step 1: Parse Flags

```bash
PROJECT_NAME=""
PORT="3000"
NO_DEPS=false

for arg in "$@"; do
    case $arg in
        --name=*)
            PROJECT_NAME="${arg#*=}"
            ;;
        --name)
            shift
            PROJECT_NAME="$1"
            ;;
        --port=*)
            PORT="${arg#*=}"
            ;;
        --port)
            shift
            PORT="$1"
            ;;
        --no-deps)
            NO_DEPS=true
            ;;
    esac
done
```

### Step 2: Select Project

```bash
if [ -z "$PROJECT_NAME" ]; then
    # List local projects
    echo "🔥 Local Projects"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [ -d "projects" ]; then
        index=1
        for dir in projects/*/; do
            if [ -d "$dir" ]; then
                name=$(basename "$dir")
                echo "  $index. $name"
                index=$((index + 1))
            fi
        done
    fi

    echo ""
    echo "📍 Select project (name/number): "
    read selection

    # Get project name
    if echo "$selection" | grep -qE '^[0-9]+$'; then
        # It's a number - get from list
        index=1
        for dir in projects/*/; do
            if [ -d "$dir" ] && [ "$index" -eq "$selection" ]; then
                PROJECT_NAME=$(basename "$dir")
                break
            fi
            index=$((index + 1))
        done
    else
        PROJECT_NAME="$selection"
    fi
fi

# Validate project exists
if [ ! -d "projects/$PROJECT_NAME" ]; then
    echo "❌ Project '$PROJECT_NAME' not found locally"
    echo "   Use /modify-project to clone it first"
    exit 1
fi

cd "projects/$PROJECT_NAME"
```

### Step 3: Install Dependencies (unless --no-deps)

```bash
if [ "$NO_DEPS" != "true" ] && [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
    echo "✅ Dependencies installed"
fi
```

### Step 4: Start Dev Server

```bash
echo ""
echo "🔥 Starting preview server..."
echo ""

# Kill any existing dev servers on the port first
echo "🧹 Cleaning up any existing servers..."
if command -v powershell &> /dev/null; then
    # Windows - use PowerShell (more reliable in Git Bash)
    powershell.exe -NoProfile -Command "Get-NetTCPConnection -LocalPort ${PORT} -State Listen -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id \$_.OwningProcess -Force }" || true
else
    # Mac/Linux - kill processes on the port
    lsof -ti:${PORT} | xargs kill -9 2>/dev/null || true
fi

# Also kill any npm/next dev processes as backup
pkill -f "npm run dev" 2>/dev/null || true
pkill -f "next dev" 2>/dev/null || true

# Wait and verify port is free before starting new preview
sleep 2

# CRITICAL: Check if port is still in use, if yes kill again before starting
if command -v powershell &> /dev/null; then
    while powershell.exe -NoProfile -Command "Get-NetTCPConnection -LocalPort ${PORT} -State Listen -ErrorAction SilentlyContinue" 2>/dev/null | grep -q "${PORT}"; do
        echo "⚠️  Port still in use, killing again..."
        powershell.exe -NoProfile -Command "Get-NetTCPConnection -LocalPort ${PORT} -State Listen -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id \$_.OwningProcess -Force }" || true
        sleep 2
    done
else
    while lsof -ti:${PORT} &>/dev/null; do
        echo "⚠️  Port still in use, killing again..."
        lsof -ti:${PORT} | xargs kill -9 2>/dev/null || true
        sleep 2
    done
fi
echo "✅ Port ${PORT} confirmed free"

# Start dev server in background
PORT=$PORT npm run dev > /dev/null 2>&1 &

DEV_SERVER_PID=$!

# Store PID for cleanup
echo $DEV_SERVER_PID > .dev_server.pid

# Show preview URL immediately
echo "🔥 Preview running at: http://localhost:${PORT}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Open the URL above in your browser to see the website."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Server running in background (PID: $DEV_SERVER_PID)"
echo ""
echo "To stop the server:"
echo "  - Press Ctrl+C"
echo "  - Or run: pkill -f 'npm run dev'"
```

## Output Format

```
/preview-project --name <project-name>

🔥 Starting preview server...

🔥 Preview running at: http://localhost:3000
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Open the URL above in your browser to see the website.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Server running in background (PID: <pid>)

To stop the server:
  - Press Ctrl+C
  - Or run: pkill -f 'npm run dev'
```

## With Custom Port

```
/preview-project --name <project-name> --port 3001

🔥 Starting preview server...

🔥 Preview running at: http://localhost:3001
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
...
```
