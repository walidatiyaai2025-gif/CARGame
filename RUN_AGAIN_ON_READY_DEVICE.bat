@echo off
setlocal
cd /d "%~dp0"
title CAR GAME - RUN AGAIN
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0RUN_AGAIN_ON_READY_DEVICE.ps1"
echo.
pause
