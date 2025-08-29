#!/usr/bin/env bash

# AppCenter Post Build Script
# This script runs after the build completes

if [ "$APPCENTER_BRANCH" == "main" ]; then
    echo "Building APK for main branch"
    
    # Build APK
    BUILD_DATE=$(date +%y%m%d)
    flutter build apk --release --build-name=0.0.0.6 --build-number=6
    
    # Rename APK
    cd build/app/outputs/flutter-apk
    mv app-release.apk ${BUILD_DATE}-rb-apk-ver0.0.0.6.apk
    
    echo "APK built successfully: ${BUILD_DATE}-rb-apk-ver0.0.0.6.apk"
fi
