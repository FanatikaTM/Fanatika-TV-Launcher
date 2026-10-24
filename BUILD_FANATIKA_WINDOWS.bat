@echo off
setlocal EnableExtensions
cd /d "%~dp0"
set "FLUTTER_CMD="
where flutter.bat >nul 2>nul
if not errorlevel 1 set "FLUTTER_CMD=flutter.bat"
if not defined FLUTTER_CMD if exist "C:\src\flutter\bin\flutter.bat" set "FLUTTER_CMD=C:\src\flutter\bin\flutter.bat"
if not defined FLUTTER_CMD if exist "C:\flutter\bin\flutter.bat" set "FLUTTER_CMD=C:\flutter\bin\flutter.bat"
if not defined FLUTTER_CMD if exist "%USERPROFILE%\development\flutter\bin\flutter.bat" set "FLUTTER_CMD=%USERPROFILE%\development\flutter\bin\flutter.bat"
if not defined FLUTTER_CMD if exist "%USERPROFILE%\flutter\bin\flutter.bat" set "FLUTTER_CMD=%USERPROFILE%\flutter\bin\flutter.bat"
if not defined FLUTTER_CMD (
 echo Flutter was not found automatically.
 echo Get Flutter from https://docs.flutter.dev/get-started/install/windows/mobile
 set /p "FLUTTER_PATH=Enter the path to flutter.bat, or press Enter to cancel: "
 if not defined FLUTTER_PATH exit /b 1
 if not exist "%FLUTTER_PATH%" (
   echo The file was not found: %FLUTTER_PATH%
   pause
   exit /b 1
 )
 set "FLUTTER_CMD=%FLUTTER_PATH%"
)
echo Building Fanatika Launcher using %FLUTTER_CMD%
call "%FLUTTER_CMD%" --version
if errorlevel 1 goto :failed
call "%FLUTTER_CMD%" doctor -v
echo.
echo If Android SDK or licenses are missing, fix those before continuing.
call "%FLUTTER_CMD%" pub get
if errorlevel 1 goto :failed
call "%FLUTTER_CMD%" build apk --debug --flavor github --target-platform android-arm
if errorlevel 1 goto :failed
echo.
echo APKs in: %CD%\build\app\outputs\flutter-apk
explorer "%CD%\build\app\outputs\flutter-apk"
pause
exit /b 0
:failed
echo Build failed. Review the first Flutter or Gradle error above.
pause
exit /b 1
