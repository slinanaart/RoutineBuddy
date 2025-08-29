import 'package:flutter/material.dart';

class CasualTemplateAction {
  final int dayOfWeek;
  final TimeOfDay time;
  final String name;
  final String category;
  final List<String> recommendedTimes;
  final int frequency;
  final bool isPremium;

  CasualTemplateAction({
    required this.dayOfWeek,
    required this.time,
    required this.name,
    required this.category,
    this.recommendedTimes = const [],
    this.frequency = 1,
    this.isPremium = false,
  });

  factory CasualTemplateAction.fromMap(Map<String, String> map) {
    return CasualTemplateAction(
      dayOfWeek: _parseDayOfWeek(map['Day'] ?? 'Monday'),
      time: _parseTime(map['Time'] ?? '06:00'),
      name: map['Action'] ?? '',
      category: map['Category'] ?? '',
      recommendedTimes: (map['Recommended Times'] ?? '')
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      frequency: int.tryParse(map['Frequency'] ?? '1') ?? 1,
      isPremium: (map['Premium'] ?? '').toLowerCase() == 'yes',
    );
  }

  static int _parseDayOfWeek(String day) {
    const Map<String, int> dayMap = {
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
      'Sunday': 7,
    };
    return dayMap[day] ?? 1;
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

  List<CasualTemplateAction> spreadAnchors(TimeOfDay sleepTime) {
    if (frequency <= 1 || category.toLowerCase() == 'schedule') {
      return [this];
    }

    final List<CasualTemplateAction> anchors = [];
    final int startMinutes = time.hour * 60 + time.minute;
    int endMinutes = sleepTime.hour * 60 + sleepTime.minute;
    
    // Handle next-day sleep time
    if (endMinutes <= startMinutes) {
      endMinutes += 24 * 60;
    }

    final int interval = ((endMinutes - startMinutes) / frequency).floor();
    
    // Ensure minimum interval
    final int safeInterval = interval < 15 ? 15 : interval;

    for (int i = 0; i < frequency; i++) {
      final int anchorMinutes = startMinutes + (i * safeInterval);
      if (anchorMinutes >= endMinutes - 5) break; // Stop before sleep time

      final int hour = (anchorMinutes ~/ 60) % 24;
      final int minute = anchorMinutes % 60;

      anchors.add(CasualTemplateAction(
        dayOfWeek: dayOfWeek,
        time: TimeOfDay(hour: hour, minute: minute),
        name: name,
        category: category,
        recommendedTimes: recommendedTimes,
        frequency: frequency,
        isPremium: isPremium,
      ));
    }

    return anchors;
  }

  @override
  String toString() {
    return '$name at ${time.hour}:${time.minute.toString().padLeft(2, '0')} (x$frequency)';
  }
}
