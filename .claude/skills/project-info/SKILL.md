---
name: project-info
description: Show detailed information about a WebForge project
user-invocable: true
argument-hint: "--name <name> --json"
---

# /project-info

Show detailed information about a WebForge project.

## What It Does

1. **Select project** (or use --name flag)
2. **Read FORGE.md** for metadata
3. **Show GitHub repo URL**
4. **Show local path**
5. **Show file count**
6. **Show last commit info**

## Flags

| Flag | Description |
|------|-------------|
| `--name <name>` | Skip project selection |
| `--json` | Output as JSON format |

## Implementation

### Step 1: Parse Flags

```bash
PROJECT_NAME=""
JSON_OUTPUT=false

for arg in "$@"; do
    case $arg in
        --name=*)
            PROJECT_NAME="${arg#*=}"
            ;;
        --name)
            shift
            PROJECT_NAME="$1"
            ;;
        --json)
            JSON_OUTPUT=true
            ;;
    esac
done
```

### Step 2: Select Project

```bash
# Use github-manager to get username
GITHUB_USER=$(get_github_username)

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
```

### Step 3: Check if Local

```bash
if [ ! -d "projects/$PROJECT_NAME" ]; then
    echo "❌ Project '$PROJECT_NAME' not found locally"
    echo "   Use /modify-project to clone it first"
    exit 1
fi

cd "projects/$PROJECT_NAME"
```

### Step 4: Gather Info

```bash
# Get FORGE.md info
if [ -f "FORGE.md" ]; then
    SOURCE_URL=$(grep "Source URL:" FORGE.md | sed 's/.*Source URL: //' | tr -d '*')
    FORGE_DATE=$(grep "Forge Date:" FORGE.md | sed 's/.*Forge Date: //' | tr -d '*')
else
    SOURCE_URL="Unknown"
    FORGE_DATE="Unknown"
fi

# Get GitHub visibility using github-manager
VISIBILITY=$(get_repo_visibility "$PROJECT_NAME")

# Get file count
FILE_COUNT=$(find . -type f | grep -v node_modules | grep -v .git | wc -l)

# Get last commit
if [ -d ".git" ]; then
    LAST_COMMIT=$(git log -1 --format="%h - %s (%ar)" 2>/dev/null || echo "No commits")
else
    LAST_COMMIT="Not initialized"
fi

# Get repo size
REPO_SIZE=$(du -sh . 2>/dev/null | cut -f1 || echo "Unknown")

cd ../..
```

### Step 5: Display Info

```bash
if [ "$JSON_OUTPUT" = "true" ]; then
    echo "{"
    echo "  \"name\": \"$PROJECT_NAME\","
    echo "  \"github\": \"github.com/$GITHUB_USER/$PROJECT_NAME\","
    echo "  \"local\": \"projects/$PROJECT_NAME\","
    echo "  \"source_url\": \"$SOURCE_URL\","
    echo "  \"forge_date\": \"$FORGE_DATE\","
    echo "  \"visibility\": \"$VISIBILITY\","
    echo "  \"file_count\": $FILE_COUNT,"
    echo "  \"repo_size\": \"$REPO_SIZE\","
    echo "  \"last_commit\": \"$LAST_COMMIT\""
    echo "}"
else
    echo "📦 Project: $PROJECT_NAME"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔗 GitHub:       github.com/$GITHUB_USER/$PROJECT_NAME"
    echo "📁 Local:        projects/$PROJECT_NAME"
    echo "🌐 Forged from:  $SOURCE_URL"
    echo "📅 Forge Date:   $FORGE_DATE"
    echo "👁️  Visibility:   $(echo "$VISIBILITY" | sed 's/.*/\u&/')"
    echo "📊 Files:        $FILE_COUNT"
    echo "💾 Size:         $REPO_SIZE"
    echo "📝 Last Commit:  $LAST_COMMIT"
fi
```

## Output Format

```
/project-info --name <project-name>

📦 Project: <project-name>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔗 GitHub:       github.com/<user>/<project-name>
📁 Local:        projects/<project-name>
🌐 Forged from:  <source-url>
📅 Forge Date:   <date>
👁️  Visibility:  <Public|Private>
📊 Files:        <count>
💾 Size:         <size>
📝 Last Commit:  <commit-hash> - <message> (<time-ago>)
```

## JSON Output Format

```json
{
  "name": "<project-name>",
  "github": "github.com/<user>/<project-name>",
  "local": "projects/<project-name>",
  "source_url": "<source-url>",
  "forge_date": "<date>",
  "visibility": "<PRIVATE|PUBLIC>",
  "file_count": <count>,
  "repo_size": "<size>",
  "last_commit": "<commit-hash> - <message> (<time-ago>)"
}
```
