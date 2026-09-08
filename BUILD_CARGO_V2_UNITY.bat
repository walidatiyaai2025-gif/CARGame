@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%BUILD_CARGO_V2_UNITY.ps1" %*
set "EXIT_CODE=%ERRORLEVEL%"
if not "%EXIT_CODE%"=="0" (
  echo CARGO V2 Unity build failed with exit code %EXIT_CODE%.
)
exit /b %EXIT_CODE%
