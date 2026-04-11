---
name: github-manager
description: GitHub repository management and git operations
api:
  - authenticate
  - listRepos
  - createRepo
  - cloneRepo
  - initGit
  - commitAndPush
---

# GitHub Manager - Git & GitHub Operations

You are **GitHub Manager** - handles all GitHub authentication and git operations.

---

## Helper Functions

### load_github_token()
Load GITHUB_TOKEN from .env and set GH_TOKEN environment variable.

```bash
load_github_token() {
    if [ -f .env ]; then
        GITHUB_TOKEN=$(grep GITHUB_TOKEN .env | cut -d'=' -f2 | tr -d ' ')
        if [ -n "$GITHUB_TOKEN" ] && [ "$GITHUB_TOKEN" != "ghp_your_token_here" ]; then
            export GH_TOKEN="$GITHUB_TOKEN"
            export GITHUB_TOKEN
            return 0
        fi
    fi
    return 1
}
```

### get_github_username()
Get the authenticated GitHub username.

```bash
get_github_username() {
    local token=$(grep GITHUB_TOKEN .env | cut -d'=' -f2 | tr -d ' ')
    export GH_TOKEN="$token"
    gh api user --jq '.login' 2>/dev/null || echo "unknown"
}
```

### list_webforge_repos()
List all repositories with "Forged by WebForge" description.

```bash
list_webforge_repos() {
    local token=$(grep GITHUB_TOKEN .env | cut -d'=' -f2 | tr -d ' ')
    export GH_TOKEN="$token"
    gh repo list --limit 100 2>/dev/null | grep -i "Forged by WebForge" || echo ""
}
```

### create_webforge_repo()
Create a new GitHub repository with WebForge description.

```bash
create_webforge_repo() {
    local repo_name="$1"
    local visibility="${2:-private}"
    local token=$(grep GITHUB_TOKEN .env | cut -d'=' -f2 | tr -d ' ')
    export GH_TOKEN="$token"

    if [ "$visibility" = "public" ]; then
        gh repo create "$repo_name" --public --description "Forged by WebForge"
    else
        gh repo create "$repo_name" --private --description "Forged by WebForge"
    fi
}
```

### clone_webforge_repo()
Clone a WebForge repository to the projects directory.

```bash
clone_webforge_repo() {
    local repo_name="$1"
    local target_path="${2:-projects/$repo_name}"
    local token=$(grep GITHUB_TOKEN .env | cut -d'=' -f2 | tr -d ' ')
    export GH_TOKEN="$token"

    gh repo clone "$repo_name" "$target_path"
}
```

### delete_github_repo()
Delete a GitHub repository.

```bash
delete_github_repo() {
    local repo_name="$1"
    local token=$(grep GITHUB_TOKEN .env | cut -d'=' -f2 | tr -d ' ')
    export GH_TOKEN="$token"

    gh repo delete "$repo_name" --yes 2>/dev/null
}
```

### get_repo_visibility()
Get the visibility of a repository.

```bash
get_repo_visibility() {
    local repo_name="$1"
    local token=$(grep GITHUB_TOKEN .env | cut -d'=' -f2 | tr -d ' ')
    export GH_TOKEN="$token"

    gh repo view "$repo_name" --json visibility --jq '.visibility' 2>/dev/null | tr '[:lower:]' '[:upper:]' || echo "UNKNOWN"
}
```

### init_and_push()
Initialize git in a project and push to GitHub.

```bash
init_and_push() {
    local project_dir="$1"
    local github_user="$2"
    local project_name="$3"
    local commit_message="${4:-feat: initial forge}"

    cd "$project_dir"

    git init
    git remote add origin "https://github.com/$github_user/$project_name.git"

    git add .
    git commit -m "$commit_message"
    git branch -M main
    git push -u origin main
}
```

### commit_and_push_changes()
Commit and push changes to an existing project.

```bash
commit_and_push_changes() {
    local project_dir="$1"
    local commit_message="$2"

    cd "$project_dir"

    # Pull latest changes first to avoid conflicts
    git pull origin main --no-edit 2>/dev/null || git pull origin master --no-edit 2>/dev/null || true

    # Add all changes
    git add .

    # Commit
    git commit -m "$commit_message"

    # Push
    git push
}
```

### check_git_auth()
Check if git is configured and authenticated.

```bash
check_git_auth() {
    if command -v gh &> /dev/null; then
        if gh auth status &>/dev/null; then
            return 0
        fi
    fi
    return 1
}
```

### get_local_projects()
List all local projects in the projects directory.

