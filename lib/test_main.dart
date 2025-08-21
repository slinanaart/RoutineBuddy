import 'package:flutter/material.dart';

// Enhanced Timeline Widget with Live Drag and Time Updates
class DraggableTimelineWidget extends StatefulWidget {
  final List<Map<String, dynamic>> actions;
  final Function(int, int) onReorder;
  final Function(Map<String, dynamic>) onActionTap;
  final TimeOfDay wakeTime;
  final TimeOfDay bedTime;

  const DraggableTimelineWidget({
    Key? key,
    required this.actions,
    required this.onReorder,
    required this.onActionTap,
    this.wakeTime = const TimeOfDay(hour: 7, minute: 0),
    this.bedTime = const TimeOfDay(hour: 23, minute: 30),
  }) : super(key: key);

  @override
  _DraggableTimelineWidgetState createState() => _DraggableTimelineWidgetState();
}

class _DraggableTimelineWidgetState extends State<DraggableTimelineWidget> {
  Map<String, dynamic>? draggingAction;
  TimeOfDay? previewTime;
  double? dragStartY;
  TimeOfDay? dragStartTime;

  @override
  Widget build(BuildContext context) {
    final now = TimeOfDay.now();
    
    return Stack(
      children: [
        // Hour ticks background
        _buildHourTicks(),
        
        // Action items
        ListView.builder(
          itemCount: widget.actions.length,
          itemBuilder: (context, index) {
            final action = widget.actions[index];
            final actionTime = action['time'] as TimeOfDay;
            final isPastAction = _isTimePast(actionTime, now);
            
            return _buildDraggableActionItem(
              action: action,
              index: index,
              isPastAction: isPastAction,
            );
          },
        ),
        
        // Floating time preview during drag
        if (draggingAction != null && previewTime != null)
          _buildFloatingTimePreview(),
      ],
    );
  }

  Widget _buildHourTicks() {
    final startHour = widget.wakeTime.hour;
    final endHour = widget.bedTime.hour + (widget.bedTime.minute > 0 ? 1 : 0);
    
    return Positioned.fill(
      child: CustomPaint(
        painter: TimelineTicksPainter(
          startHour: startHour,
          endHour: endHour,
        ),
      ),
    );
  }

  Widget _buildDraggableActionItem({
    required Map<String, dynamic> action,
    required int index,
    required bool isPastAction,
  }) {
    final actionTime = action['time'] as TimeOfDay;
    
    return LongPressDraggable<Map<String, dynamic>>(
      data: action,
      onDragStarted: () {
        setState(() {
          draggingAction = action;
          dragStartTime = actionTime;
        });
      },
      onDragUpdate: (details) {
        _updatePreviewTime(details.globalPosition.dy);
      },
      onDragEnd: (details) {
        if (previewTime != null) {
          // Update the action's time
          action['time'] = previewTime!;
          widget.onReorder(index, index); // Trigger re-sort
        }
        setState(() {
          draggingAction = null;
          previewTime = null;
          dragStartY = null;
          dragStartTime = null;
        });
      },
      feedback: _buildDragFeedback(action),
      childWhenDragging: _buildPlaceholder(),
      child: _buildActionCard(action, isPastAction),
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action, bool isPastAction) {
    final actionTime = action['time'] as TimeOfDay;
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        children: [
          // Time indicator
          Container(
            width: 60,
            child: Text(
              actionTime.format(context),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isPastAction ? Colors.grey : Colors.black87,
              ),
            ),
          ),
          
          // Timeline line and dot
          Container(
            width: 20,
            height: 60,
            child: Column(
              children: [
                Expanded(child: Container(width: 2, color: Colors.grey[300])),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPastAction ? Colors.grey : _getCategoryColor(action['category']),
                  ),
                ),
                Expanded(child: Container(width: 2, color: Colors.grey[300])),
              ],
            ),
          ),
          
