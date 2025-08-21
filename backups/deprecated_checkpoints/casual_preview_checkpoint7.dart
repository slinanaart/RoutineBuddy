import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';

class CasualTemplatePreviewTab extends StatefulWidget {
  @override
  _CasualTemplatePreviewTabState createState() => _CasualTemplatePreviewTabState();
}

class _CasualTemplatePreviewTabState extends State<CasualTemplatePreviewTab> {
  final DateTime _currentDate = DateTime.now();
  final List<Map<String, dynamic>> _templateActions = [];
  List<Map<String, dynamic>> displayActions = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadTemplateActions();
  }

  Future<void> _loadTemplateActions() async {
    try {
      _templateActions.clear();
      final String jsonString = await DefaultAssetBundle.of(context)
          .loadString('assets/data/templates.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      _templateActions.addAll(jsonList.map((action) {
        final timeStr = action['time'].toString();
        final parts = timeStr.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        Map<String, dynamic> actionMap = {
          'name': action['name'],
          'category': action['category'],
          'time': TimeOfDay(hour: hour, minute: minute),
        };

        // Handle frequency and spread times
        if (action.containsKey('frequency') && action['frequency'] != null) {
          actionMap['frequency'] = action['frequency'];
          actionMap['spreadTimes'] = _generateSpreadTimes(
            TimeOfDay(hour: hour, minute: minute),
            action['frequency'],
          );
        }

        return actionMap;
      }).toList());

      _updateDisplayActions();
    } catch (e) {
      print('Error loading template actions: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<TimeOfDay> _generateSpreadTimes(TimeOfDay baseTime, int frequency) {
    if (frequency <= 1) return [baseTime];

    // Generate spread times between 6 AM and 10 PM
    const int startHour = 6;  // 6 AM
    const int endHour = 22;   // 10 PM
    final int totalMinutes = (endHour - startHour) * 60;
    final int interval = totalMinutes ~/ (frequency - 1);

    List<TimeOfDay> times = [];
    for (int i = 0; i < frequency; i++) {
      final int minutesSinceStart = i * interval;
      final int hour = startHour + (minutesSinceStart ~/ 60);
      final int minute = minutesSinceStart % 60;
      if (hour <= endHour) {
        times.add(TimeOfDay(hour: hour, minute: minute));
      }
    }

    return times;
  }

  void _updateDisplayActions() {
    setState(() {
      displayActions = List.from(_templateActions);
      displayActions.sort((a, b) {
        final TimeOfDay timeA = a['time'];
        final TimeOfDay timeB = b['time'];
        final int minsA = timeA.hour * 60 + timeA.minute;
        final int minsB = timeB.hour * 60 + timeB.minute;
        return minsA.compareTo(minsB);
      });
    });
  }

  String _getFormattedDate() {
    return '${_currentDate.day}/${_currentDate.month}/${_currentDate.year}';
  }

  bool _canGoToPreviousDay() => true;
  bool _canGoToNextDay() => true;

  void _goToPreviousDay() {
    // Implement day navigation
  }

  void _goToNextDay() {
    // Implement day navigation
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'health':
        return Colors.green;
      case 'work':
        return Colors.blue;
      case 'social':
        return Colors.orange;
      case 'leisure':
        return Colors.purple;
      case 'daily':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'health':
        return Icons.favorite;
      case 'work':
        return Icons.work;
      case 'social':
        return Icons.people;
      case 'leisure':
        return Icons.beach_access;
      case 'daily':
        return Icons.calendar_today;
      default:
        return Icons.category;
    }
  }

  String _getCategoryDisplayName(String category) {
    switch (category.toLowerCase()) {
      case 'health':
        return 'Health & Wellness';
      case 'work':
        return 'Work & Study';
      case 'social':
        return 'Social Activities';
      case 'leisure':
        return 'Leisure & Hobby';
      case 'daily':
        return 'Daily Routine';
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Day navigation header
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: _canGoToPreviousDay() ? _goToPreviousDay : null,
                        icon: Icon(Icons.chevron_left),
                        tooltip: 'Previous day',
                      ),
                      Expanded(
                        child: Text(
                          _getFormattedDate(),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        onPressed: _canGoToNextDay() ? _goToNextDay : null,
                        icon: Icon(Icons.chevron_right),
                        tooltip: 'Next day',
                      ),
                    ],
                  ),
                ),
                
                // Preview actions list
                Expanded(
                  child: displayActions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.schedule, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No actions for this day',
                                style: TextStyle(color: Colors.grey, fontSize: 18),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: displayActions.length,
                          itemBuilder: (context, index) {
                            final action = displayActions[index];
                            final time = action['time'] as TimeOfDay;
                            final name = action['name'] ?? 'Unknown';
                            final category = action['category'] ?? 'General';
                            final displayCategory = _getCategoryDisplayName(category);
                            
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
                                    if (action.containsKey('frequency') && action['frequency'] != null)
                                      Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
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
                                                    '${action['frequency']}x/day',
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
                                      ),
                                    if (action.containsKey('spreadTimes'))
                                      Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            ...(action['spreadTimes'] as List<TimeOfDay>).map((time) => 
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
                                            ).toList(),
                                          ],
                                        ),
                                      ),
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
                ),
              ],
            ),
    );
  }
}
