@echo off
REM WebForge Agent Setup Script (Windows)
REM Checks for required dependencies and guides installation

echo.
echo ======================================
echo   WebForge Agent Setup
echo ======================================
echo.

REM Initialize all issue flags to 0
set MISSING=0
set ISSUE_GIT=0
set ISSUE_GH=0
set ISSUE_ENV=0
set ISSUE_GITHUB_TOKEN=0

echo Checking Requirements...
echo ------------------------

REM Check Git
where git >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] Git is installed
) else (
    echo [X] Git is NOT installed
    echo     Install from: https://git-scm.com/
    set ISSUE_GIT=1
)

REM Check GitHub CLI
where gh >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] GitHub CLI is installed
) else (
    echo [X] GitHub CLI is NOT installed
    echo     Install: winget install GitHub.cli
    set ISSUE_GH=1
)

REM Check Node.js (optional)
where node >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] Node.js is installed
) else (
    echo [!] Node.js not found - optional for running websites
    echo     Install from: https://nodejs.org/
)

echo.
echo Checking Configuration...
echo -------------------------

REM Check .env file only once
if exist .env (
    echo [OK] .env file exists

    REM Check GITHUB_TOKEN - verify it has a value (not empty)
    for /f "tokens=1,2 delims==" %%a in ('type .env ^| findstr /B "GITHUB_TOKEN="') do (
        set "GITHUB_TOKEN_VALUE=%%b"
    )

    if defined GITHUB_TOKEN_VALUE (
        if "%GITHUB_TOKEN_VALUE%"=="ghp_your_token_here" (
            echo [!] GITHUB_TOKEN is set to placeholder value
            echo     Get your token at: https://github.com/settings/tokens
            set ISSUE_GITHUB_TOKEN=1
        ) else (
            echo [OK] GITHUB_TOKEN is set
        )
    ) else (
        echo [!] GITHUB_TOKEN not set or empty
        echo     Get your token at: https://github.com/settings/tokens
        set ISSUE_GITHUB_TOKEN=1
    )

    REM Check FAL_KEY - optional
    for /f "tokens=1,2 delims==" %%a in ('type .env ^| findstr /B "FAL_KEY="') do (
        set "FAL_KEY_VALUE=%%b"
    )

    if defined FAL_KEY_VALUE (
        if "%FAL_KEY_VALUE%"=="fal_your_key_here" (
            echo [!] FAL_KEY is set to placeholder value - optional for image generation
            echo     Get your key at: https://fal.ai/dashboard/keys
        ) else (
            echo [OK] FAL_KEY is set - image generation enabled
        )
    ) else (
        echo [!] FAL_KEY not set - optional for image generation
        echo     Get your key at: https://fal.ai/dashboard/keys
    )
) else (
    echo [!] .env file not found
    echo     Creating from .env.example...
    copy .env.example .env >nul
    echo [OK] Created .env file
    echo     Please edit .env and add your tokens:
    echo     - GITHUB_TOKEN - required
    echo     - FAL_KEY - optional
    set ISSUE_ENV=1
)

echo.
echo Checking Skills...
echo ------------------

REM Check WebForge skill
if exist .claude\skills\webforge\SKILL.md (
    echo [OK] WebForge skill exists
) else (
    echo [X] WebForge skill not found - please reinstall from GitHub
)

REM Check image generation skill
if exist .claude\skills\webforge-image-gen\SKILL.md (
    echo [OK] Image generation skill exists
) else (
    echo [!] Image generation skill not found - optional for Claude
)

REM Check Fal skills
if exist skills\fal\skills\claude.ai\fal-generate\scripts\generate.sh (
    echo [OK] Fal.ai skills are installed
) else (
    echo [!] Fal.ai skills not found, cloning...
    goto :clone_fal
)
goto :fal_done

:clone_fal
echo.
echo [!] Downloading Fal.ai skills...
echo     This may take a few minutes...
if exist skills\fal (
    rd /s /q skills\fal
)
git clone https://github.com/fal-ai-community/skills.git skills\fal
if %errorlevel% equ 0 (
    echo [OK] Fal.ai skills installed
) else (
    echo [X] Failed to download Fal.ai skills - check your internet connection
)

:fal_done

echo.
echo Checking Claude...
echo ------------------

REM Check if Claude is running
tasklist /FI "IMAGENAME eq Claude.exe" 2>nul | find /I /N "Claude.exe">nul
if "%ERRORLEVEL%"=="0" (
    echo [OK] Claude Desktop is running
) else (
    echo [!] Claude Desktop may not be running
    echo     Make sure Claude Desktop or Claude Code is installed and running
)

echo.
echo ======================================

REM Calculate total issues - remove quotes to avoid parsing issues
set /a MISSING=%ISSUE_GIT%+%ISSUE_GH%+%ISSUE_ENV%+%ISSUE_GITHUB_TOKEN%

if %MISSING%==0 (
    echo.
    echo [OK] All checks passed!
    echo.
    echo WebForge is ready to use!
    echo.
    echo To start:
    echo 1. Open Claude Desktop/Code
    echo 2. Navigate to this folder
    echo 3. Type: start
    echo    or: /webforge
    echo.
    pause
    exit /b 0
)

echo.
echo [X] Found %MISSING% issue(s) that need to be fixed:
echo.
echo Summary of issues:
echo ------------------

if %ISSUE_GIT%==1 (
    echo   [X] Git is NOT installed
    echo       - Install from: https://git-scm.com/
)

if %ISSUE_GH%==1 (
    echo   [X] GitHub CLI is NOT installed
    echo       - Run: winget install GitHub.cli
)

if %ISSUE_ENV%==1 (
    echo   [X] .env file not found or incomplete
    echo       - Edit .env and add your tokens
)

if %ISSUE_GITHUB_TOKEN%==1 (
    echo   [X] GITHUB_TOKEN not set
    echo       - Get token at: https://github.com/settings/tokens
    echo       - Add to .env: GITHUB_TOKEN=your_token_here
)

echo.
echo After fixing the issues, run setup.bat again.
echo.
pause
exit /b 1
