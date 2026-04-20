#!/bin/bash

# WebForge Agent Setup Script
# Installs dependencies and verifies configuration

set -e

echo "WebForge Agent Setup"
echo "======================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Track issues
MISSING=0
ISSUE_GIT=0
ISSUE_GH=0
ISSUE_NODE=0
ISSUE_PYTHON=0
ISSUE_ENV=0
ISSUE_GITHUB_TOKEN=0

echo "Checking Dependencies..."
echo "------------------------"

# Check Git
if command -v git &> /dev/null; then
    echo -e "${GREEN}[OK]${NC} Git is installed"
else
    echo -e "${RED}[X]${NC} Git is NOT installed"
    echo "     Install from: https://git-scm.com/"
    ISSUE_GIT=1
fi

# Check GitHub CLI
if command -v gh &> /dev/null; then
    echo -e "${GREEN}[OK]${NC} GitHub CLI is installed"
else
    echo -e "${RED}[X]${NC} GitHub CLI is NOT installed"
    echo "     macOS: brew install gh"
    echo "     Linux: https://cli.github.com/"
    ISSUE_GH=1
fi

# Check Node.js
if command -v node &> /dev/null; then
    echo -e "${GREEN}[OK]${NC} Node.js is installed"
else
    echo -e "${RED}[X]${NC} Node.js is NOT installed"
    echo "     Install from: https://nodejs.org/"
    ISSUE_NODE=1
fi

# Check Python
PY_CMD=""
if command -v python3 &> /dev/null; then
    PY_CMD="python3"
elif command -v python &> /dev/null; then
    PY_CMD="python"
fi

if [ -n "$PY_CMD" ]; then
    echo -e "${GREEN}[OK]${NC} Python is installed ($($PY_CMD --version 2>&1))"
else
    echo -e "${RED}[X]${NC} Python is NOT installed"
    echo "     Install from: https://python.org/"
    ISSUE_PYTHON=1
fi

echo ""
echo "Installing Python Dependencies..."
echo "----------------------------------"

if [ $ISSUE_PYTHON -eq 0 ]; then
    PIP_CMD="pip3"
    command -v pip3 &> /dev/null || PIP_CMD="pip"

    echo "Installing playwright, beautifulsoup4, aiohttp, google-genai, Pillow..."
    $PIP_CMD install playwright beautifulsoup4 aiohttp google-genai Pillow 2>/dev/null && \
        echo -e "${GREEN}[OK]${NC} Python packages installed" || \
        echo -e "${YELLOW}[!]${NC} Failed — run manually: $PIP_CMD install playwright beautifulsoup4 aiohttp google-genai Pillow"

    echo "Installing Playwright Chromium browser..."
    playwright install chromium 2>/dev/null && \
        echo -e "${GREEN}[OK]${NC} Playwright Chromium installed" || \
        echo -e "${YELLOW}[!]${NC} Failed — run manually: playwright install chromium"
else
    echo -e "${YELLOW}[!]${NC} Skipping Python packages — Python not found"
fi

echo ""
echo "Installing Node Dependencies..."
echo "--------------------------------"

if [ $ISSUE_NODE -eq 0 ]; then
    echo "Installing sharp (image processing)..."
    npm list -g sharp &>/dev/null || npm install -g sharp &>/dev/null
    echo -e "${GREEN}[OK]${NC} sharp ready"

    echo "Installing serve (local preview)..."
    npm list -g serve &>/dev/null || npm install -g serve &>/dev/null
    echo -e "${GREEN}[OK]${NC} serve ready"
else
    echo -e "${YELLOW}[!]${NC} Skipping Node packages — Node.js not found"
fi

echo ""
echo "Checking Configuration..."
echo "-------------------------"

