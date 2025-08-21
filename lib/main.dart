/*
 * RoutineBuddy - Checkpoint 3
 * 
 * A Flutter application for managing daily routines and habits.
 * Features include:
 * - Template-based routine setup with "The Casual" template
 * - Manual routine customization with sleep schedule, meals, and activities
 * - Dynamic action frequency distribution with anchor-based scheduling
 * - Timeline view with reorderable actions
 * - Settings for repeat schedules and day-off management
 * 
 * Main Components:
 * - FillYourRoutineScreen: Initial template selection
 * - ManualSetupScreen: Custom routine configuration
 * - ActionPickerScreen: Activity selection and time setup
 * - HomeScreen: Main interface with Templates, Routine, and Settings tabs
 * - Timeline management with next-day time handling
 */

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

// Helper function for next-day aware time sorting
int _compareTimesWithNextDay(TimeOfDay timeA, TimeOfDay timeB, TimeOfDay wakeTime, TimeOfDay bedTime) {
  int minutesA = timeA.hour * 60 + timeA.minute;
  int minutesB = timeB.hour * 60 + timeB.minute;
  int wakeMinutes = wakeTime.hour * 60 + wakeTime.minute;
  int bedMinutes = bedTime.hour * 60 + bedTime.minute;
  
  // Handle next-day sleep time (e.g., sleep at 00:00 means next day)
  if (bedMinutes < wakeMinutes) {
    // If time is before wake time, treat it as next day
    if (minutesA < wakeMinutes) minutesA += 1440; // Add 24 hours
    if (minutesB < wakeMinutes) minutesB += 1440; // Add 24 hours
  }
  
  return minutesA.compareTo(minutesB);
}

// Helper function to format time with 00:00 instead of 12:00 AM
String formatTimeCustom(BuildContext context, TimeOfDay time) {
  if (time.hour == 0) {
    return '00:${time.minute.toString().padLeft(2, '0')}';
  }
  return time.format(context);
}

// ============================================================================
// SHARED PREFERENCES HELPERS
// ============================================================================

// Helper function to mark initial setup as complete
Future<void> markSetupComplete() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isInitialSetupComplete', true);
    print('DEBUG: Initial setup marked as complete');
  } catch (e) {
    print('DEBUG: Error marking setup complete: $e');
  }
}

// Helper function to save user settings during setup
Future<void> saveUserSettings({
  required TimeOfDay wakeTime,
  required TimeOfDay bedTime,
  required List<TimeOfDay> mealTimes,
  required List<String> mealNames,
  required String scheduleMode,
  bool isCasualTemplate = false,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Save wake and bed times
    await prefs.setInt('wakeTime_hour', wakeTime.hour);
    await prefs.setInt('wakeTime_minute', wakeTime.minute);
    await prefs.setInt('bedTime_hour', bedTime.hour);
    await prefs.setInt('bedTime_minute', bedTime.minute);
    
    // Save meal times and names
    for (int i = 0; i < mealTimes.length && i < 3; i++) {
      await prefs.setInt('meal${i}_hour', mealTimes[i].hour);
      await prefs.setInt('meal${i}_minute', mealTimes[i].minute);
      if (i < mealNames.length) {
        await prefs.setString('meal${i}_name', mealNames[i]);
      }
    }
    
    // Save other settings
    await prefs.setString('scheduleMode', scheduleMode);
    await prefs.setBool('isCasualTemplate', isCasualTemplate);
    
    print('DEBUG: User settings saved successfully');
  } catch (e) {
    print('DEBUG: Error saving user settings: $e');
  }
}

// Global template actions data for The Casual template
List<Map<String, dynamic>> getCasualTemplateActions() {
  return [
    // Monday
    {'name': 'Wake up', 'time': TimeOfDay(hour: 6, minute: 0), 'category': 'schedule', 'dayOfWeek': 1, 'isScheduleTime': true},
    {'name': 'Drink a glass of water', 'time': TimeOfDay(hour: 6, minute: 35), 'category': 'health', 'dayOfWeek': 1},
    {'name': 'Light stretch (5 min)', 'time': TimeOfDay(hour: 6, minute: 45), 'category': 'exercise', 'dayOfWeek': 1},
    {'name': 'Breakfast', 'time': TimeOfDay(hour: 7, minute: 0), 'category': 'schedule', 'dayOfWeek': 1, 'isScheduleTime': true},
    {'name': 'Start work', 'time': TimeOfDay(hour: 8, minute: 30), 'category': 'productivity', 'dayOfWeek': 1},
    {'name': 'Stand up–sit down x10, check posture', 'time': TimeOfDay(hour: 9, minute: 30), 'category': 'exercise', 'dayOfWeek': 1},
    {'name': 'Water sips', 'time': TimeOfDay(hour: 10, minute: 30), 'category': 'health', 'dayOfWeek': 1},
    {'name': 'Lunch', 'time': TimeOfDay(hour: 12, minute: 0), 'category': 'schedule', 'dayOfWeek': 1, 'isScheduleTime': true},
    {'name': 'Short walk', 'time': TimeOfDay(hour: 12, minute: 45), 'category': 'exercise', 'dayOfWeek': 1},
    {'name': 'Finish work', 'time': TimeOfDay(hour: 17, minute: 30), 'category': 'productivity', 'dayOfWeek': 1},
    {'name': 'Dinner', 'time': TimeOfDay(hour: 19, minute: 30), 'category': 'schedule', 'dayOfWeek': 1, 'isScheduleTime': true},
    {'name': 'Self time', 'time': TimeOfDay(hour: 21, minute: 0), 'category': 'leisure', 'dayOfWeek': 1},
    {'name': 'Review tomorrow\'s routine', 'time': TimeOfDay(hour: 22, minute: 0), 'category': 'schedule', 'dayOfWeek': 1, 'isScheduleTime': true},
    {'name': 'Sleep', 'time': TimeOfDay(hour: 22, minute: 30), 'category': 'schedule', 'dayOfWeek': 1, 'isScheduleTime': true},

    // Tuesday
    {'name': 'Wake up', 'time': TimeOfDay(hour: 6, minute: 0), 'category': 'schedule', 'dayOfWeek': 2, 'isScheduleTime': true},
    {'name': 'Drink a glass of water', 'time': TimeOfDay(hour: 6, minute: 35), 'category': 'health', 'dayOfWeek': 2},
    {'name': 'Gentle yoga (10 min)', 'time': TimeOfDay(hour: 6, minute: 45), 'category': 'exercise', 'dayOfWeek': 2},
    {'name': 'Breakfast', 'time': TimeOfDay(hour: 7, minute: 0), 'category': 'schedule', 'dayOfWeek': 2, 'isScheduleTime': true},
    {'name': 'Start work', 'time': TimeOfDay(hour: 8, minute: 30), 'category': 'productivity', 'dayOfWeek': 2},
    {'name': 'Stand up–sit down x10, check posture', 'time': TimeOfDay(hour: 9, minute: 30), 'category': 'exercise', 'dayOfWeek': 2},
    {'name': 'Water sips', 'time': TimeOfDay(hour: 10, minute: 30), 'category': 'health', 'dayOfWeek': 2},
    {'name': 'Lunch', 'time': TimeOfDay(hour: 12, minute: 0), 'category': 'schedule', 'dayOfWeek': 2, 'isScheduleTime': true},
    {'name': 'Light walk', 'time': TimeOfDay(hour: 12, minute: 45), 'category': 'exercise', 'dayOfWeek': 2},
    {'name': 'Finish work', 'time': TimeOfDay(hour: 17, minute: 30), 'category': 'productivity', 'dayOfWeek': 2},
    {'name': 'Dinner', 'time': TimeOfDay(hour: 19, minute: 30), 'category': 'schedule', 'dayOfWeek': 2, 'isScheduleTime': true},
    {'name': 'Self time', 'time': TimeOfDay(hour: 21, minute: 0), 'category': 'leisure', 'dayOfWeek': 2},
    {'name': 'Review tomorrow\'s routine', 'time': TimeOfDay(hour: 22, minute: 0), 'category': 'schedule', 'dayOfWeek': 2, 'isScheduleTime': true},
    {'name': 'Sleep', 'time': TimeOfDay(hour: 22, minute: 30), 'category': 'schedule', 'dayOfWeek': 2, 'isScheduleTime': true},

    // Wednesday
    {'name': 'Wake up', 'time': TimeOfDay(hour: 6, minute: 0), 'category': 'schedule', 'dayOfWeek': 3, 'isScheduleTime': true},
    {'name': 'Drink a glass of water', 'time': TimeOfDay(hour: 6, minute: 35), 'category': 'health', 'dayOfWeek': 3},
    {'name': 'Short walk or light stretch', 'time': TimeOfDay(hour: 6, minute: 45), 'category': 'exercise', 'dayOfWeek': 3},
    {'name': 'Breakfast', 'time': TimeOfDay(hour: 7, minute: 0), 'category': 'schedule', 'dayOfWeek': 3, 'isScheduleTime': true},
    {'name': 'Start work', 'time': TimeOfDay(hour: 8, minute: 30), 'category': 'productivity', 'dayOfWeek': 3},
    {'name': 'Stand up–sit down x10, check posture', 'time': TimeOfDay(hour: 9, minute: 30), 'category': 'exercise', 'dayOfWeek': 3},
    {'name': 'Water sips', 'time': TimeOfDay(hour: 10, minute: 30), 'category': 'health', 'dayOfWeek': 3},
    {'name': 'Lunch without phone', 'time': TimeOfDay(hour: 12, minute: 0), 'category': 'schedule', 'dayOfWeek': 3, 'isScheduleTime': true},
    {'name': 'Quick walk', 'time': TimeOfDay(hour: 12, minute: 45), 'category': 'exercise', 'dayOfWeek': 3},
    {'name': 'Finish work', 'time': TimeOfDay(hour: 17, minute: 30), 'category': 'productivity', 'dayOfWeek': 3},
    {'name': 'Dinner', 'time': TimeOfDay(hour: 19, minute: 30), 'category': 'schedule', 'dayOfWeek': 3, 'isScheduleTime': true},
    {'name': 'Self time', 'time': TimeOfDay(hour: 21, minute: 0), 'category': 'leisure', 'dayOfWeek': 3},
    {'name': 'Review tomorrow\'s routine', 'time': TimeOfDay(hour: 22, minute: 0), 'category': 'schedule', 'dayOfWeek': 3, 'isScheduleTime': true},
    {'name': 'Sleep', 'time': TimeOfDay(hour: 22, minute: 30), 'category': 'schedule', 'dayOfWeek': 3, 'isScheduleTime': true},

    // Thursday
    {'name': 'Wake up', 'time': TimeOfDay(hour: 6, minute: 0), 'category': 'schedule', 'dayOfWeek': 4, 'isScheduleTime': true},
    {'name': 'Drink a glass of water', 'time': TimeOfDay(hour: 6, minute: 35), 'category': 'health', 'dayOfWeek': 4},
    {'name': 'Light stretch', 'time': TimeOfDay(hour: 6, minute: 45), 'category': 'exercise', 'dayOfWeek': 4},
    {'name': 'Breakfast', 'time': TimeOfDay(hour: 7, minute: 0), 'category': 'schedule', 'dayOfWeek': 4, 'isScheduleTime': true},
    {'name': 'Start work', 'time': TimeOfDay(hour: 8, minute: 30), 'category': 'productivity', 'dayOfWeek': 4},
    {'name': 'Stand up–sit down x10, check posture', 'time': TimeOfDay(hour: 9, minute: 30), 'category': 'exercise', 'dayOfWeek': 4},
    {'name': 'Water sips', 'time': TimeOfDay(hour: 10, minute: 30), 'category': 'health', 'dayOfWeek': 4},
    {'name': 'Lunch', 'time': TimeOfDay(hour: 12, minute: 0), 'category': 'schedule', 'dayOfWeek': 4, 'isScheduleTime': true},
    {'name': 'Short walk', 'time': TimeOfDay(hour: 12, minute: 45), 'category': 'exercise', 'dayOfWeek': 4},
    {'name': 'Finish work', 'time': TimeOfDay(hour: 17, minute: 30), 'category': 'productivity', 'dayOfWeek': 4},
    {'name': 'Dinner', 'time': TimeOfDay(hour: 19, minute: 30), 'category': 'schedule', 'dayOfWeek': 4, 'isScheduleTime': true},
    {'name': 'Self time', 'time': TimeOfDay(hour: 21, minute: 0), 'category': 'leisure', 'dayOfWeek': 4},
    {'name': 'Review tomorrow\'s routine', 'time': TimeOfDay(hour: 22, minute: 0), 'category': 'schedule', 'dayOfWeek': 4, 'isScheduleTime': true},
    {'name': 'Sleep', 'time': TimeOfDay(hour: 22, minute: 30), 'category': 'schedule', 'dayOfWeek': 4, 'isScheduleTime': true},

    // Friday
    {'name': 'Wake up', 'time': TimeOfDay(hour: 6, minute: 0), 'category': 'schedule', 'dayOfWeek': 5, 'isScheduleTime': true},
    {'name': 'Drink a glass of water', 'time': TimeOfDay(hour: 6, minute: 35), 'category': 'health', 'dayOfWeek': 5},
    {'name': 'Light exercise (5 min)', 'time': TimeOfDay(hour: 6, minute: 45), 'category': 'exercise', 'dayOfWeek': 5},
    {'name': 'Breakfast', 'time': TimeOfDay(hour: 7, minute: 0), 'category': 'schedule', 'dayOfWeek': 5, 'isScheduleTime': true},
    {'name': 'Start work', 'time': TimeOfDay(hour: 8, minute: 30), 'category': 'productivity', 'dayOfWeek': 5},
    {'name': 'Stand up–sit down x10, check posture', 'time': TimeOfDay(hour: 9, minute: 30), 'category': 'exercise', 'dayOfWeek': 5},
    {'name': 'Water sips', 'time': TimeOfDay(hour: 10, minute: 30), 'category': 'health', 'dayOfWeek': 5},
    {'name': 'Lunch', 'time': TimeOfDay(hour: 12, minute: 0), 'category': 'schedule', 'dayOfWeek': 5, 'isScheduleTime': true},
    {'name': 'Light walk', 'time': TimeOfDay(hour: 12, minute: 45), 'category': 'exercise', 'dayOfWeek': 5},
    {'name': 'Finish work', 'time': TimeOfDay(hour: 17, minute: 30), 'category': 'productivity', 'dayOfWeek': 5},
    {'name': 'Dinner', 'time': TimeOfDay(hour: 19, minute: 30), 'category': 'schedule', 'dayOfWeek': 5, 'isScheduleTime': true},
    {'name': 'Self time', 'time': TimeOfDay(hour: 21, minute: 0), 'category': 'leisure', 'dayOfWeek': 5},
    {'name': 'Review tomorrow\'s routine', 'time': TimeOfDay(hour: 23, minute: 0), 'category': 'schedule', 'dayOfWeek': 5, 'isScheduleTime': true},
    {'name': 'Sleep', 'time': TimeOfDay(hour: 23, minute: 30), 'category': 'schedule', 'dayOfWeek': 5, 'isScheduleTime': true},

    // Saturday
    {'name': 'Wake up', 'time': TimeOfDay(hour: 7, minute: 0), 'category': 'schedule', 'dayOfWeek': 6, 'isScheduleTime': true},
    {'name': 'Drink a glass of water', 'time': TimeOfDay(hour: 7, minute: 5), 'category': 'health', 'dayOfWeek': 6},
    {'name': 'Morning walk', 'time': TimeOfDay(hour: 7, minute: 15), 'category': 'exercise', 'dayOfWeek': 6},
    {'name': 'Breakfast', 'time': TimeOfDay(hour: 8, minute: 0), 'category': 'schedule', 'dayOfWeek': 6, 'isScheduleTime': true},
    {'name': 'Leisure activity', 'time': TimeOfDay(hour: 10, minute: 0), 'category': 'leisure', 'dayOfWeek': 6},
    {'name': 'Lunch', 'time': TimeOfDay(hour: 12, minute: 0), 'category': 'schedule', 'dayOfWeek': 6, 'isScheduleTime': true},
    {'name': 'Relaxation or hobby', 'time': TimeOfDay(hour: 14, minute: 0), 'category': 'leisure', 'dayOfWeek': 6},
    {'name': 'Short walk', 'time': TimeOfDay(hour: 16, minute: 0), 'category': 'exercise', 'dayOfWeek': 6},
    {'name': 'Dinner', 'time': TimeOfDay(hour: 19, minute: 30), 'category': 'schedule', 'dayOfWeek': 6, 'isScheduleTime': true},
    {'name': 'Self time', 'time': TimeOfDay(hour: 21, minute: 0), 'category': 'leisure', 'dayOfWeek': 6},
    {'name': 'Review tomorrow\'s routine', 'time': TimeOfDay(hour: 23, minute: 0), 'category': 'schedule', 'dayOfWeek': 6, 'isScheduleTime': true},
    {'name': 'Sleep', 'time': TimeOfDay(hour: 23, minute: 30), 'category': 'schedule', 'dayOfWeek': 6, 'isScheduleTime': true},

    // Sunday
    {'name': 'Wake up', 'time': TimeOfDay(hour: 7, minute: 0), 'category': 'schedule', 'dayOfWeek': 7, 'isScheduleTime': true},
    {'name': 'Drink a glass of water', 'time': TimeOfDay(hour: 7, minute: 5), 'category': 'health', 'dayOfWeek': 7},
    {'name': 'Gentle stretch', 'time': TimeOfDay(hour: 7, minute: 15), 'category': 'exercise', 'dayOfWeek': 7},
    {'name': 'Breakfast', 'time': TimeOfDay(hour: 8, minute: 0), 'category': 'schedule', 'dayOfWeek': 7, 'isScheduleTime': true},
    {'name': 'Personal planning for week', 'time': TimeOfDay(hour: 10, minute: 0), 'category': 'productivity', 'dayOfWeek': 7},
    {'name': 'Lunch', 'time': TimeOfDay(hour: 12, minute: 0), 'category': 'schedule', 'dayOfWeek': 7, 'isScheduleTime': true},
    {'name': 'Light chore or shopping', 'time': TimeOfDay(hour: 14, minute: 0), 'category': 'chores', 'dayOfWeek': 7},
    {'name': 'Relaxation time', 'time': TimeOfDay(hour: 16, minute: 0), 'category': 'leisure', 'dayOfWeek': 7},
    {'name': 'Dinner', 'time': TimeOfDay(hour: 19, minute: 30), 'category': 'schedule', 'dayOfWeek': 7, 'isScheduleTime': true},
    {'name': 'Self time', 'time': TimeOfDay(hour: 21, minute: 0), 'category': 'leisure', 'dayOfWeek': 7},
    {'name': 'Review tomorrow\'s routine', 'time': TimeOfDay(hour: 22, minute: 0), 'category': 'schedule', 'dayOfWeek': 7, 'isScheduleTime': true},
    {'name': 'Sleep', 'time': TimeOfDay(hour: 22, minute: 30), 'category': 'schedule', 'dayOfWeek': 7, 'isScheduleTime': true},
  ];
}

// Helper function to reset setup (for testing or user data reset)
Future<void> resetSetup() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isInitialSetupComplete', false);
    print('DEBUG: Setup reset - will show onboarding again');
  } catch (e) {
    print('DEBUG: Error resetting setup: $e');
  }
}

// ============================================================================
// MAIN APPLICATION
// ============================================================================

void main() {
  runApp(RoutineBuddyApp());
}

class RoutineBuddyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoutineBuddy',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Color(0xFF0FA3A5)),
      home: AppInitializer(),
    );
  }
}

// App Initializer - Checks if initial setup is complete
class AppInitializer extends StatefulWidget {
  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _checkInitialSetup();
  }
  
  Future<void> _checkInitialSetup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isSetupComplete = prefs.getBool('isInitialSetupComplete') ?? false;
      
      print('DEBUG: Initial setup complete: $isSetupComplete');
      
      // Small delay for smooth transition
      await Future.delayed(Duration(milliseconds: 500));
      
      if (mounted) {
        if (isSetupComplete) {
          // Setup is complete, load user preferences and go to main app
          final savedWakeHour = prefs.getInt('wakeTime_hour') ?? 6;
          final savedWakeMinute = prefs.getInt('wakeTime_minute') ?? 0;
          final savedBedHour = prefs.getInt('bedTime_hour') ?? 23;
          final savedBedMinute = prefs.getInt('bedTime_minute') ?? 0;
          final savedScheduleMode = prefs.getString('scheduleMode') ?? 'Repeat';
          final isCasualTemplate = prefs.getBool('isCasualTemplate') ?? false;
          
          // Load meal times (with defaults)
          List<TimeOfDay> mealTimes = [
            TimeOfDay(hour: prefs.getInt('meal0_hour') ?? 8, minute: prefs.getInt('meal0_minute') ?? 0),
            TimeOfDay(hour: prefs.getInt('meal1_hour') ?? 12, minute: prefs.getInt('meal1_minute') ?? 0),
            TimeOfDay(hour: prefs.getInt('meal2_hour') ?? 19, minute: prefs.getInt('meal2_minute') ?? 0),
          ];
          
          List<String> mealNames = [
            prefs.getString('meal0_name') ?? 'Breakfast',
            prefs.getString('meal1_name') ?? 'Lunch', 
            prefs.getString('meal2_name') ?? 'Dinner',
          ];
          
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                routineActions: [], // Will load from day-specific storage
                wakeTime: TimeOfDay(hour: savedWakeHour, minute: savedWakeMinute),
                bedTime: TimeOfDay(hour: savedBedHour, minute: savedBedMinute),
                mealTimes: mealTimes,
                mealNames: mealNames,
                scheduleMode: savedScheduleMode,
                isCasualTemplate: isCasualTemplate,
                initialTabIndex: 1, // Start on Routine tab
              ),
            ),
          );
        } else {
          // First time user, show onboarding
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => FillYourRoutineScreen()),
          );
        }
      }
    } catch (e) {
      print('DEBUG: Error checking initial setup: $e');
      // On error, default to showing onboarding
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => FillYourRoutineScreen()),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'RoutineBuddy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Loading your routine...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ONBOARDING SCREENS
// ============================================================================