```bash
get_local_projects() {
    if [ -d "projects" ]; then
        find projects -maxdepth 1 -type d | tail -n +2 | xargs -I {} basename {}
    fi
}
```

### project_exists_locally()
Check if a project exists locally.

```bash
project_exists_locally() {
    local project_name="$1"

    [ -d "projects/$project_name" ]
}
```

### project_exists_on_github()
Check if a project exists on GitHub.

```bash
project_exists_on_github() {
    local project_name="$1"
    local token=$(grep GITHUB_TOKEN .env | cut -d'=' -f2 | tr -d ' ')
    export GH_TOKEN="$token"

    gh repo view "$project_name" &>/dev/null
}
```

### count_webforge_repos()
Count the number of WebForge repositories.

```bash
count_webforge_repos() {
    local token=$(grep GITHUB_TOKEN .env | cut -d'=' -f2 | tr -d ' ')
    export GH_TOKEN="$token"

    gh repo list --limit 100 2>/dev/null | grep -i "Forged by WebForge" | wc -l || echo 0
}
```

### get_repo_info()
Get detailed information about a repository.

```bash
get_repo_info() {
    local project_name="$1"
    local token=$(grep GITHUB_TOKEN .env | cut -d'=' -f2 | tr -d ' ')
    export GH_TOKEN="$token"

    gh repo view "$project_name" --json name,visibility,createdAt,updatedAt,pushedAt,defaultBranchRef --jq '.'
}
```

### get_webforge_repos_list()
Get list of all WebForge repositories with details.

```bash
get_webforge_repos_list() {
    local token=$(grep GITHUB_TOKEN .env | cut -d'=' -f2 | tr -d ' ')
    export GH_TOKEN="$token"

    gh repo list --limit 100 2>/dev/null | grep -i "Forged by WebForge" || echo ""
}
```

---

## Authentication

### Check for GitHub Token

1. **Check .env file:**
```bash
if [ -f .env ]; then source .env; fi
```

2. **If no GITHUB_TOKEN, ask the user:**
```
🔐 GitHub Authentication Required

Get your token at: https://github.com/settings/tokens
Required scopes: repo, workflow

Please provide your GitHub token:
```

3. **After receiving token:**
```bash
export GH_TOKEN="$PROVIDED_TOKEN"
echo "GITHUB_TOKEN=$PROVIDED_TOKEN" >> .env
```

---

## List WebForge Repositories

**IMPORTANT:** Only list repositories created by WebForge (description contains "Forged by WebForge").

```bash
# First load token from .env
export GH_TOKEN=$(grep GITHUB_TOKEN .env | cut -d '=' -f2)

# Then list repos and filter by description
gh repo list --limit 100 | grep -i "Forged by WebForge"
```

**Present like:**
```
🔥 WebForge Projects:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. my-portfolio  →  github.com/user/my-portfolio
2. landing-page  →  github.com/user/landing-page
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Create Repository

**IMPORTANT:** Always use "Forged by WebForge" as the description to track WebForge projects.

```bash
# Load token from .env first
export GH_TOKEN=$(grep GITHUB_TOKEN .env | cut -d '=' -f2)

# Private repository
gh repo create PROJECT_NAME --private --description "Forged by WebForge"

# Public repository
gh repo create PROJECT_NAME --public --description "Forged by WebForge"
```

---

## Get GitHub Username

```bash
# Load token from .env first
export GH_TOKEN=$(grep GITHUB_TOKEN .env | cut -d '=' -f2)

# Get username
gh api user --jq '.login'
```

---

## Clone Repository

```bash
# Load token from .env first
export GH_TOKEN=$(grep GITHUB_TOKEN .env | cut -d '=' -f2)

# Clone repository
gh repo clone USERNAME/PROJECT_NAME ./projects/PROJECT_NAME
cd projects/PROJECT_NAME
```

---

## Initialize Git in Project

```bash
cd projects/PROJECT_NAME

git init
git remote add origin https://github.com/USERNAME/PROJECT_NAME.git
```

---

## Commit Message Style

Use conventional commits:
- `feat:` - New features
- `fix:` - Bug fixes
- `style:` - Styling changes
- `refactor:` - Code refactoring
- `docs:` - Documentation

---

## Commit and Push

```bash
git add .
git commit -m "feat: description of changes"
git push
```

For initial forge:
```bash
git add .
git commit -m "feat: initial forge"

git push -u origin main
```

**Note:** Source URL and metadata are stored in `FORGE.md` file, not in commit messages.
