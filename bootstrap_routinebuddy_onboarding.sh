#!/usr/bin/env bash
set -euo pipefail

APPDIR="250814_routinebuddy_0.0.0"
echo "Rebuilding ${APPDIR} ..."
rm -rf "$APPDIR"
mkdir -p "$APPDIR"
cd "$APPDIR"

########################################
# pubspec.yaml
########################################
cat > pubspec.yaml <<'YAML'
name: routine_buddy
description: RoutineBuddy — working base + first-run onboarding
publish_to: "none"
version: 0.0.0+1

environment:
  sdk: ">=3.1.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter

flutter:
  uses-material-design: true
  assets:
    - assets/data/templates.json
    - assets/data/free_routine_actions.json
YAML

########################################
# Assets (placeholder; we’ll swap to 120 items in next build)
########################################
mkdir -p assets/data
cat > assets/data/templates.json <<'JSON'
{
  "free_templates":[
    {
      "id":"casual",
      "name":"The Casual",
      "description":"Balanced default routine for the whole week.",
      "actions":[
        {"id":"wake-water","title":"Drink water","category":"Health","recommended_time":"07:15"},
        {"id":"plan-top3","title":"Plan Top 3","category":"Planning","recommended_time":"09:00"},
        {"id":"pm-stretch","title":"Neck & shoulder stretch","category":"Health","recommended_time":"16:00"}
      ]
    }
  ],
  "locked_templates":[
    {"id":"t1","name":"Deep Work"}
  ]
}
JSON

cat > assets/data/free_routine_actions.json <<'JSON'
[
  {"id":"walk10","title":"10-minute walk","category":"Energy","recommended_time":"Afternoon"},
  {"id":"read10","title":"Read 10 minutes","category":"Learning","recommended_time":"Night"},
  {"id":"gratitude","title":"Gratitude note","category":"Mindfulness","recommended_time":"Night"}
]
JSON

########################################
# Android (matches your known-good combo)
########################################
mkdir -p android/app/src/main/kotlin/com/example/routine_buddy
mkdir -p android/app/src/main/res/values
mkdir -p android/app/src/main/res/drawable
mkdir -p android/app/src/main/res/mipmap-anydpi-v26
mkdir -p android/gradle/wrapper

cat > android/settings.gradle <<'GRADLE'
include ':app'

def localPropertiesFile = new File(rootProject.projectDir, "local.properties")
def properties = new Properties()
assert localPropertiesFile.exists() : "Missing local.properties. Run `flutter pub get` once to generate it."
localPropertiesFile.withReader("UTF-8") { reader -> properties.load(reader) }

def flutterSdkPath = properties.getProperty("flutter.sdk")
assert flutterSdkPath != null : "flutter.sdk not set in local.properties"

apply from: "$flutterSdkPath/packages/flutter_tools/gradle/app_plugin_loader.gradle"
GRADLE

cat > android/build.gradle <<'GRADLE'
buildscript {
    ext.kotlin_version = '1.8.22'
    repositories { google(); mavenCentral() }
    dependencies {
        classpath 'com.android.tools.build:gradle:7.4.2'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}
allprojects { repositories { google(); mavenCentral() } }
tasks.register("clean", Delete) { delete(rootProject.buildDir) }
GRADLE

cat > android/gradle/wrapper/gradle-wrapper.properties <<'PROPS'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-7.6.3-bin.zip
PROPS

cat > android/gradle.properties <<'PROPS'
org.gradle.jvmargs=-Xmx4096m -Dfile.encoding=UTF-8
android.useAndroidX=true
android.enableJetifier=true
kotlin.code.style=official
android.enableR8=true
# If needed, point Gradle to your JDK 21:
# org.gradle.java.home=/Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home
PROPS

cat > android/app/build.gradle <<'GRADLE'
def localProperties = new Properties()
def localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader("UTF-8") { reader -> localProperties.load(reader) }
}
def flutterRoot = localProperties.getProperty("flutter.sdk")
if (flutterRoot == null) {
    throw new GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")
}

apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'
apply from: "$flutterRoot/packages/flutter_tools/gradle/flutter.gradle"

