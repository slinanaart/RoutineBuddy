import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Save user settings during setup
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
    
    await prefs.setString('scheduleMode', scheduleMode);
    await prefs.setBool('isCasualTemplate', isCasualTemplate);
    print('DEBUG: User settings saved successfully');
  } catch (e) {
    print('DEBUG: Error saving user settings: $e');
  }
}

/// Load user settings from SharedPreferences
Future<Map<String, dynamic>> loadUserSettings() async {
  final prefs = await SharedPreferences.getInstance();
  
  // Load wake and bed times
  final wakeHour = prefs.getInt('wakeTime_hour') ?? 7;
  final wakeMinute = prefs.getInt('wakeTime_minute') ?? 0;
  final bedHour = prefs.getInt('bedTime_hour') ?? 23;
  final bedMinute = prefs.getInt('bedTime_minute') ?? 0;
  
  // Create TimeOfDay objects
  final wakeTime = TimeOfDay(hour: wakeHour, minute: wakeMinute);
  final bedTime = TimeOfDay(hour: bedHour, minute: bedMinute);
  
  // Load meal times and names
  final mealTimes = <TimeOfDay>[];
  final mealNames = <String>[];
  for (int i = 0; i < 3; i++) {
    final hour = prefs.getInt('meal${i}_hour');
    final minute = prefs.getInt('meal${i}_minute');
    final name = prefs.getString('meal${i}_name');
    if (hour != null && minute != null) {
      mealTimes.add(TimeOfDay(hour: hour, minute: minute));
      mealNames.add(name ?? 'Meal ${i + 1}');
    }
  }
  
  final scheduleMode = prefs.getString('scheduleMode') ?? 'daily';
  final isCasualTemplate = prefs.getBool('isCasualTemplate') ?? false;
  
  return {
    'wakeTime': wakeTime,
    'bedTime': bedTime,
    'mealTimes': mealTimes,
    'mealNames': mealNames,
    'scheduleMode': scheduleMode,
    'isCasualTemplate': isCasualTemplate,
  };
}

/// Helper function to format time with 00:00 instead of 12:00 AM
String formatTimeCustom(BuildContext context, TimeOfDay time) {
  if (time.hour == 0) {
    return '00:${time.minute.toString().padLeft(2, '0')}';
  }
  return time.format(context);
}

/// Helper function for next-day aware time sorting
int compareTimesWithNextDay(TimeOfDay timeA, TimeOfDay timeB, TimeOfDay wakeTime, TimeOfDay bedTime) {
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
