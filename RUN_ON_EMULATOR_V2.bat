@echo off
setlocal
cd /d "%~dp0"
title CAR GAME - RUN ON EMULATOR V2

echo ======================================================
echo CAR GAME - RUN ON EMULATOR V2
echo ======================================================
echo.

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0RUN_ON_EMULATOR_V2.ps1"
set "RC=%ERRORLEVEL%"

echo.
if "%RC%"=="0" (
    echo ======================================================
    echo SUCCESS - APPLICATION IS RUNNING
    echo ======================================================
) else (
    echo ======================================================
    echo FAILED - EXIT CODE: %RC%
    echo ======================================================
    echo Check emulator_crash_filtered_*.log in this folder.
)

echo.
pause
exit /b %RC%
