@echo off
:: =============================================================================
:: setup.bat — One-time setup for the Jekyll blog (Windows)
:: Run this once before using start.bat
:: =============================================================================

setlocal

echo.
echo =====================================================
echo   Blog Setup Script (Windows)
echo =====================================================
echo.

:: ── Check Ruby ───────────────────────────────────────────────────────────────
where ruby >nul 2>&1
if errorlevel 1 (
    echo ERROR: Ruby not found.
    echo.
    echo Please install Ruby from https://rubyinstaller.org/
    echo  - Choose "Ruby+Devkit" installer
    echo  - Check "Add Ruby executables to your PATH"
    echo  - After install, re-run this script.
    echo.
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('ruby -e "puts RUBY_VERSION"') do set RUBY_VERSION=%%i
echo [OK] Ruby %RUBY_VERSION% found.

:: ── Install Bundler ───────────────────────────────────────────────────────────
where bundle >nul 2>&1
if errorlevel 1 (
    echo Installing Bundler...
    gem install bundler --no-document
) else (
    for /f "tokens=*" %%i in ('bundle --version') do set BUNDLE_VER=%%i
    echo [OK] %BUNDLE_VER% found.
)

:: ── Install gems ──────────────────────────────────────────────────────────────
echo.
echo Installing gems (this may take a minute the first time)...
bundle install

echo.
echo =====================================================
echo   Setup complete!
echo   Run start.bat to launch the blog.
echo =====================================================
echo.
pause
endlocal
