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
      home: FillYourRoutineScreen(),
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
      appBar: AppBar(title: Text('Fill your routine')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          TemplateCard(
            title: 'Use "The Casual"',
            subtitle: 'Our balanced default for Mon–Sun. You can edit later.',
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
class CasualPreviewScreen extends StatelessWidget {
  final List<Map<String, dynamic>> casualTemplateActions = [
    {'name': 'Wake up', 'time': '06:00', 'category': 'Schedule', 'isScheduleTime': true},
    {'name': 'Drink a glass of water', 'time': '06:35', 'category': 'Health', 'frequency': 1},
    {'name': 'Light stretch (5 min)', 'time': '06:45', 'category': 'Exercise', 'frequency': 2},
    {'name': 'Breakfast', 'time': '07:00', 'category': 'Schedule', 'isScheduleTime': true},
    {'name': 'Start work', 'time': '08:30', 'category': 'Productivity'},
    {'name': 'Stand up–sit down x10, check posture', 'time': '09:30', 'category': 'Exercise', 'frequency': 4},
    {'name': 'Water sips', 'time': '10:30', 'category': 'Health', 'frequency': 6},
    {'name': 'Lunch', 'time': '12:00', 'category': 'Schedule', 'isScheduleTime': true},
    {'name': 'Short walk', 'time': '12:45', 'category': 'Exercise', 'frequency': 2},
    {'name': 'Finish work', 'time': '17:30', 'category': 'Productivity'},
    {'name': 'Dinner', 'time': '19:30', 'category': 'Schedule', 'isScheduleTime': true},
    {'name': 'Self time', 'time': '21:00', 'category': 'Leisure', 'frequency': 1},
    {'name': 'Review tomorrow\'s routine', 'time': '22:00', 'category': 'Schedule', 'isScheduleTime': true},
    {'name': 'Sleep', 'time': '22:30', 'category': 'Schedule', 'isScheduleTime': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('The Casual Routine')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: casualTemplateActions.map((action) {
                final timeStr = action['time'] as String;
                final timeParts = timeStr.split(':');
                final hour = int.parse(timeParts[0]);
                final minute = int.parse(timeParts[1]);
                return RoutineActionCard(
                  title: action['name'],
                  time: formatTimeCustom(context, TimeOfDay(hour: hour, minute: minute)),
                  category: action['category'],
                  frequency: action['frequency'] ?? 1,
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: () => Navigator.pushReplacement(
                context, 
                MaterialPageRoute(
                  builder: (_) => HomeScreen(
                    initialTabIndex: 1, // Routine tab
                    isCasualTemplate: true,
                    routineActions: casualTemplateActions.map((action) {
                      final timeStr = action['time'] as String;
                      final timeParts = timeStr.split(':');
                      return {
                        ...action,
                        'time': TimeOfDay(
                          hour: int.parse(timeParts[0]),
                          minute: int.parse(timeParts[1]),
                        ),
                      };
                    }).toList(),
                    // Pass casual template settings to maintain consistency
                    wakeTime: TimeOfDay(hour: 6, minute: 0),   // Based on earliest activity (meditation 6:30)
                    bedTime: TimeOfDay(hour: 0, minute: 0),    // Default 00:00 AM (next day)
                    mealTimes: [
                      TimeOfDay(hour: 8, minute: 30),  // Healthy breakfast (from template)
                      TimeOfDay(hour: 12, minute: 0),  // Nutritious lunch (from template)  
                      TimeOfDay(hour: 19, minute: 0),  // Light dinner (from template)
                    ],
                    mealNames: ['Healthy breakfast', 'Nutritious lunch', 'Light dinner'],
                    repeatWorkdaysRoutine: false, // Turn off as specified
                  )
                )
              ),
              icon: Icon(Icons.check),
              label: Text('Apply This Routine'),
            ),
          ),
        ],
      ),
    );
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
  bool repeatWorkdaysRoutine = true; // New option

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Setup your routine settings')),
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
                    title: Text('Repeat workdays\' routine to other days'),
                    subtitle: Text('Copy today\'s routine actions to all other weekdays automatically'),
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
                final result = await Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => ActionPickerScreen(
                    wakeTime: wakeTime,
                    bedTime: bedTime,
                    existingActions: [], // Empty for initial setup
                  ))
                );
                
                if (result != null && result is List<Map<String, dynamic>>) {
                  // Process frequency-based anchors before passing to HomeScreen
                  List<Map<String, dynamic>> processedActions = [];
                  
                  for (var action in result) {
                    // Set dayOfWeek to 'Today' for initial setup
                    action['dayOfWeek'] = 'Today';
                    
                    if ((action['frequency'] ?? 1) > 1) {
                      // Create anchor distribution for actions with frequency > 1
                      var anchors = createActionAnchors(action, action['frequency']);
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
                      )
                    )
                  );
                } else {
                  // No valid actions received, staying on ManualSetupScreen
                }
              } catch (e) {
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
        return 'App adds "Create tomorrow\'s routine" 30 min before bed each workday';
      case 'Weekly':
        return 'App adds "Create next week routine" 30 min before bed on last workday';
      case 'Repeat':
        return 'Auto-carry last week\'s routine at 00:05 Monday if no new plan is set';
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

List<Map<String, dynamic>> createActionAnchors(Map<String, dynamic> action, int frequency) {
  List<Map<String, dynamic>> anchors = [];
  // Calculate time intervals based on frequency
  if (frequency > 1) {
    TimeOfDay originalTime = action['time'];
    int anchorMinutes = originalTime.hour * 60 + originalTime.minute;
    // Use dynamic sleep time calculation with next-day logic
    TimeOfDay currentSleepTime = TimeOfDay(hour: 0, minute: 0); // Default 00:00
    TimeOfDay currentWakeTime = TimeOfDay(hour: 6, minute: 0);  // Default 06:00
    int sleepMinutes = _calculateSleepMinutes(currentSleepTime, currentWakeTime);
    // Calculate available time window from anchor to sleep
    int availableMinutes = sleepMinutes - anchorMinutes;
    // If there's not enough time until sleep, use a minimum 1-hour window
    if (availableMinutes < 60) {
      availableMinutes = 60;
    }
    // Divide the available time into equal intervals
    // For frequency=2: one interval (anchor to sleep)
    // For frequency=3: two intervals (anchor -> middle -> sleep)
    int intervalMinutes = frequency > 1 ? availableMinutes ~/ (frequency - 1) : 0;
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
class MealEditDialog extends StatefulWidget {
  final String initialName;
  final TimeOfDay initialTime;
  final TimeOfDay wakeTime;
  final TimeOfDay bedTime;
  final bool isAddMode;
  
  MealEditDialog({
    required this.initialName, 
    required this.initialTime,
    required this.wakeTime,
    required this.bedTime,
    this.isAddMode = false,
  });
  
  @override
  MealEditDialogState createState() => MealEditDialogState();
}

class MealEditDialogState extends State<MealEditDialog> {
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
  
  ActionPickerScreen({required this.wakeTime, required this.bedTime, this.existingActions});
  
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
    // Initialize selected actions from existing timeline actions
    if (widget.existingActions != null) {
      for (var action in widget.existingActions!) {
        String actionName = action['name'];
        if (!selectedActions.contains(actionName)) {
          selectedActions.add(actionName);
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
  }
  
  List<Map<String, dynamic>> allActions = [
    {'name': '☕ Morning coffee', 'category': 'Health', 'timeOfDay': 'Morning', 'dayOfWeek': 'Daily', 'time': TimeOfDay(hour: 7, minute: 30), 'frequency': 1},
    {'name': '📧 Check email', 'category': 'Work', 'timeOfDay': 'Morning', 'dayOfWeek': 'Weekdays', 'time': TimeOfDay(hour: 9, minute: 0), 'frequency': 3},
    {'name': '🏃 Exercise routine', 'category': 'Fitness', 'timeOfDay': 'Morning', 'dayOfWeek': 'Daily', 'time': TimeOfDay(hour: 7, minute: 15), 'frequency': 1},
    {'name': '🍽️ Lunch break', 'category': 'Health', 'timeOfDay': 'Afternoon', 'dayOfWeek': 'Daily', 'time': TimeOfDay(hour: 12, minute: 0), 'frequency': 1},
    {'name': '🚶 Evening walk', 'category': 'Fitness', 'timeOfDay': 'Evening', 'dayOfWeek': 'Daily', 'time': TimeOfDay(hour: 18, minute: 0), 'frequency': 1},
    {'name': '📚 Read', 'category': 'Learning', 'timeOfDay': 'Evening', 'dayOfWeek': 'Daily', 'time': TimeOfDay(hour: 20, minute: 0), 'frequency': 1},
    {'name': '🧘 Meditation', 'category': 'Mindfulness', 'timeOfDay': 'Morning', 'dayOfWeek': 'Daily', 'time': TimeOfDay(hour: 6, minute: 30), 'frequency': 1},
    {'name': '💼 Work focus time', 'category': 'Work', 'timeOfDay': 'Morning', 'dayOfWeek': 'Weekdays', 'time': TimeOfDay(hour: 10, minute: 0), 'frequency': 1},
    {'name': '🍳 Prepare breakfast', 'category': 'Health', 'timeOfDay': 'Morning', 'dayOfWeek': 'Daily', 'time': TimeOfDay(hour: 8, minute: 0), 'frequency': 1},
    {'name': '🚿 Shower', 'category': 'Health', 'timeOfDay': 'Morning', 'dayOfWeek': 'Daily', 'time': TimeOfDay(hour: 7, minute: 30), 'frequency': 1},
    {'name': '📱 Plan day', 'category': 'Planning', 'timeOfDay': 'Morning', 'dayOfWeek': 'Weekdays', 'time': TimeOfDay(hour: 8, minute: 30), 'frequency': 1},
    {'name': '🎵 Listen to music', 'category': 'Entertainment', 'timeOfDay': 'Evening', 'dayOfWeek': 'Daily', 'time': TimeOfDay(hour: 19, minute: 0), 'frequency': 1},
    {'name': '🛒 Grocery shopping', 'category': 'Errands', 'timeOfDay': 'Afternoon', 'dayOfWeek': 'Day-offs', 'time': TimeOfDay(hour: 14, minute: 0), 'frequency': 1},
    {'name': '🧽 House cleaning', 'category': 'Household', 'timeOfDay': 'Afternoon', 'dayOfWeek': 'Day-offs', 'time': TimeOfDay(hour: 15, minute: 0), 'frequency': 1},
    {'name': '📞 Call family', 'category': 'Social', 'timeOfDay': 'Evening', 'dayOfWeek': 'Day-offs', 'time': TimeOfDay(hour: 17, minute: 0), 'frequency': 1},
  ];

  List<String> get categories => allActions.map((a) => a['category'] as String).toSet().toList()..sort();
  List<String> get timesOfDay => allActions.map((a) => a['timeOfDay'] as String).toSet().toList();
  List<String> get daysOfWeek => allActions.map((a) => a['dayOfWeek'] as String).toSet().toList();

  void _updateSearchSuggestions(String query) {
    if (query.isEmpty) {
      setState(() {
        showSuggestions = false;
        searchSuggestions = [];
      });
      return;
    }
    
    final lowerQuery = query.toLowerCase();
    Set<String> suggestions = {};
    
    // Add matching action names
    for (var action in allActions) {
      if (action['category'] != 'Schedule') { // Exclude schedule actions
        String name = action['name'] as String;
        String category = action['category'] as String;
        if (name.toLowerCase().contains(lowerQuery)) {
          suggestions.add(name);
        }
        if (category.toLowerCase().contains(lowerQuery)) {
          suggestions.add(category);
        }
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
    return Scaffold(
      appBar: AppBar(title: Text('Add some actions')),
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
                                    _getRecommendationIcon(action['timeOfDay'], action['dayOfWeek']),
                                    SizedBox(width: 8),
                                    Text('${action['timeOfDay']} • ${action['dayOfWeek']}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
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
                    // Convert selected actions to routine actions with their configured times
                    List<Map<String, dynamic>> routineActions = [];
                    for (String actionName in selectedActions) {
                      final action = allActions.firstWhere(
                        (a) => a['name'] == actionName,
                        orElse: () => {
                          'name': actionName,
                          'category': 'Custom',
                          'time': TimeOfDay(hour: 12, minute: 0),
                          'frequency': 1,
                        }
                      );
                      // Use stored state if available, otherwise use default from allActions
                      final storedState = actionStates[actionName];
                      routineActions.add({
                        'name': action['name'],
                        'time': storedState?['time'] ?? action['time'],
                        'category': action['category'],
                        'frequency': storedState?['frequency'] ?? action['frequency'],
                      });
                    }
                    
                    // Return the selected actions to the calling screen
                    Navigator.pop(context, routineActions);
                  }
                : null,
              icon: Icon(Icons.check),
              label: Text('Done (${_getNonScheduleActionCount()} selected)'),
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
  
  HomeScreen({
    this.initialTabIndex = 0,
    this.routineActions,
    this.isCasualTemplate = false,
    this.wakeTime,
    this.bedTime,
    this.mealTimes,
    this.mealNames,
    this.repeatWorkdaysRoutine,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('RoutineBuddy')),
      body: IndexedStack(
        index: currentIndex,
        children: [
          TemplatesTab(),
          RoutineTab(
            routineActions: widget.routineActions,
            isCasualTemplate: widget.isCasualTemplate,
            wakeTime: wakeTime,
            bedTime: bedTime,
            repeatWorkdaysRoutine: widget.repeatWorkdaysRoutine ?? false,
          ),
          SettingsTab(
            wakeTime: wakeTime,
            bedTime: bedTime,
            mealTimes: mealTimes,
            mealNames: mealNames,
            isCasualTemplate: widget.isCasualTemplate,
            repeatWorkdaysRoutine: widget.repeatWorkdaysRoutine,
            onWakeTimeChanged: (time) => setState(() => wakeTime = time),
            onBedTimeChanged: (time) => setState(() => bedTime = time),
            onMealTimesChanged: (times) => setState(() => mealTimes = times),
            onMealNamesChanged: (names) => setState(() => mealNames = names),
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
  final bool repeatWorkdaysRoutine;
  
  RoutineTab({
    this.routineActions, 
    this.isCasualTemplate = false,
    this.wakeTime,
    this.bedTime,
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
    // Start with an empty list
    displayActions = [];
    
    // Process actions from template or existing routine
    List<Map<String, dynamic>> sourceActions = [];
    if (widget.routineActions != null && widget.routineActions!.isNotEmpty) {
      sourceActions = widget.routineActions!;
    }
    
    // Process each action and handle frequency/anchors
    for (var action in sourceActions) {
      final frequency = action['frequency'] ?? 1;
      
      if (frequency > 1 && !action['isScheduleTime']) {
        // Generate multiple anchors for high-frequency actions
        final wakeMinutes = (widget.wakeTime?.hour ?? 6) * 60 + (widget.wakeTime?.minute ?? 0);
        final bedMinutes = (widget.bedTime?.hour ?? 0) * 60 + (widget.bedTime?.minute ?? 0);
        
        // Handle next-day bedtime
        final totalMinutes = bedMinutes <= wakeMinutes 
          ? (bedMinutes + 24 * 60) - wakeMinutes 
          : bedMinutes - wakeMinutes;
          
        final interval = totalMinutes ~/ (frequency + 1); // +1 to create proper spacing
        
        // Create anchored instances
        for (int i = 0; i < frequency; i++) {
          final anchorMinutes = wakeMinutes + ((i + 1) * interval);
          final adjustedHour = (anchorMinutes ~/ 60) % 24;
          final adjustedMinute = anchorMinutes % 60;
          
          displayActions.add({
            ...action,
            'time': TimeOfDay(hour: adjustedHour, minute: adjustedMinute),
            'anchorIndex': i + 1,
            'totalAnchors': frequency,
            'originalFrequency': frequency,
          });
        }
      } else {
        // Single occurrence - add as is
        displayActions.add(action);
      }
    }
    
    // Sort all actions by time
    displayActions.sort((a, b) {
      final timeA = a['time'] as TimeOfDay;
      final timeB = b['time'] as TimeOfDay;
      final timeComparison = _compareTimesWithNextDay(timeA, timeB,
        widget.wakeTime ?? TimeOfDay(hour: 6, minute: 0),
        widget.bedTime ?? TimeOfDay(hour: 0, minute: 0));
      
      // If times are equal, prioritize schedule items
      if (timeComparison == 0) {
        bool isScheduleA = a['isScheduleTime'] == true;
        bool isScheduleB = b['isScheduleTime'] == true;
        
        if (isScheduleA && !isScheduleB) return -1;
        if (!isScheduleA && isScheduleB) return 1;
      }
      
      return timeComparison;
    });
    
    headerText = _getFormattedDate();
    
    print('DEBUG: Timeline sorted for ${headerText}:');
    for (int i = 0; i < displayActions.length; i++) {
      final a = displayActions[i];
      final time = a['time'] as TimeOfDay;
      print('DEBUG: [$i] ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} - ${a['name']} (schedule: ${a['isScheduleTime'] == true})');
    }
  }
  
  String _getSelectedDayName() {
    const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return dayNames[selectedDate.weekday - 1];
  }
  
  bool _isWeekday(DateTime date) {
    return date.weekday >= 1 && date.weekday <= 5; // Monday = 1, Friday = 5
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    if (_isSameDay(selectedDate, now)) {
      return 'Today - ${monthNames[selectedDate.month - 1]} ${selectedDate.day}';
    } else if (_isSameDay(selectedDate, now.add(Duration(days: 1)))) {
      return 'Tomorrow - ${monthNames[selectedDate.month - 1]} ${selectedDate.day}';
    } else if (_isSameDay(selectedDate, now.subtract(Duration(days: 1)))) {
      return 'Yesterday - ${monthNames[selectedDate.month - 1]} ${selectedDate.day}';
    } else {
      return '${monthNames[selectedDate.month - 1]} ${selectedDate.day}, ${selectedDate.year}';
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  void _goToPreviousDay() {
    setState(() {
      selectedDate = selectedDate.subtract(Duration(days: 1));
      headerText = _getFormattedDate();
    });
  }

  void _goToNextDay() {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: 1));
      headerText = _getFormattedDate();
    });
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

  // Delete a single anchor instance at the given displayActions index.
  void _deleteAnchorAt(int index) {
    setState(() {
      if (index < 0 || index >= displayActions.length) return;

      final target = displayActions[index];
      if (!target.containsKey('anchorIndex')) return; // not an anchor

      // Remove the specific anchor
      displayActions.removeAt(index);

      // Find other anchors that belong to the same action (match by name+category)
      String key = '${target['name']}_${target['category']}';
      List<int> anchorPositions = [];
      for (int i = 0; i < displayActions.length; i++) {
        final a = displayActions[i];
        if (a.containsKey('anchorIndex')) {
          if ('${a['name']}_${a['category']}' == key) {
            anchorPositions.add(i);
          }
        }
      }

      // Recompute totalAnchors and anchorIndex for remaining anchors of this action
      int total = anchorPositions.length;
      for (int i = 0; i < anchorPositions.length; i++) {
        final pos = anchorPositions[i];
        displayActions[pos]['anchorIndex'] = i + 1;
        displayActions[pos]['totalAnchors'] = total;
      }

      // After mutation, sort and normalize times/order
      displayActions.sort((a, b) {
        final timeA = a['time'] as TimeOfDay;
        final timeB = b['time'] as TimeOfDay;
        return _compareTimesWithNextDay(timeA, timeB, widget.wakeTime ?? TimeOfDay(hour: 6, minute: 0), widget.bedTime ?? TimeOfDay(hour: 0, minute: 0));
      });
    });
  }

  // Duplicate a single anchor instance at the given displayActions index.
  // Duplicate will insert another anchor instance with the same time and
  // increment totalAnchors for the whole action.
  void _duplicateAnchorAt(int index) {
    setState(() {
      if (index < 0 || index >= displayActions.length) return;

      final target = Map<String, dynamic>.from(displayActions[index]);
      if (!target.containsKey('anchorIndex')) return; // not an anchor

      // Find group key and existing anchors
      String key = '${target['name']}_${target['category']}';
      List<int> anchorPositions = [];
      for (int i = 0; i < displayActions.length; i++) {
        final a = displayActions[i];
        if (a.containsKey('anchorIndex')) {
          if ('${a['name']}_${a['category']}' == key) {
            anchorPositions.add(i);
          }
        }
      }

      // Insert a copy adjacent to the current index (after it)
      final newAnchor = Map<String, dynamic>.from(target);
      // Reset identifying fields for the new anchor; will reindex below
      newAnchor['anchorIndex'] = null;
      newAnchor['totalAnchors'] = null;
      displayActions.insert(index + 1, newAnchor);

      // Recompute totalAnchors and anchorIndex for all anchors of this action
      // Recollect positions
      anchorPositions = [];
      for (int i = 0; i < displayActions.length; i++) {
        final a = displayActions[i];
        if (a.containsKey('anchorIndex') || ('${a['name']}_${a['category']}' == key)) {
          if ('${a['name']}_${a['category']}' == key) anchorPositions.add(i);
        }
      }

      int total = anchorPositions.length;
      for (int i = 0; i < anchorPositions.length; i++) {
        final pos = anchorPositions[i];
        displayActions[pos]['anchorIndex'] = i + 1;
        displayActions[pos]['totalAnchors'] = total;
        // ensure frequency and originalFrequency fields remain consistent
        displayActions[pos]['frequency'] = 1;
      }

      // Sort by time and update order
      displayActions.sort((a, b) {
        final timeA = a['time'] as TimeOfDay;
        final timeB = b['time'] as TimeOfDay;
        return _compareTimesWithNextDay(timeA, timeB, widget.wakeTime ?? TimeOfDay(hour: 6, minute: 0), widget.bedTime ?? TimeOfDay(hour: 0, minute: 0));
      });
    });
  }
  
  List<Map<String, dynamic>> get casualTemplateActions => [
    {'name': '☕ Morning coffee', 'time': TimeOfDay(hour: 7, minute: 30), 'category': 'Health'},
    {'name': '🧘 Meditation', 'time': TimeOfDay(hour: 6, minute: 30), 'category': 'Mindfulness'},
    {'name': '🏃 Morning exercise', 'time': TimeOfDay(hour: 8, minute: 0), 'category': 'Fitness'},
    {'name': '🍳 Healthy breakfast', 'time': TimeOfDay(hour: 8, minute: 30), 'category': 'Health'},
    {'name': '💼 Plan Top 3 tasks', 'time': TimeOfDay(hour: 9, minute: 0), 'category': 'Planning'},
    {'name': '🍽️ Nutritious lunch', 'time': TimeOfDay(hour: 12, minute: 0), 'category': 'Health'},
    {'name': '🚶 Afternoon walk', 'time': TimeOfDay(hour: 16, minute: 0), 'category': 'Fitness'},
    {'name': '🍽️ Light dinner', 'time': TimeOfDay(hour: 19, minute: 0), 'category': 'Health'},
    {'name': '📚 Read for 30 minutes', 'time': TimeOfDay(hour: 21, minute: 0), 'category': 'Learning'},
    {'name': '🙏 Gratitude journaling', 'time': TimeOfDay(hour: 22, minute: 0), 'category': 'Mindfulness'},
  ];

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
                onPressed: _goToPreviousDay, 
                icon: Icon(Icons.chevron_left),
                tooltip: 'Previous day',
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(Duration(days: 365)),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        selectedDate = pickedDate;
                        headerText = _getFormattedDate();
                      });
                    }
                  },
                  child: Text(
                    headerText, 
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
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
              // Consolidate anchored actions back to their original form for ActionPickerScreen
              List<Map<String, dynamic>> consolidatedActions = [];
              Map<String, Map<String, dynamic>> actionGroups = {};
              List<Map<String, dynamic>> scheduleItems = [];
              
              for (var action in displayActions) {
                // Separate schedule items (wake, meals, sleep) for later processing
                if (action['category'] == 'Schedule') {
                  scheduleItems.add(action);
                  continue;
                }
                
                String actionKey = '${action['name']}_${action['category']}';
                
                if (action.containsKey('anchorIndex')) {
                  // This is an anchored action
                  if (!actionGroups.containsKey(actionKey)) {
                    actionGroups[actionKey] = {
                      'name': action['name'],
                      'category': action['category'],
                      'time': action['time'], // Will be updated to earliest time
                      'frequency': action['originalFrequency'] ?? action['totalAnchors'] ?? 1,
                      'anchorTimes': <TimeOfDay>[action['time']], // Track all anchor times
                    };
                  } else {
                    // Add this anchor time to the list
                    List<TimeOfDay> anchorTimes = actionGroups[actionKey]!['anchorTimes'] as List<TimeOfDay>;
                    anchorTimes.add(action['time']);
                    // Update to earliest time for display purposes, but preserve actual frequency
                    TimeOfDay earliestTime = anchorTimes.reduce((a, b) => 
                      (a.hour * 60 + a.minute) < (b.hour * 60 + b.minute) ? a : b);
                    actionGroups[actionKey]!['time'] = earliestTime;
                    // Update frequency to match actual count of anchors or preserve original frequency
                    actionGroups[actionKey]!['frequency'] = action['originalFrequency'] ?? anchorTimes.length;
                  }
                } else {
                  // This is a single action
                  actionGroups[actionKey] = {
                    'name': action['name'],
                    'category': action['category'],
                    'time': action['time'],
                    'frequency': action['frequency'] ?? 1,
                  };
                }
              }
              
              // Clean up the anchorTimes field and create final list
              for (var actionData in actionGroups.values) {
                actionData.remove('anchorTimes');
                consolidatedActions.add(actionData);
              }
              
              // Add schedule items back to the consolidated list
              consolidatedActions.addAll(scheduleItems);
              
              final result = await Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => ActionPickerScreen(
                  wakeTime: widget.wakeTime ?? TimeOfDay(hour: 6, minute: 0),
                  bedTime: widget.bedTime ?? TimeOfDay(hour: 0, minute: 0),
                  existingActions: consolidatedActions, // Pass consolidated actions
                ))
              );
              
              if (result != null && result is List<Map<String, dynamic>>) {
                setState(() {
                  // Clear existing actions and rebuild from ActionPickerScreen result
                  displayActions.clear();
                  
                  // Process each action from the result
                  for (var action in result) {
                    // Handle frequency-based anchor distribution
                    if ((action['frequency'] ?? 1) > 1) {
                      _addActionWithAnchors(action);
                    } else {
                      displayActions.add(action);
                    }
                  }
                  
                  // Sort all actions by time, with schedule items appearing before actions at the same time
                  displayActions.sort((a, b) {
                    final timeA = a['time'] as TimeOfDay;
                    final timeB = b['time'] as TimeOfDay;
                    final timeComparison = _compareTimesWithNextDay(timeA, timeB, 
                      widget.wakeTime ?? TimeOfDay(hour: 6, minute: 0), 
                      widget.bedTime ?? TimeOfDay(hour: 0, minute: 0));
                    
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
                        color: _getCategoryColor(action['category']),
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
              
              // Action card
              Expanded(
                child: InkWell(
                  onTap: (_isActionPast(action['time']) || action['isScheduleTime'] == true)
                    ? null  // Disable tap for past actions and schedule times
                    : () => _editTimelineAction(context, action, displayActions),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: action['isScheduleTime'] == true
                        ? Colors.blue[50]  // Light blue background for schedule times
                        : _isActionPast(action['time']) 
                          ? Colors.grey[100]  // Grey background for past actions
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: action['isScheduleTime'] == true
                        ? Border.all(color: Colors.blue[200]!, width: 1)
                        : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(_isActionPast(action['time']) ? 0.05 : 0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                action['name'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: _isActionPast(action['time']) 
                                    ? Colors.grey[500]  // Grey text for past actions
                                    : Colors.black,
                                ),
                              ),
                            ),
                            // Drag handle + optional anchor menu (Delete / Duplicate)
                            Row(
                              children: [
                                Icon(
                                  Icons.drag_handle, 
                                  color: _isActionPast(action['time']) 
                                    ? Colors.grey[300]  // Lighter drag handle for past actions
                                    : Colors.grey[400], 
                                  size: 20
                                ),
                                // Only show the anchor menu for anchored actions
                                if (action.containsKey('anchorIndex'))
                                  PopupMenuButton<String>(
                                    padding: EdgeInsets.zero,
                                    onSelected: (value) {
                                      if (value == 'delete') {
                                        _deleteAnchorAt(index);
                                      } else if (value == 'duplicate') {
                                        _duplicateAnchorAt(index);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(value: 'delete', child: Text('Delete this anchor')),
                                      PopupMenuItem(value: 'duplicate', child: Text('Duplicate this anchor')),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _isActionPast(action['time'])
                                  ? Colors.grey[200]  // Grey badge for past actions
                                  : _getCategoryColor(action['category']).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                action['category'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _isActionPast(action['time'])
                                    ? Colors.grey[600]  // Grey text for past actions
                                    : _getCategoryColor(action['category']),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (action.containsKey('anchorIndex')) ...[
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue[300]!, width: 1),
                                ),
                                child: Text(
                                  '${action['anchorIndex'] ?? 1}/${action['totalAnchors'] ?? 1}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ] else if ((action['frequency'] ?? 1) > 1) ...[
                              SizedBox(width: 8),
                              Text(
                                '${action['frequency']}x/day',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
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
            
            // Sort the timeline by time, with schedule items appearing before actions at the same time
            displayActions.sort((a, b) {
              final timeA = a['time'] as TimeOfDay;
              final timeB = b['time'] as TimeOfDay;
              final timeComparison = _compareTimesWithNextDay(timeA, timeB, 
                TimeOfDay(hour: 6, minute: 0), TimeOfDay(hour: 0, minute: 0));
              
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

    // Get wake and bed times from SharedPreferences or use defaults
    TimeOfDay wakeTime = TimeOfDay(hour: 6, minute: 0);   // Default wake time
    TimeOfDay bedTime = TimeOfDay(hour: 0, minute: 0);  // Default sleep time
    
    // Convert times to minutes for easier calculation
    int startMinutes = startTime.hour * 60 + startTime.minute;
    int wakeMinutes = wakeTime.hour * 60 + wakeTime.minute;
    int bedMinutes = bedTime.hour * 60 + bedTime.minute;
    
    // Handle next day sleep (e.g., sleep at 00:00 = next day)
    if (bedMinutes < wakeMinutes) {
      bedMinutes += 24 * 60; // Add 24 hours for next day
    }
    
    // Calculate available time from start time to sleep
    int availableMinutes = bedMinutes - startMinutes;
    
    // If start time is before wake time, use wake time as start
    if (startMinutes < wakeMinutes) {
      startMinutes = wakeMinutes;
      availableMinutes = bedMinutes - wakeMinutes;
    }
    
    // Calculate interval between anchors (we want frequency anchors, so frequency-1 intervals)
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

  void _addActionWithAnchors(Map<String, dynamic> action) {
    int frequency = action['frequency'] ?? 1;
    if (frequency <= 1) {
      displayActions.add(action);
      return;
    }

    // Use the action's time as starting point for distribution
    _distributeActionWithAnchorsFromTime(context, action, displayActions, action['time']);
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
            updatedAction['frequency'] = frequency;
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
  final Function(TimeOfDay)? onWakeTimeChanged;
  final Function(TimeOfDay)? onBedTimeChanged;
  final Function(List<TimeOfDay>)? onMealTimesChanged;
  final Function(List<String>)? onMealNamesChanged;
  
  SettingsTab({
    this.wakeTime,
    this.bedTime,
    this.mealTimes,
    this.mealNames,
    this.isCasualTemplate = false,
    this.repeatWorkdaysRoutine,
    this.onWakeTimeChanged,
    this.onBedTimeChanged,
    this.onMealTimesChanged,
    this.onMealNamesChanged,
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
  bool repeatWorkdaysRoutine = true; // New option

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
    
    // Set casual template specific defaults
    if (widget.isCasualTemplate) {
      scheduleMode = 'Weekly';
      dayOffs = {6, 7}; // Saturday and Sunday (6=Sat, 7=Sun)
      stopRoutineOnDayOffs = false; // Turn off as specified
      repeatWorkdaysRoutine = widget.repeatWorkdaysRoutine ?? false; // Use passed value
    } else {
      // Manual setup defaults
      repeatWorkdaysRoutine = widget.repeatWorkdaysRoutine ?? true;
    }
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
                  return ListTile(
                    leading: Icon(Icons.restaurant),
                    title: Text('Meal ${index + 1}'),
                    subtitle: Text(formatTimeCustom(context, meal)),
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
              ],
            ),
          ),
        ),
        SizedBox(height: 32),
        
        // Save Button
        FilledButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Settings saved successfully!')),
            );
          },
          icon: Icon(Icons.save),
          label: Text('Save Settings'),
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
        return 'App adds "Create tomorrow\'s routine" 30 min before bed each workday';
      case 'Weekly':
        return 'App adds "Create next week routine" 30 min before bed on last workday';
      case 'Repeat':
        return 'Auto-carry last week\'s routine at 00:05 Monday if no new plan is set';
      default:
        return '';
    }
  }

  String _weekdayName(int day) => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day - 1];
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
