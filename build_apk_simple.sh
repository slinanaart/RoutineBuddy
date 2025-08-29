#!/bin/bash

# Simple APK Build Script - Direct to Source Folder
# This is a simplified alternative that builds directly in the main project

echo "🚀 Simple APK Build - Direct to Source"
echo "======================================"

# Get current date and time for filename
BUILD_DATE=$(date +%y%m%d)
BUILD_TIME=$(date +%H%M)
VERSION="0.0.0.6"
BUILD_NUMBER="6"
APK_NAME="${BUILD_DATE}-${BUILD_TIME}-rb-apk-ver${VERSION}.apk"

echo "📅 Build Date: $BUILD_DATE-$BUILD_TIME"
echo "🔢 Version: $VERSION"
echo "📱 Output: $APK_NAME"

# Ensure we're using the latest checkpoint
echo "🔄 Ensuring latest checkpoint8 code is active..."
if [ -f "lib/main_checkpoint8.dart" ]; then
    cp lib/main_checkpoint8.dart lib/main.dart
    echo "✅ Using checkpoint8 code"
else
    echo "⚠️  Using existing main.dart"
fi

# Clean and get dependencies
echo "🧹 Cleaning previous builds..."
flutter clean

echo "📦 Getting dependencies..."
flutter pub get

# Build the APK
echo "🔨 Building release APK..."
flutter build apk --release --build-name=$VERSION --build-number=$BUILD_NUMBER

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    # Copy APK to source folder
    echo "📱 Copying APK to source folder..."
    cp build/app/outputs/flutter-apk/app-release.apk "./$APK_NAME"
    
    if [ -f "./$APK_NAME" ]; then
        # Get APK size
        APK_SIZE=$(ls -lh "$APK_NAME" | awk '{print $5}')
        
        echo ""
        echo "🎉 SUCCESS! APK built and ready!"
        echo "================================"
        echo "📱 File: $APK_NAME"
        echo "📍 Location: $(pwd)/$APK_NAME"
        echo "📏 Size: $APK_SIZE"
        echo "🔢 Version: $VERSION (Build $BUILD_NUMBER)"
        echo "📅 Built: $(date)"
        echo ""
        echo "✅ Ready for installation on Android devices!"
        
        # List all APKs in source folder
        echo ""
        echo "📱 All APKs in source folder:"
        ls -lh *.apk 2>/dev/null || echo "   (This is the first APK)"
        
    else
        echo "❌ Failed to copy APK to source folder"
        exit 1
    fi
else
    echo "❌ Build failed!"
    echo "💡 Try running: flutter doctor"
    exit 1
fi
