@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"
title CAR GAME - CLEAN DEBUG RUN

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0CLEAN_DEBUG_RUN.ps1"

echo.
echo PowerShell script finished.
pause
