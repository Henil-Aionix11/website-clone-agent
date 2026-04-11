---
name: delete-project
description: Delete a WebForge project from GitHub and/or local
user-invocable: true
argument-hint: "--name <name> --github-only --local-only --force"
---

# /delete-project

Delete a WebForge project from GitHub repository and/or local directory.

## What It Does

1. **Show all GitHub projects** with "Forged by WebForge" tag
2. **Ask to select project to delete**
3. **Confirm deletion** (unless --force)
4. **Delete from GitHub** (gh repo delete)
5. **Delete from local** (if exists in projects/)

## Flags

| Flag | Description |
|------|-------------|
| `--name <name>` | Skip project selection |
| `--github-only` | Delete GitHub repo only |
| `--local-only` | Delete local folder only |
| `--force` | Skip confirmation |

## Interactive Flow

```
/delete-project
↓
🔥 WebForge Projects (GitHub)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1. <project-name>    (Private) ● Local exists
  2. <project-name>    (Public)  ○ Not cloned
  3. <project-name>    (Private) ● Local exists
↓
🗑️  Which project to delete? (name/number): _
↓
⚠️  Deleting '<project-name>' will remove:
   - GitHub repository
   - Local folder: projects/<project-name>
↓
🔥 Confirm deletion? (yes/no): _
↓
✅ Project deleted from GitHub
✅ Local folder deleted
```

## Implementation

### Step 1: Parse Flags

```bash
PROJECT_NAME=""
GITHUB_ONLY=false
LOCAL_ONLY=false
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
        --github-only)
            GITHUB_ONLY=true
            ;;
        --local-only)
            LOCAL_ONLY=true
            ;;
        --force)
            FORCE=true
            ;;
    esac
done
```

### Step 2: Load Token and Get Username

```bash
# Use github-manager skill to get username
GITHUB_USER=$(get_github_username)
```

### Step 3: List GitHub Projects

```bash
if [ -z "$PROJECT_NAME" ]; then
    echo "🔥 WebForge Projects (GitHub)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Get projects from GitHub with index using github-manager
    declare -A projects
    index=1

    get_webforge_repos_list | while read -r line; do
        repo_name=$(echo "$line" | awk '{print $1}')
        visibility=$(echo "$line" | grep -oE 'Public|Private' || echo "Unknown")

        # Check if local exists
        if [ -d "projects/$repo_name" ]; then
            local_status="● Local exists"
        else
            local_status="○ Not cloned"
        fi

        echo "  $index. $repo_name    ($visibility) $local_status"
        projects["$index"]="$repo_name"
        index=$((index + 1))
    done

    echo ""
    echo "🗑️  Which project to delete? (name/number): "
    read selection

    # Check if number or name
    if echo "$selection" | grep -qE '^[0-9]+$'; then
        # It's a number
        PROJECT_NAME="${projects[$selection]}"
    else
        # It's a name
        PROJECT_NAME="$selection"
    fi
fi

# Validate project exists using github-manager
if ! project_exists_on_github "$PROJECT_NAME"; then
    echo "❌ Project '$PROJECT_NAME' not found on GitHub"
    exit 1
fi
```

### Step 4: Confirm Deletion

```bash
if [ "$FORCE" != "true" ]; then
    echo ""
    echo "⚠️  Deleting '$PROJECT_NAME' will remove:"

    if [ "$GITHUB_ONLY" != "true" ]; then
        echo "   - GitHub repository"
    fi

    if [ "$LOCAL_ONLY" != "true" ] && [ -d "projects/$PROJECT_NAME" ]; then
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

### Step 5: Delete from GitHub

```bash
if [ "$LOCAL_ONLY" != "true" ]; then
    echo ""
    echo "🗑️  Deleting GitHub repository..."
    delete_github_repo "$PROJECT_NAME"
    echo "✅ Project deleted from GitHub"
fi
```

### Step 6: Delete from Local

```bash
if [ "$GITHUB_ONLY" != "true" ] && [ -d "projects/$PROJECT_NAME" ]; then
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
  1. <project-name>    (Private) ● Local exists
  2. <project-name>    (Public)  ○ Not cloned
  3. <project-name>    (Private) ● Local exists

🗑️  Which project to delete? (name/number): <project-name>

⚠️  Deleting '<project-name>' will remove:
   - GitHub repository
   - Local folder: projects/<project-name>

🔥 Confirm deletion? (yes/no): yes

🗑️  Deleting GitHub repository...
✅ Project deleted from GitHub
🗑️  Deleting local folder...
✅ Local folder deleted

🔥 Deletion complete!
```