android {
    namespace "com.example.routine_buddy"
    compileSdkVersion 33

    defaultConfig {
        applicationId "com.example.routine_buddy"
        minSdkVersion 23
        targetSdkVersion 33
        versionCode 1
        versionName "0.0.0"
        multiDexEnabled true
    }

    signingConfigs { debug { } }

    buildTypes {
        release {
            signingConfig signingConfigs.debug
            minifyEnabled false
            shrinkResources false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
        debug {
            applicationIdSuffix ".debug"
            signingConfig signingConfigs.debug
        }
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
}

flutter { source '../..' }
dependencies { implementation "org.jetbrains.kotlin:kotlin-stdlib:1.8.22" }
GRADLE

cat > android/app/proguard-rules.pro <<'TXT'
-keep class io.flutter.** { *; }
-dontwarn javax.annotation.**
TXT

cat > android/app/src/main/AndroidManifest.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.example.routine_buddy">
  <application android:label="RoutineBuddy" android:name="${applicationName}" android:icon="@mipmap/ic_launcher">
    <activity android:name=".MainActivity" android:exported="true" android:launchMode="singleTop" android:theme="@style/LaunchTheme"
      android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
      android:hardwareAccelerated="true" android:windowSoftInputMode="adjustResize">
      <meta-data android:name="io.flutter.embedding.android.SplashScreenDrawable" android:resource="@drawable/launch_background" />
      <intent-filter><action android:name="android.intent.action.MAIN"/><category android:name="android.intent.category.LAUNCHER"/></intent-filter>
    </activity>
    <meta-data android:name="flutterEmbedding" android:value="2" />
  </application>
</manifest>
XML

cat > android/app/src/main/res/values/styles.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<resources>
  <style name="LaunchTheme" parent="@android:style/Theme.Black.NoTitleBar">
    <item name="android:windowBackground">@drawable/launch_background</item>
  </style>
</resources>
XML

cat > android/app/src/main/res/drawable/launch_background.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
  <item android:drawable="@android:color/white"/>
</layer-list>
XML

cat > android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
  <background android:drawable="@android:color/white"/>
  <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
XML

cat > android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
  <background android:drawable="@android:color/white"/>
  <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
XML

cat > android/app/src/main/kotlin/com/example/routine_buddy/MainActivity.kt <<'KT'
package com.example.routine_buddy
import io.flutter.embedding.android.FlutterActivity
class MainActivity: FlutterActivity()
KT

########################################
# lib/ main.dart + onboarding.dart
########################################
mkdir -p lib

cat > lib/main.dart <<'DART'
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding.dart';

void main() => runApp(const RoutineBuddyApp());

class RoutineBuddyApp extends StatelessWidget {
  const RoutineBuddyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoutineBuddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF0FA3A5)),
      home: const LaunchDecider(),
    );
  }
}

/// ===== Models + Repo =====
enum ScheduleMode { weekly, daily }

class AppSettings {
  final TimeOfDay wake;
  final TimeOfDay bed;
  final ScheduleMode mode;
  const AppSettings({required this.wake, required this.bed, required this.mode});
  factory AppSettings.defaults() =>
      const AppSettings(wake: TimeOfDay(hour:7,minute:0), bed: TimeOfDay(hour:23,minute:30), mode: ScheduleMode.weekly);
  Map<String,dynamic> toJson()=> {'wakeH':wake.hour,'wakeM':wake.minute,'bedH':bed.hour,'bedM':bed.minute,'mode':mode.name};
  factory AppSettings.fromJson(Map<String,dynamic> j)=> AppSettings(
    wake: TimeOfDay(hour: j['wakeH']??7, minute: j['wakeM']??0),
    bed: TimeOfDay(hour: j['bedH']??23, minute: j['bedM']??30),
    mode: (j['mode']=='daily')? ScheduleMode.daily : ScheduleMode.weekly,
  );
  AppSettings copyWith({TimeOfDay? wake, TimeOfDay? bed, ScheduleMode? mode}) =>
      AppSettings(wake: wake??this.wake, bed: bed??this.bed, mode: mode??this.mode);
}