# Check .env file
if [ -f ".env" ]; then
    echo -e "${GREEN}[OK]${NC} .env file exists"

    # Check GITHUB_TOKEN
    GITHUB_TOKEN_VALUE=$(grep "^GITHUB_TOKEN=" .env 2>/dev/null | cut -d'=' -f2)
    if [ -n "$GITHUB_TOKEN_VALUE" ] && [ "$GITHUB_TOKEN_VALUE" != "ghp_your_token_here" ]; then
        echo -e "${GREEN}[OK]${NC} GITHUB_TOKEN is set"
    else
        echo -e "${YELLOW}[!]${NC} GITHUB_TOKEN not set or empty"
        echo "     Get your token at: https://github.com/settings/tokens"
        ISSUE_GITHUB_TOKEN=1
    fi

    # Check NANOBANANA_GEMINI_API_KEY or GEMINI_API_KEY
    GEMINI_KEY=$(grep -E "^NANOBANANA_GEMINI_API_KEY=|^GEMINI_API_KEY=" .env 2>/dev/null | head -1 | cut -d'=' -f2)
    if [ -n "$GEMINI_KEY" ] && [ "$GEMINI_KEY" != "your_gemini_api_key_here" ]; then
        echo -e "${GREEN}[OK]${NC} GEMINI_API_KEY is set — AI image generation enabled"
    else
        echo -e "${YELLOW}[!]${NC} GEMINI_API_KEY not set — needed for /rebrand-project image generation"
        echo "     Add to .env: NANOBANANA_GEMINI_API_KEY=your_key_here"
    fi
else
    echo -e "${YELLOW}[!]${NC} .env file not found"
    if [ -f ".env.example" ]; then
        echo "     Creating from .env.example..."
        cp .env.example .env
        echo -e "${GREEN}[OK]${NC} Created .env file"
    fi
    echo "     Please edit .env and add your tokens:"
    echo "     - GITHUB_TOKEN — required"
    echo "     - NANOBANANA_GEMINI_API_KEY — required for image generation"
    ISSUE_ENV=1
fi

echo ""
echo "Checking Skills..."
echo "------------------"

[ -f ".claude/skills/new-project/SKILL.md" ] && echo -e "${GREEN}[OK]${NC} new-project skill" || echo -e "${RED}[X]${NC} new-project skill not found"
[ -f ".claude/skills/rebrand-project/SKILL.md" ] && echo -e "${GREEN}[OK]${NC} rebrand-project skill" || echo -e "${RED}[X]${NC} rebrand-project skill not found"
[ -f ".claude/skills/modify-project/SKILL.md" ] && echo -e "${GREEN}[OK]${NC} modify-project skill" || echo -e "${RED}[X]${NC} modify-project skill not found"
[ -f ".claude/skills/perfect-web-clone/SKILL.md" ] && echo -e "${GREEN}[OK]${NC} perfect-web-clone skill (extraction engine)" || echo -e "${RED}[X]${NC} perfect-web-clone skill not found"

echo ""
echo "======================="

# Calculate total issues
MISSING=$((ISSUE_GIT + ISSUE_GH + ISSUE_NODE + ISSUE_PYTHON + ISSUE_ENV + ISSUE_GITHUB_TOKEN))

if [ $MISSING -eq 0 ]; then
    echo ""
    echo -e "${GREEN}[OK] All checks passed!${NC}"
    echo ""
    echo "WebForge is ready to use!"
    echo ""
    echo "Commands:"
    echo "  /new-project       - Clone a website"
    echo "  /rebrand-project   - Rebrand with PDP content"
    echo "  /modify-project    - Edit a project"
    echo "  /get-projects      - List all projects"
    echo "  /delete-project    - Delete a project"
    echo ""
    exit 0
fi

echo ""
echo -e "${RED}[X] Found $MISSING issue(s) that need to be fixed:${NC}"
echo ""

[ $ISSUE_GIT -eq 1 ] && echo "  [X] Git — Install from: https://git-scm.com/"
[ $ISSUE_GH -eq 1 ] && echo "  [X] GitHub CLI — macOS: brew install gh / Linux: https://cli.github.com/"
[ $ISSUE_NODE -eq 1 ] && echo "  [X] Node.js — Install from: https://nodejs.org/"
[ $ISSUE_PYTHON -eq 1 ] && echo "  [X] Python — Install from: https://python.org/"
[ $ISSUE_ENV -eq 1 ] && echo "  [X] .env file — Create and add your tokens"
[ $ISSUE_GITHUB_TOKEN -eq 1 ] && echo "  [X] GITHUB_TOKEN — Get at: https://github.com/settings/tokens"

echo ""
echo "After fixing the issues, run ./setup.sh again."
echo ""
exit 1
