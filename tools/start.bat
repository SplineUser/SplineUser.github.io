@echo off
:: =============================================================================
:: start.bat — Launch the Jekyll blog locally (Windows)
:: =============================================================================

setlocal

set HOST=127.0.0.1
set PORT=4000
set PROD=false
set DRAFTS=false

:: ── Check dependencies ───────────────────────────────────────────────────────
where bundle >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: Bundler not found.
    echo Please run setup.bat first, or install it with:  gem install bundler
    echo.
    pause
    exit /b 1
)

:: ── Build command ────────────────────────────────────────────────────────────
set CMD=bundle exec jekyll serve --livereload -H %HOST% -P %PORT%

:: Merge local config if it exists
if exist "_config.local.yml" (
    set CMD=%CMD% --config _config.yml,_config.local.yml
    echo Using _config.local.yml overrides.
)

echo.
echo =====================================================
echo   Starting blog at http://%HOST%:%PORT%
echo   Press Ctrl+C to stop
echo =====================================================
echo.
echo %CMD%
echo.

%CMD%
endlocal
