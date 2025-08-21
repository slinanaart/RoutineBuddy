import 'package:flutter/material.dart';
import '../models/routine_action.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'action_picker_screen.dart';

class ManualSetupScreen extends StatefulWidget {
  const ManualSetupScreen({Key? key}) : super(key: key);

  @override
  _ManualSetupScreenState createState() => _ManualSetupScreenState();
}

class _ManualSetupScreenState extends State<ManualSetupScreen> {
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _bedTime = const TimeOfDay(hour: 23, minute: 0);
  List<TimeOfDay> _mealTimes = [
    const TimeOfDay(hour: 8, minute: 0),
    const TimeOfDay(hour: 13, minute: 0),
    const TimeOfDay(hour: 19, minute: 0),
  ];
  List<String> _mealNames = ['Breakfast', 'Lunch', 'Dinner'];
  String _scheduleMode = 'daily';

  Future<void> _selectTime(BuildContext context, TimeOfDay initialTime, void Function(TimeOfDay) onTimeSelected) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (pickedTime != null) {
      onTimeSelected(pickedTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Your Schedule'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sleep Schedule',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.wb_sunny),
                    title: const Text('Wake Time'),
                    trailing: TextButton(
                      onPressed: () => _selectTime(context, _wakeTime, (time) {
                        setState(() => _wakeTime = time);
                      }),
                      child: Text(_wakeTime.format(context)),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.nightlight_round),
                    title: const Text('Bed Time'),
                    trailing: TextButton(
                      onPressed: () => _selectTime(context, _bedTime, (time) {
                        setState(() => _bedTime = time);
                      }),
                      child: Text(_bedTime.format(context)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Meal Times',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (int i = 0; i < _mealTimes.length; i++)
                    ListTile(
                      leading: const Icon(Icons.restaurant),
                      title: Text(_mealNames[i]),
                      trailing: TextButton(
                        onPressed: () => _selectTime(context, _mealTimes[i], (time) {
                          setState(() {
                            _mealTimes[i] = time;
                          });
                        }),
                        child: Text(_mealTimes[i].format(context)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Schedule Mode',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Daily'),
                    leading: Radio<String>(
                      value: 'daily',
                      groupValue: _scheduleMode,
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            _scheduleMode = value;
                          });
                        }
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text('Weekly'),
                    leading: Radio<String>(
                      value: 'weekly',
                      groupValue: _scheduleMode,
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            _scheduleMode = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton(
            onPressed: () async {
              await saveUserSettings(
                wakeTime: _wakeTime,
                bedTime: _bedTime,
                mealTimes: _mealTimes,
                mealNames: _mealNames,
                scheduleMode: _scheduleMode,
              );
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ActionPickerScreen(),
                ),
              );
            },
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Continue to Pick Actions'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> saveUserSettings({
    required TimeOfDay wakeTime,
    required TimeOfDay bedTime,
    required List<TimeOfDay> mealTimes,
    required List<String> mealNames,
    required String scheduleMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Convert TimeOfDay to string for storage
    String convertTimeOfDayToString(TimeOfDay time) {
      return '${time.hour}:${time.minute}';
    }

    await prefs.setString('wakeTime', convertTimeOfDayToString(wakeTime));
    await prefs.setString('bedTime', convertTimeOfDayToString(bedTime));
    
    // Convert meal times to strings
    final List<String> mealTimesStr = mealTimes.map((time) => convertTimeOfDayToString(time)).toList();
    await prefs.setStringList('mealTimes', mealTimesStr);
    await prefs.setStringList('mealNames', mealNames);
    await prefs.setString('scheduleMode', scheduleMode);
  }
}
