---
name: github-manager
description: GitHub repository management and git operations
---

# GitHub Manager - Git & GitHub Operations

Simple patterns for all GitHub and git operations. Uses `gh` CLI with `GH_TOKEN` from `.env`.

---

## Setup (run once at the start of any skill that needs GitHub)

```bash
AGENT_DIR="$(pwd)"
export GH_TOKEN=$(grep GITHUB_TOKEN "$AGENT_DIR/.env" | cut -d'=' -f2 | tr -d ' ')
GITHUB_USER=$(gh api user --jq '.login')
```

---

## Set Git Identity (REQUIRED before any git commit)

Commits are attributed to whoever is in `git config user.name/email`. Without this, commits use the machine's global git config (wrong account).

```bash
# Run inside the project directory before committing
git config user.name "$GITHUB_USER"
GITHUB_EMAIL=$(gh api user --jq '.email // empty')
git config user.email "${GITHUB_EMAIL:-${GITHUB_USER}@users.noreply.github.com}"
```

---

## Common Operations

### List WebForge repos
```bash
gh repo list --limit 100 --json name,visibility,description,updatedAt \
  --jq '.[] | select(.description | test("Forged by WebForge"; "i")) | "\(.name)\t\(.visibility)\t\(.updatedAt)"'
```

### Create repo
```bash
gh repo create "$PROJECT_NAME" --private --description "Forged by WebForge"
```

### Clone repo
```bash
gh repo clone "$GITHUB_USER/$PROJECT_NAME" "projects/$PROJECT_NAME"
```

### Delete repo
```bash
gh repo delete "$GITHUB_USER/$PROJECT_NAME" --yes
```

### Check if repo exists
```bash
gh repo view "$GITHUB_USER/$PROJECT_NAME" &>/dev/null && echo "exists" || echo "not found"
```

### Get repo visibility
```bash
gh repo view "$GITHUB_USER/$PROJECT_NAME" --json visibility --jq '.visibility'
```

---

## Git Operations

### Init and push (new project)
```bash
cd "$PROJECT_DIR"
git config user.name "$GITHUB_USER"
git config user.email "${GITHUB_EMAIL:-${GITHUB_USER}@users.noreply.github.com}"
git init
git remote add origin "https://github.com/$GITHUB_USER/$PROJECT_NAME.git"
git add .
git commit -m "feat: initial forge"
git branch -M main
git push -u origin main
cd "$AGENT_DIR"
```

### Commit and push (existing project)
```bash
cd "$PROJECT_DIR"
git config user.name "$GITHUB_USER"
git config user.email "${GITHUB_EMAIL:-${GITHUB_USER}@users.noreply.github.com}"
git pull origin main --no-edit 2>/dev/null || true
git add .
git commit -m "feat: description of changes"
git push
cd "$AGENT_DIR"
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

## Notes

- `GH_TOKEN` env var is all `gh` needs for auth. No token-in-URL hacks needed.
- `gh` handles HTTPS authentication automatically when `GH_TOKEN` is set.
- Always set `git config user.name/email` in each repo before committing. Global config may point to a different account.
- WebForge repos are identified by description containing "Forged by WebForge".
