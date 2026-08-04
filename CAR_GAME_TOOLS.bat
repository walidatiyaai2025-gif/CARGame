@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
cd /d "%~dp0"
title CAR GAME TOOLS

set "PROJECT=%~dp0"
set "APK=%PROJECT%build\app\outputs\flutter-apk\app-release.apk"
set "AAB=%PROJECT%build\app\outputs\bundle\release\app-release.aab"
set "PACKAGE=com.walka.cargosort"
set "PS=powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass"

:menu
cls
echo ======================================================
echo                 CAR GAME TOOLS
echo ======================================================
echo.
echo  1  - Sync exact copy from GitHub and delete local changes
echo  2  - Fresh rebuild Android and build APK
echo  3  - Sync and build APK
echo  4  - Build Release APK only
echo  5  - Build Google Play AAB
echo  6  - Install APK on connected device
echo  7  - Uninstall application from device
echo  8  - Run application on connected device
echo  9  - Collect Android crash logs
echo  10 - Flutter clean + pub get + analyze
echo  11 - Flutter doctor
echo  12 - Open APK folder
echo  13 - Open project folder
echo  14 - Open GitHub repository
echo  15 - Show Git status
echo  16 - Restart ADB
echo  0  - Exit
echo.
set /p "choice=Choose an option: "

if "%choice%"=="1" goto sync
if "%choice%"=="2" goto fresh
if "%choice%"=="3" goto syncbuild
if "%choice%"=="4" goto buildapk
if "%choice%"=="5" goto buildaab
if "%choice%"=="6" goto install
if "%choice%"=="7" goto uninstall
if "%choice%"=="8" goto runapp
if "%choice%"=="9" goto logs
if "%choice%"=="10" goto prepare
if "%choice%"=="11" goto doctor
if "%choice%"=="12" goto openapk
if "%choice%"=="13" goto openproject
if "%choice%"=="14" goto github
if "%choice%"=="15" goto gitstatus
if "%choice%"=="16" goto restartadb
if "%choice%"=="0" exit /b 0

echo Invalid choice.
pause
goto menu

:sync
call :header "SYNC EXACT COPY FROM GITHUB"
echo WARNING: This deletes ALL local changes and untracked files.
choice /C YN /M "Continue"
if errorlevel 2 goto menu
%PS% -Command "$ErrorActionPreference='Stop'; $PSNativeCommandUseErrorActionPreference=$false; git fetch --all --prune; if($LASTEXITCODE -ne 0){exit $LASTEXITCODE}; git switch main; if($LASTEXITCODE -ne 0){exit $LASTEXITCODE}; git reset --hard origin/main; if($LASTEXITCODE -ne 0){exit $LASTEXITCODE}; git clean -xfd; exit $LASTEXITCODE"
call :result
goto menu

:fresh
call :header "FRESH ANDROID REBUILD"
if not exist "%PROJECT%REBUILD_FRESH_ANDROID.ps1" (
  echo Missing REBUILD_FRESH_ANDROID.ps1
  pause
  goto menu
)
%PS% -File "%PROJECT%REBUILD_FRESH_ANDROID.ps1"
call :result
goto menu

:syncbuild
call :header "SYNC AND BUILD"
if not exist "%PROJECT%SYNC_AND_BUILD.ps1" (
  echo Missing SYNC_AND_BUILD.ps1
  pause
  goto menu
)
%PS% -File "%PROJECT%SYNC_AND_BUILD.ps1"
call :result
goto menu

:buildapk
call :header "BUILD RELEASE APK"
%PS% -Command "$PSNativeCommandUseErrorActionPreference=$false; flutter clean; if($LASTEXITCODE -ne 0){exit $LASTEXITCODE}; flutter pub get; if($LASTEXITCODE -ne 0){exit $LASTEXITCODE}; flutter gen-l10n; if($LASTEXITCODE -ne 0){exit $LASTEXITCODE}; flutter build apk --release --target-platform android-arm64; exit $LASTEXITCODE"
call :result
if exist "%APK%" echo APK: %APK%
goto menu