// First Screen: Choose template or create manually
class FillYourRoutineScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fill your routine'),
        // Allow back navigation during template selection
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          TemplateCard(
            title: 'Use "The Casual"',
            subtitle: 'Maintain a simple, balanced daily flow that supports health, light activity, and personal time with minimal effort',
            gradient: [Color(0xFF0FA3A5), Color(0xFF22C55E)],
            icon: Icons.favorite,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CasualPreviewScreen())),
          ),
          SizedBox(height: 16),
          TemplateCard(
            title: 'Create your own routine',
            subtitle: 'Set your anchors and build your own timeline.',
            gradient: [Color(0xFF3B82F6), Color(0xFF0EA5E9)],
            icon: Icons.edit_calendar_outlined,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManualSetupScreen())),
          ),
        ],
      ),
    );
  }
}

// Template Card Widget
class TemplateCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final IconData icon;
  final VoidCallback onTap;

  TemplateCard({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(colors: gradient),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: Offset(0, 8))],
        ),
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Icon(icon, color: Colors.white),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  SizedBox(height: 6),
                  Text(subtitle, style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

// Preview "The Casual" template
class CasualPreviewScreen extends StatefulWidget {
  @override
  _CasualPreviewScreenState createState() => _CasualPreviewScreenState();
}

class _CasualPreviewScreenState extends State<CasualPreviewScreen> {
  late DateTime selectedDate;
  List<Map<String, dynamic>> displayActions = [];
  
  @override
  void initState() {
    super.initState();
    // Start with Monday of current week for template preview
    final now = DateTime.now();
    final mondayOfWeek = now.subtract(Duration(days: now.weekday - 1));
    selectedDate = mondayOfWeek;
    _loadPreviewActions();
  }
  
  void _loadPreviewActions() {
    final currentWeekday = selectedDate.weekday; // 1=Monday, 7=Sunday
    
    // Get casual template actions for current day
    final dayActions = getCasualTemplateActions()
        .where((action) => action['dayOfWeek'] == currentWeekday)
        .map((action) => Map<String, dynamic>.from(action))
        .toList();
    
    // Sort actions by time
    dayActions.sort((a, b) {
      final timeA = a['time'] as TimeOfDay;
      final timeB = b['time'] as TimeOfDay;
      
      // Convert times to minutes, treating 00:00 (sleep) as end of day (24:00 = 1440 minutes)
      int minutesA = timeA.hour * 60 + timeA.minute;
      int minutesB = timeB.hour * 60 + timeB.minute;
      
      // Special handling for sleep time (00:00) - treat as end of day
      final nameA = a['name'] ?? '';
      final nameB = b['name'] ?? '';
      if ((nameA.contains('Sleep') || nameA.contains('😴')) && timeA.hour == 0 && timeA.minute == 0) {
        minutesA = 24 * 60; // 24:00 = end of day
      }
      if ((nameB.contains('Sleep') || nameB.contains('😴')) && timeB.hour == 0 && timeB.minute == 0) {
        minutesB = 24 * 60; // 24:00 = end of day
      }
      
      return minutesA.compareTo(minutesB);
    });
    
    setState(() {
      displayActions = dayActions;
    });
    
    print('DEBUG: Loaded ${dayActions.length} preview actions for ${_getDayName(currentWeekday)}');
  }
  
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Unknown';
    }
  }
  
  String _getFormattedDate() {
    // For template preview, just show day of week since template hasn't been applied yet
    return _getDayName(selectedDate.weekday);
  }
  
  void _goToPreviousDay() {
    // Only allow navigation within the current week (Monday to Sunday)
    final mondayOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    if (selectedDate.isAfter(mondayOfWeek)) {
      setState(() {
        selectedDate = selectedDate.subtract(Duration(days: 1));
        _loadPreviewActions();
      });
    }
  }

  void _goToNextDay() {
    // Only allow navigation within the current week (Monday to Sunday)
    final sundayOfWeek = selectedDate.add(Duration(days: 7 - selectedDate.weekday));
    if (selectedDate.isBefore(sundayOfWeek)) {
      setState(() {
        selectedDate = selectedDate.add(Duration(days: 1));
        _loadPreviewActions();
      });
    }
  }

  bool _canGoToPreviousDay() {
    final mondayOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    return selectedDate.isAfter(mondayOfWeek);
  }

  bool _canGoToNextDay() {
    final sundayOfWeek = selectedDate.add(Duration(days: 7 - selectedDate.weekday));
    return selectedDate.isBefore(sundayOfWeek);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(child: Center(child: Text('The Casual Routine'))),
            IconButton(
              icon: Icon(Icons.info_outline),
              tooltip: 'Target User: Office or hybrid workers who want gentle reminders for everyday basics without overcomplication',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Target User'),
                      content: Text('Office or hybrid workers who want gentle reminders for everyday basics without overcomplication'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Day navigation header
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: _canGoToPreviousDay() ? _goToPreviousDay : null,
                  icon: Icon(Icons.chevron_left),
                  tooltip: 'Previous day',
                ),
                Expanded(
                  child: Text(
                    _getFormattedDate(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: _canGoToNextDay() ? _goToNextDay : null,
                  icon: Icon(Icons.chevron_right),
                  tooltip: 'Next day',
                ),
              ],
            ),
          ),
          
          // Preview actions list
          Expanded(
            child: displayActions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No actions for this day',
                          style: TextStyle(color: Colors.grey, fontSize: 18),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: displayActions.length,
                    itemBuilder: (context, index) {
                      final action = displayActions[index];
                      final time = action['time'] as TimeOfDay;
                      final name = action['name'] ?? 'Unknown';
                      final category = action['category'] ?? 'General';
                      final displayCategory = _getCategoryDisplayName(category);
                      
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getCategoryColor(category),
                            child: Icon(
                              _getCategoryIcon(category),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: displayCategory.isNotEmpty ? Text(
                            displayCategory,
                            style: TextStyle(color: Colors.grey[600]),
                          ) : null,
                          trailing: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(category).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getCategoryColor(category),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Apply template button
          Padding(
            padding: EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: () async {
                // Save user settings and mark setup as complete - matching CSV specifications
                await saveUserSettings(
                  wakeTime: TimeOfDay(hour: 6, minute: 0),        // From template: Wake up 06:00
                  bedTime: TimeOfDay(hour: 23, minute: 30),       // From template: Bedtime 23:30
                  mealTimes: [
                    TimeOfDay(hour: 7, minute: 0),               // Breakfast 07:00
                    TimeOfDay(hour: 12, minute: 0),              // Lunch 12:00
                    TimeOfDay(hour: 19, minute: 0),              // Dinner 19:00
                  ],
                  mealNames: ['Breakfast', 'Lunch', 'Dinner'],
                  scheduleMode: 'Daily',                         // CSV: Schedule mode: Daily
                  isCasualTemplate: true,
                );
                await markSetupComplete();
                
                Navigator.pushReplacement(
                  context, 
                  MaterialPageRoute(
                    builder: (_) => HomeScreen(
                      initialTabIndex: 1, // Routine tab
                      isCasualTemplate: true,
                      wakeTime: TimeOfDay(hour: 6, minute: 0),
                      bedTime: TimeOfDay(hour: 22, minute: 30),
                      mealTimes: [
                        TimeOfDay(hour: 7, minute: 0),
                        TimeOfDay(hour: 12, minute: 0),
                        TimeOfDay(hour: 19, minute: 30),
                      ],
                      mealNames: ['Breakfast', 'Lunch', 'Dinner'],
                      repeatWorkdaysRoutine: false,              // CSV: Repeat weekdays routine: OFF
                      stopRoutineOnDayOffs: false,               // CSV: Stop routine on day-offs: OFF
                      dayOffs: <int>{},                          // No day-offs since stop routine is OFF
                      scheduleMode: 'Daily',                     // CSV: Schedule mode: Daily
                      isFromInitialSetup: true,
                    ),
                  ),
                );
              },
              icon: Icon(Icons.check),
              label: Text('Apply This Template'),
              style: FilledButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'health': return Colors.green;
      case 'exercise': return Colors.orange;
      case 'work': return Colors.blue;
      case 'productivity': return Colors.purple;
      case 'personal': return Colors.teal;
      case 'system': return Colors.grey;
      case 'leisure': return Colors.pink;
      case 'planning': return Colors.indigo;
      case 'home': return Colors.brown;
      case 'chores': return Colors.amber;
      case 'schedule': return Colors.red;
      default: return Colors.grey;
    }
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'health': return Icons.local_drink;
      case 'exercise': return Icons.fitness_center;
      case 'work': return Icons.work;
      case 'productivity': return Icons.business_center;
      case 'personal': return Icons.person;
      case 'system': return Icons.list_alt;
      case 'leisure': return Icons.weekend;
      case 'planning': return Icons.event_note;
      case 'home': return Icons.home;
      case 'chores': return Icons.cleaning_services;
      case 'schedule': return Icons.schedule;
      default: return Icons.circle;
    }
  }

  String _getCategoryDisplayName(String category) {
    switch (category.toLowerCase()) {
      case 'health': return 'Health';
      case 'exercise': return 'Exercise';
      case 'work': return 'Work';
      case 'productivity': return 'Productivity';
      case 'personal': return 'Personal';
      case 'leisure': return 'Leisure';
      case 'planning': return 'Planning';
      case 'home': return 'Home';
      case 'chores': return 'Chores';
      case 'schedule': return ''; // Don't show label for schedule items
      case 'custom': return ''; // Don't show label for custom items that are actually schedule items
      default: return category;
    }
  }
}

// Manual setup flow
class ManualSetupScreen extends StatefulWidget {
  @override
  _ManualSetupScreenState createState() => _ManualSetupScreenState();
}

class _ManualSetupScreenState extends State<ManualSetupScreen> {
  TimeOfDay wakeTime = TimeOfDay(hour: 6, minute: 0);
  TimeOfDay bedTime = TimeOfDay(hour: 0, minute: 0);
  List<TimeOfDay> mealTimes = [
    TimeOfDay(hour: 8, minute: 0),   // Breakfast
    TimeOfDay(hour: 12, minute: 0),  // Lunch  
    TimeOfDay(hour: 19, minute: 0),  // Dinner
  ];
  List<String> mealNames = [
    'Breakfast',
    'Lunch',
    'Dinner',
  ];
  String scheduleMode = 'Weekly';
  Set<int> dayOffs = {}; // 1=Mon, 2=Tue, ..., 7=Sun
  bool stopRoutineOnDayOffs = false;
  bool repeatWorkdaysRoutine = true; // Default ON for custom routines - user can turn off

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Setup your routine settings'),
        // Allow back navigation to template selection
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Sleep Schedule
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sleep Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  ListTile(
                    leading: Icon(Icons.wb_sunny),
                    title: Text('Wake time'),
                    subtitle: Text(formatTimeCustom(context, wakeTime)),
                    onTap: () async {
                      final time = await showTimePicker(context: context, initialTime: wakeTime);
                      if (time != null) setState(() => wakeTime = time);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.bedtime),
                    title: Text('Sleep time'),
                    subtitle: Text(
                      '${formatTimeCustom(context, bedTime)}${bedTime.hour <= 6 ? ' (next day)' : ''}'
                    ),
                    onTap: () async {
                      final time = await showTimePicker(context: context, initialTime: bedTime);
                      if (time != null) setState(() => bedTime = time);
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          
          // Meal Times
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Meal Times', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: _addMeal,
                        icon: Icon(Icons.add),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ...mealTimes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final meal = entry.value;
                    final mealName = index < mealNames.length ? mealNames[index] : 'Meal ${index + 1}';
                    return ListTile(
                      leading: Icon(Icons.restaurant),
                      title: Text('$mealName at ${formatTimeCustom(context, meal)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _editMealNameAndTime(index),
                            icon: Icon(Icons.edit, size: 20),
                          ),
                          IconButton(
                            onPressed: () => _removeMeal(index),
                            icon: Icon(Icons.close, size: 20),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          
          // Schedule Mode
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Schedule Mode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'Weekly', label: Text('Weekly')),
                      ButtonSegment(value: 'Daily', label: Text('Daily')),
                      ButtonSegment(value: 'Repeat', label: Text('Repeat')),
                    ],
                    selected: {scheduleMode},
                    onSelectionChanged: (set) => setState(() => scheduleMode = set.first),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _getModeDescription(scheduleMode),
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          
          // Day-offs
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Day-offs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: List.generate(7, (i) {
                      final day = i + 1; // 1=Mon, 7=Sun
                      final isOff = dayOffs.contains(day);
                      return FilterChip(
                        label: Text(_weekdayName(day)),
                        selected: isOff,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              dayOffs.add(day);
                            } else {
                              dayOffs.remove(day);
                            }
                          });
                        },
                      );
                    }),
                  ),
                  SizedBox(height: 16),
                  SwitchListTile(
                    title: Text('Stop Routine on Day-offs'),
                    subtitle: Text('No actions will be indicated on selected Day-offs'),
                    value: stopRoutineOnDayOffs,
                    onChanged: (value) => setState(() => stopRoutineOnDayOffs = value),
                  ),
                  SwitchListTile(
                    title: Text('Repeat Weekdays Routine'),
                    subtitle: Text('Repeat the routine of the latest weekdays'),
                    value: repeatWorkdaysRoutine,
                    onChanged: (value) => setState(() => repeatWorkdaysRoutine = value),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 32),
          
          // Continue Button
          FilledButton.icon(
            onPressed: () async {
              try {
                print('DEBUG: ManualSetupScreen calling ActionPickerScreen...');
                final result = await Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => ActionPickerScreen(
                    wakeTime: wakeTime,
                    bedTime: bedTime,
                    existingActions: [], // Empty for initial setup
                    isInitialSetup: true, // This is the initial setup flow
                  ))
                );
                
                print('DEBUG: ManualSetupScreen received result: $result');
                print('DEBUG: Result type: ${result.runtimeType}');
                print('DEBUG: Result is null: ${result == null}');
                
                if (result != null && result is List<Map<String, dynamic>>) {
                  print('DEBUG: ManualSetupScreen processing ${result.length} actions...');
                  // Process frequency-based anchors before passing to HomeScreen
                  List<Map<String, dynamic>> processedActions = [];
                  
                  for (var action in result) {
                    // Mark as user-created action - don't set specific dayOfWeek
                    action['isUserAction'] = true; // Mark as user-created action
                    // Remove or don't set dayOfWeek for user actions to avoid template matching
                    action.remove('dayOfWeek'); // Remove any dayOfWeek to prevent template matching
                    
                    if ((action['frequency'] ?? 1) > 1) {
                      // Create anchor distribution for actions with frequency > 1
                      var anchors = _createActionAnchors(action, action['frequency']);
                      processedActions.addAll(anchors);
                    } else {
                      processedActions.add(action);
                    }
                  }
                  
                  // Sort processed actions by time
                  processedActions.sort((a, b) {
                    final timeA = a['time'] as TimeOfDay;
                    final timeB = b['time'] as TimeOfDay;
                    return _compareTimesWithNextDay(timeA, timeB, wakeTime, bedTime);
                  });
                  
                  // Add schedule times (wake, meals, bed) to the timeline
                  List<Map<String, dynamic>> scheduleActions = [];
                  
                  // Add wake time
                  scheduleActions.add({
                    'name': '🌅 Wake up',
                    'time': wakeTime,
                    'category': 'Schedule',
                    'frequency': 1,
                    'isScheduleTime': true,
                  });
                  
                  // Add meal times
                  for (int i = 0; i < mealTimes.length; i++) {
                    String mealName = i < mealNames.length ? mealNames[i] : 'Meal ${i + 1}';
                    String mealIcon = '�️';
                    if (mealName.toLowerCase().contains('breakfast')) mealIcon = '�';
                    else if (mealName.toLowerCase().contains('lunch')) mealIcon = '🍽️';
                    else if (mealName.toLowerCase().contains('dinner')) mealIcon = '🍽️';
                    
                    scheduleActions.add({
                      'name': '$mealIcon $mealName',
                      'time': mealTimes[i],
                      'category': 'Schedule',
                      'frequency': 1,
                      'isScheduleTime': true,
                    });
                  }
                  
                  // Add sleep time
                  scheduleActions.add({
                    'name': '🌙 Sleep',
                    'time': bedTime,
                    'category': 'Schedule',
                    'frequency': 1,
                    'isScheduleTime': true,
                  });
                  
                  // Combine schedule actions with user actions
                  processedActions.addAll(scheduleActions);
                  
                  // Sort all actions by time
                  processedActions.sort((a, b) {
                    final timeA = a['time'] as TimeOfDay;
                    final timeB = b['time'] as TimeOfDay;
                    return _compareTimesWithNextDay(timeA, timeB, wakeTime, bedTime);
                  });
                  
                  // Save user settings and mark setup as complete
                  await saveUserSettings(
                    wakeTime: wakeTime,
                    bedTime: bedTime,
                    mealTimes: mealTimes,
                    mealNames: mealNames,
                    scheduleMode: scheduleMode,
                    isCasualTemplate: false,
                  );
                  await markSetupComplete();
                  
                  // Navigate to HomeScreen with Routine tab and pass the processed actions
                  Navigator.pushReplacement(
                    context, 
                    MaterialPageRoute(
                      builder: (_) => HomeScreen(
                        initialTabIndex: 1, // Routine tab
                        routineActions: processedActions,
                        wakeTime: wakeTime,
                        bedTime: bedTime,
                        mealTimes: mealTimes,
                        mealNames: mealNames,
                        repeatWorkdaysRoutine: repeatWorkdaysRoutine,
                        stopRoutineOnDayOffs: stopRoutineOnDayOffs,
                        dayOffs: dayOffs,  // Pass the actual dayOffs set from manual setup
                        scheduleMode: scheduleMode,  // Pass the schedule mode
                        isFromInitialSetup: true, // Disable back navigation
                      )
                    )
                  );
                } else {
                  print('DEBUG: ManualSetupScreen - No valid actions received, staying on ManualSetupScreen');
                  print('DEBUG: result was: $result');
                }
              } catch (e) {
                print('DEBUG: ManualSetupScreen - Exception occurred: $e');
                // Handle navigation errors silently
              }
            },
            icon: Icon(Icons.navigate_next),
            label: Text('Continue to add actions'),
          ),
          SizedBox(height: 20), // Add some bottom padding
        ],
      ),
    );
  }

  void _addMeal() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _MealEditDialog(
        initialName: 'New Meal',
        initialTime: TimeOfDay(hour: 12, minute: 0),
        wakeTime: wakeTime,
        bedTime: bedTime,
        isAddMode: true,
      ),
    );
    
    if (result != null) {
      setState(() {
        mealTimes.add(result['time']);
        mealNames.add(result['name']);
        _sortMealTimes();
      });
    }
  }

  void _editMealNameAndTime(int index) async {
    final currentName = index < mealNames.length ? mealNames[index] : 'Meal ${index + 1}';
    final currentTime = mealTimes[index];
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _MealEditDialog(
        initialName: currentName, 
        initialTime: currentTime,
        wakeTime: wakeTime,
        bedTime: bedTime,
      ),
    );
    
    if (result != null) {
      setState(() {
        // Ensure mealNames list is long enough
        while (mealNames.length <= index) {
          mealNames.add('Meal ${mealNames.length + 1}');
        }
        mealNames[index] = result['name'];
        mealTimes[index] = result['time'];
        _sortMealTimes();
      });
    }
  }

  void _removeMeal(int index) {
    setState(() {
      mealTimes.removeAt(index);
      if (index < mealNames.length) {
        mealNames.removeAt(index);
      }
    });
  }

  void _sortMealTimes() {
    // Create pairs of times and names for sorting
    List<MapEntry<TimeOfDay, String>> pairs = [];
    for (int i = 0; i < mealTimes.length; i++) {
      final name = i < mealNames.length ? mealNames[i] : 'Meal ${i + 1}';
      pairs.add(MapEntry(mealTimes[i], name));
    }
    
    // Sort pairs by time
    pairs.sort((a, b) {
      final aMinutes = a.key.hour * 60 + a.key.minute;
      final bMinutes = b.key.hour * 60 + b.key.minute;
      return aMinutes.compareTo(bMinutes);
    });
    
    // Update both lists
    mealTimes = pairs.map((p) => p.key).toList();
    mealNames = pairs.map((p) => p.value).toList();
  }

  String _getModeDescription(String mode) {
    switch (mode) {
      case 'Daily':
        return 'Auto-add "Review tomorrow\'s routine" 30 mins before bedtime daily. Wake time check for blank routines.';
      case 'Weekly':
        return 'Auto-add "Review next week\'s routine" 30 mins before bedtime on last workday. Weekly planning dialogs.';
      case 'Repeat':
        return 'Routines repeat weekly with no prompts. Auto-carry last week\'s routine if no edits made.';
      default:
        return '';
    }
  }

  String _weekdayName(int day) => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day - 1];

  // Helper method to calculate sleep time in minutes, handling next-day logic
  int _calculateSleepMinutes(TimeOfDay sleepTime, TimeOfDay wakeTime) {
    int sleepHour = sleepTime.hour;
    int sleepMinute = sleepTime.minute;
    int wakeHour = wakeTime.hour;
    
    // If sleep time is earlier than wake time (e.g., 00:00 vs 06:00),
    // it means sleep time is the next day
    if (sleepHour < wakeHour || (sleepHour == wakeHour && sleepMinute <= wakeTime.minute)) {
      // Add 24 hours to treat it as next day
      return (sleepHour + 24) * 60 + sleepMinute;
    } else {
      // Same day
      return sleepHour * 60 + sleepMinute;
    }
  }

  List<Map<String, dynamic>> _createActionAnchors(Map<String, dynamic> action, int frequency) {
    List<Map<String, dynamic>> anchors = [];
    
    // Calculate time intervals based on frequency
    if (frequency > 1) {
      TimeOfDay originalTime = action['time'];
      int anchorMinutes = originalTime.hour * 60 + originalTime.minute;
      
      // Use actual sleep and wake times from user settings
      TimeOfDay currentSleepTime = bedTime;  // Use actual user bedtime
      TimeOfDay currentWakeTime = wakeTime;  // Use actual user wake time
      int sleepMinutes = _calculateSleepMinutes(currentSleepTime, currentWakeTime);
      
      // Calculate available time window from anchor to sleep
      int availableMinutes = sleepMinutes - anchorMinutes;
      
      // If there's not enough time until sleep, use a minimum 1-hour window
      if (availableMinutes < 60) {
        availableMinutes = 60;
      }
      
      // Divide the available time into equal intervals
      // For frequency=2: divide by 2 to get 2 equal intervals
      // For frequency=3: divide by 3 to get 3 equal intervals
      int intervalMinutes = frequency > 1 ? availableMinutes ~/ frequency : 0;
      
      for (int i = 0; i < frequency; i++) {
        int actionMinutes = anchorMinutes + (intervalMinutes * i);
        
        // Ensure we don't go past sleep time boundaries
        if (actionMinutes >= sleepMinutes) {
          // If we're past sleep time, cap it at sleep time minus 30 minutes
          actionMinutes = sleepMinutes - 30;
        }
        
        // Handle next-day wrap-around: if actionMinutes >= 1440 (24 hours), wrap to next day
        int displayHour = (actionMinutes ~/ 60) % 24;
        int displayMinute = actionMinutes % 60;
        
        // Ensure we don't go before wake time
        int wakeMinutes = currentWakeTime.hour * 60 + currentWakeTime.minute;
        if (actionMinutes < wakeMinutes) {
          actionMinutes = wakeMinutes;
          displayHour = currentWakeTime.hour;
          displayMinute = currentWakeTime.minute;
        }
        
        TimeOfDay timeOfDay = TimeOfDay(hour: displayHour, minute: displayMinute);
        
        anchors.add({
          ...action,
          'time': timeOfDay,
          'frequency': 1, // Each anchor has frequency 1
          'anchorIndex': i + 1, // 1-based indexing for display
          'totalAnchors': frequency,
          'originalFrequency': frequency, // Keep track of original frequency
        });
      }
    } else {
      anchors.add(action);
    }
    
    return anchors;
  }
}

