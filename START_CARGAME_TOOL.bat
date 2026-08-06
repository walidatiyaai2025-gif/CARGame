@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0START_CARGAME_TOOL.ps1"
set "EXITCODE=%ERRORLEVEL%"
echo.
if not "%EXITCODE%"=="0" (
  echo ============================================================
  echo LAUNCHER FAILED - Exit code: %EXITCODE%
  echo ============================================================
)
pause
exit /b %EXITCODE%
