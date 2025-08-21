# RoutineBuddy Build Convention

## APK Naming Format:
**Format:** `[yymmdd]-rb-apk-ver0.0.0.[x].apk`

Where:
- `[yymmdd]`: Build date (e.g., 250817 for August 17, 2025)
- `rb`: RoutineBuddy identifier
- `apk`: File type identifier
- `ver0.0.0.[x]`: Version number where x increments with each build
- `.apk`: File extension

## Examples:
- `250817-rb-apk-ver0.0.0.4.apk` (Current build - August 17, 2025, version 4)
- `250818-rb-apk-ver0.0.0.5.apk` (Next build)
- `250820-rb-apk-ver0.0.0.6.apk` (Future build)

## Version History:
- **v0.0.0.1**: Original build (August 14, 2025)
- **v0.0.0.2**: Feature updates (August 15, 2025) 
- **v0.0.0.3**: Bug fixes (August 16, 2025)
- **v0.0.0.4**: Checkpoint3 with 6 major fixes (August 17, 2025)
  - Edit dialog consistency
  - Schedule item preservation
  - Settings synchronization 
  - 1-based anchor indexing
  - Done button filtering
  - Sleep time next-day logic

## Build Instructions:
1. Update version in `android/app/build.gradle` (versionCode and versionName)
2. Ensure latest code: `cp lib/main_checkpoint3.dart lib/main.dart`
3. Use fresh project approach if main project has Gradle issues
4. Copy Android configuration (app name "RoutineBuddy" and launcher icons)
5. Build: `flutter build apk --release`
6. Rename to convention: `[yymmdd]-rb-apk-ver0.0.0.[x].apk`
7. Place in: `build/outputs/release/`

## Android Configuration:
- **App Name:** "RoutineBuddy" (set in AndroidManifest.xml)
- **Package:** com.example.routine_buddy
- **Launcher Icons:** Custom icons in mipmap folders
- **Target SDK:** 33

## Next Build:
- **Version:** 0.0.0.5
- **Expected features:** Action filter, Day-off routine, Timeline string improvements
