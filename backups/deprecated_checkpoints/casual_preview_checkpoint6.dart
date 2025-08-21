import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'main.dart' as main_lib;

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
          .map((e) => e as String)
          .toList();
    } else if (json['recommended_time'] != null) {
      // From template.json - convert to list based on frequency
      final baseTime = json['recommended_time'] as String;
      recommendedTimes = [baseTime];
      
      // If frequency > 1, generate additional time slots
      if (frequency > 1) {
        final List<String> periods = ['Morning', 'Noon', 'Afternoon', 'Evening', 'Night'];
        recommendedTimes = List.generate(frequency, (i) {
          final index = (i * (periods.length / frequency)).floor();
          return periods[index.clamp(0, periods.length - 1)];
        });
      }
    }

    return RoutineAction(
      id: json['id']?.toString(),
      title: json['name'] as String? ?? json['title'] as String?,
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

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'id': id,
      'name': title,
      'category': category,
      'recommendedTimes': recommendedTimes,
      'recommendedDays': recommendedDays,
      'frequency': recommendedTimes?.length ?? 1,
    };

    if (time != null) {
      json['time'] = '${time!.hour}:${time!.minute}';
    }

    // Add frequency information if present
    if (recommendedTimes != null && recommendedTimes!.isNotEmpty) {
      json['frequency'] = recommendedTimes!.length;
    }

    return json;
  }
}

/// The main preview screen for the casual template
class CasualPreview extends StatefulWidget {
  const CasualPreview({super.key});

  @override
  State<CasualPreview> createState() => _CasualPreviewState();
}

class _CasualPreviewState extends State<CasualPreview> {
  List<RoutineAction> _actions = [];
  List<RoutineAction> _selectedActions = [];
  final Set<String> _expandedCategories = {};
  