          // Action card
          Expanded(
            child: GestureDetector(
              onTap: isPastAction ? null : () => widget.onActionTap(action),
              child: Card(
                color: isPastAction ? Colors.grey[100] : null,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isPastAction ? Colors.grey : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            action['category'],
                            style: TextStyle(
                              fontSize: 12,
                              color: isPastAction ? Colors.grey : Colors.grey[600],
                            ),
                          ),
                          if ((action['frequency'] ?? 1) > 1) ...[
                            Text(' • ', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            Text(
                              '${action['frequency']}x/day',
                              style: TextStyle(
                                fontSize: 12,
                                color: isPastAction ? Colors.grey : Colors.grey[600],
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
          ),
        ],
      ),
    );
  }

  Widget _buildDragFeedback(Map<String, dynamic> action) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 200,
        padding: EdgeInsets.all(12),
        child: Text(
          action['name'],
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 60,
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[400]!, width: 2, style: BorderStyle.solid),
      ),
    );
  }

  Widget _buildFloatingTimePreview() {
    return Positioned(
      top: 50,
      right: 20,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(20),
        color: Colors.blue,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            previewTime!.format(context),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  void _updatePreviewTime(double globalY) {
    if (dragStartY == null) {
      dragStartY = globalY;
      return;
    }

    final deltaY = globalY - dragStartY!;
    final minutesDelta = (deltaY / 2).round(); // 2 pixels per minute
    
    if (dragStartTime != null) {
      final startMinutes = dragStartTime!.hour * 60 + dragStartTime!.minute;
      final newMinutes = (startMinutes + minutesDelta).clamp(
        widget.wakeTime.hour * 60 + widget.wakeTime.minute,
        widget.bedTime.hour * 60 + widget.bedTime.minute,
      );
      
      setState(() {
        previewTime = TimeOfDay(
          hour: newMinutes ~/ 60,
          minute: newMinutes % 60,
        );
      });
    }
  }

  bool _isTimePast(TimeOfDay actionTime, TimeOfDay currentTime) {
    final actionMinutes = actionTime.hour * 60 + actionTime.minute;
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    return actionMinutes < currentMinutes;
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Health': return Colors.green;
      case 'Fitness': return Colors.orange;
      case 'Work': return Colors.blue;
      case 'Learning': return Colors.purple;
      case 'Mindfulness': return Colors.teal;
      case 'Social': return Colors.pink;
      case 'Entertainment': return Colors.amber;
      case 'Household': return Colors.brown;
      case 'Errands': return Colors.indigo;
      case 'Planning': return Colors.cyan;
      default: return Colors.grey;
    }
  }
}

class TimelineTicksPainter extends CustomPainter {
  final int startHour;
  final int endHour;

  TimelineTicksPainter({required this.startHour, required this.endHour});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;

    final hourHeight = size.height / (endHour - startHour);