:buildaab
call :header "BUILD GOOGLE PLAY AAB"
%PS% -Command "$PSNativeCommandUseErrorActionPreference=$false; flutter clean; if($LASTEXITCODE -ne 0){exit $LASTEXITCODE}; flutter pub get; if($LASTEXITCODE -ne 0){exit $LASTEXITCODE}; flutter gen-l10n; if($LASTEXITCODE -ne 0){exit $LASTEXITCODE}; flutter build appbundle --release; exit $LASTEXITCODE"
call :result
if exist "%AAB%" echo AAB: %AAB%
goto menu

:install
call :header "INSTALL APK"
call :findadb
if errorlevel 1 goto menu
if not exist "%APK%" (
  echo APK not found:
  echo %APK%
  pause
  goto menu
)
"%ADB%" devices
"%ADB%" install -r "%APK%"
call :result
goto menu

:uninstall
call :header "UNINSTALL APPLICATION"
call :findadb
if errorlevel 1 goto menu
"%ADB%" uninstall %PACKAGE%
call :result
goto menu

:runapp
call :header "RUN APPLICATION"
call :findadb
if errorlevel 1 goto menu
"%ADB%" shell monkey -p %PACKAGE% -c android.intent.category.LAUNCHER 1
call :result
goto menu

:logs
call :header "COLLECT ANDROID LOGS"
if not exist "%PROJECT%COLLECT_ANDROID_LOG.ps1" (
  echo Missing COLLECT_ANDROID_LOG.ps1
  pause
  goto menu
)
%PS% -File "%PROJECT%COLLECT_ANDROID_LOG.ps1"
call :result
goto menu

:prepare
call :header "CLEAN, GET PACKAGES, ANALYZE"
%PS% -Command "$PSNativeCommandUseErrorActionPreference=$false; flutter clean; if($LASTEXITCODE -ne 0){exit $LASTEXITCODE}; flutter pub get; if($LASTEXITCODE -ne 0){exit $LASTEXITCODE}; flutter gen-l10n; if($LASTEXITCODE -ne 0){exit $LASTEXITCODE}; flutter analyze --no-fatal-infos; exit $LASTEXITCODE"
call :result
goto menu

:doctor
call :header "FLUTTER DOCTOR"
%PS% -Command "$PSNativeCommandUseErrorActionPreference=$false; flutter doctor -v; exit $LASTEXITCODE"
call :result
goto menu

:openapk
if exist "%PROJECT%build\app\outputs\flutter-apk" (
  start "" "%PROJECT%build\app\outputs\flutter-apk"
) else (
  echo APK folder does not exist yet.
  pause
)
goto menu

:openproject
start "" "%PROJECT%"
goto menu

:github
start "" "https://github.com/walidatiyaai2025-gif/CARGame"
goto menu

:gitstatus
call :header "GIT STATUS"
%PS% -Command "$PSNativeCommandUseErrorActionPreference=$false; git status; git log -1 --oneline"
pause
goto menu

:restartadb
call :header "RESTART ADB"
call :findadb
if errorlevel 1 goto menu
"%ADB%" kill-server
"%ADB%" start-server
"%ADB%" devices
call :result
goto menu

:findadb
set "ADB="
for /f "delims=" %%A in ('where adb 2^>nul') do if not defined ADB set "ADB=%%A"
if not defined ADB if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" set "ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
if not defined ADB if exist "%ANDROID_HOME%\platform-tools\adb.exe" set "ADB=%ANDROID_HOME%\platform-tools\adb.exe"
if not defined ADB (
  echo adb.exe was not found.
  echo Install Android SDK Platform-Tools.
  pause
  exit /b 1
)
echo ADB: %ADB%
exit /b 0

:header
cls
echo ======================================================
echo %~1
echo ======================================================
echo.
exit /b 0

:result
set "RC=%ERRORLEVEL%"
echo.
if "%RC%"=="0" (
  echo ======================================================
  echo SUCCESS
  echo ======================================================
) else (
  echo ======================================================
  echo FAILED - Exit code: %RC%
  echo ======================================================
)
echo.
pause
exit /b %RC%