// Meal Edit Dialog (Combined Name and Time)
class _MealEditDialog extends StatefulWidget {
  final String initialName;
  final TimeOfDay initialTime;
  final TimeOfDay wakeTime;
  final TimeOfDay bedTime;
  final bool isAddMode;
  
  _MealEditDialog({
    required this.initialName, 
    required this.initialTime,
    required this.wakeTime,
    required this.bedTime,
    this.isAddMode = false,
  });
  
  @override
  _MealEditDialogState createState() => _MealEditDialogState();
}

class _MealEditDialogState extends State<_MealEditDialog> {
  late TextEditingController _nameController;
  late TimeOfDay _selectedTime;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _selectedTime = widget.initialTime;
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  bool _isTimeValid(TimeOfDay time) {
    final timeMinutes = time.hour * 60 + time.minute;
    final wakeMinutes = widget.wakeTime.hour * 60 + widget.wakeTime.minute;
    final bedMinutes = widget.bedTime.hour * 60 + widget.bedTime.minute;
    
    // Handle next-day sleep time (e.g., sleep at 00:00 means next day)
    if (bedMinutes < wakeMinutes) {
      // Sleep time is next day - check if time is after wake OR before sleep (next day)
      return timeMinutes >= wakeMinutes || timeMinutes <= bedMinutes;
    } else {
      // Same day - normal validation
      return timeMinutes >= wakeMinutes && timeMinutes <= bedMinutes;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isTimeValid = _isTimeValid(_selectedTime);
    
    return AlertDialog(
      title: Text(widget.isAddMode ? 'Add Meal' : 'Edit Meal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Meal Name',
              hintText: 'e.g., Breakfast, Lunch, Dinner',
            ),
            autofocus: true,
          ),
          SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.access_time),
            title: Text('Time'),
            subtitle: Text(
              '${formatTimeCustom(context, _selectedTime)}${!isTimeValid ? ' (Outside wake-sleep hours)' : ''}',
              style: TextStyle(
                color: isTimeValid ? null : Colors.red,
              ),
            ),
            trailing: Icon(Icons.edit),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
              );
              if (time != null) {
                setState(() {
                  _selectedTime = time;
                });
              }
            },
          ),
          if (!isTimeValid)
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Meal time should be between wake time and sleep time',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        FilledButton(
          onPressed: isTimeValid && _nameController.text.isNotEmpty
            ? () => Navigator.pop(context, {
                'name': _nameController.text,
                'time': _selectedTime,
              })
            : null,
          child: Text('Save'),
        ),
      ],
    );
  }
}

// Action picker screen
class ActionPickerScreen extends StatefulWidget {
  final TimeOfDay wakeTime;
  final TimeOfDay bedTime;
  final List<Map<String, dynamic>>? existingActions; // Pass existing actions from timeline
  final bool isInitialSetup; // Distinguish between initial setup and regular action adding
  
  ActionPickerScreen({
    required this.wakeTime, 
    required this.bedTime, 
    this.existingActions,
    this.isInitialSetup = false, // Default to false for backward compatibility
  });
  
  @override
  _ActionPickerScreenState createState() => _ActionPickerScreenState();
}

class _ActionPickerScreenState extends State<ActionPickerScreen> {
  List<String> selectedActions = [];
  Map<String, Map<String, dynamic>> actionStates = {}; // Track time and frequency for each action
  String sortBy = 'time'; // Default: sort by Recommended Time, then 'actions', 'day'
  String timeSortOrder = 'morning'; // 'morning', 'afternoon', 'evening', 'all'
  String actionsSortOrder = 'a-z'; // 'a-z', 'z-a' (renamed from categorySortOrder)
  String daySortOrder = 'everyday'; // 'everyday', 'weekdays', 'day-offs'
  String? selectedCategory;
  String? selectedTimeOfDay;
  String? selectedDayOfWeek;
  String searchQuery = '';
  bool showSuggestions = false;
  List<String> searchSuggestions = [];
  
  @override
  void initState() {
    super.initState();
    
    print('DEBUG: ActionPickerScreen initState() called');
    print('DEBUG: existingActions = ${widget.existingActions}');
    print('DEBUG: existingActions length = ${widget.existingActions?.length ?? 0}');
    
    // Initialize selected actions from existing timeline actions
    if (widget.existingActions != null) {
      for (var action in widget.existingActions!) {
        String actionName = action['name'];
        print('DEBUG: Processing existing action: $actionName');
        if (!selectedActions.contains(actionName)) {
          selectedActions.add(actionName);
          print('DEBUG: Added $actionName to selectedActions');
        }
        // Store the state (time and frequency) for each action
        actionStates[actionName] = {
          'time': action['time'],
          'frequency': action['originalFrequency'] ?? action['frequency'] ?? 1,
        };
        
        // Add schedule items and custom actions to allActions if not already present
        if (action['category'] == 'Schedule' || action['category'] == 'Custom') {
          bool actionExists = allActions.any((a) => a['name'] == actionName);
          if (!actionExists) {
            allActions.add({
              'name': action['name'],
              'category': action['category'],
              'timeOfDay': 'All Day',
              'dayOfWeek': 'Daily',
              'time': action['time'],
              'frequency': action['frequency'] ?? 1,
            });
          }
        }
      }
    }
    
    print('DEBUG: ActionPickerScreen initialized with ${selectedActions.length} selected actions: $selectedActions');
    _loadActionsFromJson();
  }
  
  List<Map<String, dynamic>> allActions = [];
  bool isLoading = true;

  Future<void> _loadActionsFromJson() async {
    try {
      String jsonString = await DefaultAssetBundle.of(context).loadString('assets/data/free_routine_actions.json');
      List<dynamic> jsonData = json.decode(jsonString);
      
      setState(() {
        allActions = jsonData.map((item) => {
          'name': item['name'],
          'category': item['category'],
          'recommendedTimes': item['recommendedTimes'],
          'recommendedDays': item['recommendedDays'],
          'time': TimeOfDay(hour: 12, minute: 0), // Default time
          'frequency': 1, // Default frequency
        }).toList();
        isLoading = false;
      });
      
      print('DEBUG: Loaded ${allActions.length} actions from JSON');
    } catch (e) {
      print('DEBUG: Error loading actions from JSON: $e');
      // Fallback to minimal action set if JSON loading fails
      setState(() {
        allActions = [
          {'name': 'Drink a glass of water', 'category': 'health', 'time': TimeOfDay(hour: 6, minute: 35), 'frequency': 1},
          {'name': 'Quick walk', 'category': 'exercise', 'time': TimeOfDay(hour: 12, minute: 45), 'frequency': 1},
          {'name': 'Self time', 'category': 'personal', 'time': TimeOfDay(hour: 21, minute: 0), 'frequency': 1},
        ];
        isLoading = false;
      });
    }
  }

  List<String> get categories => allActions.map((a) => a['category'] as String).toSet().toList()..sort();

  void _updateSearchSuggestions(String query) {
    if (query.isEmpty || allActions.isEmpty) {
      setState(() {
        showSuggestions = false;
        searchSuggestions = [];
      });
      return;
    }
    
    final lowerQuery = query.toLowerCase();
    Set<String> suggestions = {};
    
    // Add matching action names and categories
    for (var action in allActions) {
      String name = action['name'] as String;
      String category = action['category'] as String;
      if (name.toLowerCase().contains(lowerQuery)) {
        suggestions.add(name);
      }
      if (category.toLowerCase().contains(lowerQuery)) {
        suggestions.add(category);
      }
    }
    
    setState(() {
      searchSuggestions = suggestions.take(5).toList(); // Limit to 5 suggestions
      showSuggestions = suggestions.isNotEmpty;
    });
  }

