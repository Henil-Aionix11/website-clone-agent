@echo off
REM WebForge Agent Setup Script (Windows)
REM Installs dependencies and verifies configuration

echo.
echo ======================================
echo   WebForge Agent Setup
echo ======================================
echo.

REM Initialize all issue flags to 0
set MISSING=0
set ISSUE_GIT=0
set ISSUE_GH=0
set ISSUE_NODE=0
set ISSUE_PYTHON=0
set ISSUE_ENV=0
set ISSUE_GITHUB_TOKEN=0

echo Checking Dependencies...
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

REM Check Node.js
where node >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] Node.js is installed
) else (
    echo [X] Node.js is NOT installed
    echo     Install from: https://nodejs.org/
    set ISSUE_NODE=1
)

REM Check Python
where python >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] Python is installed
) else (
    echo [X] Python is NOT installed
    echo     Install from: https://python.org/
    set ISSUE_PYTHON=1
)

echo.
echo Installing Python Dependencies...
echo ----------------------------------

if %ISSUE_PYTHON%==0 (
    echo Installing playwright, beautifulsoup4, aiohttp, google-genai, Pillow...
    pip install playwright beautifulsoup4 aiohttp google-genai Pillow >nul 2>nul
    if %errorlevel% equ 0 (
        echo [OK] Python packages installed
    ) else (
        echo [!] Failed to install Python packages
        echo     Run manually: pip install playwright beautifulsoup4 aiohttp google-genai Pillow
    )

    echo Installing Playwright Chromium browser...
    playwright install chromium >nul 2>nul
    if %errorlevel% equ 0 (
        echo [OK] Playwright Chromium installed
    ) else (
        echo [!] Failed to install Playwright Chromium
        echo     Run manually: playwright install chromium
    )
) else (
    echo [!] Skipping Python packages - Python not found
)

echo.
echo Installing Node Dependencies...
echo --------------------------------

if %ISSUE_NODE%==0 (
    echo Installing sharp (image processing)...
    npm list -g sharp >nul 2>nul
    if %errorlevel% neq 0 (
        npm install -g sharp >nul 2>nul
    )
    echo [OK] sharp ready

    echo Installing serve (local preview)...
    npm list -g serve >nul 2>nul
    if %errorlevel% neq 0 (
        npm install -g serve >nul 2>nul
    )
    echo [OK] serve ready
) else (
    echo [!] Skipping Node packages - Node.js not found
)

echo.
echo Checking Configuration...
echo -------------------------

REM Check .env file
if exist .env (
    echo [OK] .env file exists

    REM Check GITHUB_TOKEN
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

    REM Check NANOBANANA_GEMINI_API_KEY or GEMINI_API_KEY
    set "GEMINI_KEY_FOUND=0"
    for /f "tokens=1,2 delims==" %%a in ('type .env ^| findstr "NANOBANANA_GEMINI_API_KEY= GEMINI_API_KEY="') do (
        if not "%%b"=="" set "GEMINI_KEY_FOUND=1"
    )

    if "%GEMINI_KEY_FOUND%"=="1" (
        echo [OK] GEMINI_API_KEY is set - AI image generation enabled
    ) else (
        echo [!] GEMINI_API_KEY not set - needed for /rebrand-project image generation
        echo     Add to .env: NANOBANANA_GEMINI_API_KEY=your_key_here
    )
) else (
    echo [!] .env file not found
    if exist .env.example (
        echo     Creating from .env.example...
        copy .env.example .env >nul
        echo [OK] Created .env file
    )
    echo     Please edit .env and add your tokens:
    echo     - GITHUB_TOKEN - required
    echo     - NANOBANANA_GEMINI_API_KEY - required for image generation
    set ISSUE_ENV=1
)

echo.
echo Checking Skills...
echo ------------------

if exist .claude\skills\new-project\SKILL.md (
    echo [OK] new-project skill
) else (
    echo [X] new-project skill not found
)

if exist .claude\skills\rebrand-project\SKILL.md (
    echo [OK] rebrand-project skill
) else (
    echo [X] rebrand-project skill not found
)

if exist .claude\skills\modify-project\SKILL.md (
    echo [OK] modify-project skill
) else (
    echo [X] modify-project skill not found
)

if exist .claude\skills\perfect-web-clone\SKILL.md (
    echo [OK] perfect-web-clone skill (extraction engine)
) else (
    echo [X] perfect-web-clone skill not found
)

echo.
echo ======================================

REM Calculate total issues
set /a MISSING=%ISSUE_GIT%+%ISSUE_GH%+%ISSUE_NODE%+%ISSUE_PYTHON%+%ISSUE_ENV%+%ISSUE_GITHUB_TOKEN%

if %MISSING%==0 (
    echo.
    echo [OK] All checks passed!
    echo.
    echo WebForge is ready to use!
    echo.
    echo Commands:
    echo   /new-project       - Clone a website
    echo   /rebrand-project   - Rebrand with PDP content
    echo   /modify-project    - Edit a project
    echo   /get-projects      - List all projects
    echo   /delete-project    - Delete a project
    echo.
    pause
    exit /b 0
)

echo.
echo [X] Found %MISSING% issue(s) that need to be fixed:
echo.

if %ISSUE_GIT%==1 (
    echo   [X] Git - Install from: https://git-scm.com/
)
if %ISSUE_GH%==1 (
    echo   [X] GitHub CLI - Run: winget install GitHub.cli
)
if %ISSUE_NODE%==1 (
    echo   [X] Node.js - Install from: https://nodejs.org/
)
if %ISSUE_PYTHON%==1 (
    echo   [X] Python - Install from: https://python.org/
)
if %ISSUE_ENV%==1 (
    echo   [X] .env file - Create and add your tokens
)
if %ISSUE_GITHUB_TOKEN%==1 (
    echo   [X] GITHUB_TOKEN - Get at: https://github.com/settings/tokens
)

echo.
echo After fixing the issues, run setup.bat again.
echo.
pause
exit /b 1
