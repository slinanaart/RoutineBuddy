#!/bin/bash

# Robust APK Build Script for RoutineBuddy
# This script uses the existing project structure and handles errors gracefully

set -e  # Exit on any error

echo "🚀 RoutineBuddy APK Builder (Robust)"
echo "==================================="

# Configuration
BUILD_DATE=$(date +%y%m%d)
BUILD_TIME=$(date +%H%M)
VERSION="0.0.0.6"
BUILD_NUMBER="6"
APK_NAME="${BUILD_DATE}-${BUILD_TIME}-rb-apk-ver${VERSION}.apk"

echo "📅 Build: $BUILD_DATE-$BUILD_TIME"
echo "🔢 Version: $VERSION"
echo "📱 Output: $APK_NAME"

# Step 1: Ensure we're using the latest checkpoint
echo ""
echo "🔄 Step 1: Activating checkpoint8 code..."
if [ -f "lib/main_checkpoint8.dart" ]; then
    cp lib/main_checkpoint8.dart lib/main.dart
    echo "✅ Using checkpoint8 code"
else
    echo "⚠️  Using existing main.dart"
fi

# Step 2: Fix common Android build issues
echo ""
echo "🔧 Step 2: Fixing Android configuration..."

# Fix gradle wrapper permissions
chmod +x android/gradlew 2>/dev/null || true

# Update gradle wrapper if needed
echo "🔄 Updating Gradle wrapper..."
cd android && ./gradlew wrapper --gradle-version=7.6.4 && cd ..

# Step 3: Clean and prepare
echo ""
echo "🧹 Step 3: Cleaning project..."
flutter clean

echo "📦 Step 4: Getting dependencies..."
flutter pub get

# Step 5: Try to build APK
echo ""
echo "🔨 Step 5: Building APK..."
echo "This may take 5-10 minutes..."

if flutter build apk --release --build-name=$VERSION --build-number=$BUILD_NUMBER --verbose; then
    echo "✅ Build completed successfully!"
    
    # Check if APK exists
    if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
        echo "📱 APK found, copying to source folder..."
        cp build/app/outputs/flutter-apk/app-release.apk "./$APK_NAME"
        
        # Get size
        APK_SIZE=$(ls -lh "$APK_NAME" | awk '{print $5}')
        
        echo ""
        echo "🎉 SUCCESS! APK is ready!"
        echo "=========================="
        echo "📱 File: $APK_NAME"
        echo "📍 Location: $(pwd)/$APK_NAME"
        echo "📏 Size: $APK_SIZE"
        echo "🔢 Version: $VERSION (Build $BUILD_NUMBER)"
        echo "📅 Built: $(date)"
        echo ""
        echo "✅ Ready for Android installation!"
        
        # Show all APKs
        echo ""
        echo "📱 All APKs in source folder:"
        ls -lh *.apk 2>/dev/null | tail -5
        
    else
        echo "❌ APK file not found after build"
        echo "🔍 Checking build outputs..."
        find build -name "*.apk" 2>/dev/null || echo "No APK files found in build directory"
        exit 1
    fi
    
else
    echo "❌ Build failed!"
    echo ""
    echo "🔍 Troubleshooting steps:"
    echo "1. Run: flutter doctor"
    echo "2. Check Android SDK installation"
    echo "3. Try: flutter clean && flutter pub get"
    echo "4. Check Gradle version compatibility"
    exit 1
fi