  List<Map<String, dynamic>> get filteredAndSortedActions {
    List<Map<String, dynamic>> filtered = allActions.where((action) {
      // Exclude schedule-type actions (configured only in Settings tab)
      if (action['category'] == 'Schedule') return false;
      
      bool matchesSearch = searchQuery.isEmpty || 
          action['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
          (action['category'] as String).toLowerCase().contains(searchQuery.toLowerCase());
      bool matchesCategory = selectedCategory == null || action['category'] == selectedCategory;
      bool matchesTime = selectedTimeOfDay == null || action['timeOfDay'] == selectedTimeOfDay;
      bool matchesDay = selectedDayOfWeek == null || action['dayOfWeek'] == selectedDayOfWeek;
      
      return matchesSearch && matchesCategory && matchesTime && matchesDay;
    }).toList();
    
    // Fix sorting logic with proper null checks and cycling priorities
    try {
      if (sortBy == 'actions') {
        filtered.sort((a, b) {
          if (actionsSortOrder == 'a-z') {
            return (a['name'] as String).compareTo(b['name'] as String);
          } else {
            return (b['name'] as String).compareTo(a['name'] as String);
          }
        });
      } else if (sortBy == 'time') {
        // Sort by recommended time with cycling priority
        Map<String, int> timeOrder = {};
        if (timeSortOrder == 'morning') {
          timeOrder = {'Morning': 1, 'Afternoon': 2, 'Evening': 3, 'All Day': 4};
        } else if (timeSortOrder == 'afternoon') {
          timeOrder = {'Afternoon': 1, 'Evening': 2, 'All Day': 3, 'Morning': 4};
        } else if (timeSortOrder == 'evening') {
          timeOrder = {'Evening': 1, 'All Day': 2, 'Morning': 3, 'Afternoon': 4};
        } else { // 'all'
          timeOrder = {'All Day': 1, 'Morning': 2, 'Afternoon': 3, 'Evening': 4};
        }
        
        filtered.sort((a, b) {
          int timeA = timeOrder[a['timeOfDay']] ?? 5;
          int timeB = timeOrder[b['timeOfDay']] ?? 5;
          if (timeA != timeB) return timeA.compareTo(timeB);
          // Secondary sort by actual time
          TimeOfDay timeOfDayA = a['time'] as TimeOfDay;
          TimeOfDay timeOfDayB = b['time'] as TimeOfDay;
          return (timeOfDayA.hour * 60 + timeOfDayA.minute).compareTo(timeOfDayB.hour * 60 + timeOfDayB.minute);
        });
      } else if (sortBy == 'day') {
        Map<String, int> dayOrder = {};
        if (daySortOrder == 'everyday') {
          dayOrder = {'Daily': 1, 'Weekdays': 2, 'Day-offs': 3};
        } else if (daySortOrder == 'weekdays') {
          dayOrder = {'Weekdays': 1, 'Daily': 2, 'Day-offs': 3};
        } else { // 'day-offs'
          dayOrder = {'Day-offs': 1, 'Daily': 2, 'Weekdays': 3};
        }
        filtered.sort((a, b) {
          int orderA = dayOrder[a['dayOfWeek'] as String] ?? 4;
          int orderB = dayOrder[b['dayOfWeek'] as String] ?? 4;
          return orderA.compareTo(orderB);
        });
      }
    } catch (e) {
      // Fallback to category sorting if there's any issue
      filtered.sort((a, b) => (a['category'] as String).compareTo(b['category'] as String));
    }
    
    // Priority: Selected actions go to top, maintaining sort order within each group
    List<Map<String, dynamic>> selectedItems = [];
    List<Map<String, dynamic>> unselectedItems = [];
    
    for (var action in filtered) {
      if (selectedActions.contains(action['name'])) {
        selectedItems.add(action);
      } else {
        unselectedItems.add(action);
      }
    }
    
    // Return selected items first, then unselected items
    return [...selectedItems, ...unselectedItems];
  }

  int _getNonScheduleActionCount() {
    return selectedActions.where((actionName) {
      final action = allActions.firstWhere(
        (a) => a['name'] == actionName,
        orElse: () => {'category': 'Custom'} // Default for custom actions
      );
      return action['category'] != 'Schedule';
    }).length;
  }

  void _editAction(Map<String, dynamic> action) async {
    // Create an action with current stored state if available
    Map<String, dynamic> actionWithState = Map.from(action);
    final storedState = actionStates[action['name']];
    if (storedState != null) {
      actionWithState['time'] = storedState['time'];
      actionWithState['frequency'] = storedState['frequency'];
    }
    
    final shouldAutoSelect = await showDialog<bool>(
      context: context,
      builder: (context) => _ActionEditDialog(
        action: actionWithState,
        wakeTime: widget.wakeTime,
        bedTime: widget.bedTime,
        onSave: (updatedAction) {
          setState(() {
            int index = allActions.indexWhere((a) => a['name'] == action['name']);
            if (index != -1) {
              allActions[index] = updatedAction;
            }
            
            // Update actionStates with the new time and frequency
            actionStates[action['name']] = {
              'time': updatedAction['time'],
              'frequency': updatedAction['frequency'],
            };
          });
        },
      ),
    );
    
    // Auto-select the action if it was edited and saved
    if (shouldAutoSelect == true) {
      final actionName = action['name'];
      setState(() {
        if (!selectedActions.contains(actionName)) {
          selectedActions.add(actionName);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Add some actions')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Add some actions'),
        // Allow back navigation during initial setup, but this is the final step
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar with suggestions
                Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Search actions',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        suffixIcon: searchQuery.isNotEmpty 
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  searchQuery = '';
                                  showSuggestions = false;
                                });
                              },
                            )
                          : null,
                      ),
                      onChanged: (value) {
                        setState(() => searchQuery = value);
                        _updateSearchSuggestions(value);
                      },
                    ),
                    // Search suggestions dropdown
                    if (showSuggestions && searchSuggestions.isNotEmpty)
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(maxHeight: 150),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
                          color: Colors.white,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: searchSuggestions.length,
                          itemBuilder: (context, index) {
                            String suggestion = searchSuggestions[index];
                            return ListTile(
                              dense: true,
                              title: Text(suggestion),
                              leading: Icon(Icons.search, size: 16),
                              onTap: () {
                                setState(() {
                                  searchQuery = suggestion;
                                  showSuggestions = false;
                                });
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 16),
                
                // Filter dropdowns
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        value: selectedCategory,
                        items: [
                          DropdownMenuItem(value: null, child: Text('All')),
                          ...categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))),
                        ],
                        onChanged: (value) => setState(() => selectedCategory = value),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Time',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        value: selectedTimeOfDay,
                        items: [
                          DropdownMenuItem(value: null, child: Text('All')),
                          DropdownMenuItem(value: 'Morning', child: Text('Morning')),
                          DropdownMenuItem(value: 'Noon', child: Text('Noon')),
                          DropdownMenuItem(value: 'Afternoon', child: Text('Afternoon')),
                          DropdownMenuItem(value: 'Evening', child: Text('Evening')),
                          DropdownMenuItem(value: 'Night', child: Text('Night')),
                          // Use value 'All Day' to match action data entries that use 'All Day'
                          DropdownMenuItem(value: 'All Day', child: Text('Any time')),
                        ],
                        onChanged: (value) => setState(() => selectedTimeOfDay = value),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Day',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        value: selectedDayOfWeek,
                        items: [
                          DropdownMenuItem(value: null, child: Text('All')),
                          DropdownMenuItem(value: 'Weekdays', child: Text('Weekdays')),
                          DropdownMenuItem(value: 'Day-offs', child: Text('Day-offs')),
                          DropdownMenuItem(value: 'Daily', child: Text('Everyday')),
                        ],
                        onChanged: (value) => setState(() => selectedDayOfWeek = value),
                      ),
                    ),
                    SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          selectedCategory = null;
                          selectedTimeOfDay = null;
                          selectedDayOfWeek = null;
                          searchQuery = '';
                          showSuggestions = false;
                          searchSuggestions = [];
                        });
                      },
                      icon: Icon(Icons.clear),
                      label: Text('Clear'),
                    ),
                  ],
                ),
                
                // Sort chips with cycling indicators
                SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sort_by_alpha, size: 16),
                          SizedBox(width: 4),
                          Text('Actions'),
                          if (sortBy == 'actions') ...[
                            SizedBox(width: 4),
                            Text(
                              actionsSortOrder == 'a-z' ? '(A-Z)' : '(Z-A)',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                      selected: sortBy == 'actions',
                      onSelected: (selected) {
                        setState(() {
                          if (sortBy == 'actions') {
                            // Cycle through actions sort orders
                            actionsSortOrder = actionsSortOrder == 'a-z' ? 'z-a' : 'a-z';
                          } else {
                            sortBy = 'actions';
                            actionsSortOrder = 'a-z'; // Reset to default
                          }
                        });
                      },
                    ),
                    FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time, size: 16),
                          SizedBox(width: 4),
                          Text('Time'),
                          if (sortBy == 'time') ...[
                            SizedBox(width: 4),
                            Text(
                              timeSortOrder == 'morning' ? '(AM)' :
                              timeSortOrder == 'afternoon' ? '(PM)' :
                              timeSortOrder == 'evening' ? '(EVE)' : '(ALL)',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                      selected: sortBy == 'time',
                      onSelected: (selected) {
                        setState(() {
                          if (sortBy == 'time') {
                            // Cycle through time sort orders: morning → afternoon → evening → all → morning
                            if (timeSortOrder == 'morning') {
                              timeSortOrder = 'afternoon';
                            } else if (timeSortOrder == 'afternoon') {
                              timeSortOrder = 'evening';
                            } else if (timeSortOrder == 'evening') {
                              timeSortOrder = 'all';
                            } else {
                              timeSortOrder = 'morning';
                            }
                          } else {
                            sortBy = 'time';
                            timeSortOrder = 'morning'; // Reset to default
                          }
                        });
                      },
                    ),
                    FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today, size: 16),
                          SizedBox(width: 4),
                          Text('Day'),
                          if (sortBy == 'day') ...[
                            SizedBox(width: 4),
                            Text(
                              daySortOrder == 'everyday' ? '(Everyday)' : 
                              daySortOrder == 'weekdays' ? '(Weekdays)' : '(Day-offs)',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                      selected: sortBy == 'day',
                      onSelected: (selected) {
                        setState(() {
                          if (sortBy == 'day') {
                            // Cycle through day sort orders: everyday → weekdays → day-offs → everyday
                            if (daySortOrder == 'everyday') {
                              daySortOrder = 'weekdays';
                            } else if (daySortOrder == 'weekdays') {
                              daySortOrder = 'day-offs';
                            } else {
                              daySortOrder = 'everyday';
                            }
                          } else {
                            sortBy = 'day';
                            daySortOrder = 'everyday'; // Reset to default
                          }
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              itemCount: filteredAndSortedActions.length,
              itemBuilder: (context, index) {
                final action = filteredAndSortedActions[index];
                final actionName = action['name'];
                final isSelected = selectedActions.contains(actionName);
                
                return Card(
                  margin: EdgeInsets.only(bottom: 8, left: 16, right: 16),
                  child: InkWell(
                    onTap: () => _editAction(action),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedActions.add(actionName);
                                } else {
                                  selectedActions.remove(actionName);
                                  actionStates.remove(actionName); // Remove stored state when unchecked
                                }
                              });
                            },
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  actionName,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.category, size: 14, color: Colors.grey[600]),
                                    SizedBox(width: 4),
                                    Text('${action['category']}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                    SizedBox(width: 12),
                                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                    SizedBox(width: 4),
                                    Text(
                                      isSelected && actionStates.containsKey(actionName) 
                                        ? '${formatTimeCustom(context, actionStates[actionName]!['time'])}' 
                                        : '${formatTimeCustom(context, action['time'])}', 
                                      style: TextStyle(
                                        color: isSelected ? Colors.blue[600] : Colors.grey[600], 
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      )
                                    ),
                                    SizedBox(width: 12),
                                    Icon(Icons.repeat, size: 14, color: Colors.grey[600]),
                                    SizedBox(width: 4),
                                    Text(
                                      isSelected && actionStates.containsKey(actionName) 
                                        ? '${actionStates[actionName]!['frequency']}x/day' 
                                        : '${action['frequency']}x/day', 
                                      style: TextStyle(
                                        color: isSelected ? Colors.blue[600] : Colors.grey[600], 
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      )
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    _getRecommendationIcon(
                                      action['recommendedTimes']?.join(', ') ?? 'Anytime', 
                                      action['recommendedDays']?.join(', ') ?? 'Any day'
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(child: Text(
                                      '${action['recommendedTimes']?.join(', ') ?? 'Anytime'} • ${action['recommendedDays']?.join(', ') ?? 'Any day'}', 
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    )),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Removed edit icon - tap anywhere on the card to edit
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Done button
          Padding(
            padding: EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: selectedActions.isNotEmpty 
                ? () {
                    print('DEBUG: ActionPickerScreen Done clicked with ${selectedActions.length} selected actions');
                    print('DEBUG: selectedActions = $selectedActions');
                    
                    // Convert selected actions to routine actions with their configured times
                    List<Map<String, dynamic>> routineActions = [];
                    for (String actionName in selectedActions) {
                      // First try to find in existing actions to preserve original category
                      Map<String, dynamic>? existingAction;
                      if (widget.existingActions != null) {
                        try {
                          existingAction = widget.existingActions!.firstWhere(
                            (a) => a['name'] == actionName,
                          );
                        } catch (e) {
                          existingAction = null;
                        }
                      }
                      
                      // If not found in existing, try allActions (JSON data)
                      final action = existingAction ?? allActions.firstWhere(
                        (a) => a['name'] == actionName,
                        orElse: () => {
                          'name': actionName,
                          'category': 'Custom',
                          'time': TimeOfDay(hour: 12, minute: 0),
                          'frequency': 1,
                        }
                      );
                      
                      // Use stored state if available, otherwise use default from found action
                      final storedState = actionStates[actionName];
                      routineActions.add({
                        'name': action['name'],
                        'time': storedState?['time'] ?? action['time'],
                        'category': action['category'],
                        'frequency': storedState?['frequency'] ?? action['frequency'],
                      });
                    }
                    
                    print('DEBUG: Returning ${routineActions.length} actions from ActionPickerScreen');
                    for (var action in routineActions) {
                      print('DEBUG: Returning action: ${action['name']} at ${action['time']}');
                    }
                    
                    print('DEBUG: About to call Navigator.pop with routineActions: $routineActions');
                    // Return the selected actions to the calling screen
                    Navigator.pop(context, routineActions);
                  }
                : null, // Disabled when no actions selected
              icon: Icon(widget.isInitialSetup ? Icons.save : Icons.check),
              label: Text(widget.isInitialSetup 
                ? 'Create Routine (${_getNonScheduleActionCount()} selected)'
                : 'Done (${_getNonScheduleActionCount()} selected)'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getRecommendationIcon(String timeOfDay, String dayOfWeek) {
    if (timeOfDay == 'Morning') {
      return Icon(Icons.wb_sunny, color: Colors.orange, size: 20);
    } else if (timeOfDay == 'Afternoon') {
      return Icon(Icons.wb_cloudy, color: Colors.blue, size: 20);
    } else if (timeOfDay == 'Evening') {
      return Icon(Icons.nights_stay, color: Colors.indigo, size: 20);
    }
    
    if (dayOfWeek == 'Day-offs') {
      return Icon(Icons.weekend, color: Colors.green, size: 20);
    } else if (dayOfWeek == 'Weekdays') {
      return Icon(Icons.work, color: Colors.purple, size: 20);
    }
    
    return Icon(Icons.schedule, color: Colors.grey, size: 20);
  }
}

// Action edit dialog
class _ActionEditDialog extends StatefulWidget {
  final Map<String, dynamic> action;
  final Function(Map<String, dynamic>) onSave;
  final TimeOfDay wakeTime;
  final TimeOfDay bedTime;
  
  _ActionEditDialog({
    required this.action, 
    required this.onSave,
    required this.wakeTime,
    required this.bedTime,
  });
  
  @override
  _ActionEditDialogState createState() => _ActionEditDialogState();
}

class _ActionEditDialogState extends State<_ActionEditDialog> {
  late TimeOfDay selectedTime;
  late int frequency;
  
  @override
  void initState() {
    super.initState();
    selectedTime = widget.action['time'];
    frequency = widget.action['frequency'];
  }
  
  bool _isTimeValid(TimeOfDay time) {
    final timeMinutes = time.hour * 60 + time.minute;
    final wakeMinutes = widget.wakeTime.hour * 60 + widget.wakeTime.minute;
    final bedMinutes = widget.bedTime.hour * 60 + widget.bedTime.minute;
    
    // Handle next-day sleep time (e.g., sleep at 00:00 means next day)
    if (bedMinutes < wakeMinutes) {
      // Sleep time is next day - check if time is after wake OR before sleep (next day)
      return timeMinutes >= wakeMinutes || timeMinutes <= bedMinutes;
    } else {
      // Same day - normal validation
      return timeMinutes >= wakeMinutes && timeMinutes <= bedMinutes;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Action'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.action['name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          
          ListTile(
            leading: Icon(Icons.access_time),
            title: Text('Time'),
            subtitle: Text(
              '${formatTimeCustom(context, selectedTime)}${!_isTimeValid(selectedTime) ? ' (Outside wake-sleep hours)' : ''}',
              style: TextStyle(
                color: _isTimeValid(selectedTime) ? null : Colors.red,
              ),
            ),
            onTap: () async {
              final time = await showTimePicker(context: context, initialTime: selectedTime);
              if (time != null) {
                setState(() => selectedTime = time);
              }
            },
          ),
          if (!_isTimeValid(selectedTime))
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Action time should be between wake time and sleep time',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          
          ListTile(
            leading: Icon(Icons.repeat),
            title: Text('Frequency'),
            subtitle: Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                IconButton(
                  onPressed: frequency > 1 ? () {
                    setState(() {
                      frequency--;
                    });
                  } : null,
                  icon: Icon(Icons.remove_circle_outline),
                ),
                Container(
                  width: 60,
                  child: Center(
                    child: Text(
                      '$frequency',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: frequency < 10 ? () {
                    setState(() {
                      frequency++;
                    });
                  } : null,
                  icon: Icon(Icons.add_circle_outline),
                ),
                // Fix grammar: "1 time per day" vs "x times per day"
                Text(frequency == 1 ? ' 1 time per day' : ' $frequency times per day'),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isTimeValid(selectedTime) ? () {
            final updatedAction = Map<String, dynamic>.from(widget.action);
            updatedAction['time'] = selectedTime;
            updatedAction['frequency'] = frequency;
            widget.onSave(updatedAction);
            Navigator.pop(context, true); // Return true to indicate auto-select
          } : null,
          child: Text('Save'),
        ),
      ],
    );
  }
}

// ============================================================================
// MAIN HOME SCREEN
// ============================================================================

// Main home screen with tabs
class HomeScreen extends StatefulWidget {
  final int initialTabIndex;
  final List<Map<String, dynamic>>? routineActions;
  final bool isCasualTemplate;
  final TimeOfDay? wakeTime;
  final TimeOfDay? bedTime;
  final List<TimeOfDay>? mealTimes;
  final List<String>? mealNames;
  final bool? repeatWorkdaysRoutine;
  final bool? stopRoutineOnDayOffs;
  final Set<int>? dayOffs;
  final String? scheduleMode;
  final bool isFromInitialSetup; // New parameter to disable back navigation
  
  HomeScreen({
    this.initialTabIndex = 0,
    this.routineActions,
    this.isCasualTemplate = false,
    this.wakeTime,
    this.bedTime,
    this.mealTimes,
    this.mealNames,
    this.repeatWorkdaysRoutine,
    this.stopRoutineOnDayOffs,
    this.dayOffs,
    this.scheduleMode,
    this.isFromInitialSetup = false, // Default to false for existing usage
  });
  
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int currentIndex;
  late TimeOfDay wakeTime;
  late TimeOfDay bedTime;
  late List<TimeOfDay> mealTimes;
  late List<String> mealNames;
  
  // Schedule management state
  Timer? _scheduleTimer;
  Map<String, List<Map<String, dynamic>>> routineData = {}; // Date -> Actions
  bool hasCheckedWakeTimeToday = false;
  
  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialTabIndex;
    // Initialize settings with passed values or defaults
    wakeTime = widget.wakeTime ?? TimeOfDay(hour: 6, minute: 0);
    bedTime = widget.bedTime ?? TimeOfDay(hour: 0, minute: 0);
    mealTimes = List.from(widget.mealTimes ?? [
      TimeOfDay(hour: 8, minute: 0),   // Breakfast
      TimeOfDay(hour: 12, minute: 0),  // Lunch  
      TimeOfDay(hour: 19, minute: 0),  // Dinner
    ]);
    mealNames = List.from(widget.mealNames ?? ['Breakfast', 'Lunch', 'Dinner']);
    
    // Clear old routine data to fix repeat routine issue
    _clearOldRoutineData();
    
    // Initialize schedule checking
    _initializeScheduleLogic();
  }
  
  @override
  void dispose() {
    _scheduleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('RoutineBuddy'),
        automaticallyImplyLeading: !widget.isFromInitialSetup, // Hide back button if coming from initial setup
      ),
      body: IndexedStack(
        index: currentIndex,
        children: [
          TemplatesTab(),
          RoutineTab(
            routineActions: widget.routineActions,
            isCasualTemplate: widget.isCasualTemplate,
            wakeTime: wakeTime,
            bedTime: bedTime,
            mealTimes: mealTimes,
            mealNames: mealNames,
            scheduleMode: widget.scheduleMode ?? 'Weekly',
            stopRoutineOnDayOffs: widget.stopRoutineOnDayOffs ?? false,
            dayOffs: widget.dayOffs ?? <int>{},
            repeatWorkdaysRoutine: widget.repeatWorkdaysRoutine ?? true,
          ),
          SettingsTab(
            wakeTime: wakeTime,
            bedTime: bedTime,
            mealTimes: mealTimes,
            mealNames: mealNames,
            isCasualTemplate: widget.isCasualTemplate,
            stopRoutineOnDayOffs: widget.stopRoutineOnDayOffs,
            dayOffs: widget.dayOffs,
            scheduleMode: widget.scheduleMode,
            repeatWorkdaysRoutine: widget.repeatWorkdaysRoutine,
            onWakeTimeChanged: (time) => setState(() => wakeTime = time),
            onBedTimeChanged: (time) => setState(() => bedTime = time),
            onMealTimesChanged: (times) => setState(() => mealTimes = times),
            onMealNamesChanged: (names) => setState(() => mealNames = names),
            onRepeatWorkdaysRoutineChanged: (value) {
              print('DEBUG: Repeat weekdays routine changed to: $value');
              // Refresh the routine view to reflect any changes
              if (currentIndex == 1) { // If we're on the routine tab
                setState(() {
                  // This will trigger a rebuild of the RoutineTab which will reload actions
                });
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => setState(() => currentIndex = index),
        destinations: [
          NavigationDestination(icon: Icon(Icons.view_list), label: 'Templates'),
          NavigationDestination(icon: Icon(Icons.today), label: 'Routine'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
  
  // Method to clear old routine data that might have incorrect dayOfWeek values
  void _clearOldRoutineData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final version = prefs.getInt('routine_data_version') ?? 0;
      
      // If data version is old or doesn't exist, clear routine data
      // BUT only if we haven't already set up actions in this session
      if (version < 3 && _RoutineTabState.daySpecificActions.isEmpty) {
        await prefs.remove('routine_actions');
        await prefs.remove('routine_data');
        await prefs.setInt('routine_data_version', 3);
        print('Cleared old routine data to implement forward-only repeat logic');
      } else if (version < 3) {
        // Version is old but we have actions - just update version without clearing
        await prefs.setInt('routine_data_version', 3);
        print('Updated routine data version without clearing existing actions');
      }
    } catch (e) {
      print('Error clearing old routine data: $e');
    }
  }
  
  // ============================================================================
  // SCHEDULE MODE LOGIC IMPLEMENTATION
  // ============================================================================
  
  void _initializeScheduleLogic() {
    // Set up periodic checking for schedule anchors
    _scheduleTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _checkScheduleAnchors();
    });
    
    // Check immediately on startup
    _checkScheduleAnchors();
  }
  
  void _checkScheduleAnchors() {
    final now = DateTime.now();
    final scheduleMode = widget.scheduleMode ?? 'Weekly';
    
    // Check for wake time notifications (Daily mode only)
    if (scheduleMode == 'Daily') {
      _checkWakeTimeNotification(now);
    }
    
    // Check for routine planning anchors
    _checkRoutinePlanningAnchors(now, scheduleMode);
    
    // Check and apply carry-over rules
    _checkAndApplyCarryOverRule();
  }
  
  void _checkWakeTimeNotification(DateTime now) {
    // Only check once per day
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (hasCheckedWakeTimeToday && routineData.containsKey(today)) return;
    
    // Check if it's wake time and today's routine is blank
    final currentTime = TimeOfDay.fromDateTime(now);
    final wakeMinutes = wakeTime.hour * 60 + wakeTime.minute;
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    
    if (currentMinutes >= wakeMinutes && currentMinutes <= wakeMinutes + 30) {
      final repeatWorkdays = widget.repeatWorkdaysRoutine ?? false;
      
      if (!_isRoutineFilledForDate(today) && !repeatWorkdays) {
        hasCheckedWakeTimeToday = true;
        _showWakeTimeNotification();
      } else if (repeatWorkdays) {
        // Auto-carry yesterday's routine
        _carryOverYesterdaysRoutine(today);
      }
    }
  }
  
  void _checkRoutinePlanningAnchors(DateTime now, String scheduleMode) {
    final currentTime = TimeOfDay.fromDateTime(now);
    final reviewTime = _getReviewTime(); // 30 minutes before bedtime
    
    if (_isTimeMatch(currentTime, reviewTime)) {
      switch (scheduleMode) {
        case 'Weekly':
          if (_isLastWorkday(now)) {
            _handleWeeklyReview();
          }
          break;
        case 'Daily':
          _handleDailyReview();
          break;
        case 'Repeat':
          // No anchor needed for repeat mode
          break;
      }
    }
  }
  
  TimeOfDay _getReviewTime() {
    // 30 minutes before bedtime
    int bedMinutes = bedTime.hour * 60 + bedTime.minute;
    int reviewMinutes = bedMinutes - 30;
    
    if (reviewMinutes < 0) {
      reviewMinutes += 1440; // Handle next day
    }
    
    return TimeOfDay(hour: reviewMinutes ~/ 60, minute: reviewMinutes % 60);
  }
  
  bool _isTimeMatch(TimeOfDay current, TimeOfDay target) {
    return current.hour == target.hour && current.minute == target.minute;
  }
  
  bool _isLastWorkday(DateTime date) {
    final dayOffs = widget.dayOffs ?? <int>{};
    final stopOnDayOffs = widget.stopRoutineOnDayOffs ?? false;
    
    if (!stopOnDayOffs) {
      // If not stopping on day-offs, last workday is Sunday (7)
      return date.weekday == 7;
    } else {
      // Find the last day that's not a day-off
      for (int i = 7; i >= 1; i--) {
        if (!dayOffs.contains(i)) {
          return date.weekday == i;
        }
      }
      return false; // Shouldn't happen
    }
  }
  
  bool _isRoutineFilledForDate(String date) {
    return routineData.containsKey(date) && routineData[date]!.isNotEmpty;
  }
  
  void _handleWeeklyReview() {
    final nextWeekStart = _getNextWeekStart();
    final nextWeekKey = _getWeekKey(nextWeekStart);
    
    if (_isWeekRoutineBlank(nextWeekKey)) {
      _showWeeklyPlanningDialog();
    } else {
      _openNextWeekTimeline();
    }
  }
  
  void _handleDailyReview() {
    final tomorrow = DateTime.now().add(Duration(days: 1));
    final tomorrowKey = _getDateKey(tomorrow);
    
    if (!_isRoutineFilledForDate(tomorrowKey)) {
      _showDailyPlanningDialog();
    } else {
      _openTomorrowTimeline();
    }
  }
  
  DateTime _getNextWeekStart() {
    final now = DateTime.now();
    final daysUntilMonday = (8 - now.weekday) % 7;
    return now.add(Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday));
  }
  
  String _getWeekKey(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return '${monday.year}-W${((monday.day - 1) ~/ 7) + 1}';
  }
  
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  bool _isWeekRoutineBlank(String weekKey) {
    // Check if any day of the week has routines
    final startDate = _getWeekStartDate(weekKey);
    for (int i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      final dateKey = _getDateKey(date);
      if (_isRoutineFilledForDate(dateKey)) {
        return false;
      }
    }
    return true;
  }
  
  DateTime _getWeekStartDate(String weekKey) {
    // Parse week key and return Monday of that week
    final parts = weekKey.split('-W');
    final year = int.parse(parts[0]);
    // Simplified - you'd need proper week calculation here
    return DateTime(year, 1, 1); // Placeholder
  }
  
  void _carryOverYesterdaysRoutine(String today) {
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    final yesterdayKey = _getDateKey(yesterday);
    
    if (_isRoutineFilledForDate(yesterdayKey)) {
      setState(() {
        routineData[today] = List.from(routineData[yesterdayKey]!);
      });
    }
  }
  
  // ============================================================================
  // DIALOG IMPLEMENTATIONS
  // ============================================================================
  
  void _showWakeTimeNotification() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("You don't have any actions planned for today. Want to set them up now?"),
        action: SnackBarAction(
          label: 'Plan now',
          onPressed: () => _openTodayPlanning(),
        ),
        duration: Duration(seconds: 8),
      ),
    );
  }
  
  void _showWeeklyPlanningDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Plan Next Week'),
        content: Text('Your next week\'s routine is currently blank. How would you like to plan it?'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _addActionsToWeek();
            },
            icon: Icon(Icons.add),
            label: Text('Add actions to the days'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _duplicatePreviousRoutine();
            },
            icon: Icon(Icons.content_copy),
            label: Text('Duplicate previous routine'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _applyRoutineTemplate();
            },
            icon: Icon(Icons.folder),
            label: Text('Apply a routine template'),
          ),
        ],
      ),
    );
  }
  
  void _showDailyPlanningDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Plan Tomorrow'),
        content: Text('Your tomorrow\'s routine is currently blank. Let\'s plan it now:'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _addActionsToDay();
            },
            icon: Icon(Icons.add),
            label: Text('Add actions to the day'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Duplication removed - each day is independent
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Each day has its own independent routine. Please add actions directly to each day.'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: Icon(Icons.info),
            label: Text('Each day is independent'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _applyRoutineTemplate();
            },
            icon: Icon(Icons.folder),
            label: Text('Apply a routine template'),
          ),
        ],
      ),
    );
  }
  
  // ============================================================================
  // AUTOMATIC CARRY-OVER RULE (ALL MODES)
  // ============================================================================
  
  void _checkAndApplyCarryOverRule() {
    final now = DateTime.now();
    final scheduleMode = widget.scheduleMode ?? 'Weekly';
    
    switch (scheduleMode) {
      case 'Weekly':
        _checkWeeklyCarryOver(now);
        break;
      case 'Daily':
        _checkDailyCarryOver(now);
        break;
      case 'Repeat':
        _checkRepeatModeCarryOver(now);
        break;
    }
  }
  
  void _checkWeeklyCarryOver(DateTime now) {
    // Check if we're at the start of a new week (Monday 00:05)
    if (now.weekday == 1 && now.hour == 0 && now.minute == 5) {
      final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
      final nextWeekStart = currentWeekStart.add(Duration(days: 7));
      
      // Check if next week is blank and no user edits were made
      if (_isWeekBlank(nextWeekStart) && !_hasUserMadeEditsThisWeek()) {
        _autoCarryLastWeekRoutine(nextWeekStart);
      }
    }
  }
  
  void _checkDailyCarryOver(DateTime now) {
    // Check if tomorrow is blank and it's past the review time
    final tomorrow = now.add(Duration(days: 1));
    final tomorrowKey = _getDateKey(tomorrow);
    final reviewTime = _getReviewTime();
    final currentTime = TimeOfDay.fromDateTime(now);
    
    if (!_isRoutineFilledForDate(tomorrowKey) && 
        _isTimePast(currentTime, reviewTime) &&
        !_hasUserMadeEditsToday()) {
      _autoCarryTodaysRoutine(tomorrow);
    }
  }
  
  void _checkRepeatModeCarryOver(DateTime now) {
    // For repeat mode, auto-carry happens at 00:05 Monday if no new plan is set
    if (now.weekday == 1 && now.hour == 0 && now.minute == 5) {
      final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
      
      if (_isWeekBlank(currentWeekStart)) {
        final lastWeekStart = currentWeekStart.subtract(Duration(days: 7));
        _autoCarryLastWeekRoutine(currentWeekStart, sourceWeek: lastWeekStart);
      }
    }
  }
  
  bool _isWeekBlank(DateTime weekStart) {
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final dateKey = _getDateKey(date);
      if (_isRoutineFilledForDate(dateKey)) {
        return false;
      }
    }
    return true;
  }
  
  bool _hasUserMadeEditsThisWeek() {
    // Track if user has made any manual edits this week
    // This would be stored in app state/preferences
    return false; // Placeholder - implement based on user interaction tracking
  }
  
  bool _hasUserMadeEditsToday() {
    // Track if user has made any manual edits today
    return false; // Placeholder - implement based on user interaction tracking
  }
  
  bool _isTimePast(TimeOfDay current, TimeOfDay target) {
    final currentMinutes = current.hour * 60 + current.minute;
    final targetMinutes = target.hour * 60 + target.minute;
    return currentMinutes > targetMinutes;
  }
  
  void _autoCarryLastWeekRoutine(DateTime targetWeekStart, {DateTime? sourceWeek}) {
    final source = sourceWeek ?? targetWeekStart.subtract(Duration(days: 7));
    
    setState(() {
      for (int i = 0; i < 7; i++) {
        final sourceDate = source.add(Duration(days: i));
        final targetDate = targetWeekStart.add(Duration(days: i));
        final sourceKey = _getDateKey(sourceDate);
        final targetKey = _getDateKey(targetDate);
        
        if (_isRoutineFilledForDate(sourceKey)) {
          routineData[targetKey] = List.from(routineData[sourceKey]!);
        }
      }
    });
    
    // Show notification that routine was auto-carried
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Last week\'s routine has been automatically carried forward.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
  
  void _autoCarryTodaysRoutine(DateTime targetDate) {
    final today = DateTime.now();
    final todayKey = _getDateKey(today);
    final targetKey = _getDateKey(targetDate);
    
    if (_isRoutineFilledForDate(todayKey)) {
      setState(() {
        routineData[targetKey] = List.from(routineData[todayKey]!);
      });
      
      // Show notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Today\'s routine has been carried forward to tomorrow.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  // ============================================================================
  // ACTION IMPLEMENTATIONS
  // ============================================================================
  
  void _openTodayPlanning() {
    setState(() => currentIndex = 1); // Switch to Routine tab
  }
  
  void _openNextWeekTimeline() {
    // Open next week's timeline in review & edit mode
    setState(() => currentIndex = 1);
  }
  
  void _openTomorrowTimeline() {
    // Open tomorrow's timeline in review & edit mode
    setState(() => currentIndex = 1);
  }
  
  void _addActionsToWeek() {
    // Navigate to action picker for week planning
    setState(() => currentIndex = 1);
  }
  
  void _addActionsToDay() {
    // Navigate to action picker for day planning
    setState(() => currentIndex = 1);
  }
  
  void _duplicatePreviousRoutine() {
    // Copy most recent 7 days to next week
    final nextWeekStart = _getNextWeekStart();
    final previousWeekStart = nextWeekStart.subtract(Duration(days: 7));
    
    setState(() {
      for (int i = 0; i < 7; i++) {
        final sourceDate = previousWeekStart.add(Duration(days: i));
        final targetDate = nextWeekStart.add(Duration(days: i));
        final sourceKey = _getDateKey(sourceDate);
        final targetKey = _getDateKey(targetDate);
        
        if (_isRoutineFilledForDate(sourceKey)) {
          routineData[targetKey] = List.from(routineData[sourceKey]!);
        }
      }
    });
  }
  
  void _applyRoutineTemplate() {
    // Navigate to template selection
    setState(() => currentIndex = 0);
  }
}

// Templates tab
class TemplatesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Color(0xFF0FA3A5), child: Icon(Icons.favorite, color: Colors.white)),
            title: Text('The Casual'),
            subtitle: Text('Balanced daily routine'),
            trailing: Text('FREE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CasualPreviewScreen())),
          ),
        ),
        Card(
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.business, color: Colors.white)),
            title: Text('The Professional'),
            subtitle: Text('Work-focused routine'),
            trailing: Icon(Icons.lock, color: Colors.grey),
          ),
        ),
        Card(
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Colors.purple, child: Icon(Icons.fitness_center, color: Colors.white)),
            title: Text('The Athlete'),
            subtitle: Text('Fitness-first routine'),
            trailing: Icon(Icons.lock, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}

