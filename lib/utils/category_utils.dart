import 'package:flutter/material.dart';

class CategoryUtils {
  static Color getColor(String category) {
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
  
  static IconData getIcon(String category) {
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

  static String getDisplayName(String category) {
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