class RoutineAction {
  final String id, title, category;
  final TimeOfDay time;
  final bool enabled;
  const RoutineAction({required this.id, required this.title, required this.category, required this.time, this.enabled=true});
  Map<String,dynamic> toJson()=> {'id':id,'title':title,'category':category,'hour':time.hour,'minute':time.minute,'enabled':enabled};
  factory RoutineAction.fromJson(Map<String,dynamic> j)=> RoutineAction(
    id: j['id'], title: j['title'], category: j['category']??'General',
    time: TimeOfDay(hour: j['hour']??9, minute: j['minute']??0), enabled: j['enabled']??true,
  );
}

class Repo {
  static const _kSettings='rb_settings';
  static String _wk(DateTime m)=> 'rb_week:${m.year}-${m.month.toString().padLeft(2,'0')}-${m.day.toString().padLeft(2,'0')}';
  Future<AppSettings> loadSettings() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kSettings);
    if (raw==null) return AppSettings.defaults();
    try { return AppSettings.fromJson(jsonDecode(raw)); } catch(_){ return AppSettings.defaults(); }
  }
  Future<void> saveSettings(AppSettings s) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kSettings, jsonEncode(s.toJson()));
  }
  Future<Map<String,List<RoutineAction>>> loadWeek(DateTime monday) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_wk(monday));
    if (raw==null) return {};
    final Map<String,List<RoutineAction>> map = {};
    final dec = jsonDecode(raw) as Map<String,dynamic>;
    dec.forEach((k,v){ map[k] = (v as List).map((e)=>RoutineAction.fromJson(e)).toList(); });
    return map;
  }
  Future<void> saveWeek(DateTime monday, Map<String,List<RoutineAction>> plan) async {
    final enc = <String,dynamic>{};
    plan.forEach((k,v){ enc[k] = v.map((a)=>a.toJson()).toList(); });
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_wk(monday), jsonEncode(enc));
  }
}

/// ===== Minimal 3-tab home (we’ll expand later) =====
class HomeScaffold extends StatefulWidget {
  const HomeScaffold({super.key});
  @override State<HomeScaffold> createState()=> _HomeScaffoldState();
}
class _HomeScaffoldState extends State<HomeScaffold> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const Center(child: Text('Templates tab (coming next)')),
      const Center(child: Text('Routine tab (timeline goes here)')),
      const Center(child: Text('Settings tab')),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(['Templates','Routine','Settings'][_index])),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i)=> setState(()=>_index=i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_customize_outlined), label:'Templates'),
          NavigationDestination(icon: Icon(Icons.schedule_outlined), label:'Routine'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label:'Settings'),
        ],
      ),
    );
  }
}
DART

cat > lib/onboarding.dart <<'DART'
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart' as app;

/// Decides whether to show onboarding first-run, else go to HomeScaffold.
class LaunchDecider extends StatefulWidget {
  const LaunchDecider({super.key});
  @override State<LaunchDecider> createState()=> _LaunchDeciderState();
}
class _LaunchDeciderState extends State<LaunchDecider> {
  bool? _firstRun;
  @override void initState(){ super.initState(); _check(); }
  Future<void> _check() async {
    final sp = await SharedPreferences.getInstance();
    final seen = sp.getBool('rb_onboarded_v1') ?? false;
    setState(()=> _firstRun = !seen);
  }
  @override Widget build(BuildContext context) {
    if (_firstRun == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return _firstRun! ? const FillYourRoutineScreen() : const app.HomeScaffold();
  }
}

/// First-time screen: pick 'The Casual' or create manually.
class FillYourRoutineScreen extends StatelessWidget {
  const FillYourRoutineScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fill your routine')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _TemplateCard(
            title: 'Use “The Casual”',
            subtitle: 'Our balanced default for Mon–Sun. You can edit later.',
            variant: _CardVariant.casual,
          ),
          SizedBox(height: 16),
          _TemplateCard(
            title: 'Create it manually',
            subtitle: 'Set your anchors and build your own timeline.',
            variant: _CardVariant.manual,
          ),
        ],
      ),
    );
  }
}