// Routine tab
class RoutineTab extends StatefulWidget {
  final List<Map<String, dynamic>>? routineActions;
  final bool isCasualTemplate;
  final TimeOfDay? wakeTime;
  final TimeOfDay? bedTime;
  final List<TimeOfDay>? mealTimes;
  final List<String>? mealNames;
  final String scheduleMode;
  final bool stopRoutineOnDayOffs;
  final Set<int> dayOffs;
  final bool repeatWorkdaysRoutine;
  
  RoutineTab({
    this.routineActions, 
    this.isCasualTemplate = false,
    this.wakeTime,
    this.bedTime,
    this.mealTimes,
    this.mealNames,
    this.scheduleMode = 'Weekly',
    this.stopRoutineOnDayOffs = false,
    this.dayOffs = const <int>{},
    this.repeatWorkdaysRoutine = false,
  });

  @override
  _RoutineTabState createState() => _RoutineTabState();
}

class _RoutineTabState extends State<RoutineTab> {
  late List<Map<String, dynamic>> displayActions;
  late String headerText;
  late DateTime currentTime;
  late DateTime selectedDate;
  
  // INDEPENDENT DAY STORAGE: Each day stores its own actions
  static Map<String, List<Map<String, dynamic>>> daySpecificActions = {};
  
  // COPIED ACTIONS TRACKING: Track which actions were copied via repeat weekdays
  // Key: dayKey, Value: Set of action names that were copied (not manually added)
  static Map<String, Set<String>> copiedActions = {};

