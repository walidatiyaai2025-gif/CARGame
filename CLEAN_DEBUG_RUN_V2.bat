@echo off
setlocal
cd /d "%~dp0"
title CAR GAME - ISOLATED CLEAN DEBUG RUN
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0CLEAN_DEBUG_RUN_V2.ps1"
echo.
pause
