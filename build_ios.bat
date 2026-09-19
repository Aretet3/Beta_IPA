@echo off
echo ==========================================
echo   Beta iOS Builder
echo ==========================================
echo.

cd /d "%~dp0"

echo [1/6] Checking Flutter...
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Flutter not found. Install from https://flutter.dev
    pause
    exit /b 1
)

echo [2/6] Getting dependencies...
flutter pub get
if errorlevel 1 (
    echo ERROR: Failed to get dependencies
    pause
    exit /b 1
)

echo [3/6] Installing CocoaPods...
cd ios
pod repo update
pod install
cd ..

echo [4/6] Building iOS (release, no codesign)...
flutter build ios --release --no-codesign
if errorlevel 1 (
    echo ERROR: Build failed
    pause
    exit /b 1
)

echo [5/6] Creating IPA...
cd build\ios\iphoneos
if exist Payload rmdir /s /q Payload
mkdir Payload
move Runner.app Payload\
del /f /q Beta.ipa 2>nul
powershell -Command "Compress-Archive -Path Payload -DestinationPath Beta.ipa -Force"
cd ..\..\..

echo [6/6] Done!
echo.
echo IPA location: build\ios\iphoneos\Beta.ipa
echo.
echo To install on iPhone:
echo   1. Connect iPhone via USB
echo   2. Open Xcode - Window - Devices and Simulators
echo   3. Drag Beta.ipa onto your device
echo.
echo Or use AltStore/SideStore for wireless install.
echo.
pause
