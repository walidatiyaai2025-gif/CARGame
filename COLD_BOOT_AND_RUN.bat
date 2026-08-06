@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0COLD_BOOT_AND_RUN.ps1"
echo.
pause
