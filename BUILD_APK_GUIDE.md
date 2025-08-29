# RoutineBuddy APK Build Guide

## 🚀 Build Scripts Available

### 1. **build_apk.sh** (Recommended)
- **Purpose**: Creates a fresh Flutter project and builds APK to avoid Gradle conflicts
- **Output**: Places APK in both `build/outputs/release/` and source folder
- **Usage**: `./build_apk.sh [version_number]`
- **Features**:
  - Auto-detects next version number
  - Creates clean build environment
  - Copies custom icons and configurations
  - Places APK in source folder for easy access

### 2. **build_apk_simple.sh** (Alternative)
- **Purpose**: Builds directly in main project (faster but may have Gradle issues)
- **Output**: Places APK directly in source folder
- **Usage**: `./build_apk_simple.sh`
- **Features**:
  - Quick build process
  - Direct output to source folder
  - Timestamped filenames

## 📱 APK Output

Both scripts will create APK files with names like:
- `YYMMDD-rb-apk-ver0.0.0.X.apk` (build_apk.sh)
- `YYMMDD-HHMM-rb-apk-ver0.0.0.6.apk` (build_apk_simple.sh)

## 🔧 Setup

1. Make scripts executable:
   ```bash
   chmod +x build_apk.sh build_apk_simple.sh
   ```

2. Run preferred build script:
   ```bash
   ./build_apk.sh        # Recommended for stable builds
   ./build_apk_simple.sh # For quick testing
   ```

## 📋 Build Process

The scripts will:
1. ✅ Use latest checkpoint8 code
2. ✅ Clean previous builds
3. ✅ Get dependencies
4. ✅ Build release APK
5. ✅ Copy APK to source folder
6. ✅ Show build summary

## 🎯 APK Location

After successful build:
- **Source Folder**: `./YYMMDD-*-rb-apk-ver*.apk`
- **Build Folder**: `build/outputs/release/` (build_apk.sh only)
- **Ready for**: Android device installation

## 🌐 Online Build Alternatives

If local build fails, use:
1. **GitHub Actions**: Automatic builds on push to main
2. **Codemagic**: Manual builds using codemagic.yaml
3. **AppCenter**: Using appcenter-post-build.sh

## 📱 Installation

Transfer the APK to your Android device and install:
1. Enable "Install from unknown sources" in Android settings
2. Transfer APK file to device
3. Tap APK file to install
4. Launch RoutineBuddy app

## 🔍 Troubleshooting

- **Gradle issues**: Use `build_apk.sh` (creates fresh project)
- **Build fails**: Run `flutter doctor` to check setup
- **APK not found**: Check script output for error messages
- **Large APK size**: Normal for Flutter apps (~50-100MB)

## 📝 Notes

- APK files are automatically ignored by git (.gitignore)
- Version numbers auto-increment in build_apk.sh
- Both scripts ensure checkpoint8 code is active
- Fresh project approach avoids most build issues