    for (int hour = startHour; hour <= endHour; hour++) {
      final y = (hour - startHour) * hourHeight;
      
      // Hour line
      canvas.drawLine(
        Offset(80, y),
        Offset(100, y),
        paint,
      );

      // Hour label
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${hour.toString().padLeft(2, '0')}:00',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(canvas, Offset(10, y - 6));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('The Casual Routine')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                RoutineActionCard(title: '☕ Morning coffee', time: '7:30 AM', category: 'Morning', frequency: 1),
                RoutineActionCard(title: '📧 Check email', time: '8:00 AM', category: 'Morning', frequency: 1),
                RoutineActionCard(title: '🏃 Exercise routine', time: '6:30 AM', category: 'Morning', frequency: 1),
                RoutineActionCard(title: '🍽️ Lunch break', time: '12:00 PM', category: 'Afternoon', frequency: 1),
                RoutineActionCard(title: '🚶 Evening walk', time: '6:00 PM', category: 'Evening', frequency: 1),
                RoutineActionCard(title: '📱 Plan tomorrow', time: '10:00 PM', category: 'Evening', frequency: 1),
              ],
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
  TimeOfDay wakeTime = TimeOfDay(hour: 7, minute: 0);
  TimeOfDay bedTime = TimeOfDay(hour: 23, minute: 30);
  List<TimeOfDay> mealTimes = [
    TimeOfDay(hour: 8, minute: 0),   // Breakfast
    TimeOfDay(hour: 12, minute: 0),  // Lunch  
    TimeOfDay(hour: 19, minute: 0),  // Dinner
  ];
  String scheduleMode = 'Weekly';
  Set<int> dayOffs = {}; // 1=Mon, 2=Tue, ..., 7=Sun
  bool stopRoutineOnDayOffs = false;

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
                    subtitle: Text(wakeTime.format(context)),
                    onTap: () async {
                      final time = await showTimePicker(context: context, initialTime: wakeTime);
                      if (time != null) setState(() => wakeTime = time);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.bedtime),
                    title: Text('Bed time'),
                    subtitle: Text(bedTime.format(context)),
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
                    return ListTile(
                      leading: Icon(Icons.restaurant),
                      title: Text('Meal ${index + 1}'),
                      subtitle: Text(meal.format(context)),
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
                    title: Text('Stop Routine on the day-offs'),
                    subtitle: Text('No actions will be indicated on selected day-off days'),
                    value: stopRoutineOnDayOffs,
                    onChanged: (value) => setState(() => stopRoutineOnDayOffs = value),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 32),
          
