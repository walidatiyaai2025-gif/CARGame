@echo off
setlocal EnableExtensions
cd /d "%~dp0"
title CAR GAME - CONTROL CENTER

:menu
cls
echo ============================================================
echo                 CAR GAME - CONTROL CENTER
echo ============================================================
echo.
echo   1. Clean Debug Run on Emulator
echo   2. Build Universal Release APK
echo   3. Build Google Play AAB
echo   4. Run existing Release APK on Emulator
echo   5. Collect Android Runtime Logs
echo   6. Open Release APK Folder
echo   7. Reset local project to GitHub main
echo   8. Exit
echo.
set /p choice=Choose an option [1-8]: 

if "%choice%"=="1" goto debug
if "%choice%"=="2" goto release
if "%choice%"=="3" goto aab
if "%choice%"=="4" goto emulator
if "%choice%"=="5" goto logs
if "%choice%"=="6" goto folder
if "%choice%"=="7" goto reset
if "%choice%"=="8" goto end

echo.
echo Invalid option.
pause
goto menu

:debug
call "%~dp0CLEAN_DEBUG_RUN_V2.bat"
goto menu

:release
call "%~dp0BUILD_RELEASE_V2.bat"
goto menu

:aab
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0BUILD_RELEASE_V2.ps1" -BuildAppBundle
pause
goto menu

:emulator
if exist "%~dp0RUN_ON_EMULATOR_V2.bat" (
    call "%~dp0RUN_ON_EMULATOR_V2.bat"
) else (
    echo RUN_ON_EMULATOR_V2.bat was not found.
    pause
)
goto menu

:logs
if exist "%~dp0COLLECT_ANDROID_LOG.ps1" (
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0COLLECT_ANDROID_LOG.ps1" -Seconds 60
) else (
    echo COLLECT_ANDROID_LOG.ps1 was not found.
)
pause
goto menu

:folder
set "APK=%~dp0build\app\outputs\flutter-apk\app-release.apk"
if exist "%APK%" (
    explorer.exe /select,"%APK%"
) else (
    echo Release APK was not found:
    echo %APK%
    pause
)
goto menu

:reset
echo.
echo WARNING: This will delete all uncommitted local changes and generated files.
set /p confirm=Type RESET to continue: 
if /I not "%confirm%"=="RESET" goto menu
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Continue'; git config core.longpaths true; git fetch origin; git reset --hard origin/main; if (Test-Path '.\build') { cmd /d /c ('rd /s /q \\?\' + (Resolve-Path '.\build').Path) }; git clean -xfd -e .gradle-user-home-clean -e .gradle-user-home-release"
pause
goto menu

:end
endlocal
exit /b 0
