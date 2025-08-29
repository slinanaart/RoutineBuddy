import 'package:flutter/material.dart';

class CasualTemplateSettings {
  final TimeOfDay wakeTime;
  final TimeOfDay sleepTime;
  final Map<String, TimeOfDay> mealTimes;
  final String scheduleMode;
  final List<String> dayOffs;
  final bool stopRoutineOnDayOffs;
  final bool repeatWeekdaysRoutine;

  CasualTemplateSettings({
    required this.wakeTime,
    required this.sleepTime,
    this.mealTimes = const {},
    this.scheduleMode = 'Daily',
    this.dayOffs = const ['Sat', 'Sun'],
    this.stopRoutineOnDayOffs = false,
    this.repeatWeekdaysRoutine = false,
  });

  factory CasualTemplateSettings.fromMap(Map<String, String> map) {
    return CasualTemplateSettings(
      wakeTime: _parseTime(map['Wake Time'] ?? '06:00'),
      sleepTime: _parseTime(map['Sleep Time'] ?? '22:30'),
      mealTimes: _parseMealTimes(map['Meal Times'] ?? ''),
      scheduleMode: map['Schedule Mode'] ?? 'Daily',
      dayOffs: (map['Day-offs'] ?? 'Sat, Sun').split(',').map((e) => e.trim()).toList(),
      stopRoutineOnDayOffs: map['Stop routine on the day-offs']?.toLowerCase() == 'on',
      repeatWeekdaysRoutine: map['Repeat weekdays routine']?.toLowerCase() == 'on',
    );
  }

  static TimeOfDay _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0].trim()),
        minute: int.parse(parts[1].trim()),
      );
    } catch (e) {
      debugPrint('Error parsing time: $timeStr');
      return const TimeOfDay(hour: 6, minute: 0);
    }
  }

  static Map<String, TimeOfDay> _parseMealTimes(String mealTimesStr) {
    try {
      final Map<String, TimeOfDay> result = {};
      final parts = mealTimesStr.split(',');
      for (var part in parts) {
        final mealParts = part.split(':');
        if (mealParts.length == 2) {
          final mealName = mealParts[0].trim().replaceAll(':', '');
          result[mealName] = _parseTime(mealParts[1].trim());
        }
      }
      return result;
    } catch (e) {
      debugPrint('Error parsing meal times: $mealTimesStr');
      return {};
    }
  }
}