  @override
  void initState() {
    super.initState();
    currentTime = DateTime.now();
    selectedDate = DateTime.now(); // Start with today
    _initializeDisplayActions();
    
    // Update current time every minute
    Timer.periodic(Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          currentTime = DateTime.now();
        });
      }
    });
  }

  void _initializeDisplayActions() {
    // Generate day key for storage (e.g., "2025-08-18")
    String dayKey = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    
    // DEBUG: Print initialization details
    print('DEBUG: _initializeDisplayActions called for $dayKey');
    print('DEBUG: daySpecificActions contains: ${daySpecificActions.keys.toList()}');
    if (daySpecificActions.containsKey(dayKey)) {
      print('DEBUG: Found ${daySpecificActions[dayKey]!.length} stored actions for $dayKey');
    }
    
    // Start fresh with display actions only (but keep storage intact)
    displayActions = [];
    
    if (widget.isCasualTemplate) {
      // CASUAL TEMPLATE: Show day-specific actions for each day
      if (!daySpecificActions.containsKey(dayKey)) {
        // Filter actions for current day of week
        final currentWeekday = selectedDate.weekday; // 1=Monday, 7=Sunday
        final dayActions = getCasualTemplateActions()
            .where((action) => action['dayOfWeek'] == currentWeekday)
            .map((action) => Map<String, dynamic>.from(action))
            .toList();
        
        daySpecificActions[dayKey] = dayActions;
        print('DEBUG: Loaded ${dayActions.length} casual template actions for ${_getDayName(currentWeekday)} ($dayKey)');
      }
      
      // Load user actions for this specific day
      if (daySpecificActions.containsKey(dayKey)) {
        for (var action in daySpecificActions[dayKey]!) {
          // Add all actions from storage for preview (including schedule items)
          displayActions.add(Map<String, dynamic>.from(action));
        }
      }
    } else {
      // INDEPENDENT DAY SYSTEM: Load user actions for this specific day
      
      // FIRST-TIME SETUP: Only apply when coming from ManualSetupScreen for the very first time
      if (widget.routineActions != null && 
          widget.routineActions!.isNotEmpty && 
          daySpecificActions.isEmpty && 
          !daySpecificActions.containsKey(dayKey)) {
        print('DEBUG: First-time setup detected - using widget.routineActions with ${widget.routineActions!.length} actions');
        print('DEBUG: This is the initial setup day: $dayKey');
        
        // Extract user actions (non-schedule items) from widget.routineActions
        // These are already processed anchor actions from ManualSetupScreen
        List<Map<String, dynamic>> userActionsFromFirstTime = widget.routineActions!
            .where((action) => action['isScheduleTime'] != true)
            .map((action) => Map<String, dynamic>.from(action))
            .toList();
        
        print('DEBUG: First-time user actions with times:');
        for (var action in userActionsFromFirstTime) {
          final time = action['time'] as TimeOfDay?;
          final name = action['name'] ?? 'Unknown';
          final anchor = action['anchorIndex'] ?? 1;
          final total = action['totalAnchors'] ?? 1;
          print('DEBUG: - $name at ${time?.hour ?? 0}:${(time?.minute ?? 0).toString().padLeft(2, '0')} (anchor $anchor/$total)');
        }
        
        // Save to day storage for future visits
        daySpecificActions[dayKey] = userActionsFromFirstTime;
        
        // Apply repeat weekdays logic for initial setup too
        final repeatWorkdays = widget.repeatWorkdaysRoutine;
        print('DEBUG: Initial setup - checking repeat weekdays: $repeatWorkdays');
        if (repeatWorkdays) {
          final currentDate = DateTime.parse(dayKey);
          final weekday = currentDate.weekday; // 1=Monday, 7=Sunday
          
          // Copy to future weekdays only if current day is a weekday (Monday=1 to Friday=5)
          if (weekday >= 1 && weekday <= 5) {
            print('DEBUG: Initial setup - repeat weekdays enabled, copying to future weekdays only');
            
            // Copy to future weekdays only (from current day forward)
            for (int i = weekday; i <= 5; i++) { // From current weekday to Friday
              final daysOffset = i - weekday;
              final targetDate = currentDate.add(Duration(days: daysOffset));
              final targetKey = targetDate.toIso8601String().split('T')[0];
              
              // Copy the actions to future weekdays
              daySpecificActions[targetKey] = List.from(userActionsFromFirstTime);
              
              // Track which actions were copied (not manually added)
              if (daysOffset > 0) { // Don't mark original day as copied
                copiedActions[targetKey] = userActionsFromFirstTime.map((action) => action['name'] as String).toSet();
              }
              
              print('DEBUG: Initial setup - copied routine to $targetKey (${_getDayName(i)})');
            }
          }
        } else {
          print('DEBUG: Initial setup - repeat weekdays disabled, actions only saved to current day');
        }
        
        // Add to display (these are already properly timed anchor actions)
        for (var action in userActionsFromFirstTime) {
          displayActions.add(Map<String, dynamic>.from(action));
        }
        
        print('DEBUG: Saved ${userActionsFromFirstTime.length} user actions to day storage for future visits');
      } else {
        // Regular flow: Load user actions for this specific day from storage
        if (daySpecificActions.containsKey(dayKey)) {
          print('DEBUG: Loading ${daySpecificActions[dayKey]!.length} stored actions for $dayKey');
          for (var action in daySpecificActions[dayKey]!) {
            // Only add non-schedule actions from storage
            if (action['isScheduleTime'] != true) {
              displayActions.add(Map<String, dynamic>.from(action));
              print('DEBUG: Added stored action: ${action['name']} at ${action['time']}');
            } else {
              print('DEBUG: Skipped schedule action: ${action['name']}');
            }
          }
        } else {
          print('DEBUG: No stored actions found for $dayKey - day will be empty');
          print('DEBUG: Available day keys: ${daySpecificActions.keys.toList()}');
        }
      }
    }
    
    // Always add schedule mode actions (these are generated fresh each time)
    _addScheduleModeActions();
    
    // SORT ALL ACTIONS BY TIME: Ensure proper chronological order with strict wake/sleep positioning
    displayActions.sort((a, b) {
      final timeA = a['time'] as TimeOfDay;
      final timeB = b['time'] as TimeOfDay;
      final nameA = a['name'] ?? a['actionName'] ?? '';
      final nameB = b['name'] ?? b['actionName'] ?? '';
      
      // Check if items are wake or sleep
      bool aIsWake = nameA.contains('Wake') || nameA.contains('🌅');
      bool bIsWake = nameB.contains('Wake') || nameB.contains('🌅');
      bool aIsSleep = nameA.contains('Sleep') || nameA.contains('😴');
      bool bIsSleep = nameB.contains('Sleep') || nameB.contains('😴');
      
      // Wake always comes first
      if (aIsWake && !bIsWake) return -1;
      if (bIsWake && !aIsWake) return 1;
      
      // Sleep always comes last
      if (aIsSleep && !bIsSleep) return 1;
      if (bIsSleep && !aIsSleep) return -1;
      
      // If both are wake or both are sleep, sort by time
      if ((aIsWake && bIsWake) || (aIsSleep && bIsSleep)) {
        int minutesA = timeA.hour * 60 + timeA.minute;
        int minutesB = timeB.hour * 60 + timeB.minute;
        return minutesA.compareTo(minutesB);
      }
      
      // For regular items (non-wake/sleep), sort by time normally
      int minutesA = timeA.hour * 60 + timeA.minute;
      int minutesB = timeB.hour * 60 + timeB.minute;
      
      return minutesA.compareTo(minutesB);
    });
    
    // Debug: Show sorted timeline
    print('DEBUG: Timeline sorted for ${_getFormattedDate()}:');
    for (int i = 0; i < displayActions.length; i++) {
      final action = displayActions[i];
      final time = action['time'] as TimeOfDay;
      final name = action['name'] ?? action['actionName'] ?? 'Unknown';
      final isSchedule = action['isScheduleTime'] == true;
      print('DEBUG: [$i] ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} - $name (schedule: $isSchedule)');
    }
    
    headerText = _getFormattedDate();
  }
  
  String _getFormattedDate() {
    final now = DateTime.now();
    const monthAbbr = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    const dayAbbr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    final dayName = dayAbbr[selectedDate.weekday - 1]; // weekday is 1-indexed
    final monthName = monthAbbr[selectedDate.month - 1];
    
    if (_isSameDay(selectedDate, now)) {
      return 'Today - $dayName, $monthName ${selectedDate.day}';
    } else if (_isSameDay(selectedDate, now.add(Duration(days: 1)))) {
      return 'Tomorrow - $dayName, $monthName ${selectedDate.day}';
    } else if (_isSameDay(selectedDate, now.subtract(Duration(days: 1)))) {
      return 'Yesterday - $dayName, $monthName ${selectedDate.day}';
    } else {
      return '$dayName, $monthName ${selectedDate.day}';
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Unknown';
    }
  }

  void _goToPreviousDay() {
    DateTime previousDay = selectedDate.subtract(Duration(days: 1));
    DateTime today = DateTime.now();
    
    // Allow going to previous day if:
    // 1. It's today or later
    // 2. OR there are actions stored for that day
    String previousDayKey = '${previousDay.year}-${previousDay.month.toString().padLeft(2, '0')}-${previousDay.day.toString().padLeft(2, '0')}';
    bool isPreviousDayTodayOrLater = !previousDay.isBefore(DateTime(today.year, today.month, today.day));
    bool hasPreviousDayActions = daySpecificActions.containsKey(previousDayKey);
    
    if (isPreviousDayTodayOrLater || hasPreviousDayActions) {
      setState(() {
        selectedDate = previousDay;
        _initializeDisplayActions(); // Reload actions for the new day
      });
    } else {
      print('DEBUG: Cannot go to previous day $previousDayKey - no actions and before today');
    }
  }

  void _goToNextDay() {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: 1));
      _initializeDisplayActions(); // Reload actions for the new day
    });
  }
  
  // Helper method to find the first day when user set up their routine
  DateTime? _getFirstSetupDay() {
    if (daySpecificActions.isEmpty) {
      return null;
    }
    
    // Find the earliest date in day storage
    DateTime? earliest;
    for (String dayKey in daySpecificActions.keys) {
      try {
        List<String> parts = dayKey.split('-');
        if (parts.length == 3) {
          DateTime date = DateTime(
            int.parse(parts[0]), // year
            int.parse(parts[1]), // month  
            int.parse(parts[2]), // day
          );
          if (earliest == null || date.isBefore(earliest)) {
            earliest = date;
          }
        }
      } catch (e) {
        print('DEBUG: Error parsing day key: $dayKey');
      }
    }
    
    return earliest;
  }
  
  // Helper method to check if we can navigate to previous day
  bool _canGoToPreviousDay() {
    DateTime previousDay = selectedDate.subtract(Duration(days: 1));
    DateTime today = DateTime.now();
    
    // Allow going to previous day if:
    // 1. It's today or later
    // 2. OR there are actions stored for that day
    String previousDayKey = '${previousDay.year}-${previousDay.month.toString().padLeft(2, '0')}-${previousDay.day.toString().padLeft(2, '0')}';
    bool isPreviousDayTodayOrLater = !previousDay.isBefore(DateTime(today.year, today.month, today.day));
    bool hasPreviousDayActions = daySpecificActions.containsKey(previousDayKey);
    
    return isPreviousDayTodayOrLater || hasPreviousDayActions;
  }
  
  bool _isActionPast(TimeOfDay actionTime) {
    final now = DateTime.now();
    
    // Only grey out if it's today and the time has passed
    if (!_isSameDay(selectedDate, now)) {
      return false; // Never grey out actions for other days
    }
    
    final currentTime = TimeOfDay.now();
    final actionMinutes = actionTime.hour * 60 + actionTime.minute;
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final wakeMinutes = (widget.wakeTime ?? TimeOfDay(hour: 6, minute: 0)).hour * 60 + (widget.wakeTime ?? TimeOfDay(hour: 6, minute: 0)).minute;
    final bedMinutes = (widget.bedTime ?? TimeOfDay(hour: 0, minute: 0)).hour * 60 + (widget.bedTime ?? TimeOfDay(hour: 0, minute: 0)).minute;
    
    // Handle next-day sleep time logic
    if (bedMinutes < wakeMinutes) {
      // Sleep time is next day (e.g., sleep at 00:00, wake at 06:00)
      if (actionMinutes < wakeMinutes) {
        // Action is in the "next day" period (00:00 to wake time)
        // This action belongs to tomorrow, so it's never "past" relative to today
        return false;
      }
    }
    
    // Standard same-day logic for actions after wake time
    return actionMinutes < currentMinutes;
  }



  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: _canGoToPreviousDay() ? _goToPreviousDay : null, 
                icon: Icon(Icons.chevron_left),
                tooltip: 'Previous day',
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        DateTime? firstSetupDay = _getFirstSetupDay();
                        DateTime minDate = firstSetupDay ?? DateTime.now().subtract(Duration(days: 365));
                        
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: minDate,
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            selectedDate = pickedDate;
                            _initializeDisplayActions();
                          });
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue[200]!, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today, color: Colors.blue[600], size: 16),
                            SizedBox(width: 6),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      headerText, 
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _goToNextDay, 
                icon: Icon(Icons.chevron_right),
                tooltip: 'Next day',
              ),
            ],
          ),
        ),
        Expanded(
          child: displayActions.isEmpty 
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.schedule, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No routine set for today', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    SizedBox(height: 8),
                    Text('Add some actions to get started!', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              )
            : _buildVerticalTimeline(),
        ),
        Padding(
          padding: EdgeInsets.all(16),
          child: FloatingActionButton.extended(
            onPressed: () async {
              // Get current day key
              String dayKey = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
              
              // For action picker, pass the saved user actions so they appear as checked
              List<Map<String, dynamic>> existingUserActions = [];
              if (daySpecificActions.containsKey(dayKey)) {
                existingUserActions = daySpecificActions[dayKey]!
                    .map((action) => Map<String, dynamic>.from(action))
                    .toList();
              }
              
              print('DEBUG: Passing ${existingUserActions.length} existing actions to action picker for day $dayKey');
              for (var action in existingUserActions) {
                final name = action['name'] ?? action['actionName'] ?? 'Unknown';
                print('DEBUG: Existing action: $name');
              }
              
              final result = await Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => ActionPickerScreen(
                  wakeTime: widget.wakeTime ?? TimeOfDay(hour: 6, minute: 0),
                  bedTime: widget.bedTime ?? TimeOfDay(hour: 0, minute: 0),
                  existingActions: existingUserActions, // Pass saved user actions directly
                ))
              );
              
              print('DEBUG: NAVIGATOR RETURNED - Action picker returned: $result');
              
              print('DEBUG: Action picker returned: $result');
              print('DEBUG: Result type: ${result.runtimeType}');
              print('DEBUG: Result is null: ${result == null}');
              print('DEBUG: Result is List: ${result is List}');
              print('DEBUG: Result is List<Map<String, dynamic>>: ${result is List<Map<String, dynamic>>}');
              
              if (result != null && result is List<Map<String, dynamic>>) {
                // INDEPENDENT DAY STORAGE: Save actions to the specific day
                String dayKey = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                
                print('DEBUG: *** ACTION PICKER SUCCESS *** Saving actions for $dayKey, got ${result.length} items from action picker');
                
                // Process frequency-based actions before saving
                List<Map<String, dynamic>> processedActions = [];
                
                for (var action in result) {
                  // Skip schedule actions
                  if (action['isScheduleTime'] == true) {
                    continue;
                  }
                  
                  // Mark as user action and remove dayOfWeek
                  action['isUserAction'] = true;
                  action.remove('dayOfWeek');
                  
                  // Process frequency-based actions
                  if ((action['frequency'] ?? 1) > 1) {
                    print('DEBUG: Processing frequency-based action: ${action['name']} with frequency ${action['frequency']}');
                    var anchors = _createActionAnchors(action, action['frequency']);
                    processedActions.addAll(anchors);
                    print('DEBUG: Created ${anchors.length} anchors for ${action['name']}');
                  } else {
                    processedActions.add(action);
                  }
                }
                
                print('DEBUG: Total processed actions: ${processedActions.length}');
                for (var action in processedActions) {
                  final name = action['name'] ?? action['actionName'] ?? 'Unknown';
                  final time = action['time'] as TimeOfDay?;
                  final anchor = action['anchorIndex'] ?? 1;
                  final total = action['totalAnchors'] ?? 1;
                  print('DEBUG: - $name at ${time?.hour ?? 0}:${(time?.minute ?? 0).toString().padLeft(2, '0')} (anchor $anchor/$total)');
                }
                
                // Save processed actions to storage
                daySpecificActions[dayKey] = processedActions;
                
                // Remove manually added actions from copied tracking
                // When user manually adds actions, they should not be considered "copied"
                if (copiedActions.containsKey(dayKey)) {
                  final manuallyAddedNames = processedActions.map((action) => action['name'] as String).toSet();
                  copiedActions[dayKey]?.removeAll(manuallyAddedNames);
                  if (copiedActions[dayKey]?.isEmpty == true) {
                    copiedActions.remove(dayKey);
                  }
                  print('DEBUG: Removed manually added actions from copied tracking for $dayKey');
                }
                
                print('DEBUG: Stored ${processedActions.length} processed actions in day storage');
                print('DEBUG: Repeat weekdays routine setting: ${widget.repeatWorkdaysRoutine}');
                for (var action in processedActions) {
                  final name = action['name'] ?? action['actionName'] ?? 'Unknown';
                  print('DEBUG: Stored: $name');
                }
                
                // Handle repeat weekdays routine feature
                final repeatWorkdays = widget.repeatWorkdaysRoutine;
                print('DEBUG: Checking repeat weekdays - enabled: $repeatWorkdays');
                if (repeatWorkdays) {
                  final currentDate = DateTime.parse(dayKey);
                  final weekday = currentDate.weekday; // 1=Monday, 7=Sunday
                  
                  // Copy to future weekdays only if current day is a weekday (Monday=1 to Friday=5)
                  if (weekday >= 1 && weekday <= 5) {
                    print('DEBUG: Repeat weekdays enabled - copying routine to future weekdays only');
                    
                    // Copy to future weekdays only (from current day forward)
                    for (int i = weekday; i <= 5; i++) { // From current weekday to Friday
                      final daysOffset = i - weekday;
                      final targetDate = currentDate.add(Duration(days: daysOffset));
                      final targetKey = targetDate.toIso8601String().split('T')[0];
                      
                      // Copy the actions to future weekdays
                      daySpecificActions[targetKey] = List.from(processedActions);
                      
                      // Track which actions were copied (not manually added)
                      if (daysOffset > 0) { // Don't mark original day as copied
                        copiedActions[targetKey] = processedActions.map((action) => action['name'] as String).toSet();
                      }
                      
                      print('DEBUG: Copied routine to $targetKey (${_getDayName(i)})');
                    }
                  }
                } else {
                  print('DEBUG: Repeat weekdays routine is disabled - actions only saved to current day');
                }
                
                // Then rebuild displayActions from scratch for immediate display
                setState(() {
                  displayActions.clear();
                  
                  // Add processed user actions from storage
                  for (var action in processedActions) {
                    displayActions.add(Map<String, dynamic>.from(action));
                  }
                  
                  // Add schedule mode actions
                  _addScheduleModeActions();
                  
                  // Sort all actions by chronological time order
                  print('DEBUG: Before sorting, displayActions has ${displayActions.length} items');
                  for (int i = 0; i < displayActions.length; i++) {
                    final action = displayActions[i];
                    final time = action['time'] as TimeOfDay;
                    final name = action['name'] ?? action['actionName'] ?? 'Unknown';
                    final isSchedule = action['isScheduleTime'] == true;
                    print('DEBUG: [$i] ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} - $name (schedule: $isSchedule)');
                  }
                  
                  displayActions.sort((a, b) {
                    final timeA = a['time'] as TimeOfDay;
                    final timeB = b['time'] as TimeOfDay;
                    
                    // Convert times to minutes, treating 00:00 (sleep) as end of day (24:00 = 1440 minutes)
                    int minutesA = timeA.hour * 60 + timeA.minute;
                    int minutesB = timeB.hour * 60 + timeB.minute;
                    
                    // Special handling for sleep time (00:00) - treat as end of day
                    final nameA = a['name'] ?? a['actionName'] ?? '';
                    final nameB = b['name'] ?? b['actionName'] ?? '';
                    if ((nameA.contains('Sleep') || nameA.contains('😴')) && timeA.hour == 0 && timeA.minute == 0) {
                      minutesA = 24 * 60; // 24:00 = end of day
                    }
                    if ((nameB.contains('Sleep') || nameB.contains('😴')) && timeB.hour == 0 && timeB.minute == 0) {
                      minutesB = 24 * 60; // 24:00 = end of day
                    }
                    
                    final timeComparison = minutesA.compareTo(minutesB);
                    
                    // If times are equal, prioritize schedule items
                    if (timeComparison == 0) {
                      bool isScheduleA = a['isScheduleTime'] == true;
                      bool isScheduleB = b['isScheduleTime'] == true;
                      
                      if (isScheduleA && !isScheduleB) return -1;
                      if (!isScheduleA && isScheduleB) return 1;
                    }
                    
                    return timeComparison;
                  });
                  
                  print('DEBUG: After sorting:');
                  for (int i = 0; i < displayActions.length; i++) {
                    final action = displayActions[i];
                    final time = action['time'] as TimeOfDay;
                    final name = action['name'] ?? action['actionName'] ?? 'Unknown';
                    final isSchedule = action['isScheduleTime'] == true;
                    print('DEBUG: [$i] ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} - $name (schedule: $isSchedule)');
                  }
                });
              } else {
                print('DEBUG: *** NO ACTIONS RETURNED *** Action picker returned null or wrong type: $result');
              }
            },
            icon: Icon(Icons.add),
            label: Text('Add Action'),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalTimeline() {
    return ReorderableListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: displayActions.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final item = displayActions.removeAt(oldIndex);
          displayActions.insert(newIndex, item);
          
          // Update times based on new order to maintain timeline logic
          _updateTimesAfterReorder();
        });
      },
      itemBuilder: (context, index) {
        final action = displayActions[index];
        final time = action['time'] as TimeOfDay;
        final timeString = formatTimeCustom(context, time);
        final category = action['category']?.toString().toLowerCase() ?? '';
        
        // Action-specific icon mapping
        Color categoryColor = Colors.blue;
        IconData actionIcon = Icons.circle;
        String displayCategory = '';
        
        // Get action-specific icon based on action name
        final actionName = action['name']?.toString().toLowerCase() ?? '';
        if (actionName.contains('water') || actionName.contains('drink')) {
          actionIcon = Icons.local_drink;
          categoryColor = Colors.blue;
        } else if (actionName.contains('coffee')) {
          actionIcon = Icons.coffee;
          categoryColor = Colors.brown;
        } else if (actionName.contains('walk') || actionName.contains('jog')) {
          actionIcon = Icons.directions_walk;
          categoryColor = Colors.green;
        } else if (actionName.contains('stretch') || actionName.contains('yoga') || actionName.contains('exercise')) {
          actionIcon = Icons.self_improvement;
          categoryColor = Colors.orange;
        } else if (actionName.contains('work') || actionName.contains('start work') || actionName.contains('finish work')) {
          actionIcon = Icons.work;
          categoryColor = Colors.indigo;
        } else if (actionName.contains('meal') || actionName.contains('breakfast') || actionName.contains('lunch') || actionName.contains('dinner') || actionName.contains('eat')) {
          actionIcon = Icons.restaurant;
          categoryColor = Colors.orange;
        } else if (actionName.contains('sleep') || actionName.contains('bed')) {
          actionIcon = Icons.bedtime;
          categoryColor = Colors.purple;
        } else if (actionName.contains('wake')) {
          actionIcon = Icons.wb_sunny;
          categoryColor = Colors.amber;
        } else if (actionName.contains('review') || actionName.contains('plan')) {
          actionIcon = Icons.event_note;
          categoryColor = Colors.indigo;
        } else if (actionName.contains('posture') || actionName.contains('stand')) {
          actionIcon = Icons.accessibility_new;
          categoryColor = Colors.teal;
        } else if (actionName.contains('breathing') || actionName.contains('meditation')) {
          actionIcon = Icons.air;
          categoryColor = Colors.cyan;
        } else if (actionName.contains('time') || actionName.contains('self')) {
          actionIcon = Icons.person;
          categoryColor = Colors.pink;
        } else {
          // Category-based fallback
          switch (category) {
            case 'health':
              categoryColor = Colors.green;
              actionIcon = Icons.favorite;
              displayCategory = 'Health';
              break;
            case 'exercise':
              categoryColor = Colors.orange;
              actionIcon = Icons.fitness_center;
              displayCategory = 'Exercise';
              break;
            case 'productivity':
              categoryColor = Colors.purple;
              actionIcon = Icons.business_center;
              displayCategory = 'Productivity';
              break;
            case 'leisure':
              categoryColor = Colors.pink;
              actionIcon = Icons.weekend;
              displayCategory = 'Leisure';
              break;
            case 'planning':
              categoryColor = Colors.indigo;
              actionIcon = Icons.event_note;
              displayCategory = 'Planning';
              break;
            case 'chores':
              categoryColor = Colors.amber;
              actionIcon = Icons.cleaning_services;
              displayCategory = 'Chores';
              break;
            case 'schedule':
              categoryColor = Colors.red;
              actionIcon = Icons.schedule;
              displayCategory = '';
              break;
            default:
              categoryColor = Colors.grey;
              actionIcon = Icons.circle;
              displayCategory = category;
          }
        }
        
        // Set display category based on actual category
        if (category == 'health') displayCategory = 'Health';
        else if (category == 'exercise') displayCategory = 'Exercise';
        else if (category == 'productivity') displayCategory = 'Productivity';
        else if (category == 'leisure') displayCategory = 'Leisure';
        else if (category == 'planning') displayCategory = 'Planning';
        else if (category == 'chores') displayCategory = 'Chores';
        else if (category == 'schedule') displayCategory = '';
        else displayCategory = category;
        
        return Container(
          key: ValueKey('${action['name']}_$index'),
          margin: EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time column
              Container(
                width: 80,
                child: Column(
                  children: [
                    Text(
                      timeString.split(' ')[0], // Time without AM/PM
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    Text(
                      timeString.split(' ').length > 1 ? timeString.split(' ')[1] : '', // AM/PM
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Timeline line
              Container(
                width: 30,
                child: Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: categoryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (index < displayActions.length - 1)
                      Container(
                        width: 2,
                        height: 60,
                        color: Colors.grey[300],
                      ),
                  ],
                ),
              ),
              
              // Action card with anchor-style UI
              Expanded(
                child: InkWell(
                  onTap: () => _handleActionTap(context, action), // Always allow tapping, no disabled state
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isActionPast(action['time']) 
                        ? Colors.grey[50]  // Light grey background for past actions
                        : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: categoryColor.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: categoryColor.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Icon with category color
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: categoryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            actionIcon,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 16),
                        
                        // Action details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                action['name'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _isActionPast(action['time']) 
                                    ? Colors.grey[600]  // Grey text for past actions
                                    : Colors.black87,
                                ),
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  // Category tag (only show if not empty)
                                  if (displayCategory.isNotEmpty) ...[
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: categoryColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        displayCategory,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: categoryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                  ],
                                  
                                  // Anchor indicator
                                  if (action.containsKey('anchorIndex')) ...[
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo[50],
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.indigo[200]!, width: 1),
                                      ),
                                      child: Text(
                                        '${action['anchorIndex']}/${action['totalAnchors']}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.indigo[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Drag handle
                        Icon(
                          Icons.drag_handle, 
                          color: _isActionPast(action['time']) 
                            ? Colors.grey[300]  // Lighter drag handle for past actions
                            : Colors.grey[400], 
                          size: 20
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _addScheduleModeActions() {
    // PERMANENT ANCHORS: Always add wake/bed/meal times regardless of schedule mode
    // BUT: Skip if template already has schedule items (priority to template times)
    
    // Check if template already has schedule items
    bool hasTemplateWake = false;
    bool hasTemplateSleep = false;
    Set<String> templateMealNames = {};
    bool hasTemplateReview = false;
    
    for (var action in displayActions) {
      final category = action['category']?.toString().toLowerCase() ?? '';
      final name = action['name']?.toString() ?? '';
      
      if (category == 'schedule') {
        if (name.toLowerCase().contains('wake')) {
          hasTemplateWake = true;
        } else if (name.toLowerCase().contains('sleep')) {
          hasTemplateSleep = true;
        } else if (name.toLowerCase().contains('breakfast')) {
          templateMealNames.add('Breakfast');
        } else if (name.toLowerCase().contains('lunch')) {
          templateMealNames.add('Lunch');
        } else if (name.toLowerCase().contains('dinner')) {
          templateMealNames.add('Dinner');
        } else if (name.toLowerCase().contains('review')) {
          hasTemplateReview = true;
        }
      }
    }
    
    // Add wake time anchor ONLY if template doesn't have it
    if (widget.wakeTime != null && !hasTemplateWake) {
      TimeOfDay wakeTime = widget.wakeTime!;
      
      displayActions.add({
        'name': '🌅 Wake up',
        'time': wakeTime,
        'category': 'schedule',
        'isScheduleTime': true,
        'isEvent': true,
        'description': 'Start your day',
        'icon': '🌅',
      });
    }
    
    // Add meal time anchors ONLY if template doesn't have them
    if (widget.mealTimes != null && widget.mealNames != null) {
      for (int i = 0; i < widget.mealTimes!.length && i < widget.mealNames!.length; i++) {
        String mealName = widget.mealNames![i];
        
        // Only add if template doesn't already have this meal
        if (!templateMealNames.contains(mealName)) {
          TimeOfDay mealTime = widget.mealTimes![i];
          
          displayActions.add({
            'name': '🍽️ $mealName',
            'time': mealTime,
            'category': 'schedule',
            'isScheduleTime': true,
            'isEvent': true,
            'description': 'Meal time',
            'icon': '🍽️',
          });
        }
      }
    }
    
    // Add bed time anchor ONLY if template doesn't have it
    if (widget.bedTime != null && !hasTemplateSleep) {
      TimeOfDay bedTime = widget.bedTime!;
      
      displayActions.add({
        'name': '😴 Sleep',
        'time': bedTime,
        'category': 'schedule',
        'isScheduleTime': true,
        'isEvent': true,
        'description': 'Rest and recovery time',
        'icon': '😴',
      });
    }
    
    // SCHEDULE MODE ACTIONS: Add review actions based on mode ONLY if template doesn't have review
    if (widget.scheduleMode == 'Repeat' || hasTemplateReview) {
      // No additional review actions for repeat mode or if template has review
      return;
    }
    
    final reviewTime = _getReviewTime();
    Map<String, dynamic>? scheduleAction;
    
    // Determine which schedule action to add based on mode and day
    switch (widget.scheduleMode) {
      case 'Weekly':
        if (_shouldShowWeeklyReview()) {
          scheduleAction = {
            'name': '📅 Review next week\'s routine',
            'time': reviewTime,
            'category': 'schedule',
            'isScheduleTime': true,
            'isEvent': true,  // Mark as event, not editable action
            'description': 'Plan and organize your activities for the upcoming week',
            'icon': '📅',
          };
        }
        break;
      case 'Daily':
        if (_shouldShowDailyReview()) {
          scheduleAction = {
            'name': '📋 Review tomorrow\'s routine',
            'time': reviewTime,
            'category': 'schedule',
            'isScheduleTime': true,
            'isEvent': true,  // Mark as event, not editable action
            'description': 'Plan and organize your activities for tomorrow',
            'icon': '📋',
          };
        }
        break;
    }
    
    // Add the schedule action if it should be shown
    if (scheduleAction != null) {
      displayActions.add(scheduleAction);
    }
  }
  
  TimeOfDay _getReviewTime() {
    final bedTime = widget.bedTime ?? TimeOfDay(hour: 0, minute: 0);
    int bedMinutes = bedTime.hour * 60 + bedTime.minute;
    int reviewMinutes = bedMinutes - 30;
    
    if (reviewMinutes < 0) {
      reviewMinutes += 1440; // Handle next day
    }
    
    return TimeOfDay(hour: reviewMinutes ~/ 60, minute: reviewMinutes % 60);
  }
  
  bool _shouldShowWeeklyReview() {
    // Show weekly review on the last workday
    final dayOffs = widget.dayOffs;
    final stopOnDayOffs = widget.stopRoutineOnDayOffs;
    
    if (!stopOnDayOffs) {
      // If not stopping on day-offs, last workday is Sunday (7)
      return selectedDate.weekday == 7;
    } else {
      // Find the last day that's not a day-off
      for (int i = 7; i >= 1; i--) {
        if (!dayOffs.contains(i)) {
          return selectedDate.weekday == i;
        }
      }
      return false;
    }
  }
  
  bool _shouldShowDailyReview() {
    // Show daily review every day
    return true;
  }
  
  void _handleActionTap(BuildContext context, Map<String, dynamic> action) {
    if (action['isScheduleTime'] == true) {
      // Handle schedule items (Wake, Sleep, Breakfast, Lunch, Dinner) - allow time editing only
      _editScheduleItemTime(context, action);
    } else if (action['isEvent'] == true) {
      // Handle schedule event taps (show planning dialogs, not editable)
      _handleScheduleActionTap(context, action);
    } else {
      // Handle regular action taps (show edit dialog)
      _editTimelineAction(context, action, displayActions);
    }
  }
  
  void _handleScheduleActionTap(BuildContext context, Map<String, dynamic> action) {
    final actionName = action['name'] as String;
    
    if (actionName.contains('Review next week')) {
      _showWeeklyPlanningDialog(context);
    } else if (actionName.contains('Review tomorrow')) {
      _handleReviewTomorrowTap(context);
    }
  }
  
  void _handleReviewTomorrowTap(BuildContext context) {
    // Check if tomorrow already has actions
    final tomorrow = DateTime.now().add(Duration(days: 1));
    final tomorrowKey = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
    
    // Check both daySpecificActions storage and current displayActions if we're viewing tomorrow
    bool tomorrowHasActions = false;
    
    // First check if we have stored actions for tomorrow
    if (daySpecificActions.containsKey(tomorrowKey) && daySpecificActions[tomorrowKey]!.isNotEmpty) {
      tomorrowHasActions = true;
    }
    
    // Also check if we're currently viewing tomorrow and it has actions
    if (selectedDate.year == tomorrow.year && 
        selectedDate.month == tomorrow.month && 
        selectedDate.day == tomorrow.day && 
        displayActions.isNotEmpty) {
      tomorrowHasActions = true;
    }
    
    if (tomorrowHasActions) {
      // Tomorrow already has actions - navigate directly to review them
      setState(() {
        selectedDate = tomorrow;
        _initializeDisplayActions();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Showing tomorrow\'s routine for review'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // Tomorrow is blank - show planning dialog
      _showDailyPlanningDialog(context);
    }
  }
  
  void _showWeeklyPlanningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.calendar_today, color: Colors.blue, size: 24),
            ),
            SizedBox(width: 12),
            Text('Plan Next Week', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Your next week\'s routine is currently blank. How would you like to plan it?',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _addActionsToWeek();
                },
                icon: Icon(Icons.add, size: 20),
                label: Text('Add actions to the days'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _duplicatePreviousRoutine();
                },
                icon: Icon(Icons.content_copy, size: 20),
                label: Text('Duplicate previous routine'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _applyRoutineTemplate();
                },
                icon: Icon(Icons.folder, size: 20),
                label: Text('Apply a routine template'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
        actionsPadding: EdgeInsets.all(16),
      ),
    );
  }
  
  void _showDailyPlanningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.today, color: Colors.indigo, size: 24),
            ),
            SizedBox(width: 12),
            Text('Plan Tomorrow', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Your tomorrow\'s routine is currently blank. Let\'s plan it now:',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _addActionsToDay();
                },
                icon: Icon(Icons.add, size: 20),
                label: Text('Add actions to the day'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Duplication removed - each day is independent
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Each day has its own independent routine. Please add actions directly to each day.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                icon: Icon(Icons.info, size: 20),
                label: Text('Each day is independent'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _applyRoutineTemplate();
                },
                icon: Icon(Icons.folder, size: 20),
                label: Text('Apply a routine template'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
        actionsPadding: EdgeInsets.all(16),
      ),
    );
  }
  
  void _addActionsToWeek() {
    // Navigate to action picker or show week planning interface
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening week planning interface...'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  void _addActionsToDay() {
    // Navigate to tomorrow's routine with action picker mode
    final tomorrow = DateTime.now().add(Duration(days: 1));
    setState(() {
      selectedDate = tomorrow;
      _initializeDisplayActions();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to tomorrow\'s routine. Add actions here!'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Add Action',
          textColor: Colors.white,
          onPressed: () {
            // This would open action picker - placeholder for now
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Action picker would open here')),
            );
          },
        ),
      ),
    );
  }
  
  void _duplicatePreviousRoutine() {
    // Logic to duplicate previous week's routine
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Previous routine duplicated successfully!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
  
  void _editScheduleItemTime(BuildContext context, Map<String, dynamic> action) async {
    // Show a simple time picker for schedule items only
    final currentTime = action['time'] as TimeOfDay;
    final newTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
      helpText: 'Edit ${action['name']} time',
    );
    
    if (newTime != null && newTime != currentTime) {
      // Get current wake and sleep times for validation
      TimeOfDay? currentWakeTime = widget.wakeTime;
      TimeOfDay? currentSleepTime = widget.bedTime;
      
      // Check for overrides in storage
      String dayKey = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
      if (daySpecificActions.containsKey(dayKey)) {
        for (var storedAction in daySpecificActions[dayKey]!) {
          if (storedAction['isScheduleTime'] == true) {
            if (storedAction['name']?.contains('Wake') == true || storedAction['name']?.contains('🌅') == true) {
              currentWakeTime = storedAction['time'] as TimeOfDay;
            } else if (storedAction['name']?.contains('Sleep') == true || storedAction['name']?.contains('😴') == true) {
              currentSleepTime = storedAction['time'] as TimeOfDay;
            }
          }
        }
      }
      
      // Validate wake-sleep positioning rules
      bool isWakeTime = action['name']?.contains('Wake') == true || action['name']?.contains('🌅') == true;
      bool isSleepTime = action['name']?.contains('Sleep') == true || action['name']?.contains('😴') == true;
      
      if (isWakeTime || isSleepTime) {
        // For wake/sleep times, check against all other items
        int newTimeMinutes = newTime.hour * 60 + newTime.minute;
        
        // Get all non-wake/sleep items to validate against
        List<Map<String, dynamic>> otherItems = displayActions.where((item) {
          bool itemIsWake = item['name']?.contains('Wake') == true || item['name']?.contains('🌅') == true;
          bool itemIsSleep = item['name']?.contains('Sleep') == true || item['name']?.contains('😴') == true;
          return !itemIsWake && !itemIsSleep;
        }).toList();
        
        if (isWakeTime) {
          // Wake time must be earlier than all other items
          for (var item in otherItems) {
            TimeOfDay itemTime = item['time'] as TimeOfDay;
            int itemMinutes = itemTime.hour * 60 + itemTime.minute;
            
            if (newTimeMinutes >= itemMinutes) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Wake time must be earlier than all other activities. ${item['name']} is at ${formatTimeCustom(context, itemTime)}.'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 4),
                ),
              );
              return; // Don't save the invalid time
            }
          }
        }
        
        if (isSleepTime) {
          // Sleep time must be later than all other items (including next day)
          // Convert sleep time to next day minutes if it's midnight or later (0-5 AM range)
          int sleepMinutes = newTimeMinutes;
          if (newTime.hour >= 0 && newTime.hour <= 5) {
            sleepMinutes = newTimeMinutes + (24 * 60); // Add 24 hours for next day
          }
          
          for (var item in otherItems) {
            TimeOfDay itemTime = item['time'] as TimeOfDay;
            int itemMinutes = itemTime.hour * 60 + itemTime.minute;
            
            if (sleepMinutes <= itemMinutes) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Sleep time must be later than all other activities. ${item['name']} is at ${formatTimeCustom(context, itemTime)}.'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 4),
                ),
              );
              return; // Don't save the invalid time
            }
          }
        }
      } else {
        // For meal times and other items, validate against wake-sleep window
        if (currentWakeTime != null && currentSleepTime != null) {
          int newTimeMinutes = newTime.hour * 60 + newTime.minute;
          int wakeTimeMinutes = currentWakeTime.hour * 60 + currentWakeTime.minute;
          int sleepTimeMinutes = currentSleepTime.hour * 60 + currentSleepTime.minute;
          
          // Handle sleep time being next day (0-5 AM range treated as next day)
          if (currentSleepTime.hour >= 0 && currentSleepTime.hour <= 5) {
            sleepTimeMinutes = sleepTimeMinutes + (24 * 60); // Add 24 hours for next day
          }
          
          // Check if new time is within wake-sleep window
          bool isWithinWindow = newTimeMinutes >= wakeTimeMinutes && newTimeMinutes <= sleepTimeMinutes;
          
          if (!isWithinWindow) {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${action['name']} must be between wake time (${formatTimeCustom(context, currentWakeTime)}) and sleep time (${formatTimeCustom(context, currentSleepTime)})'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
            return; // Don't save the invalid time
          }
        }
      }
      
      setState(() {
        // Check if current day is today and if the schedule item time has already passed
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final currentDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        final isToday = currentDay.isAtSameMomentAs(today);
        final isPastDay = currentDay.isBefore(today);
        
        bool shouldOnlyAffectFuture = false;
        
        if (isToday) {
          // For today, check if the current schedule item time has already passed
          final currentTime = TimeOfDay.now();
          final currentMinutes = currentTime.hour * 60 + currentTime.minute;
          final scheduleMinutes = (action['time'] as TimeOfDay).hour * 60 + (action['time'] as TimeOfDay).minute;
          
          // If schedule time has already passed today, only affect future days
          if (currentMinutes > scheduleMinutes) {
            shouldOnlyAffectFuture = true;
            print('DEBUG: Schedule time ${action['name']} has passed today (${action['time']}), only affecting future days');
          } else {
            print('DEBUG: Schedule time ${action['name']} has not passed today yet (${action['time']}), can update today');
          }
        } else if (isPastDay) {
          // For past days, always only affect future
          shouldOnlyAffectFuture = true;
          print('DEBUG: Editing past day, only affecting future days');
        }
        
        if (shouldOnlyAffectFuture) {
          // Only apply changes to future days (tomorrow onwards)
          final tomorrow = today.add(Duration(days: 1));
          
          // Apply to all future days that have this schedule item
          for (var entry in daySpecificActions.entries) {
            final dayKeyDate = DateTime.parse(entry.key);
            
            // Only update days from tomorrow onwards
            if (!dayKeyDate.isBefore(tomorrow)) {
              bool foundInFutureDay = false;
              
              // Update in future day storage if exists
              for (var storedAction in entry.value) {
                if (storedAction['name'] == action['name'] && 
                    storedAction['isScheduleTime'] == true) {
                  storedAction['time'] = newTime;
                  foundInFutureDay = true;
                  print('DEBUG: Updated ${action['name']} in future day ${entry.key} to ${newTime.hour}:${newTime.minute.toString().padLeft(2, '0')}');
                  break;
                }
              }
              
              // If not found in future day storage, add it
              if (!foundInFutureDay) {
                Map<String, dynamic> newScheduleItem = Map<String, dynamic>.from(action);
                newScheduleItem['time'] = newTime;
                entry.value.add(newScheduleItem);
                print('DEBUG: Added new ${action['name']} to future day ${entry.key} with time ${newTime.hour}:${newTime.minute.toString().padLeft(2, '0')}');
              }
            }
          }
          
          // Show message about future-only application
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${action['name']} time updated to ${formatTimeCustom(context, newTime)} for tomorrow onwards. Today\'s schedule unchanged (time has passed).'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
          
          print('DEBUG: Schedule change applied to future days only (today\'s time has passed)');
          
        } else {
          // For future days or today before the scheduled time, update normally
          String dayKey = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
          
          // Ensure day storage exists
          if (!daySpecificActions.containsKey(dayKey)) {
            daySpecificActions[dayKey] = [];
          }
          
          bool foundInStorage = false;
          
          // Update in storage if exists
          if (daySpecificActions.containsKey(dayKey)) {
            for (var storedAction in daySpecificActions[dayKey]!) {
              if (storedAction['name'] == action['name'] && 
                  storedAction['isScheduleTime'] == true) {
                storedAction['time'] = newTime;
                foundInStorage = true;
                print('DEBUG: Updated ${action['name']} in storage to ${newTime.hour}:${newTime.minute.toString().padLeft(2, '0')}');
                break;
              }
            }
          }
          
          // If not found in storage, add it (this can happen with casual template)
          if (!foundInStorage) {
            Map<String, dynamic> newScheduleItem = Map<String, dynamic>.from(action);
            newScheduleItem['time'] = newTime;
            daySpecificActions[dayKey]!.add(newScheduleItem);
            print('DEBUG: Added new ${action['name']} to storage with time ${newTime.hour}:${newTime.minute.toString().padLeft(2, '0')}');
          }
          
          // Update in display list for current view
          for (var displayAction in displayActions) {
            if (displayAction['name'] == action['name'] && 
                displayAction['isScheduleTime'] == true) {
              displayAction['time'] = newTime;
              print('DEBUG: Updated ${action['name']} in display to ${newTime.hour}:${newTime.minute.toString().padLeft(2, '0')}');
              break;
            }
          }
          
          // Show normal confirmation
          String message = isToday ? 
            '${action['name']} time updated to ${formatTimeCustom(context, newTime)} (effective today)' :
            '${action['name']} time updated to ${formatTimeCustom(context, newTime)}';
            
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
          
          print('DEBUG: Schedule change applied to current day: $dayKey');
        }
        
        // Re-sort the timeline with strict wake/sleep positioning (only for future days or current view)
        displayActions.sort((a, b) {
          final timeA = a['time'] as TimeOfDay;
          final timeB = b['time'] as TimeOfDay;
          final nameA = a['name'] ?? '';
          final nameB = b['name'] ?? '';
          
          // Check if items are wake or sleep
          bool aIsWake = nameA.contains('Wake') || nameA.contains('🌅');
          bool bIsWake = nameB.contains('Wake') || nameB.contains('🌅');
          bool aIsSleep = nameA.contains('Sleep') || nameA.contains('😴');
          bool bIsSleep = nameB.contains('Sleep') || nameB.contains('😴');
          
          // Wake always comes first
          if (aIsWake && !bIsWake) return -1;
          if (bIsWake && !aIsWake) return 1;
          
          // Sleep always comes last
          if (aIsSleep && !bIsSleep) return 1;
          if (bIsSleep && !aIsSleep) return -1;
          
          // If both are wake or both are sleep, sort by time
          if ((aIsWake && bIsWake) || (aIsSleep && bIsSleep)) {
            int minutesA = timeA.hour * 60 + timeA.minute;
            int minutesB = timeB.hour * 60 + timeB.minute;
            return minutesA.compareTo(minutesB);
          }
          
          // For regular items (non-wake/sleep), sort by time normally
          int minutesA = timeA.hour * 60 + timeA.minute;
          int minutesB = timeB.hour * 60 + timeB.minute;
          
          return minutesA.compareTo(minutesB);
        });
        
        // Update header text after sorting
        headerText = _getFormattedDate();
        
        String dayKey = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
        print('DEBUG: Storage now contains ${daySpecificActions[dayKey]?.length ?? 0} items for $dayKey');
        print('DEBUG: Display now contains ${displayActions.length} items');
      });
    }
  }
  
  void _applyRoutineTemplate() {
    // Navigate to Templates tab to apply template for remaining week days
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigate to Templates tab to apply template for the week'),
        backgroundColor: Colors.purple,
        action: SnackBarAction(
          label: 'Go to Templates',
          textColor: Colors.white,
          onPressed: () {
            // Switch to templates tab in parent HomeScreen
            // This would need to be passed up to parent - for now show message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Switch to Templates tab to apply templates')),
            );
          },
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Health': return Colors.green;
      case 'Fitness': return Colors.orange;
      case 'Work': return Colors.blue;
      case 'Learning': return Colors.purple;
      case 'Mindfulness': return Colors.teal;
      case 'Planning': return Colors.indigo;
      case 'Entertainment': return Colors.pink;
      case 'Social': return Colors.cyan;
      case 'Errands': return Colors.brown;
      case 'Household': return Colors.grey;
      case 'Morning': return Colors.orange;
      case 'Afternoon': return Colors.blue;
      case 'Evening': return Colors.purple;
      case 'Schedule': return Colors.blue[600]!; // Blue for schedule times
      default: return Colors.grey;
    }
  }

  void _updateTimesAfterReorder() {
    // This could implement smart time adjustment after reordering
    // For now, we'll keep the original times but could add logic to
    // redistribute times evenly or maintain minimum intervals
  }

  void _editTimelineAction(BuildContext context, Map<String, dynamic> action, List<Map<String, dynamic>> allActions) async {
    // Create a copy of the action for editing
    Map<String, dynamic> editedAction = Map.from(action);
    
    // For anchored actions, preserve original frequency for editing
    if (editedAction.containsKey('originalFrequency')) {
      editedAction['frequency'] = editedAction['originalFrequency'];
    }
    
    showDialog(
      context: context,
      builder: (context) => _TimelineActionEditDialog(
        action: editedAction,
        onSave: (updatedAction) {
          setState(() {
            // Get the original action name and category for identification
            String actionName = action['name'];
            String actionCategory = action['category'];
            
            // Remove ALL existing instances of this action (both anchored and single)
            displayActions.removeWhere((a) => 
              a['name'] == actionName && 
              a['category'] == actionCategory
            );
            
            // Create new action(s) based on the updated frequency
            int newFrequency = updatedAction['frequency'] ?? 1;
            
            if (newFrequency <= 1) {
              // Single action - add it directly
              Map<String, dynamic> singleAction = Map.from(updatedAction);
              singleAction['frequency'] = 1;
              singleAction.remove('anchorIndex');
              singleAction.remove('totalAnchors');
              singleAction.remove('originalFrequency');
              displayActions.add(singleAction);
            } else {
              // Multiple instances - use anchor distribution with the selected time as start
              _distributeActionWithAnchorsFromTime(context, updatedAction, displayActions, updatedAction['time']);
            }
            
            // Sort the timeline by chronological time order
            displayActions.sort((a, b) {
              final timeA = a['time'] as TimeOfDay;
              final timeB = b['time'] as TimeOfDay;
              
              // Convert times to minutes, treating 00:00 (sleep) as end of day
              int minutesA = timeA.hour * 60 + timeA.minute;
              int minutesB = timeB.hour * 60 + timeB.minute;
              
              // Special handling for sleep time (00:00) - treat as end of day
              final nameA = a['name'] ?? a['actionName'] ?? '';
              final nameB = b['name'] ?? b['actionName'] ?? '';
              if ((nameA.contains('Sleep') || nameA.contains('😴')) && timeA.hour == 0 && timeA.minute == 0) {
                minutesA = 24 * 60; // 24:00 = end of day
              }
              if ((nameB.contains('Sleep') || nameB.contains('😴')) && timeB.hour == 0 && timeB.minute == 0) {
                minutesB = 24 * 60; // 24:00 = end of day
              }
              
              final timeComparison = minutesA.compareTo(minutesB);
              
              // If times are equal, prioritize schedule items
              if (timeComparison == 0) {
                bool isScheduleA = a['isScheduleTime'] == true;
                bool isScheduleB = b['isScheduleTime'] == true;
                
                if (isScheduleA && !isScheduleB) return -1; // Schedule item comes first
                if (!isScheduleA && isScheduleB) return 1;  // Action comes second
              }
              
              return timeComparison;
            });
          });
        },
      ),
    );
  }

  void _distributeActionWithAnchorsFromTime(BuildContext context, Map<String, dynamic> action, List<Map<String, dynamic>> allActions, TimeOfDay startTime) {
    int frequency = action['frequency'] ?? 1;
    if (frequency <= 1) {
      allActions.add(action);
      return;
    }

    // Get bed time from SharedPreferences or use default
    TimeOfDay bedTime = TimeOfDay(hour: 0, minute: 0);  // Default sleep time (midnight)
    
    // Convert times to minutes for easier calculation
    int startMinutes = startTime.hour * 60 + startTime.minute;
    int bedMinutes = bedTime.hour * 60 + bedTime.minute;
    
    // Handle next day sleep (e.g., sleep at 00:00 = next day)
    if (bedMinutes <= startMinutes) {
      bedMinutes += 24 * 60; // Add 24 hours for next day
    }
    
    // Calculate available time from action start time to sleep time
    int availableMinutes = bedMinutes - startMinutes;
    
    // Calculate interval between anchors (spread equally from action time to sleep time)
    int intervalMinutes = availableMinutes ~/ frequency;
    
    // Ensure minimum 30-minute intervals
    if (intervalMinutes < 30) {
      intervalMinutes = 30;
    }
    
    // Create new actions at anchor points starting from the selected time
    for (int i = 0; i < frequency; i++) {
      int targetMinutes = startMinutes + (i * intervalMinutes);
      
      // Ensure we don't go past sleep time
      if (targetMinutes >= bedMinutes) {
        targetMinutes = bedMinutes - 30; // 30 minutes before sleep
      }
      
      // Convert back to hours and minutes, handling next day
      int hours = (targetMinutes ~/ 60) % 24;
      int minutes = targetMinutes % 60;
      
      Map<String, dynamic> newAction = Map.from(action);
      newAction['time'] = TimeOfDay(hour: hours, minute: minutes);
      newAction['frequency'] = 1; // Each anchor has frequency 1
      newAction['anchorIndex'] = i + 1; // 1-based indexing for display
      newAction['totalAnchors'] = frequency;
      newAction['originalFrequency'] = frequency;
      
      allActions.add(newAction);
    }
  }
  
  // Helper method to create action anchors for frequency-based actions
  List<Map<String, dynamic>> _createActionAnchors(Map<String, dynamic> action, int frequency) {
    List<Map<String, dynamic>> anchors = [];
    
    // Calculate time intervals based on frequency
    if (frequency > 1) {
      TimeOfDay originalTime = action['time'];
      int anchorMinutes = originalTime.hour * 60 + originalTime.minute;
      
      // Use actual sleep and wake times from user settings
      TimeOfDay currentSleepTime = widget.bedTime ?? TimeOfDay(hour: 0, minute: 0);
      TimeOfDay currentWakeTime = widget.wakeTime ?? TimeOfDay(hour: 6, minute: 0);
      int sleepMinutes = _calculateSleepMinutes(currentSleepTime, currentWakeTime);
      
      // Calculate available time window from anchor to sleep
      int availableMinutes = sleepMinutes - anchorMinutes;
      
      // If there's not enough time until sleep, use a minimum 1-hour window
      if (availableMinutes < 60) {
        availableMinutes = 60;
      }
      
      // Divide the available time into equal intervals
      // For frequency=2: divide by 2 to get 2 equal intervals
      // For frequency=3: divide by 3 to get 3 equal intervals
      int intervalMinutes = frequency > 1 ? availableMinutes ~/ frequency : 0;
      
      for (int i = 0; i < frequency; i++) {
        int actionMinutes = anchorMinutes + (intervalMinutes * i);
        
        // Ensure we don't go past sleep time boundaries
        if (actionMinutes >= sleepMinutes) {
          // If we're past sleep time, cap it at sleep time minus 30 minutes
          actionMinutes = sleepMinutes - 30;
        }
        
        // Handle next-day wrap-around: if actionMinutes >= 1440 (24 hours), wrap to next day
        int displayHour = (actionMinutes ~/ 60) % 24;
        int displayMinute = actionMinutes % 60;
        
        // Ensure we don't go before wake time
        int wakeMinutes = currentWakeTime.hour * 60 + currentWakeTime.minute;
        if (actionMinutes < wakeMinutes) {
          actionMinutes = wakeMinutes;
          displayHour = currentWakeTime.hour;
          displayMinute = currentWakeTime.minute;
        }
        
        TimeOfDay timeOfDay = TimeOfDay(hour: displayHour, minute: displayMinute);
        
        anchors.add({
          ...action,
          'time': timeOfDay,
          'frequency': 1, // Each anchor has frequency 1
          'anchorIndex': i + 1, // 1-based indexing for display
          'totalAnchors': frequency,
          'originalFrequency': frequency, // Keep track of original frequency
        });
      }
    } else {
      anchors.add(action);
    }
    
    return anchors;
  }
  
  // Helper method to calculate sleep time in minutes
  int _calculateSleepMinutes(TimeOfDay sleepTime, TimeOfDay wakeTime) {
    int sleepMinutes = sleepTime.hour * 60 + sleepTime.minute;
    int wakeMinutes = wakeTime.hour * 60 + wakeTime.minute;
    
    // If sleep time is 00:00 or if sleep comes before wake (next day)
    if (sleepMinutes == 0 || sleepMinutes <= wakeMinutes) {
      sleepMinutes = 24 * 60; // 24:00 = 1440 minutes (next day)
    }
    
    return sleepMinutes;
  }
}

