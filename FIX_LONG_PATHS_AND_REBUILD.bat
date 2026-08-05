@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"
title CAR Game - Fix Long Paths and Rebuild

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0FIX_LONG_PATHS_AND_REBUILD.ps1"
set "RC=%ERRORLEVEL%"

echo.
if "%RC%"=="0" (
    echo ============================================================
    echo SUCCESS
    echo ============================================================
) else (
    echo ============================================================
    echo FAILED - Exit code: %RC%
    echo ============================================================
)

echo.
pause
exit /b %RC%
