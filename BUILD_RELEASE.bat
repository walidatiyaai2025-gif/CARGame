@echo off
setlocal
cd /d "%~dp0"
title CAR GAME - UNIVERSAL RELEASE BUILD AND PHONE TEST
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0BUILD_RELEASE.ps1" -InstallAndRun
echo.
pause
