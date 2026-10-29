@echo off
setlocal
REM Read-only HOME check. Does not change default or disable the OEM launcher.
where adb >nul 2>&1
if errorlevel 1 (
  echo ADB not found. Install Android platform-tools and ensure adb is in PATH.
  pause
  exit /b 1
)
echo === Connected TVs ===
adb devices
set /p DEVICE=TV serial or IP:port (leave blank for a single connected TV): 
set "TARGET="
if not "%DEVICE%"=="" set "TARGET=-s %DEVICE%"
echo === Installed Fanatika package ===
adb %TARGET% shell pm path com.fanatika.tvlauncher
echo === Android HOME candidates ===
adb %TARGET% shell cmd package query-activities --brief -a android.intent.action.MAIN -c android.intent.category.HOME
echo === Android HOME resolution ===
adb %TARGET% shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME
echo === Android HOME role holders (if supported) ===
adb %TARGET% shell cmd role get-role-holders --user 0 android.app.role.HOME
echo.
echo If Fanatika is not the resolved HOME app, use Android Settings - Apps - Default apps - Home app.
echo If it is selected but the TV still opens Xiaomi Home, the firmware may override the HOME key.
echo Do not disable Xiaomi/Google system launcher until a recovery path is confirmed.
pause