// Timeline Action Edit Dialog
class _TimelineActionEditDialog extends StatefulWidget {
  final Map<String, dynamic> action;
  final Function(Map<String, dynamic>) onSave;

  _TimelineActionEditDialog({required this.action, required this.onSave});

  @override
  _TimelineActionEditDialogState createState() => _TimelineActionEditDialogState();
}

class _TimelineActionEditDialogState extends State<_TimelineActionEditDialog> {
  late TimeOfDay selectedTime;
  late int frequency;

  @override
  void initState() {
    super.initState();
    selectedTime = widget.action['time'] as TimeOfDay;
    frequency = widget.action['frequency'] ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    final isScheduleItem = widget.action['category'] == 'schedule' || widget.action['isScheduleTime'] == true;
    
    return AlertDialog(
      title: Text('Edit Action'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.action['name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          
          ListTile(
            leading: Icon(Icons.access_time),
            title: Text('Time'),
            subtitle: Text(formatTimeCustom(context, selectedTime)),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: selectedTime,
              );
              if (time != null) {
                setState(() {
                  selectedTime = time;
                });
              }
            },
          ),
          
          // Only show frequency controls for non-schedule items
          if (!isScheduleItem) ...[
            ListTile(
              leading: Icon(Icons.repeat),
              title: Text('Frequency'),
              subtitle: Row(
                children: [
                  IconButton(
                    onPressed: frequency > 1 ? () {
                      setState(() {
                        frequency--;
                      });
                    } : null,
                    icon: Icon(Icons.remove_circle_outline),
                  ),
                  Container(
                    width: 60,
                    child: Center(
                      child: Text(
                        '$frequency',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: frequency < 10 ? () {
                      setState(() {
                        frequency++;
                      });
                    } : null,
                    icon: Icon(Icons.add_circle_outline),
                  ),
                  Text(' times per day'),
                ],
              ),
            ),
          ] else ...[
            // Show info for schedule items
            ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Schedule Item'),
              subtitle: Text('Time can be edited, frequency is fixed at 1'),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Map<String, dynamic> updatedAction = Map.from(widget.action);
            updatedAction['time'] = selectedTime;
            // Don't update frequency for schedule items
            if (!isScheduleItem) {
              updatedAction['frequency'] = frequency;
            }
            widget.onSave(updatedAction);
            Navigator.of(context).pop();
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}

// Settings tab
class SettingsTab extends StatefulWidget {
  final TimeOfDay? wakeTime;
  final TimeOfDay? bedTime;
  final List<TimeOfDay>? mealTimes;
  final List<String>? mealNames;
  final bool isCasualTemplate;
  final bool? repeatWorkdaysRoutine;
  final bool? stopRoutineOnDayOffs;
  final Set<int>? dayOffs;
  final String? scheduleMode;
  final Function(TimeOfDay)? onWakeTimeChanged;
  final Function(TimeOfDay)? onBedTimeChanged;
  final Function(List<TimeOfDay>)? onMealTimesChanged;
  final Function(List<String>)? onMealNamesChanged;
  final Function(bool)? onRepeatWorkdaysRoutineChanged;
  
  SettingsTab({
    this.wakeTime,
    this.bedTime,
    this.mealTimes,
    this.mealNames,
    this.isCasualTemplate = false,
    this.repeatWorkdaysRoutine,
    this.stopRoutineOnDayOffs,
    this.dayOffs,
    this.scheduleMode,
    this.onWakeTimeChanged,
    this.onBedTimeChanged,
    this.onMealTimesChanged,
    this.onMealNamesChanged,
    this.onRepeatWorkdaysRoutineChanged,
  });
  
  @override
  _SettingsTabState createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  late TimeOfDay wakeTime;
  late TimeOfDay bedTime;
  late List<TimeOfDay> mealTimes;
  late List<String> mealNames;
  String scheduleMode = 'Weekly';
  Set<int> dayOffs = {}; // 1=Mon, 2=Tue, ..., 7=Sun
  bool stopRoutineOnDayOffs = true; // New option
  bool repeatWorkdaysRoutine = false; // Default OFF - user must explicitly enable

  // Original values to track changes
  late TimeOfDay originalWakeTime;
  late TimeOfDay originalBedTime;
  late List<TimeOfDay> originalMealTimes;
  late List<String> originalMealNames;
  late String originalScheduleMode;
  late Set<int> originalDayOffs;
  late bool originalStopRoutineOnDayOffs;
  late bool originalRepeatWorkdaysRoutine;

  @override
  void initState() {
    super.initState();
    // Use shared data if provided, otherwise use defaults
    wakeTime = widget.wakeTime ?? TimeOfDay(hour: 6, minute: 0);
    bedTime = widget.bedTime ?? TimeOfDay(hour: 0, minute: 0);
    mealTimes = List.from(widget.mealTimes ?? [
      TimeOfDay(hour: 8, minute: 0),   // Breakfast
      TimeOfDay(hour: 12, minute: 0),  // Lunch  
      TimeOfDay(hour: 19, minute: 0),  // Dinner
    ]);
    mealNames = List.from(widget.mealNames ?? ['Breakfast', 'Lunch', 'Dinner']);
    
    // Use passed values for day-offs and stop routine settings
    dayOffs = Set.from(widget.dayOffs ?? {});
    stopRoutineOnDayOffs = widget.stopRoutineOnDayOffs ?? true;
    repeatWorkdaysRoutine = widget.repeatWorkdaysRoutine ?? true;
    scheduleMode = widget.scheduleMode ?? 'Weekly';  // Use passed schedule mode
    
    // Store original values for change detection
    originalWakeTime = wakeTime;
    originalBedTime = bedTime;
    originalMealTimes = List.from(mealTimes);
    originalMealNames = List.from(mealNames);
    originalScheduleMode = scheduleMode;
    originalDayOffs = Set.from(dayOffs);
    originalStopRoutineOnDayOffs = stopRoutineOnDayOffs;
    originalRepeatWorkdaysRoutine = repeatWorkdaysRoutine;
    
    // Set casual template specific defaults
    if (widget.isCasualTemplate) {
      if (dayOffs.isEmpty) {
        dayOffs = {6, 7}; // Saturday and Sunday (6=Sat, 7=Sun) only if not set
      }
      stopRoutineOnDayOffs = false; // Turn off as specified
      repeatWorkdaysRoutine = widget.repeatWorkdaysRoutine ?? false; // Use passed value
    } else {
      // Manual setup defaults
      repeatWorkdaysRoutine = widget.repeatWorkdaysRoutine ?? true;
    }
  }

  void _applyWeekdayRoutineNow() {
    // Apply weekday routine immediately when toggle is enabled
    print('DEBUG: Applying weekday routine immediately due to toggle change');
    
    // Find the current day or the most recent weekday with actions
    final today = DateTime.now().toIso8601String().split('T')[0];
    final currentDate = DateTime.now();
    final currentWeekday = currentDate.weekday; // 1=Monday, 7=Sunday
    
    // If today is a weekday, use today's actions
    String? sourceDay;
    if (currentWeekday >= 1 && currentWeekday <= 5) {
      sourceDay = today;
    } else {
      // If today is weekend, find the last weekday with actions
      for (int i = 1; i <= 7; i++) {
        final candidateDate = currentDate.subtract(Duration(days: i));
        final candidateWeekday = candidateDate.weekday;
        if (candidateWeekday >= 1 && candidateWeekday <= 5) {
          final candidateKey = candidateDate.toIso8601String().split('T')[0];
          if (_RoutineTabState.daySpecificActions.containsKey(candidateKey)) {
            sourceDay = candidateKey;
            break;
          }
        }
      }
    }
    
    if (sourceDay != null && _RoutineTabState.daySpecificActions.containsKey(sourceDay)) {
      final sourceActions = _RoutineTabState.daySpecificActions[sourceDay]!;
      if (sourceActions.isNotEmpty) {
        print('DEBUG: Found source day $sourceDay with ${sourceActions.length} actions');
        
        // Copy to future weekdays only (from current day forward)
        final sourceDateParsed = DateTime.parse(sourceDay);
        final sourceWeekday = sourceDateParsed.weekday;
        
        if (sourceWeekday >= 1 && sourceWeekday <= 5) {
          for (int i = sourceWeekday; i <= 5; i++) { // From source weekday to Friday
            final daysOffset = i - sourceWeekday;
            final targetDate = sourceDateParsed.add(Duration(days: daysOffset));
            final targetKey = targetDate.toIso8601String().split('T')[0];
            
            // Copy the actions to future weekdays only
            _RoutineTabState.daySpecificActions[targetKey] = List.from(sourceActions);
            
            // Track which actions were copied (not manually added)
            if (daysOffset > 0) { // Don't mark original day as copied
              _RoutineTabState.copiedActions[targetKey] = sourceActions.map((action) => action['name'] as String).toSet();
            }
            
            print('DEBUG: Copied routine to $targetKey');
          }
        }
        
        // Notify parent that data has changed if needed
        widget.onRepeatWorkdaysRoutineChanged?.call(true);
        print('DEBUG: Weekday routine applied successfully (forward only)');
      } else {
        print('DEBUG: Source day has no actions to copy');
      }
    } else {
      print('DEBUG: No suitable source day found for weekday routine');
    }
  }

  void _removeCopiedWeekdayActions() {
    // Remove only the copied actions, keeping manually added ones
    print('DEBUG: Removing copied weekday actions due to toggle off');
    print('DEBUG: copiedActions keys: ${_RoutineTabState.copiedActions.keys.toList()}');
    print('DEBUG: daySpecificActions keys: ${_RoutineTabState.daySpecificActions.keys.toList()}');
    
    // Go through all days and remove only copied actions
    final keysToCheck = List<String>.from(_RoutineTabState.copiedActions.keys);
    for (String dayKey in keysToCheck) {
      final copiedActionNames = _RoutineTabState.copiedActions[dayKey];
      if (copiedActionNames != null && _RoutineTabState.daySpecificActions.containsKey(dayKey)) {
        final currentActions = _RoutineTabState.daySpecificActions[dayKey]!;
        print('DEBUG: Processing $dayKey - copied actions: $copiedActionNames');
        print('DEBUG: Current actions count: ${currentActions.length}');
        
        // Remove only actions that were copied, keep manually added ones
        final remainingActions = currentActions.where((action) {
          final actionName = action['name'] as String;
          final isCopied = copiedActionNames.contains(actionName);
          print('DEBUG: Action "$actionName" - copied: $isCopied');
          return !isCopied;
        }).toList();
        
        if (remainingActions.isEmpty) {
          // If no manually added actions remain, remove the day entirely
          _RoutineTabState.daySpecificActions.remove(dayKey);
          print('DEBUG: Removed all copied actions from $dayKey - day entry removed');
        } else {
          // Keep manually added actions
          _RoutineTabState.daySpecificActions[dayKey] = remainingActions;
          print('DEBUG: Removed ${copiedActionNames.length} copied actions from $dayKey, kept ${remainingActions.length} manual actions');
        }
        
        // Clear the copied actions tracking for this day
        _RoutineTabState.copiedActions.remove(dayKey);
      } else {
        print('DEBUG: Skipping $dayKey - copiedActionNames: $copiedActionNames, hasDay: ${_RoutineTabState.daySpecificActions.containsKey(dayKey)}');
      }
    }
    
    print('DEBUG: Finished removing copied weekday actions');
    print('DEBUG: Remaining daySpecificActions keys: ${_RoutineTabState.daySpecificActions.keys.toList()}');
    print('DEBUG: Remaining copiedActions keys: ${_RoutineTabState.copiedActions.keys.toList()}');
    
    // Notify parent that data has changed to refresh the UI
    widget.onRepeatWorkdaysRoutineChanged?.call(false);
  }

  // Check if any settings have been changed
  bool get hasChanges {
    return wakeTime != originalWakeTime ||
           bedTime != originalBedTime ||
           !_areTimeListsEqual(mealTimes, originalMealTimes) ||
           !_areStringListsEqual(mealNames, originalMealNames) ||
           scheduleMode != originalScheduleMode ||
           !dayOffs.containsAll(originalDayOffs) ||
           !originalDayOffs.containsAll(dayOffs) ||
           stopRoutineOnDayOffs != originalStopRoutineOnDayOffs ||
           repeatWorkdaysRoutine != originalRepeatWorkdaysRoutine;
  }

  bool _areTimeListsEqual(List<TimeOfDay> list1, List<TimeOfDay> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  bool _areStringListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // Sleep Schedule
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sleep Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.wb_sunny),
                  title: Text('Wake time'),
                  subtitle: Text(formatTimeCustom(context, wakeTime)),
                  onTap: () async {
                    final time = await showTimePicker(context: context, initialTime: wakeTime);
                    if (time != null) {
                      setState(() => wakeTime = time);
                      widget.onWakeTimeChanged?.call(time);
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.bedtime),
                  title: Text('Sleep time'),
                  subtitle: Text(
                    '${formatTimeCustom(context, bedTime)}${bedTime.hour <= 6 ? ' (next day)' : ''}'
                  ),
                  onTap: () async {
                    final time = await showTimePicker(context: context, initialTime: bedTime);
                    if (time != null) {
                      setState(() => bedTime = time);
                      widget.onBedTimeChanged?.call(time);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        
        // Meal Times
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Meal Times', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      onPressed: _addMeal,
                      icon: Icon(Icons.add),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ...mealTimes.asMap().entries.map((entry) {
                  final index = entry.key;
                  final meal = entry.value;
                  final mealName = index < mealNames.length ? mealNames[index] : 'Meal ${index + 1}';
                  return ListTile(
                    leading: Icon(Icons.restaurant),
                    title: Text('$mealName at ${formatTimeCustom(context, meal)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _editMeal(index),
                          icon: Icon(Icons.edit, size: 20),
                        ),
                        IconButton(
                          onPressed: () => _removeMeal(index),
                          icon: Icon(Icons.close, size: 20),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        
        // Schedule Mode
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Schedule Mode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'Weekly', label: Text('Weekly')),
                    ButtonSegment(value: 'Daily', label: Text('Daily')),
                    ButtonSegment(value: 'Repeat', label: Text('Repeat')),
                  ],
                  selected: {scheduleMode},
                  onSelectionChanged: (set) => setState(() => scheduleMode = set.first),
                ),
                SizedBox(height: 8),
                Text(
                  _getModeDescription(scheduleMode),
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        
        // Day-offs
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Day-offs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: List.generate(7, (i) {
                    final day = i + 1; // 1=Mon, 7=Sun
                    final isOff = dayOffs.contains(day);
                    return FilterChip(
                      label: Text(_weekdayName(day)),
                      selected: isOff,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            dayOffs.add(day);
                          } else {
                            dayOffs.remove(day);
                          }
                        });
                      },
                    );
                  }),
                ),
                SizedBox(height: 16),
                SwitchListTile(
                  title: Text('Stop Routine on Day-offs'),
                  subtitle: Text('Do not show any routine actions on selected Day-offs'),
                  value: stopRoutineOnDayOffs,
                  onChanged: (value) {
                    setState(() => stopRoutineOnDayOffs = value);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: Text('Repeat Weekdays Routine'),
                  subtitle: Text('Repeat the routine of the latest weekdays'),
                  value: repeatWorkdaysRoutine,
                  onChanged: (value) {
                    setState(() {
                      repeatWorkdaysRoutine = value;
                      if (value) {
                        _applyWeekdayRoutineNow();
                      } else {
                        _removeCopiedWeekdayActions();
                      }
                    });
                    // Notify parent of the change
                    widget.onRepeatWorkdaysRoutineChanged?.call(value);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 32),
        
        // Save Button
        FilledButton.icon(
          onPressed: hasChanges ? () {
            // Update parent's state through callbacks
            widget.onWakeTimeChanged?.call(wakeTime);
            widget.onBedTimeChanged?.call(bedTime);
            widget.onMealTimesChanged?.call(mealTimes);
            widget.onMealNamesChanged?.call(mealNames);
            
            // Update the original values to reflect the current state
            originalWakeTime = wakeTime;
            originalBedTime = bedTime;
            originalMealTimes = List.from(mealTimes);
            originalMealNames = List.from(mealNames);
            originalScheduleMode = scheduleMode;
            originalDayOffs = Set.from(dayOffs);
            originalStopRoutineOnDayOffs = stopRoutineOnDayOffs;
            originalRepeatWorkdaysRoutine = repeatWorkdaysRoutine;
            
            setState(() {}); // Refresh UI to update button state
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Settings saved successfully!')),
            );
          } : null,
          icon: Icon(Icons.save),
          label: Text('Save Settings'),
        ),
        SizedBox(height: 16),
        
        // Reset App Data Button (for testing)
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('App Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    // Show confirmation dialog
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Reset App Data'),
                        content: Text('This will clear all your routine data and show the initial setup screen again. Are you sure?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text('Reset'),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirmed == true) {
                      await resetSetup();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('App data reset. Restart the app to see the setup screen.')),
                      );
                    }
                  },
                  icon: Icon(Icons.refresh),
                  label: Text('Reset App Data'),
                ),
                SizedBox(height: 4),
                Text(
                  'For testing: clears all data and shows setup screen on next app start',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _addMeal() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _MealEditDialog(
        initialName: 'New Meal',
        initialTime: TimeOfDay(hour: 12, minute: 0),
        wakeTime: wakeTime,
        bedTime: bedTime,
        isAddMode: true,
      ),
    );
    
    if (result != null) {
      setState(() {
        mealTimes.add(result['time']);
        mealNames.add(result['name']);
        _sortMealTimes();
      });
      widget.onMealTimesChanged?.call(mealTimes);
      widget.onMealNamesChanged?.call(mealNames);
    }
  }

  void _editMeal(int index) async {
    final currentName = index < mealNames.length ? mealNames[index] : 'Meal ${index + 1}';
    final currentTime = mealTimes[index];
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _MealEditDialog(
        initialName: currentName,
        initialTime: currentTime,
        wakeTime: wakeTime,
        bedTime: bedTime,
      ),
    );
    
    if (result != null) {
      setState(() {
        mealTimes[index] = result['time'];
        if (index < mealNames.length) {
          mealNames[index] = result['name'];
        } else {
          mealNames.add(result['name']);
        }
        _sortMealTimes();
      });
      widget.onMealTimesChanged?.call(mealTimes);
      widget.onMealNamesChanged?.call(mealNames);
    }
  }

  void _removeMeal(int index) {
    setState(() {
      mealTimes.removeAt(index);
      if (index < mealNames.length) {
        mealNames.removeAt(index);
      }
    });
    widget.onMealTimesChanged?.call(mealTimes);
    widget.onMealNamesChanged?.call(mealNames);
  }

  void _sortMealTimes() {
    mealTimes.sort((a, b) {
      int aMinutes = a.hour * 60 + a.minute;
      int bMinutes = b.hour * 60 + b.minute;
      return aMinutes.compareTo(bMinutes);
    });
  }

  String _getModeDescription(String mode) {
    switch (mode) {
      case 'Daily':
        return 'Auto-add "Review tomorrow\'s routine" 30 mins before bedtime daily. Wake time check for blank routines.';
      case 'Weekly':
        return 'Auto-add "Review next week\'s routine" 30 mins before bedtime on last workday. Weekly planning dialogs.';
      case 'Repeat':
        return 'Routines repeat weekly with no prompts. Auto-carry last week\'s routine if no edits made.';
      default:
        return '';
    }
  }

  String _weekdayName(int day) => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day - 1];
  
