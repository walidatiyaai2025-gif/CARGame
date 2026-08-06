@echo off
setlocal
cd /d "%~dp0"
title CAR GAME - FIRST TIME SETUP AND RUN
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0FIRST_TIME_SETUP_AND_RUN.ps1"
echo.
pause
