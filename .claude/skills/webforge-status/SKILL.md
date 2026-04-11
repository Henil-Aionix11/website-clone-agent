---
name: webforge-status
description: Show WebForge agent status and configuration
user-invocable: true
argument-hint: "--json"
---

# /status

Show WebForge agent status, configuration, and project counts.

## What It Does

1. **Check setup status** (Git, GitHub CLI, Node.js)
2. **Verify environment variables** (GITHUB_TOKEN, FAL_KEY)
3. **Check Fal skills status**
4. **Count projects** (local and remote)
5. **Show GitHub auth status**

## Flags

| Flag | Description |
|------|-------------|
| `--json` | Output as JSON format |

## Implementation

### Step 1: Check System Dependencies

```bash
# Check Git
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version 2>/dev/null | awk '{print $3}' || echo "installed")
    GIT_STATUS="✅"
else
    GIT_VERSION="not installed"
    GIT_STATUS="❌"
fi

# Check GitHub CLI
if command -v gh &> /dev/null; then
    GH_VERSION=$(gh --version 2>/dev/null | head -1 | awk '{print $3}' || echo "installed")
    GH_STATUS="✅"
else
    GH_VERSION="not installed"
    GH_STATUS="❌"
fi

# Check Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version 2>/dev/null || echo "installed")
    NODE_STATUS="✅"
else
    NODE_VERSION="not installed"
    NODE_STATUS="⚠️ "
fi
```

### Step 2: Check Environment Variables

```bash
# Check GITHUB_TOKEN
if [ -f .env ]; then
    GITHUB_TOKEN=$(grep GITHUB_TOKEN .env | cut -d'=' -f2 | tr -d ' ')
    if [ -n "$GITHUB_TOKEN" ] && [ "$GITHUB_TOKEN" != "ghp_your_token_here" ]; then
        TOKEN_STATUS="✅"
        TOKEN_INFO="configured"
    else
        TOKEN_STATUS="❌"
        TOKEN_INFO="not configured"
    fi

    # Check FAL_KEY
    FAL_KEY=$(grep FAL_KEY .env | cut -d'=' -f2 | tr -d ' ')
    if [ -n "$FAL_KEY" ] && [ "$FAL_KEY" != "fal_your_key_here" ]; then
        FAL_STATUS="✅"
        FAL_INFO="configured"
    else
        FAL_STATUS="⚠️ "
        FAL_INFO="not configured (optional)"
    fi
else
    TOKEN_STATUS="❌"
    TOKEN_INFO=".env file not found"
    FAL_STATUS="⚠️ "
    FAL_INFO="not configured"
fi
```

### Step 3: Check Fal Skills

```bash
# Check Fal skills
if [ -d "skills/fal" ] && [ -f "skills/fal/skills/claude.ai/fal-generate/scripts/generate.sh" ]; then
    FAL_SKILLS_STATUS="✅"
    FAL_SKILLS_INFO="ready"
elif [ -d "skills/fal" ]; then
    FAL_SKILLS_STATUS="⚠️ "
    FAL_SKILLS_INFO="incomplete"
else
    FAL_SKILLS_STATUS="⚠️ "
    FAL_SKILLS_INFO="not found (optional)"
fi
```

### Step 4: Count Projects

```bash
# Count local projects
if [ -d "projects" ]; then
    LOCAL_COUNT=$(find projects -maxdepth 1 -type d 2>/dev/null | tail -n +2 | wc -l)
else
    LOCAL_COUNT=0
fi

# Count remote projects
if [ "$TOKEN_STATUS" = "✅" ]; then
    export GH_TOKEN="$GITHUB_TOKEN"
    REMOTE_COUNT=$(gh repo list --limit 100 2>/dev/null | grep -i "Forged by WebForge" | wc -l || echo 0)
else
    REMOTE_COUNT=0
fi
```

### Step 5: Check GitHub Auth

```bash
if [ "$TOKEN_STATUS" = "✅" ] && command -v gh &> /dev/null; then
    export GH_TOKEN="$GITHUB_TOKEN"
    GITHUB_USER=$(gh api user --jq '.login' 2>/dev/null || echo "unknown")
    AUTH_STATUS="✅"
    AUTH_INFO="authenticated as $GITHUB_USER"
else
    AUTH_STATUS="❌"
    AUTH_INFO="not authenticated"
fi
```

### Step 6: Display Status

