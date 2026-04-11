---
name: webforge-help
description: Show all available WebForge commands with usage
user-invocable: true
argument-hint: "--command <name> --verbose"
---

# /help

Show all available WebForge commands with usage examples.

## What It Does

1. **List all commands** with brief descriptions
2. **Show usage examples**
3. **Provide command-specific help** (with --command flag)

## Flags

| Flag | Description |
|------|-------------|
| `--command <name>` | Show detailed help for specific command |
| `--verbose` | Show detailed help for all commands |

## Basic Help Output

```
/help

🔥 WebForge Commands
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Initialization:
  /start-agent          Initialize WebForge agent and run setup

Project Management:
  /get-projects         List all WebForge projects
  /new-project          Create a new project
  /modify-project       Modify existing project
  /delete-project       Delete a project

Development:
  /preview-project      Start dev server for project

Information:
  /project-info         Show project details
  /status               Show agent status
  /help                 Show this help message

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Use /help --command <name> for detailed help on a specific command.
Use /help --verbose for detailed help on all commands.
```

## Verbose Help Output

```
/help --verbose

🔥 WebForge Commands - Detailed Help
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Initialization

### /start-agent
Initialize WebForge agent and verify all dependencies.

Usage:  /start-agent [flags]
Flags:  --skip-setup    Skip running setup script
        --verbose       Show detailed output

Example:  /start-agent
          /start-agent --skip-setup

---

## Project Management

### /get-projects
List all WebForge projects from GitHub and/or local directories.

Usage:  /get-projects [flags]
Flags:  --local         Show only local projects
        --remote        Show only GitHub projects (default)
        --all           Show both local and remote
        --json          Output as JSON

Example:  /get-projects
          /get-projects --local
          /get-projects --json

---

### /new-project
Create a new WebForge project by cloning a reference website.

Usage:  /new-project [flags]
Flags:  --name <name>           Skip project name prompt
        --visibility <pub|priv> Skip visibility prompt
        --url <url>             Skip URL prompt
        --no-preview            Skip preview, push directly
        --no-push               Don't push to GitHub

Example:  /new-project
          /new-project --name <project-name> --visibility private --url <url>

---

### /modify-project
Modify an existing WebForge project. Automatically clones if not local.

Usage:  /modify-project [flags]
Flags:  --name <name>       Skip project selection
        --skip-preview      Skip preview, push directly

Example:  /modify-project
          /modify-project --name <project-name>

---

### /delete-project
Delete a WebForge project from GitHub and/or local.

Usage:  /delete-project [flags]
Flags:  --name <name>       Skip project selection
        --github-only       Delete GitHub repo only
        --local-only        Delete local folder only
        --force             Skip confirmation

Example:  /delete-project
          /delete-project --name <project-name> --force

---

## Development

### /preview-project
Start the development server for a WebForge project.

Usage:  /preview-project [flags]
Flags:  --name <name>       Skip project selection
        --port <port>       Custom port (default: 3000)
        --no-deps           Skip npm install

Example:  /preview-project
          /preview-project --name <project-name> --port 3001

---

## Information

### /project-info
Show detailed information about a WebForge project.

Usage:  /project-info [flags]
Flags:  --name <name>       Skip project selection
        --json              Output as JSON

Example:  /project-info
          /project-info --name <project-name>

---

### /status
Show WebForge agent status and configuration.

Usage:  /status [flags]
Flags:  --json              Output as JSON

Example:  /status
          /status --json

---

### /help
Show all available WebForge commands with usage.

Usage:  /help [flags]
Flags:  --command <name>    Show help for specific command
        --verbose           Show detailed help

Example:  /help
          /help --command new-project
          /help --verbose

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Command-Specific Help

```
/help --command new-project

🔥 /new-project
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Create a new WebForge project by cloning a reference website.

FLAGS:
  --name <name>           Skip project name prompt
  --visibility <pub|priv> Skip visibility prompt
  --url <url>             Skip URL prompt
  --no-preview            Skip preview, push directly
  --no-push               Don't push to GitHub

EXAMPLES:
  /new-project
  /new-project --name <project-name> --visibility private --url <url>
  /new-project --name <project-name> --url <url> --no-preview

INTERACTIVE FLOW:
  1. Enter project name (lowercase, hyphens, 3-30 chars)
  2. Select visibility (public/private)
  3. Enter reference website URL
  4. Wait for cloning to complete
  5. Choose to generate AI images (optional)
  6. Preview at localhost:3000
  7. Confirm push to GitHub

For more info, see: .claude/skills/new-project/SKILL.md
```

---

### /start-agent
Initialize WebForge agent and verify all dependencies.

Usage:  /start-agent [flags]
Flags:  --verbose       Show detailed output

Example:  /start-agent

---

### /status
Show WebForge agent status and configuration.

Usage:  /status [flags]
Flags:  --json          Output as JSON

Example:  /status
          /status --json

---

### /help
Show all available WebForge commands with usage.

Usage:  /help [flags]
Flags:  --command <name>    Show help for specific command
        --verbose           Show detailed help

Example:  /help
          /help --command new-project
          /help --verbose

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Command Aliases

| Alias | Command |
|-------|---------|
| `/start` | `/start-agent` |
| `/list` | `/get-projects` |
| `/create` | `/new-project` |
| `/edit` | `/modify-project` |
| `/remove` | `/delete-project` |
| `/info` | `/project-info` |
| `/preview` | `/preview-project` |