          // Continue Button
          FilledButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ActionPickerScreen())),
            icon: Icon(Icons.navigate_next),
            label: Text('Continue to add actions'),
          ),
        ],
      ),
    );
  }

  void _addMeal() async {
    final time = await showTimePicker(context: context, initialTime: TimeOfDay(hour: 12, minute: 0));
    if (time != null) {
      setState(() {
        mealTimes.add(time);
        _sortMealTimes();
      });
    }
  }

  void _editMeal(int index) async {
    final time = await showTimePicker(context: context, initialTime: mealTimes[index]);
    if (time != null) {
      setState(() {
        mealTimes[index] = time;
        _sortMealTimes();
      });
    }
  }

  void _removeMeal(int index) {
    setState(() => mealTimes.removeAt(index));
  }

  void _sortMealTimes() {
    mealTimes.sort((a, b) {
      final aMinutes = a.hour * 60 + a.minute;
      final bMinutes = b.hour * 60 + b.minute;
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

// Action picker screen
class ActionPickerScreen extends StatefulWidget {
  @override
  _ActionPickerScreenState createState() => _ActionPickerScreenState();
}

class _ActionPickerScreenState extends State<ActionPickerScreen> {
  List<String> selectedActions = [];
  String sortBy = 'category'; // 'category', 'time', 'day'
  String? selectedCategory;
  String? selectedTimeOfDay;
  String? selectedDayOfWeek;
  String searchQuery = '';
  
  List<Map<String, dynamic>> allActions = [
    {'name': '☕ Morning coffee', 'category': 'Health', 'timeOfDay': 'Morning', 'dayOfWeek': 'Daily', 'time': TimeOfDay(hour: 7, minute: 30), 'frequency': 1},
    {'name': '📧 Check email', 'category': 'Work', 'timeOfDay': 'Morning', 'dayOfWeek': 'Weekdays', 'time': TimeOfDay(hour: 9, minute: 0), 'frequency': 3},
    {'name': '🏃 Exercise routine', 'category': 'Fitness', 'timeOfDay': 'Morning', 'dayOfWeek': 'Daily', 'time': TimeOfDay(hour: 6, minute: 30), 'frequency': 1},
    {'name': '🍽️ Lunch break', 'category': 'Health', 'timeOfDay': 'Afternoon', 'dayOfWeek': 'Daily', 'time': TimeOfDay(hour: 12, minute: 0), 'frequency': 1},
    {'name': '🚶 Evening walk', 'category': 'Fitness', 'timeOfDay': 'Evening', 'dayOfWeek': 'Daily', 'time': TimeOfDay(hour: 18, minute: 0), 'frequency': 1},
    {'name': '📚 Read', 'category': 'Learning', 'timeOfDay': 'Evening', 'dayOfWeek': 'Daily', 'time': TimeOfDay(hour: 20, minute: 0), 'frequency': 1},
    {'name': '🧘 Meditation', 'category': 'Mindfulness', 'timeOfDay': 'Morning', 'dayOfWeek': 'Daily', 'time': TimeOfDay(hour: 6, minute: 0), 'frequency': 1},
    {'name': '💼 Work focus time', 'category': 'Work', 'timeOfDay': 'Morning', 'dayOfWeek': 'Weekdays', 'time': TimeOfDay(hour: 10, minute: 0), 'frequency': 1},
    {'name': '🍳 Prepare breakfast', 'category': 'Health', 'timeOfDay': 'Morning', 'dayOfWeek': 'Daily', 'time': TimeOfDay(hour: 8, minute: 0), 'frequency': 1},
    {'name': '🚿 Shower', 'category': 'Health', 'timeOfDay': 'Morning', 'dayOfWeek': 'Daily', 'time': TimeOfDay(hour: 7, minute: 0), 'frequency': 1},
    {'name': '📱 Plan day', 'category': 'Planning', 'timeOfDay': 'Morning', 'dayOfWeek': 'Weekdays', 'time': TimeOfDay(hour: 8, minute: 30), 'frequency': 1},
    {'name': '🎵 Listen to music', 'category': 'Entertainment', 'timeOfDay': 'Evening', 'dayOfWeek': 'Daily', 'time': TimeOfDay(hour: 19, minute: 0), 'frequency': 1},
    {'name': '🛒 Grocery shopping', 'category': 'Errands', 'timeOfDay': 'Afternoon', 'dayOfWeek': 'Weekend', 'time': TimeOfDay(hour: 14, minute: 0), 'frequency': 1},
    {'name': '🧽 House cleaning', 'category': 'Household', 'timeOfDay': 'Afternoon', 'dayOfWeek': 'Weekend', 'time': TimeOfDay(hour: 15, minute: 0), 'frequency': 1},
    {'name': '📞 Call family', 'category': 'Social', 'timeOfDay': 'Evening', 'dayOfWeek': 'Weekend', 'time': TimeOfDay(hour: 17, minute: 0), 'frequency': 1},
  ];

  List<String> get categories => allActions.map((a) => a['category'] as String).toSet().toList()..sort();
  List<String> get timesOfDay => allActions.map((a) => a['timeOfDay'] as String).toSet().toList();
  List<String> get daysOfWeek => allActions.map((a) => a['dayOfWeek'] as String).toSet().toList();

  List<Map<String, dynamic>> get filteredAndSortedActions {
    List<Map<String, dynamic>> filtered = allActions.where((action) {
      bool matchesSearch = searchQuery.isEmpty || 
          action['name'].toLowerCase().contains(searchQuery.toLowerCase());
      bool matchesCategory = selectedCategory == null || action['category'] == selectedCategory;
      bool matchesTime = selectedTimeOfDay == null || action['timeOfDay'] == selectedTimeOfDay;
      bool matchesDay = selectedDayOfWeek == null || action['dayOfWeek'] == selectedDayOfWeek;
      
      return matchesSearch && matchesCategory && matchesTime && matchesDay;
    }).toList();
    
    if (sortBy == 'category') {
      filtered.sort((a, b) => a['category'].compareTo(b['category']));
    } else if (sortBy == 'time') {
      filtered.sort((a, b) {
        Map<String, int> timeOrder = {'Morning': 1, 'Afternoon': 2, 'Evening': 3};
        return timeOrder[a['timeOfDay']]!.compareTo(timeOrder[b['timeOfDay']]!);
      });
    } else if (sortBy == 'day') {
      filtered.sort((a, b) {
        Map<String, int> dayOrder = {'Daily': 1, 'Weekdays': 2, 'Weekend': 3};
        return dayOrder[a['dayOfWeek']]!.compareTo(dayOrder[b['dayOfWeek']]!);
      });
    }
    
    return filtered;
  }

  void _editAction(Map<String, dynamic> action) async {
    final shouldAutoSelect = await showDialog<bool>(
      context: context,
      builder: (context) => _ActionEditDialog(
        action: action,
        onSave: (updatedAction) {
          setState(() {
            int index = allActions.indexWhere((a) => a['name'] == action['name']);
            if (index != -1) {
              allActions[index] = updatedAction;
            }
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
                // Search bar
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Search actions',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => searchQuery = value),
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
                          DropdownMenuItem(value: null, child: Text('All Categories')),
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
                          DropdownMenuItem(value: null, child: Text('All Times')),
                          ...timesOfDay.map((time) => DropdownMenuItem(value: time, child: Text(time))),
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
                          labelText: 'Frequency',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.repeat),
                        ),
                        value: selectedDayOfWeek,
                        items: [
                          DropdownMenuItem(value: null, child: Text('All Days')),
                          ...daysOfWeek.map((day) => DropdownMenuItem(value: day, child: Text(day))),
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
                        });
                      },
                      icon: Icon(Icons.clear),
                      label: Text('Clear'),
                    ),
                  ],
                ),
                
                // Sort chips
                SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.category, size: 16),
                          SizedBox(width: 4),
                          Text('Category'),
                        ],
                      ),
                      selected: sortBy == 'category',
                      onSelected: (selected) => setState(() => sortBy = 'category'),
                    ),
                    FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time, size: 16),
                          SizedBox(width: 4),
                          Text('Time'),
                        ],
                      ),
                      selected: sortBy == 'time',
                      onSelected: (selected) => setState(() => sortBy = 'time'),
                    ),
                    FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today, size: 16),
                          SizedBox(width: 4),
                          Text('Day'),
                        ],
                      ),
                      selected: sortBy == 'day',
                      onSelected: (selected) => setState(() => sortBy = 'day'),
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
                                    Text('${action['time'].format(context)}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                    SizedBox(width: 12),
                                    Icon(Icons.repeat, size: 14, color: Colors.grey[600]),
                                    SizedBox(width: 4),
                                    Text('${action['frequency']}x/day', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
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
                          Icon(Icons.edit, color: Colors.grey[400]),
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
                      final action = allActions.firstWhere((a) => a['name'] == actionName);
                      routineActions.add({
                        'name': action['name'],
                        'time': action['time'],
                        'category': action['category'],
                        'frequency': action['frequency'],
                      });
                    }
                    
                    // Navigate to home screen with routine tab and pass the selected actions
                    Navigator.pushReplacement(
                      context, 
                      MaterialPageRoute(
                        builder: (_) => HomeScreen(
                          initialTabIndex: 1, // Routine tab
                          routineActions: routineActions,
                        )
                      )
                    );
                  }
                : null,
              icon: Icon(Icons.check),
              label: Text('Done (${selectedActions.length} selected)'),
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
    
    if (dayOfWeek == 'Weekend') {
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
  
  _ActionEditDialog({required this.action, required this.onSave});
  
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
            subtitle: Text(selectedTime.format(context)),
            onTap: () async {
              final time = await showTimePicker(context: context, initialTime: selectedTime);
              if (time != null) {
                setState(() => selectedTime = time);
              }
            },
          ),
          
          ListTile(
            leading: Icon(Icons.repeat),
            title: Text('Frequency'),
            subtitle: Text('$frequency times per day'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: frequency > 1 ? () => setState(() => frequency--) : null,
                  icon: Icon(Icons.remove),
                ),
                Text('$frequency'),
                IconButton(
                  onPressed: frequency < 10 ? () => setState(() => frequency++) : null,
                  icon: Icon(Icons.add),
                ),
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
          onPressed: () {
            final updatedAction = Map<String, dynamic>.from(widget.action);
            updatedAction['time'] = selectedTime;
            updatedAction['frequency'] = frequency;
            widget.onSave(updatedAction);
            Navigator.pop(context, true); // Return true to indicate auto-select
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}

// Main home screen with tabs
class HomeScreen extends StatefulWidget {
  final int initialTabIndex;
  final List<Map<String, dynamic>>? routineActions;
  final bool isCasualTemplate;
  
  HomeScreen({
    this.initialTabIndex = 0,
    this.routineActions,
    this.isCasualTemplate = false,
  });
  
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialTabIndex;
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
          ),
          SettingsTab(),
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
  
  RoutineTab({this.routineActions, this.isCasualTemplate = false});

  @override
  _RoutineTabState createState() => _RoutineTabState();
}

