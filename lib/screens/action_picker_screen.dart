import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/routine_action.dart';

class ActionPickerScreen extends StatefulWidget {
  const ActionPickerScreen({Key? key}) : super(key: key);

  @override
  _ActionPickerScreenState createState() => _ActionPickerScreenState();
}

class _ActionPickerScreenState extends State<ActionPickerScreen> {
  List<RoutineAction> _actions = [];
  List<RoutineAction> _selectedActions = [];
  Set<String> _expandedCategories = {};
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadActions();
  }

  Future<void> _loadActions() async {
    try {
      final String jsonString = await DefaultAssetBundle.of(context)
          .loadString('assets/data/free_routine_actions.json');
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
    } catch (e) {
      debugPrint('Error loading actions: $e');
    }
  }

  Future<void> _saveSelectedActions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString =
          json.encode(_selectedActions.map((a) => a.toJson()).toList());
      await prefs.setString('selectedActions', jsonString);
    } catch (e) {
      debugPrint('Error saving selected actions: $e');
    }
  }

  Widget _buildActionCard(RoutineAction action) {
    final bool isSelected =
        _selectedActions.any((a) => a.id == action.id);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        title: Text(action.title ?? 'Untitled Action'),
        subtitle: action.category != null ? Text(action.category!) : null,
        trailing: Icon(
          isSelected ? Icons.check_box : Icons.check_box_outline_blank,
          color: isSelected ? Colors.blue : Colors.grey,
        ),
        onTap: () {
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
        title: const Text('Pick Actions'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(_selectedActions);
            },
            child: const Text('Done'),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: categorizedActions.length,
        itemBuilder: (context, index) {
          final category = categorizedActions.keys.elementAt(index);
          final actions = categorizedActions[category]!;
          final isExpanded = _expandedCategories.contains(category);

          return Card(
            margin: const EdgeInsets.all(8),
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    category,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedCategories.remove(category);
                      } else {
                        _expandedCategories.add(category);
                      }
                    });
                  },
                ),
                if (isExpanded)
                  Column(
                    children: actions.map(_buildActionCard).toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