```bash
if [[ "$*" == *"--json"* ]]; then
    echo "{"
    echo "  \"git\": {"
    echo "    \"status\": \"$([ "$GIT_STATUS" = "✅" ] && echo "ok" || echo "error")\","
    echo "    \"version\": \"$GIT_VERSION\""
    echo "  },"
    echo "  \"github_cli\": {"
    echo "    \"status\": \"$([ "$GH_STATUS" = "✅" ] && echo "ok" || echo "error")\","
    echo "    \"version\": \"$GH_VERSION\""
    echo "  },"
    echo "  \"nodejs\": {"
    echo "    \"status\": \"$([ "$NODE_STATUS" = "✅" ] && echo "ok" || echo "warning")\","
    echo "    \"version\": \"$NODE_VERSION\""
    echo "  },"
    echo "  \"github_token\": {"
    echo "    \"status\": \"$([ "$TOKEN_STATUS" = "✅" ] && echo "configured" || echo "not_configured")\""
    echo "  },"
    echo "  \"fal_key\": {"
    echo "    \"status\": \"$([ "$FAL_STATUS" = "✅" ] && echo "configured" || echo "not_configured")\""
    echo "  },"
    echo "  \"fal_skills\": {"
    echo "    \"status\": \"$([ "$FAL_SKILLS_STATUS" = "✅" ] && echo "ready" || echo "not_ready")\""
    echo "  },"
    echo "  \"projects\": {"
    echo "    \"local\": $LOCAL_COUNT,"
    echo "    \"remote\": $REMOTE_COUNT"
    echo "  },"
    echo "  \"github_auth\": {"
    echo "    \"status\": \"$([ "$AUTH_STATUS" = "✅" ] && echo "authenticated" || echo "not_authenticated")\","
    echo "    \"username\": \"$GITHUB_USER\""
    echo "  }"
    echo "}"
else
    echo "🔥 WebForge Agent Status"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "System Dependencies:"
    echo "  $GIT_STATUS Git:           $GIT_VERSION"
    echo "  $GH_STATUS GitHub CLI:    $GH_VERSION"
    echo "  $NODE_STATUS Node.js:       $NODE_VERSION"
    echo ""
    echo "Configuration:"
    echo "  $TOKEN_STATUS GITHUB_TOKEN:  $TOKEN_INFO"
    echo "  $FAL_STATUS FAL_KEY:       $FAL_INFO"
    echo ""
    echo "Fal Skills:"
    echo "  $FAL_SKILLS_STATUS Fal skills:    $FAL_SKILLS_INFO"
    echo ""
    echo "Projects:"
    echo "  📊 Local:  $LOCAL_COUNT"
    echo "  📊 Remote: $REMOTE_COUNT"
    echo ""
    echo "GitHub:"
    echo "  $AUTH_STATUS $AUTH_INFO"
    echo ""

    # Show issues if any
    if [ "$GIT_STATUS" = "❌" ] || [ "$GH_STATUS" = "❌" ] || [ "$TOKEN_STATUS" = "❌" ]; then
        echo "⚠️  Issues detected:"
        if [ "$GIT_STATUS" = "❌" ]; then
            echo "   - Git not installed"
        fi
        if [ "$GH_STATUS" = "❌" ]; then
            echo "   - GitHub CLI not installed (run: winget install GitHub.cli)"
        fi
        if [ "$TOKEN_STATUS" = "❌" ]; then
            echo "   - GITHUB_TOKEN not configured"
        fi
        echo ""
        echo "Run /start-agent to fix these issues."
    fi
fi
```

## Output Format

```
/status

🔥 WebForge Agent Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

System Dependencies:
  ✅ Git:           <version>
  ✅ GitHub CLI:    <version>
  ✅ Node.js:       <version>

Configuration:
  ✅ GITHUB_TOKEN:  configured
  ✅ FAL_KEY:       configured

Fal Skills:
  ✅ Fal skills:    ready

Projects:
  📊 Local:  <count>
  📊 Remote: <count>

GitHub:
  ✅ authenticated as <username>
```

## JSON Output Format

```json
{
  "git": {
    "status": "ok",
    "version": "<version>"
  },
  "github_cli": {
    "status": "ok",
    "version": "<version>"
  },
  "nodejs": {
    "status": "ok",
    "version": "<version>"
  },
  "github_token": {
    "status": "configured"
  },
  "fal_key": {
    "status": "configured"
  },
  "fal_skills": {
    "status": "ready"
  },
  "projects": {
    "local": <count>,
    "remote": <count>
  },
  "github_auth": {
    "status": "authenticated",
    "username": "<username>"
  }
}
```
