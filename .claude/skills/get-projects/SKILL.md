---
name: get-projects
description: List all WebForge projects from GitHub and/or local
user-invocable: true
---

# /get-projects

List all WebForge projects from GitHub and/or local directories.

## What It Does

1. Loads GH_TOKEN from .env
2. Lists all GitHub repos with "Forged by WebForge" description
3. Checks for local copies in projects/ directory
4. Displays formatted table with project info

## Flags

| Flag | Description |
|------|-------------|
| `--local` | Show only local projects |
| `--remote` | Show only GitHub projects (default) |
| `--all` | Show both local and remote projects |
| `--json` | Output as JSON format |

## Implementation

### Step 1: Load Token and Get Username

```bash
# Use github-manager skill to get username
GITHUB_USER=$(get_github_username)
```

### Step 2: List Projects

```bash
echo "🔥 WebForge Projects"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check which mode to use
if [[ "$*" == *"--local"* ]]; then
    # Local only
    if [ -d "projects" ]; then
        for dir in projects/*/; do
            if [ -d "$dir" ]; then
                name=$(basename "$dir")
                printf "  %-20s %s\n" "$name" "● Local"
            fi
        done
    fi
elif [[ "$*" == *"--all"* ]]; then
    # Both local and remote
    declare -A local_projects
    if [ -d "projects" ]; then
        for dir in projects/*/; do
            if [ -d "$dir" ]; then
                name=$(basename "$dir")
                local_projects["$name"]=1
            fi
        done
    fi

    # Use github-manager to get repos
    get_webforge_repos_list | while read -r line; do
        repo_name=$(echo "$line" | awk '{print $1}')
        visibility=$(echo "$line" | grep -oE 'Public|Private' || echo "Unknown")
        updated=$(echo "$line" | awk '{for(i=3;i<=NF;i++) if($i ~/ago/) print $i " " $(i+1);}')

        if [ -n "${local_projects[$repo_name]}" ]; then
            local_status="● Exists"
        else
            local_status="○ Not cloned"
        fi

        printf "%-20s %-12s %-18s %s\n" "$repo_name" "$visibility" "$updated" "$local_status"
    done
else
    # Remote only (default)
    # Use github-manager to get repos
    get_webforge_repos_list | while read -r line; do
        repo_name=$(echo "$line" | awk '{print $1}')
        visibility=$(echo "$line" | grep -oE 'Public|Private' || echo "Unknown")
        updated=$(echo "$line" | awk '{for(i=3;i<=NF;i++) if($i ~/ago/) print $i " " $(i+1);}')

        if [ -d "projects/$repo_name" ]; then
            local_status="● Exists"
        else
            local_status="○ Not cloned"
        fi

        printf "%-20s %-12s %-18s %s\n" "$repo_name" "$visibility" "$updated" "$local_status"
    done
fi
```

### Step 4: JSON Output (if --json)

```bash
if [[ "$*" == *"--json"* ]]; then
    echo "{"
    echo "  \"projects\": ["
    gh repo list --limit 100 --json name,visibility,updatedAt,pushedAt 2>/dev/null | jq '.[] | select(.description | contains("Forged by WebForge"))'
    echo "  ]"
    echo "}"
fi
```

## Output Format

```
🔥 WebForge Projects (GitHub)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
┌─────────────────┬──────────┬────────────────┬──────────────┐
│ Name            │ Visibility│ Last Updated   │ Local        │
├─────────────────┼──────────┼────────────────┼──────────────┤
│ <project-name>  │ <Private>│ <time ago>     ● Exists      │
│ <project-name>  │ <Public> │ <time ago>     ○ Not cloned  │
└─────────────────┴──────────┴────────────────┴──────────────┘
```
