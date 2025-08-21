import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'main.dart';

/// ===== Action Model =====
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
      recommendedTimes: (json['recommendedTimes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      recommendedDays: (json['recommendedDays'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': title,
      'category': category,
      'time': time != null ? '${time!.hour}:${time!.minute}' : null,
      'recommendedTimes': recommendedTimes,
      'recommendedDays': recommendedDays,
      'frequency': recommendedTimes?.length ?? 1,
    };
  }
}

class CasualPreview extends StatefulWidget {
  const CasualPreview({super.key});

  @override
  State<CasualPreview> createState() => _CasualPreviewState();
}

class _CasualPreviewState extends State<CasualPreview> {
  List<RoutineAction> _actions = [];
  List<RoutineAction> _selectedActions = [];
  final Set<String> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    _loadActions();
  }

  Future<void> _loadActions() async {
    final String jsonString =
        await DefaultAssetBundle.of(context).loadString('assets/data/free_routine_actions.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    setState(() {
      _actions = jsonList.map((json) => RoutineAction.fromJson(json)).toList();
    });

    // Load selected actions from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final String? selectedActionsJson = prefs.getString('selectedActions');
    if (selectedActionsJson != null) {
      final List<dynamic> selectedList = json.decode(selectedActionsJson);
      setState(() {
        _selectedActions =
            selectedList.map((json) => RoutineAction.fromJson(json)).toList();
      });
    }
  }

  Future<void> _saveSelectedActions() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString =
        json.encode(_selectedActions.map((a) => a.toJson()).toList());
    await prefs.setString('selectedActions', jsonString);
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'health':
        return Colors.green;
      case 'exercise':
        return Colors.blue;
      case 'productivity':
        return Colors.orange;
      case 'leisure':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildActionCard(RoutineAction action) {
    final bool isSelected =
        _selectedActions.any((a) => a.id == action.id);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        title: Text(action.title ?? 'Untitled Action'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(action.category ?? 'default'),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    action.category ?? 'Uncategorized',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Frequency indicator
                if (action.recommendedTimes?.isNotEmpty == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.repeat, size: 12, color: Colors.blue.withOpacity(0.7)),
                        const SizedBox(width: 2),
                        Text(
                          '${action.recommendedTimes!.length}x/day',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (action.recommendedTimes?.isNotEmpty == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      action.recommendedTimes!.join(", "),
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            isSelected ? Icons.check_circle : Icons.add_circle_outline,
            color: isSelected ? Colors.green : null,
          ),
          onPressed: () {
            setState(() {
              if (isSelected) {
                _selectedActions.removeWhere((a) => a.id == action.id);
              } else {
                _selectedActions.add(action);
              }
              _saveSelectedActions();
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Group actions by category
    final Map<String, List<RoutineAction>> categorizedActions = {};
    for (var action in _actions) {
      final category = action.category ?? 'Uncategorized';
      if (!categorizedActions.containsKey(category)) {
        categorizedActions[category] = [];
      }
      categorizedActions[category]!.add(action);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Actions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              // Convert selected actions to the format expected by MainScreen
              final List<Map<String, dynamic>> distributedActions = [];
              for (final action in _selectedActions) {
                final baseAction = action.toJson();
                final frequency = action.recommendedTimes?.length ?? 1;
                
                if (frequency > 1) {
                  // Map recommended times to actual TimeOfDay values
                  final List<TimeOfDay> timeslots = action.recommendedTimes!.map((timeStr) {
                    switch (timeStr.toLowerCase()) {
                      case 'morning':
                        return const TimeOfDay(hour: 8, minute: 0);
                      case 'noon':
                        return const TimeOfDay(hour: 12, minute: 0);
                      case 'afternoon':
                        return const TimeOfDay(hour: 14, minute: 0);
                      case 'evening':
                        return const TimeOfDay(hour: 18, minute: 0);
                      case 'night':
                        return const TimeOfDay(hour: 20, minute: 0);
                      default:
                        return const TimeOfDay(hour: 8, minute: 0);
                    }
                  }).toList();

                  // Create an action for each time slot
                  for (int i = 0; i < timeslots.length; i++) {
                    final newAction = Map<String, dynamic>.from(baseAction);
                    newAction['time'] = timeslots[i];
                    newAction['frequency'] = 1;
                    newAction['anchorIndex'] = i + 1;
                    newAction['totalAnchors'] = frequency;
                    newAction['originalFrequency'] = frequency;
                    distributedActions.add(newAction);
                  }
                } else {
                  // For single-time actions, use a default time
                  baseAction['time'] = const TimeOfDay(hour: 8, minute: 0);
                  distributedActions.add(baseAction);
                }
              }

              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => MainScreen(actions: distributedActions),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: categorizedActions.entries.map((entry) {
          final category = entry.key;
          final actions = entry.value;
          final isExpanded = _expandedCategories.contains(category);

          return ExpansionTile(
            key: Key(category),
            initiallyExpanded: isExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                if (expanded) {
                  _expandedCategories.add(category);
                } else {
                  _expandedCategories.remove(category);
                }
              });
            },
            title: Text(
              category,
              style: TextStyle(
                color: _getCategoryColor(category),
                fontWeight: FontWeight.bold,
              ),
            ),
            children: actions.map(_buildActionCard).toList(),
          );
        }).toList(),
      ),
    );
  }
}
