import 'package:flutter/material.dart';
import '../models/casual_template_settings.dart';
import '../models/casual_template_action.dart';
import '../utils/casual_template_parser.dart';

class CasualPreviewScreen extends StatefulWidget {
  const CasualPreviewScreen({Key? key}) : super(key: key);

  @override
  State<CasualPreviewScreen> createState() => _CasualPreviewScreenState();
}

class _CasualPreviewScreenState extends State<CasualPreviewScreen> {
  late Future<(CasualTemplateSettings, List<CasualTemplateAction>)> _templateFuture;
  int _selectedDayOfWeek = DateTime.now().weekday;
  CasualTemplateSettings? _settings;
  List<CasualTemplateAction>? _actions;

  @override
  void initState() {
    super.initState();
    _templateFuture = _loadTemplate();
  }

  Future<(CasualTemplateSettings, List<CasualTemplateAction>)> _loadTemplate() async {
    return CasualTemplateParser.parseFromAsset('assets/data/The_Casual_Template.csv');
  }

  List<CasualTemplateAction> _getActionsForDay(int dayOfWeek) {
    if (_actions == null || _settings == null) return [];

    final dayActions = _actions!
        .where((action) => action.dayOfWeek == dayOfWeek)
        .expand((action) => action.spreadAnchors(_settings!.sleepTime))
        .toList();

    // Sort by time
    dayActions.sort((a, b) {
      final aMinutes = a.time.hour * 60 + a.time.minute;
      final bMinutes = b.time.hour * 60 + b.time.minute;
      return aMinutes.compareTo(bMinutes);
    });

    return dayActions;
  }

  String _getDayName(int dayOfWeek) {
    const days = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[dayOfWeek];
  }

  void _previousDay() {
    setState(() {
      _selectedDayOfWeek = _selectedDayOfWeek > 1 ? _selectedDayOfWeek - 1 : 7;
    });
  }

  void _nextDay() {
    setState(() {
      _selectedDayOfWeek = _selectedDayOfWeek < 7 ? _selectedDayOfWeek + 1 : 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Casual Preview'),
      ),
      body: FutureBuilder(
        future: _templateFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No template data available'));
          }

          _settings = snapshot.data!.$1;
          _actions = snapshot.data!.$2;

          final dayActions = _getActionsForDay(_selectedDayOfWeek);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _previousDay,
                    ),
                    Text(
                      _getDayName(_selectedDayOfWeek),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _nextDay,
                    ),
                  ],
                ),
              ),
              if (_settings != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Wake: ${_settings!.wakeTime.format(context)}'),
                      Text('Sleep: ${_settings!.sleepTime.format(context)}'),
                    ],
                  ),
                ),
                const Divider(),
              ],
              Expanded(
                child: ListView.builder(
                  itemCount: dayActions.length,
                  itemBuilder: (context, index) {
                    final action = dayActions[index];
                    final isSchedule = action.category.toLowerCase() == 'schedule';
                    
                    return ListTile(
                      leading: Chip(
                        label: Text(
                          '${action.time.hour.toString().padLeft(2, '0')}:${action.time.minute.toString().padLeft(2, '0')}',
                        ),
                        backgroundColor: isSchedule ? Colors.blue.shade100 : null,
                      ),
                      title: Text(action.name),
                      subtitle: Row(
                        children: [
                          Text(action.category),
                          if (action.frequency > 1) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.repeat,
                                    size: 12,
                                    color: Colors.blue.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${action.frequency}x/day',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