  // Default times (will be updated from settings)
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _bedTime = const TimeOfDay(hour: 22, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadTimeSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActions();
    });
  }

  // Helper function to map time period to actual time
  TimeOfDay _mapTimePeriodToTime(String period, TimeOfDay wakeTime, TimeOfDay bedTime) {
    int wakeMinutes = wakeTime.hour * 60 + wakeTime.minute;
    int bedMinutes = bedTime.hour * 60 + bedTime.minute;
    
    // Handle next-day bed time
    if (bedMinutes < wakeMinutes) {
      bedMinutes += 24 * 60;
    }
  
    // Calculate day duration in minutes
    int dayDuration = bedMinutes - wakeMinutes;
    
    // Map periods to relative positions in the day
    Map<String, double> periodMap = {
      'early_morning': 0.0,
      'morning': 0.2,
      'late_morning': 0.3,
      'noon': 0.4,
      'afternoon': 0.5,
      'late_afternoon': 0.6,
      'evening': 0.7,
      'late_evening': 0.8,
      'night': 0.9,
    };
    
    double relativePosition = periodMap[period.toLowerCase()] ?? 0.5;
    int targetMinutes = wakeMinutes + (dayDuration * relativePosition).round();
    
    // Handle time wrapping to next day
    if (targetMinutes >= 24 * 60) {
      targetMinutes -= 24 * 60;
    }
    
    return TimeOfDay(
      hour: (targetMinutes ~/ 60) % 24,
      minute: targetMinutes % 60,
    );
  }

  // Helper function to generate evenly spread time slots based on frequency
  List<String> _generateTimeSlots(int frequency) {
    final List<String> periods = [
      'early_morning', 'morning', 'late_morning', 'noon',
      'afternoon', 'late_afternoon', 'evening', 'late_evening', 'night'
    ];
    
    if (frequency <= 1) return ['morning'];
    if (frequency >= periods.length) return periods;
    
    // Calculate step size to spread actions evenly
    final step = (periods.length / frequency).floor();
    final List<String> selectedPeriods = [];
    
    for (int i = 0; i < frequency; i++) {
      final index = (i * step) % periods.length;
      selectedPeriods.add(periods[index]);
    }
    
    return selectedPeriods;
  }
  
  // Helper function to format actions with proper frequency and time spreading
  List<Map<String, dynamic>> _formatActionsWithFrequency(List<RoutineAction> actions) {
    final List<Map<String, dynamic>> formattedActions = [];

    for (final action in actions) {
      final baseAction = action.toJson();
      final frequency = baseAction['frequency'] ?? 1;

      if (frequency > 1) {
        // Generate time slots based on frequency if recommendedTimes is not provided
        List<String> timeSlots = action.recommendedTimes ?? _generateTimeSlots(frequency);
        
        // Map each time slot to an actual TimeOfDay
        final List<TimeOfDay> timeslots = timeSlots.map((period) {
          return _mapTimePeriodToTime(period, _wakeTime, _bedTime);
        }).toList();

        // Sort timeslots chronologically
        timeslots.sort((a, b) {
          final minutesA = a.hour * 60 + a.minute;
          final minutesB = b.hour * 60 + b.minute;
          return minutesA.compareTo(minutesB);
        });

        // Create an action for each timeslot
        for (int i = 0; i < timeslots.length; i++) {
          final Map<String, dynamic> timeSlotAction = Map<String, dynamic>.from(baseAction);
          timeSlotAction['time'] = timeslots[i];
          timeSlotAction['frequency'] = 1;
          timeSlotAction['anchorIndex'] = i + 1;
          timeSlotAction['totalAnchors'] = frequency;
          timeSlotAction['originalFrequency'] = frequency;
          formattedActions.add(timeSlotAction);
        }
      } else {
        // For single-time actions or those without recommended times,
        // set a default time based on category or use morning
        final defaultTime = _mapTimePeriodToTime('morning', _wakeTime, _bedTime);
        baseAction['time'] = defaultTime;
        baseAction['frequency'] = 1;
        formattedActions.add(baseAction);
      }
    }

    return formattedActions;
  }

  Future<void> _loadTimeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _wakeTime = TimeOfDay(
          hour: prefs.getInt('wakeTime_hour') ?? 7,
          minute: prefs.getInt('wakeTime_minute') ?? 0,
        );
        _bedTime = TimeOfDay(
          hour: prefs.getInt('bedTime_hour') ?? 22,
          minute: prefs.getInt('bedTime_minute') ?? 0,
        );
      });
    } catch (e) {
      print('Error loading time settings: $e');
    }
  }

  Future<void> _loadActions() async {
    try {
      final bundle = DefaultAssetBundle.of(context);
      final jsonString = await bundle.loadString('assets/data/free_routine_actions.json');
      final jsonData = json.decode(jsonString) as List;
      setState(() {
        _actions = jsonData.map((json) => RoutineAction.fromJson(json)).toList();
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
    } catch (e) {
      print('Error loading actions: $e');
      setState(() {
        _actions = [];
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
    switch(category.toLowerCase()) {
      case 'meals':
        return Colors.orange;
      case 'activities':
        return Colors.blue;
      case 'rest':
        return Colors.purple;
      case 'exercise':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildActionCard(RoutineAction action) {
    final bool isSelected = _selectedActions.any((a) => a.id == action.id);

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
                // Always show frequency badge if frequency > 1 or has recommended times
                if ((action.recommendedTimes?.length ?? 0) > 1) ...[
                  // Frequency badge
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
                        Icon(Icons.repeat, size: 12, color: Colors.blue[700]),
                        const SizedBox(width: 4),
                        Text(
                          '${action.recommendedTimes!.length}x daily',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Times badge
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
                // Days badge
                if (action.recommendedDays?.isNotEmpty == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      action.recommendedDays!.join(", "),
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
            onPressed: _selectedActions.isEmpty ? null : () async {
              // Format actions with frequency and time spreading
              final formattedActions = _formatActionsWithFrequency(_selectedActions);

              // Save settings and navigate
              await main_lib.saveUserSettings(
                wakeTime: _wakeTime,
                bedTime: _bedTime,
                mealTimes: [], // Can be updated later in settings
                mealNames: [], // Can be updated later in settings
                scheduleMode: 'casual',
                isCasualTemplate: true,
              );

              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => main_lib.HomeScreen(
                    routineActions: formattedActions,
                    isCasualTemplate: true,
                    isFromInitialSetup: true,
                    wakeTime: _wakeTime,
                    bedTime: _bedTime,
                  ),
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
