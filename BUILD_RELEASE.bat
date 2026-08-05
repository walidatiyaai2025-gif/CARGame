@echo off
setlocal
cd /d "%~dp0"
title CAR GAME - RELEASE BUILD
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0BUILD_RELEASE.ps1"
echo.
pause
