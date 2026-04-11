#!/bin/bash

# WebForge Agent Setup Script
# Checks for required dependencies and guides installation

set -e

echo "🔥 WebForge Agent Setup"
echo "======================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track missing requirements
MISSING=0

# Track specific issues
ISSUE_GIT=0
ISSUE_GH=0
ISSUE_ENV=0
ISSUE_GITHUB_TOKEN=0

# Function to check command
check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 is installed"
        return 0
    else
        echo -e "${RED}✗${NC} $1 is NOT installed"
        if [ "$1" = "git" ]; then
            ISSUE_GIT=1
        elif [ "$1" = "gh" ]; then
            ISSUE_GH=1
        fi
        return 1
    fi
}

# Function to check file
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $2 exists"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} $2 not found ($1)"
        MISSING=$((MISSING + 1))
        return 1
    fi
}

echo "Checking Requirements..."
echo "------------------------"

# Check system dependencies
check_command "git" || echo "   Install from: https://git-scm.com/"
check_command "gh" || echo "   Run: brew install gh (macOS) or visit https://cli.github.com/ (Linux)"
if command -v node &> /dev/null; then
    echo -e "${GREEN}✓${NC} Node.js is installed"
else
    echo -e "${YELLOW}⚠${NC} Node.js not found - optional for running websites"
    echo "   Install from: https://nodejs.org/"
fi

echo ""
echo "Checking Configuration..."
echo "-------------------------"

# Check .env file
if [ -f ".env" ]; then
    echo -e "${GREEN}✓${NC} .env file exists"

    # Check if GITHUB_TOKEN is set and has a value (not empty, not placeholder)
    GITHUB_TOKEN_VALUE=$(grep "^GITHUB_TOKEN=" .env 2>/dev/null | cut -d'=' -f2)
    if [ -n "$GITHUB_TOKEN_VALUE" ] && [ "$GITHUB_TOKEN_VALUE" != "ghp_your_token_here" ]; then
        echo -e "${GREEN}✓${NC} GITHUB_TOKEN is set"
    else
        echo -e "${YELLOW}⚠${NC} GITHUB_TOKEN not set or empty"
        echo "   Get your token at: https://github.com/settings/tokens"
        ISSUE_GITHUB_TOKEN=1
    fi

    # Check if FAL_KEY is set (optional, not the placeholder)
    FAL_KEY_VALUE=$(grep "^FAL_KEY=" .env 2>/dev/null | cut -d'=' -f2)
    if [ -n "$FAL_KEY_VALUE" ] && [ "$FAL_KEY_VALUE" != "fal_your_key_here" ]; then
        echo -e "${GREEN}✓${NC} FAL_KEY is set - image generation enabled"
    else
        echo -e "${YELLOW}⚠${NC} FAL_KEY not set - optional for image generation"
        echo "   Get your key at: https://fal.ai/dashboard/keys"
    fi
else
    echo -e "${YELLOW}⚠${NC} .env file not found"
    echo "   Creating from .env.example..."
    cp .env.example .env
    echo -e "${GREEN}✓${NC} Created .env file"
    echo "   Please edit .env and add your tokens:"
    echo "   - GITHUB_TOKEN - required"
    echo "   - FAL_KEY - optional"
    ISSUE_ENV=1
fi

echo ""
echo "Checking Skills..."
echo "------------------"

# Check if skills exist
if [ -f ".claude/skills/webforge/SKILL.md" ]; then
    echo -e "${GREEN}✓${NC} WebForge skill exists"
else
    echo -e "${RED}✗${NC} WebForge skill not found - please reinstall from GitHub"
fi

if [ -f ".claude/skills/webforge-image-gen/SKILL.md" ]; then
    echo -e "${GREEN}✓${NC} Image generation skill exists"
else
    echo -e "${YELLOW}⚠${NC} Image generation skill not found - optional for Claude"
fi

# Check Fal skills
if [ -d "skills/fal" ] && [ -f "skills/fal/skills/claude.ai/fal-generate/scripts/generate.sh" ]; then
    echo -e "${GREEN}✓${NC} Fal.ai skills are installed"
else
    echo -e "${YELLOW}⚠${NC} Fal.ai skills not found, cloning..."
    echo ""
    echo "📦 Downloading Fal.ai skills..."
    echo "   This may take a few minutes..."

    # Remove incomplete Fal skills if exists
    if [ -d "skills/fal" ]; then
        rm -rf skills/fal
    fi

    # Clone Fal skills
    if git clone https://github.com/fal-ai-community/skills.git skills/fal > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Fal.ai skills installed"
    else
        echo -e "${RED}✗${NC} Failed to download Fal.ai skills - check your internet connection"
    fi
fi

echo ""
echo "Checking Claude..."
echo "------------------"

# Check if Claude Desktop is running
if pgrep -x "Claude" > /dev/null || pgrep -x "claude" > /dev/null; then
    echo -e "${GREEN}✓${NC} Claude Desktop is running"
else
    echo -e "${YELLOW}⚠${NC} Claude Desktop may not be running"
    echo "   Make sure Claude Desktop or Claude Code is installed and running"
fi

echo ""
echo "======================="

# Calculate total issues
MISSING=$((ISSUE_GIT + ISSUE_GH + ISSUE_ENV + ISSUE_GITHUB_TOKEN))

if [ $MISSING -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "WebForge is ready to use!"
    echo ""
    echo "To start:"
    echo "1. Open Claude Desktop/Code"
    echo "2. Navigate to this folder"
    echo "3. Type: start"
    echo "   or: /webforge"
    echo ""
    exit 0
fi

echo ""
echo -e "${RED}✗ Found $MISSING issue(s) that need to be fixed:${NC}"
echo ""
echo "Summary of issues:"
echo "------------------"

# List specific issues
if [ $ISSUE_GIT -eq 1 ]; then
    echo -e "  ${RED}✗${NC} Git is NOT installed"
    echo "     → Install from: https://git-scm.com/"
fi

if [ $ISSUE_GH -eq 1 ]; then
    echo -e "  ${RED}✗${NC} GitHub CLI is NOT installed"
    echo "     → Run: brew install gh (macOS) or visit https://cli.github.com/ (Linux)"
fi

if [ $ISSUE_ENV -eq 1 ]; then
    echo -e "  ${RED}✗${NC} .env file not found or incomplete"
    echo "     → Edit .env and add your tokens"
fi

if [ $ISSUE_GITHUB_TOKEN -eq 1 ]; then
    echo -e "  ${RED}✗${NC} GITHUB_TOKEN not set"
    echo "     → Get token at: https://github.com/settings/tokens"
    echo "     → Add to .env: GITHUB_TOKEN=your_token_here"
fi

echo ""
echo "After fixing the issues, run ./setup.sh again."
echo ""
exit 1
