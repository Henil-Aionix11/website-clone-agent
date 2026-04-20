---
name: get-projects
description: List all WebForge projects from GitHub and/or local
user-invocable: true
---

# /get-projects

List all WebForge projects from GitHub.

## What It Does

1. Loads GH_TOKEN from .env
2. Lists all GitHub repos with "Forged by WebForge" description
3. Displays formatted list with project info

## Implementation

### Step 1: Setup GitHub Auth

```bash
AGENT_DIR="$(pwd)"
export GH_TOKEN=$(grep GITHUB_TOKEN "$AGENT_DIR/.env" | cut -d'=' -f2 | tr -d ' ')
GITHUB_USER=$(gh api user --jq '.login')
```

### Step 2: List GitHub Projects

```bash
echo "🔥 WebForge Projects"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

gh repo list --limit 100 --json name,visibility,description,updatedAt \
  --jq '.[] | select(.description | test("Forged by WebForge"; "i")) | "\(.name)\t\(.visibility)\t\(.updatedAt)"' | while IFS=$'\t' read -r repo_name visibility updated; do
    printf "  %-20s %-12s\n" "$repo_name" "$visibility"
done
```

## Output Format

```
🔥 WebForge Projects
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  packing-cube         PRIVATE
  Farmer-trick         PRIVATE
```