  // Helper methods for timeline UI
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'health': return Colors.green;
      case 'exercise': return Colors.orange;
      case 'work': return Colors.blue;
      case 'productivity': return Colors.purple;
      case 'personal': return Colors.teal;
      case 'system': return Colors.indigo;
      case 'leisure': return Colors.pink;
      case 'planning': return Colors.indigo;
      case 'home': return Colors.brown;
      case 'chores': return Colors.amber;
      case 'schedule': return Colors.red;
      default: return Colors.grey;
    }
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'health': return Icons.local_drink;
      case 'exercise': return Icons.fitness_center;
      case 'work': return Icons.work;
      case 'productivity': return Icons.business_center;
      case 'personal': return Icons.person;
      case 'system': return Icons.list_alt;
      case 'leisure': return Icons.weekend;
      case 'planning': return Icons.event_note;
      case 'home': return Icons.home;
      case 'chores': return Icons.cleaning_services;
      case 'schedule': return Icons.schedule;
      default: return Icons.circle;
    }
  }

  String _getCategoryDisplayName(String category) {
    switch (category.toLowerCase()) {
      case 'health': return 'Health';
      case 'exercise': return 'Exercise';
      case 'work': return 'Work';
      case 'productivity': return 'Productivity';
      case 'personal': return 'Personal';
      case 'leisure': return 'Leisure';
      case 'planning': return 'Planning';
      case 'home': return 'Home';
      case 'chores': return 'Chores';
      case 'schedule': return ''; // Don't show label for schedule items
      case 'custom': return ''; // Don't show label for custom items that are actually schedule items
      default: return category;
    }
  }
}

// Routine action card widget
class RoutineActionCard extends StatelessWidget {
  final String title;
  final String time;
  final String category;
  final int frequency;

  RoutineActionCard({required this.title, required this.time, required this.category, required this.frequency});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(category),
          child: Text(time.split(':')[0], style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$time • $category'),
            if (frequency > 1) Text('${frequency}x per day', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.more_vert),
          onPressed: () {},
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Morning': return Colors.orange;
      case 'Afternoon': return Colors.blue;
      case 'Evening': return Colors.purple;
      default: return Colors.grey;
    }
  }
}
