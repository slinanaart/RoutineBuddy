import 'package:flutter/material.dart';

/// A model class representing a routine action with its properties
class RoutineAction {
  final String? id;
  final String? title;
  final String? category;
  final TimeOfDay? time;
  final List<String>? recommendedTimes;
  final List<String>? recommendedDays;

  RoutineAction({
    this.id,
    this.title,
    this.category,
    this.time,
    this.recommendedTimes,
    this.recommendedDays,
  });

  factory RoutineAction.fromJson(Map<String, dynamic> json) {
    // Handle both formats - template.json and free_routine_actions.json
    List<String>? recommendedTimes;
    // Get frequency first
    final int frequency = (json['frequency'] is String)
        ? int.tryParse(json['frequency'].toString()) ?? 1
        : (json['frequency'] as num?)?.toInt() ?? 1;

    if (json['recommendedTimes'] != null) {
      // From free_routine_actions.json
      recommendedTimes = (json['recommendedTimes'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();
    }

    return RoutineAction(
      id: json['id']?.toString(),
      title: json['name'] as String?,
      category: json['category'] as String?,
      time: json['time'] != null
          ? TimeOfDay(
              hour: int.parse(json['time'].split(':')[0]),
              minute: int.parse(json['time'].split(':')[1]),
            )
          : null,
      recommendedTimes: recommendedTimes,
      recommendedDays: (json['recommendedDays'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': title,
    'category': category,
    'time': time != null ? '${time!.hour}:${time!.minute}' : null,
    'recommendedTimes': recommendedTimes,
    'recommendedDays': recommendedDays,
  };
}
