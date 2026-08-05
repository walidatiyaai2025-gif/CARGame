@echo off
setlocal
cd /d "%~dp0"
title CAR GAME - ISOLATED RELEASE BUILD V2
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0BUILD_RELEASE_V2.ps1"
echo.
pause
