#!/bin/bash

echo "🔍 Debugging APK build..."
echo "📅 Date: $(date +%y%m%d)"
echo ""

# Check if we can build a simple APK directly
echo "🧪 Testing direct flutter build apk..."
flutter build apk --release 2>&1 | head -20

echo ""
echo "🔍 Searching for any existing APK files..."
find . -name "*.apk" -type f 2>/dev/null | head -10

echo ""
echo "📁 Checking build directories..."
ls -la build/ 2>/dev/null || echo "No build directory found"
ls -la android/app/build/outputs/ 2>/dev/null || echo "No android build outputs found"

echo ""
echo "🔧 Flutter doctor check..."
flutter doctor --android-licenses 2>&1 | head -5
