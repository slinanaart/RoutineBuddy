#!/bin/bash

# RoutineBuddy APK Build Script
# Usage: ./build_apk.sh [version_number]

# Get current date in yymmdd format
DATE=$(date +%y%m%d)

# Get version number from argument or auto-increment
if [ -z "$1" ]; then
    # Auto-detect next version by checking existing APKs
    LAST_VERSION=$(ls build/outputs/release/*-rb-apk-ver0.0.0.*.apk 2>/dev/null | grep -o 'ver0\.0\.0\.[0-9]*' | grep -o '[0-9]*$' | sort -n | tail -1)
    if [ -z "$LAST_VERSION" ]; then
        VERSION=1
    else
        VERSION=$((LAST_VERSION + 1))
    fi
else
    VERSION=$1
fi

APK_NAME="${DATE}-rb-apk-ver0.0.0.${VERSION}.apk"

echo "🚀 Building RoutineBuddy APK..."
echo "📅 Date: $DATE"
echo "🔢 Version: 0.0.0.$VERSION"
echo "📱 Output: $APK_NAME"

# Ensure checkpoint3 code is active
echo "🔄 Activating checkpoint3 code..."
cp lib/main_checkpoint3.dart lib/main.dart

# Create fresh project if main project has Gradle issues
echo "🆕 Creating fresh build environment..."
rm -rf temp_build_project
flutter create --platforms android temp_build_project
cp lib/main.dart temp_build_project/lib/
cp -r assets temp_build_project/ 2>/dev/null || true
cp pubspec.yaml temp_build_project/

# Copy Android configuration for proper app name and custom launcher icon
echo "📱 Configuring app name and custom launcher icon..."
# Copy manifest (sets app label)
cp android/app/src/main/AndroidManifest.xml temp_build_project/android/app/src/main/
# Copy launch background (optional)
mkdir -p temp_build_project/android/app/src/main/res/drawable
cp android/app/src/main/res/drawable/launch_background.xml temp_build_project/android/app/src/main/res/drawable/ 2>/dev/null || true
# Copy custom adaptive launcher icon resources
mkdir -p temp_build_project/android/app/src/main/res/mipmap-anydpi-v26
cp android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml temp_build_project/android/app/src/main/res/mipmap-anydpi-v26/ 2>/dev/null || true
cp android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml temp_build_project/android/app/src/main/res/mipmap-anydpi-v26/ 2>/dev/null || true
mkdir -p temp_build_project/android/app/src/main/res/values
cp android/app/src/main/res/values/ic_launcher_colors.xml temp_build_project/android/app/src/main/res/values/ 2>/dev/null || true
cp android/app/src/main/res/drawable/rb_icon_foreground.xml temp_build_project/android/app/src/main/res/drawable/ 2>/dev/null || true

# Build APK
echo "🔨 Building APK..."
cd temp_build_project
flutter build apk --release

# Copy and rename APK
echo "📦 Packaging APK..."
cd ..
mkdir -p build/outputs/release
cp temp_build_project/build/app/outputs/flutter-apk/app-release.apk "build/outputs/release/$APK_NAME"

# Cleanup
rm -rf temp_build_project

echo "✅ Build complete!"
echo "📱 APK: build/outputs/release/$APK_NAME"
echo "💾 Size: $(du -h "build/outputs/release/$APK_NAME" | cut -f1)"

# Open outputs folder
open build/outputs/release/