enum _CardVariant { casual, manual }

class _TemplateCard extends StatelessWidget {
  final String title; final String subtitle; final _CardVariant variant;
  const _TemplateCard({required this.title, required this.subtitle, required this.variant, super.key});
  @override
  Widget build(BuildContext context) {
    final gradient = variant == _CardVariant.casual
        ? [const Color(0xFF0FA3A5), const Color(0xFF22C55E)]
        : [const Color(0xFF3B82F6), const Color(0xFF0EA5E9)];
    final icon = variant == _CardVariant.casual ? Icons.favorite : Icons.edit_calendar_outlined;
    return InkWell(
      onTap: (){
        if (variant == _CardVariant.casual) {
          Navigator.push(context, MaterialPageRoute(builder: (_)=> const CasualPreviewScreen()));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_)=> const ManualSettingsFlow()));
        }
      },
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(colors: gradient),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0,8))],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(radius: 28, backgroundColor: Colors.white.withOpacity(0.2),
              child: Icon(icon, color: Colors.white)),
            const SizedBox(width: 16),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('Use “The Casual”', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Text('Our balanced default for Mon–Sun. You can edit later.', style: TextStyle(color: Colors.white70)),
              ],
            )),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

/// Preview The Casual weekly routine with an Apply button.
class CasualPreviewScreen extends StatefulWidget {
  const CasualPreviewScreen({super.key});
  @override State<CasualPreviewScreen> createState()=> _CasualPreviewScreenState();
}
class _CasualPreviewScreenState extends State<CasualPreviewScreen> {
  late DateTime weekStart;
  List<app.RoutineAction> sample = [];
  @override void initState(){ super.initState(); weekStart = _mondayOf(DateTime.now()); _load(); }
  Future<void> _load() async {
    sample = [
      app.RoutineAction(id:'wake-water', title:'Drink water', category:'Health', time: const TimeOfDay(hour:7,minute:15)),
      app.RoutineAction(id:'plan-top3', title:'Plan Top 3', category:'Planning', time: const TimeOfDay(hour:9,minute:0)),
      app.RoutineAction(id:'pm-stretch', title:'Neck & shoulder stretch', category:'Health', time: const TimeOfDay(hour:16,minute:0)),
    ];
    setState((){});
  }
  Future<void> _apply() async {
    final repo = app.Repo();
    final plan = <String, List<app.RoutineAction>>{};
    for (int i=0;i<7;i++){
      final d = weekStart.add(Duration(days:i));
      final k = _key(d);
      plan[k] = sample.map((e)=> e).toList();
    }
    await repo.saveWeek(weekStart, plan);
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('rb_onboarded_v1', true);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_)=> const app.HomeScaffold()), (_)=> false);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('The Casual'), actions: [
        TextButton(onPressed: _apply, child: const Text('Apply this Routine')),
      ]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Weekly preview (Mon–Sun)', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...List.generate(7, (i){
            final day = weekStart.add(Duration(days:i));
            return Card(
              child: ListTile(
                title: Text(_weekday(day.weekday)),
                subtitle: Wrap(spacing: 8, children: sample.map((a)=> Chip(label: Text('${a.title} • ${a.time.format(context)}'))).toList()),
              ),
            );
          }),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: _apply, icon: const Icon(Icons.check_circle_outline), label: const Text('Apply this Routine')),
          const SizedBox(height: 12),
          TextButton.icon(onPressed: ()=> Navigator.pop(context), icon: const Icon(Icons.arrow_back), label: const Text('Back')),
        ],
      ),
    );
  }
  String _key(DateTime d)=> '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  DateTime _mondayOf(DateTime d)=> d.subtract(Duration(days: d.weekday-1));
  String _weekday(int wd)=> const ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][wd-1];
}

