@echo off
setlocal EnableExtensions
chcp 65001 >nul
title CAR Game - Fresh Download Build and Run
cd /d "%~dp0"

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0INSTALL_BUILD_RUN.ps1"

set "RC=%ERRORLEVEL%"
echo.
echo ============================================================
if "%RC%"=="0" (
  echo PROCESS FINISHED
) else (
  echo PROCESS RETURNED EXIT CODE %RC%
)
echo ============================================================
echo.
echo This window will remain open so you can review all messages.
pause
exit /b %RC%
