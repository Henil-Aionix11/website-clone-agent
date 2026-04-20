---
name: delete-project
description: Delete a WebForge project from GitHub and/or local
user-invocable: true
argument-hint: "--name <name> --force"
---

# /delete-project

Delete a WebForge project from GitHub and local.

## What It Does

1. **Show all GitHub projects** with "Forged by WebForge" tag
2. **Ask to select project to delete**
3. **Confirm deletion** (unless --force)
4. **Delete from GitHub** (gh repo delete)
5. **Delete local copy** (if exists in projects/)

## Flags

| Flag | Description |
|------|-------------|
| `--name <name>` | Skip project selection |
| `--force` | Skip confirmation |

## Implementation

### Step 1: Parse Flags

```bash
PROJECT_NAME=""
FORCE=false

for arg in "$@"; do
    case $arg in
        --name=*)
            PROJECT_NAME="${arg#*=}"
            ;;
        --name)
            shift
            PROJECT_NAME="$1"
            ;;
        --force)
            FORCE=true
            ;;
    esac
done
```

### Step 2: Setup GitHub Auth

```bash
AGENT_DIR="$(pwd)"
export GH_TOKEN=$(grep GITHUB_TOKEN "$AGENT_DIR/.env" | cut -d'=' -f2 | tr -d ' ')
GITHUB_USER=$(gh api user --jq '.login')
```

### Step 3: List GitHub Projects

```bash
if [ -z "$PROJECT_NAME" ]; then
    echo "🔥 WebForge Projects (GitHub)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    gh repo list --limit 100 --json name,visibility,description \
      --jq '.[] | select(.description | test("Forged by WebForge"; "i")) | "\(.name)\t\(.visibility)"' | while IFS=$'\t' read -r repo_name visibility; do
        echo "  • $repo_name    ($visibility)"
    done

    echo ""
    echo "🗑️  Which project to delete? (name): "
    read PROJECT_NAME
fi

# Validate project exists on GitHub
if ! gh repo view "$GITHUB_USER/$PROJECT_NAME" &>/dev/null; then
    echo "❌ Project '$PROJECT_NAME' not found on GitHub"
    exit 1
fi
```

### Step 4: Confirm Deletion

```bash
if [ "$FORCE" != "true" ]; then
    echo ""
    echo "⚠️  Deleting '$PROJECT_NAME' will remove:"
    echo "   - GitHub repository: $GITHUB_USER/$PROJECT_NAME"
    if [ -d "projects/$PROJECT_NAME" ]; then
        echo "   - Local folder: projects/$PROJECT_NAME"
    fi
    echo ""
    echo "🔥 Confirm deletion? (yes/no): "
    read confirm

    if [ "$confirm" != "yes" ]; then
        echo "❌ Deletion cancelled"
        exit 0
    fi
fi
```

### Step 5: Delete from GitHub + Local

```bash
echo ""
echo "🗑️  Deleting GitHub repository..."
gh repo delete "$GITHUB_USER/$PROJECT_NAME" --yes
echo "✅ Project deleted from GitHub"

if [ -d "projects/$PROJECT_NAME" ]; then
    echo "🗑️  Deleting local folder..."
    rm -rf "projects/$PROJECT_NAME"
    echo "✅ Local folder deleted"
fi

echo ""
echo "🔥 Deletion complete!"
```

## Output Format

```
/delete-project

🔥 WebForge Projects (GitHub)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  • packing-cube    (PRIVATE)
  • Farmer-trick    (PRIVATE)

🗑️  Which project to delete? (name): packing-cube

⚠️  Deleting 'packing-cube' will remove:
   - GitHub repository: user/packing-cube
   - Local folder: projects/packing-cube

🔥 Confirm deletion? (yes/no): yes

🗑️  Deleting GitHub repository...
✅ Project deleted from GitHub
🗑️  Deleting local folder...
✅ Local folder deleted

🔥 Deletion complete!
```