class _RoutineTabState extends State<RoutineTab> {
  late List<Map<String, dynamic>> displayActions;
  late String headerText;

  @override
  void initState() {
    super.initState();
    _initializeDisplayActions();
  }

  void _initializeDisplayActions() {
    if (widget.isCasualTemplate) {
      displayActions = List.from(casualTemplateActions);
      headerText = 'The Casual - Today';
    } else if (widget.routineActions != null && widget.routineActions!.isNotEmpty) {
      displayActions = List.from(widget.routineActions!);
      // Sort by time
      displayActions.sort((a, b) {
        final timeA = a['time'] as TimeOfDay;
        final timeB = b['time'] as TimeOfDay;
        return (timeA.hour * 60 + timeA.minute).compareTo(timeB.hour * 60 + timeB.minute);
      });
      headerText = 'Your Routine - Today';
    } else {
      displayActions = [];
      headerText = 'Today - August 16';
    }
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
              IconButton(onPressed: () {}, icon: Icon(Icons.chevron_left)),
              Text(headerText, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () {}, icon: Icon(Icons.chevron_right)),
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
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ActionPickerScreen())),
            icon: Icon(Icons.add),
            label: Text('Add Action'),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalTimeline() {
    return DraggableTimelineWidget(
      actions: displayActions,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          // Sort actions by time after any changes
          displayActions.sort((a, b) {
            final timeA = a['time'] as TimeOfDay;
            final timeB = b['time'] as TimeOfDay;
            return (timeA.hour * 60 + timeA.minute).compareTo(timeB.hour * 60 + timeB.minute);
          });
        });
      },
      onActionTap: (action) => _editTimelineAction(context, action, displayActions),
      wakeTime: TimeOfDay(hour: 7, minute: 0), // Could be from settings
      bedTime: TimeOfDay(hour: 23, minute: 30), // Could be from settings
    );
  }

  void _editTimelineAction(BuildContext context, Map<String, dynamic> action, List<Map<String, dynamic>> allActions) async {
    // Create a copy of the action for editing
    Map<String, dynamic> editedAction = Map.from(action);
    
    showDialog(
      context: context,
      builder: (context) => _TimelineActionEditDialog(
        action: editedAction,
        onSave: (updatedAction) {
          setState(() {
            // Find and update the action in the list
            int index = displayActions.indexWhere((a) => 
              a['name'] == action['name'] && 
              a['time'] == action['time'] && 
              a['category'] == action['category']
            );
            
            if (index != -1) {
              // Handle frequency-based anchor distribution
              if ((updatedAction['frequency'] ?? 1) > 1) {
                _distributeActionWithAnchors(context, updatedAction, displayActions, index);
              } else {
                displayActions[index] = updatedAction;
              }
            }
          });
        },
      ),
    );
  }

  void _distributeActionWithAnchors(BuildContext context, Map<String, dynamic> action, List<Map<String, dynamic>> allActions, int originalIndex) {
    int frequency = action['frequency'] ?? 1;
    if (frequency <= 1) {
      allActions[originalIndex] = action;
      return;
    }

    // Get wake and bed times from SharedPreferences or use defaults
    TimeOfDay wakeTime = TimeOfDay(hour: 7, minute: 0);   // Default wake time
    TimeOfDay bedTime = TimeOfDay(hour: 23, minute: 30);  // Default bed time
    
    // Calculate total minutes in the day from wake to bed
    int wakeTotalMinutes = wakeTime.hour * 60 + wakeTime.minute;
    int bedTotalMinutes = bedTime.hour * 60 + bedTime.minute;
    int totalDayMinutes = bedTotalMinutes - wakeTotalMinutes;
    
    // Calculate interval between anchors
    int intervalMinutes = totalDayMinutes ~/ frequency;
    
    // Remove the original action
    allActions.removeAt(originalIndex);
    
    // Create new actions at anchor points
    for (int i = 0; i < frequency; i++) {
      int anchorMinutes = wakeTotalMinutes + (i * intervalMinutes);
      int hours = anchorMinutes ~/ 60;
      int minutes = anchorMinutes % 60;
      
      // Ensure hours don't exceed 23
      if (hours > 23) {
        hours = 23;
        minutes = 30;
      }
      
      Map<String, dynamic> newAction = Map.from(action);
      newAction['time'] = TimeOfDay(hour: hours, minute: minutes);
      newAction['name'] = '${action['name']} ${i + 1}/${frequency}';
      
      allActions.add(newAction);
    }
    
    // Sort actions by time
    allActions.sort((a, b) {
      final timeA = a['time'] as TimeOfDay;
      final timeB = b['time'] as TimeOfDay;
      return (timeA.hour * 60 + timeA.minute).compareTo(timeB.hour * 60 + timeB.minute);
    });
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
          ListTile(
            leading: Icon(Icons.access_time),
            title: Text('Time'),
            subtitle: Text(selectedTime.format(context)),
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
          SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'Frequency (times per day)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            controller: TextEditingController(text: frequency.toString()),
            onChanged: (value) {
              setState(() {
                frequency = int.tryParse(value) ?? 1;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
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
  @override
  _SettingsTabState createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  TimeOfDay wakeTime = TimeOfDay(hour: 7, minute: 0);
  TimeOfDay bedTime = TimeOfDay(hour: 23, minute: 30);
  List<TimeOfDay> mealTimes = [
    TimeOfDay(hour: 8, minute: 0),   // Breakfast
    TimeOfDay(hour: 12, minute: 0),  // Lunch  
    TimeOfDay(hour: 19, minute: 0),  // Dinner
  ];
  String scheduleMode = 'Weekly';
  Set<int> dayOffs = {}; // 1=Mon, 2=Tue, ..., 7=Sun
  bool stopRoutineOnDayOffs = true; // New option

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
                  subtitle: Text(wakeTime.format(context)),
                  onTap: () async {
                    final time = await showTimePicker(context: context, initialTime: wakeTime);
                    if (time != null) setState(() => wakeTime = time);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.bedtime),
                  title: Text('Bed time'),
                  subtitle: Text(bedTime.format(context)),
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
                  return ListTile(
                    leading: Icon(Icons.restaurant),
                    title: Text('Meal ${index + 1}'),
                    subtitle: Text(meal.format(context)),
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
                  subtitle: Text('Do not show any routine actions on selected day-offs'),
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
    final time = await showTimePicker(context: context, initialTime: TimeOfDay(hour: 12, minute: 0));
    if (time != null) {
      setState(() {
        mealTimes.add(time);
        _sortMealTimes();
      });
    }
  }

  void _editMeal(int index) async {
    final time = await showTimePicker(context: context, initialTime: mealTimes[index]);
    if (time != null) {
      setState(() {
        mealTimes[index] = time;
        _sortMealTimes();
      });
    }
  }

  void _removeMeal(int index) {
    setState(() => mealTimes.removeAt(index));
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
