@echo off
setlocal
where flutter >nul 2>nul
if errorlevel 1 (
 echo Flutter NOT found on PATH.
 echo Get Flutter: https://docs.flutter.dev/get-started/install/windows/mobile
 echo Extract Flutter to C:\src\flutter and add C:\src\flutter\bin to PATH.
) else (
 echo Flutter found:
 where flutter
 flutter --version
)
echo.
where java >nul 2>nul
if errorlevel 1 (echo Java not found. Install JDK 17.) else (java -version)
echo.
where adb >nul 2>nul
if errorlevel 1 (echo ADB not found on PATH. Use Android SDK platform-tools.) else (adb version)
echo.
echo Check Flutter dependencies by running: flutter doctor -v
pause