/// Manual path: configure anchors & mode, then add today’s actions.
class ManualSettingsFlow extends StatefulWidget {
  const ManualSettingsFlow({super.key});
  @override State<ManualSettingsFlow> createState()=> _ManualSettingsFlowState();
}
class _ManualSettingsFlowState extends State<ManualSettingsFlow> {
  late app.AppSettings s;
  @override void initState(){ super.initState(); s = app.AppSettings.defaults(); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set your anchors')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TimeRow(label:'Wake time', value:s.wake, onPick:(t)=> setState(()=> s=s.copyWith(wake:t)) ),
          _TimeRow(label:'Bed time',  value:s.bed,  onPick:(t)=> setState(()=> s=s.copyWith(bed:t))  ),
          const SizedBox(height: 16),
          const Text('Schedule Mode', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SegmentedButton<app.ScheduleMode>(
            segments: const [
              ButtonSegment(value: app.ScheduleMode.weekly, label: Text('Weekly')),
              ButtonSegment(value: app.ScheduleMode.daily,  label: Text('Daily')),
            ],
            selected: {s.mode},
            onSelectionChanged: (set)=> setState(()=> s = s.copyWith(mode: set.first)),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async {
              final repo = app.Repo();
              await repo.saveSettings(s);
              final sp = await SharedPreferences.getInstance();
              await sp.setBool('rb_onboarded_v1', true);
              if (!mounted) return;
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_)=> const AddActionsFirstRun()));
            },
            icon: const Icon(Icons.navigate_next),
            label: const Text('Continue to add actions'),
          ),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final String label; final TimeOfDay value; final ValueChanged<TimeOfDay> onPick;
  const _TimeRow({required this.label, required this.value, required this.onPick, super.key});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: TextButton(
        onPressed: () async { final p = await showTimePicker(context: context, initialTime: value); if (p!=null) onPick(p); },
        child: Text(value.format(context)),
      ),
    );
  }
}

/// “Add actions to your today” — basic picker (we’ll replace with 120-item list next).
class AddActionsFirstRun extends StatefulWidget {
  const AddActionsFirstRun({super.key});
  @override State<AddActionsFirstRun> createState()=> _AddActionsFirstRunState();
}
class _AddActionsFirstRunState extends State<AddActionsFirstRun> {
  final repo = app.Repo();
  List<app.RoutineAction> all = [];
  final selected = <String,app.RoutineAction>{};

  @override void initState(){ super.initState(); _load(); }
  Future<void> _load() async {
    all = [
      app.RoutineAction(id:'walk10',   title:'10-minute walk',   category:'Energy',      time: const TimeOfDay(hour:15,minute:0)),
      app.RoutineAction(id:'read10',   title:'Read 10 minutes',  category:'Learning',    time: const TimeOfDay(hour:22,minute:0)),
      app.RoutineAction(id:'gratitude',title:'Gratitude note',   category:'Mindfulness', time: const TimeOfDay(hour:21,minute:30)),
    ];
    setState((){});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add actions to your today'), actions: [
        TextButton(onPressed: _finish, child: Text('Add (${selected.length})')),
      ]),
      body: ListView.separated(
        itemCount: all.length, separatorBuilder: (_, __)=> const Divider(height: 0),
        itemBuilder: (context,i){
          final a = all[i];
          final picked = selected.containsKey(a.id);
          return ListTile(
            leading: Checkbox(value: picked, onChanged: (v){ setState(()=> v==true? selected[a.id]=a : selected.remove(a.id)); }),
            title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${a.category} • ${a.time.format(context)}'),
            onTap: () => setState(()=> picked? selected.remove(a.id) : selected[a.id]=a),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _finish,
        icon: const Icon(Icons.add_task),
        label: Text('Add ${selected.isEmpty? "" : "(${selected.length})"}'),
      ),
    );
  }

  Future<void> _finish() async {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday-1));
    final key = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
    final plan = await repo.loadWeek(monday);
    final list = [...(plan[key] ?? <app.RoutineAction>[])];
    final ids = list.map((e)=>e.id).toSet();
    for (final a in selected.values){
      if (!ids.contains(a.id)) list.add(a);
    }
    plan[key] = list;
    await repo.saveWeek(monday, plan);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_)=> const app.HomeScaffold()),
      (_) => false,
    );
  }
}
DART

echo "Project scaffolding complete."
