import 'package:flutter/material.dart';
import 'main_checkpoint6.dart' as main;

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
    selectedDate = DateTime.now();
    _loadPreviewActions();
  }
  
  void _loadPreviewActions() {
    final currentWeekday = selectedDate.weekday;
    final dayActions = main.getCasualTemplateActions()
        .where((action) => action['dayOfWeek'] == currentWeekday)
        .map((action) {
          final newAction = Map<String, dynamic>.from(action);
          // Add frequency based on category and action type
          if (action['category'] == 'health' || action['category'] == 'exercise') {
            if (action['name'].toString().contains('water')) {
              newAction['frequency'] = 6;
            } else if (action['name'].toString().contains('stretch')) {
              newAction['frequency'] = 2;
            } else if (action['name'].toString().contains('walk')) {
              newAction['frequency'] = 2;
            } else if (action['name'].toString().contains('posture')) {
              newAction['frequency'] = 4;
            } else {
              newAction['frequency'] = 1;
            }
            
            // Calculate spread times for frequent actions
            if (newAction['frequency'] > 1 && !action['isScheduleTime']) {
              final frequency = newAction['frequency'] as int;
              final startHour = 6; // 6 AM
              final endHour = 22; // 10 PM
              final totalMinutes = (endHour - startHour) * 60;
              final intervalMinutes = totalMinutes ~/ frequency;
              
              List<TimeOfDay> spreadTimes = [];
              for (int i = 0; i < frequency; i++) {
                final minutesFromStart = i * intervalMinutes;
                final newHour = ((startHour * 60 + minutesFromStart) ~/ 60) % 24;
                final newMinute = (startHour * 60 + minutesFromStart) % 60;
                spreadTimes.add(TimeOfDay(hour: newHour, minute: newMinute));
              }
              newAction['spreadTimes'] = spreadTimes;
              newAction['time'] = spreadTimes[0]; // Use first time as main time
            }
          }
          return newAction;
        })
        .toList();
        
    // Sort actions by time
    dayActions.sort((a, b) {
      final timeA = a['time'] as TimeOfDay;
      final timeB = b['time'] as TimeOfDay;
      return (timeA.hour * 60 + timeA.minute).compareTo(timeB.hour * 60 + timeB.minute);
    });
    
    setState(() {
      displayActions = dayActions;
    });
  }

  String _getCategoryDisplayName(String category) {
    return category.substring(0, 1).toUpperCase() + category.substring(1);
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'schedule':
        return Colors.purple;
      case 'health':
        return Colors.green;
      case 'exercise':
        return Colors.orange;
      case 'productivity':
        return Colors.blue;
      case 'leisure':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'schedule':
        return Icons.schedule;
      case 'health':
        return Icons.favorite;
      case 'exercise':
        return Icons.fitness_center;
      case 'productivity':
        return Icons.work;
      case 'leisure':
        return Icons.beach_access;
      default:
        return Icons.circle;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('The Casual Template'),
      ),
      body: ListView.builder(
        itemCount: displayActions.length,
        padding: EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final action = displayActions[index];
          final time = action['time'] as TimeOfDay;
          final name = action['name'] ?? 'Unknown';
          final category = action['category'] ?? 'General';
          final displayCategory = _getCategoryDisplayName(category);
          final frequency = action['frequency'] as int?;
          final spreadTimes = action['spreadTimes'] as List<TimeOfDay>?;
          
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
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayCategory,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  if (frequency != null && frequency > 1) ...[
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sync,
                                size: 12,
                                color: Colors.blue[800],
                              ),
                              SizedBox(width: 2),
                              Text(
                                '${frequency}x/day',
                                style: TextStyle(
                                  color: Colors.blue[800],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (spreadTimes != null) ...[
                      SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          ...spreadTimes.map((time) => 
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
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
    );
  }
}
