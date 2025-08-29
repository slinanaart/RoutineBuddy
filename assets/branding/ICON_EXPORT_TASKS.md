# Icon Export & Integration Tasks (v2)

Export Targets (source: routine_buddy_icon_v2.svg):
- Android mipmap: 48,72,96,144,192,512 (play store), adaptive foreground/background from maskable variant
- iOS AppIcon.appiconset: 20,29,40,60,76,83.5 @1x/@2x/@3x as required plus 1024 marketing
- Web PWA: 192, 256, 384, 512 (maskable + regular), 1024 marketing
- Favicon: 16, 32 (monochrome simplification optional)

Foreground / Background (Adaptive Android):
- Foreground: simplified maskable (trim outer most ring bleed)
- Background: flat #064F50

Action Steps:
1. Generate PNGs (e.g. flutter_launcher_icons or native tooling)
2. Update pubspec.yaml for flutter_launcher_icons config (if using plugin)
3. Replace android/app/src/main/res/mipmap-* assets
4. Create ios Runner Assets.xcassets/AppIcon.appiconset Contents.json (auto if using plugin)
5. Update web/icons + manifest.json with maskable + any "purpose": "any maskable" entries
6. Test on device & Chrome Lighthouse for PWA maskable compliance

Suggested Tooling Option A (Automated):
- Add dev dependency: flutter_launcher_icons
- Configure adaptive icons + web

Option B (Manual Export):
- Use Inkscape or Sketch to export exact sizes
- Verify no anti-alias fringe on transparent edges

Quality Checklist:
- Small size legibility (32px) – anchors recognizable, smile not mandatory
- Contrast ratio against common backgrounds (light/dark) OK
- No stray semi-transparent pixels in edge alpha

Notes:
- Keep master SVG pristine; do not rasterize text (none used)
- Maintain consistent stroke scaling; avoid fractional pixel blur
