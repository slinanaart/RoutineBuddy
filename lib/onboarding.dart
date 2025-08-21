import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart' as app;

// Helper function to get emoji for actions
String _getEmojiForAction(String actionName) {
  final name = actionName.toLowerCase();
  if (name.contains('wake')) return '🌅';
  if (name.contains('water') || name.contains('drink')) return '💧';
  if (name.contains('coffee')) return '☕';
  if (name.contains('walk') || name.contains('jog')) return '🚶';
  if (name.contains('stretch') || name.contains('yoga')) return '🧘';
  if (name.contains('exercise') || name.contains('fitness')) return '🏃';
  if (name.contains('work') || name.contains('start') || name.contains('finish')) return '💼';
  if (name.contains('meal') || name.contains('breakfast')) return '🍳';
  if (name.contains('lunch')) return '🥗';
  if (name.contains('dinner')) return '🍽️';
  if (name.contains('sleep') || name.contains('bed')) return '😴';
  if (name.contains('review') || name.contains('plan')) return '📋';
  if (name.contains('posture') || name.contains('stand')) return '🧍';
  if (name.contains('meditation') || name.contains('mindful')) return '🧘';
  if (name.contains('time') || name.contains('self')) return '⏰';
  if (name.contains('read')) return '📚';
  if (name.contains('journal')) return '📝';
  return '📌'; // default
}

/// Decides whether to show onboarding first-run, else go to HomeScaffold.
class LaunchDecider extends StatefulWidget {
  const LaunchDecider({super.key});
  @override State<LaunchDecider> createState()=> _LaunchDeciderState();
}
class _LaunchDeciderState extends State<LaunchDecider> {
  bool? _firstRun;
  @override void initState(){ super.initState(); _check(); }
  Future<void> _check() async {
    final sp = await SharedPreferences.getInstance();
    final seen = sp.getBool('rb_onboarded_v1') ?? false;
    setState(()=> _firstRun = !seen);
  }
  @override Widget build(BuildContext context) {
    if (_firstRun == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return _firstRun! ? const FillYourRoutineScreen() : app.HomeScreen();
  }
}

/// First-time screen: pick 'The Casual' or create manually.
class FillYourRoutineScreen extends StatelessWidget {
  const FillYourRoutineScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fill your routine')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _TemplateCard(
            title: 'Use "The Casual"',
            subtitle: 'Our balanced default for Mon–Sun. You can edit later.',
            variant: _CardVariant.casual,
          ),
          SizedBox(height: 16),
          _TemplateCard(
            title: 'Create your own routine',
            subtitle: 'Set your anchors and build your own timeline.',
            variant: _CardVariant.manual,
          ),
        ],
      ),
    );
  }
}

enum _CardVariant { casual, manual }

class _TemplateCard extends StatelessWidget {
  final String title; final String subtitle; final _CardVariant variant;
  const _TemplateCard({required this.title, required this.subtitle, required this.variant});
  @override
  Widget build(BuildContext context) {
    final gradient = variant == _CardVariant.casual
        ? [const Color(0xFF0FA3A5), const Color(0xFF22C55E)]
        : [const Color(0xFF3B82F6), const Color(0xFF0EA5E9)];
    final icon = variant == _CardVariant.casual ? Icons.favorite : Icons.edit_calendar_outlined;
    return InkWell(
      onTap: (){
        if (variant == _CardVariant.casual) {
          // Navigate to preview screen that handles its own navigation
          Navigator.push(context, MaterialPageRoute(builder: (_)=> const OnboardingCasualPreviewScreen()));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_)=> const ManualSettingsFlow()));
        }
      },
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(colors: gradient),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0,8))],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(radius: 28, backgroundColor: Colors.white.withOpacity(0.2),
              child: Icon(icon, color: Colors.white)),
            const SizedBox(width: 16),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(subtitle, style: const TextStyle(color: Colors.white70)),
              ],
            )),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

/// Preview The Casual weekly routine with an Apply button.
class OnboardingCasualPreviewScreen extends StatefulWidget {
  const OnboardingCasualPreviewScreen({super.key});
  @override State<OnboardingCasualPreviewScreen> createState()=> _OnboardingCasualPreviewScreenState();
}
class _OnboardingCasualPreviewScreenState extends State<OnboardingCasualPreviewScreen> {
  final repo = app.Repo();
  List<Map<String, dynamic>> sample = [];
  late DateTime weekStart;

  @override void initState(){ super.initState(); _load(); }
  String _dayKey(DateTime d)=> '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  DateTime _mondayOf(DateTime d){ return d.subtract(Duration(days: d.weekday-1)); }

  @override void didChangeDependencies(){
    super.didChangeDependencies();
    final now = DateTime.now();
    weekStart = _mondayOf(now);
  }
  
  void _load() {
    sample = repo.loadCasualTemplate();
    print('DEBUG: Using OnboardingCasualPreviewScreen (correct one for onboarding)');
    setState(() {});
  }
  
  Future<void> _apply() async {
    final plan = <String, List<Map<String, dynamic>>>{};
    for (int i = 0; i < 7; i++) {
      final d = weekStart.add(Duration(days: i));
      final k = _dayKey(d);
      plan[k] = sample.map((e) => e).toList();
    }
    await repo.saveWeek(weekStart, plan);
    
    // Apply auto-anchors and carry-over rules
    final settings = await repo.loadSettings();
    await repo.applySchedulingRules(settings);
    
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('rb_onboarded_v1', true);
    if (!mounted) return;
    
    // Navigate directly to main app HomeScreen with routine tab selected
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => app.HomeScreen(initialTabIndex: 1)), // Go to routine tab
      (_) => false
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('The Casual Routine')),
      body: Column(
        children: [
          Expanded(child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sample.length,
            itemBuilder: (context, index) {
                final action = sample[index];
                return Card(
                child: ListTile(
                  leading: Text(_getEmojiForAction(action['title'] ?? ''), style: const TextStyle(fontSize: 22)),
                  title: Text(action['title'] ?? ''),
                  subtitle: Text(action['category'] ?? ''),
                ),
              );
            },
          )),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: _apply,
              icon: const Icon(Icons.check),
              label: const Text('Apply This Routine'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Step 1 of manual onboarding - set wake/bed time and schedule preferences
class ManualSettingsFlow extends StatefulWidget {
  const ManualSettingsFlow({super.key});
  @override State<ManualSettingsFlow> createState()=> _ManualSettingsFlowState();
}
class _ManualSettingsFlowState extends State<ManualSettingsFlow> {
  TimeOfDay wake = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay bed = const TimeOfDay(hour: 23, minute: 30);
  List<TimeOfDay> meals = [const TimeOfDay(hour: 8, minute: 0), const TimeOfDay(hour: 12, minute: 0), const TimeOfDay(hour: 19, minute: 0)];
  app.ScheduleMode mode = app.ScheduleMode.weekly;
  List<int> dayOffs = [];

  @override Widget build(BuildContext context) {
    final repo = app.Repo();
    final s = app.AppSettings(wake: wake, bed: bed, meals: meals, mode: mode, dayOffs: dayOffs);
    return Scaffold(
      appBar: AppBar(title: const Text('Setup your schedule')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('When do you wake up?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ListTile(
              leading: const Icon(Icons.wb_sunny),
              title: Text('Wake time: ${wake.format(context)}'),
              onTap: () async {
                final t = await showTimePicker(context: context, initialTime: wake);
                if (t != null) setState(() => wake = t);
              },
            ),
            const SizedBox(height: 12),
            const Text('When do you go to bed?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ListTile(
              leading: const Icon(Icons.bedtime),
              title: Text('Bed time: ${bed.format(context)}'),
              onTap: () async {
                final t = await showTimePicker(context: context, initialTime: bed);
                if (t != null) setState(() => bed = t);
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                await repo.saveSettings(s);
                final sp = await SharedPreferences.getInstance();
                await sp.setBool('rb_onboarded_v1', true);
                if (!mounted) return;
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_)=> const AddActionsFirstRun()));
              },
              icon: const Icon(Icons.navigate_next),
              label: const Text('Continue to add actions'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Step 2 - Add actions to your routine for the first time
class AddActionsFirstRun extends StatefulWidget {
  const AddActionsFirstRun({super.key});
  @override State<AddActionsFirstRun> createState()=> _AddActionsFirstRunState();
}
class _AddActionsFirstRunState extends State<AddActionsFirstRun> {
  final repo = app.Repo();
  Map<String, app.RoutineAction> selected = {};
  List<app.RoutineAction> all = [];
  String search = '';

  @override void initState(){ super.initState(); all = repo.loadAllActions(); }
  
  List<app.RoutineAction> get filtered {
    if (search.isEmpty) return all;
    return all.where((e)=> e.title.toLowerCase().contains(search.toLowerCase()) || e.category.toLowerCase().contains(search.toLowerCase())).toList();
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add some actions')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(labelText: 'Search actions', prefixIcon: Icon(Icons.search)),
              onChanged: (v)=> setState(()=> search = v),
            ),
          ),
          Expanded(child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final action = filtered[i];
              final isSelected = selected.containsKey(action.id);
              return CheckboxListTile(
                value: isSelected,
                onChanged: (bool? val) {
                  setState(() {
                    if (val == true) selected[action.id] = action;
                    else selected.remove(action.id);
                  });
                },
                title: Row(
                  children: [
                    Text(_getEmojiForAction(action.title), style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(action.title)),
                  ],
                ),
                subtitle: Text(action.category),
              );
            },
          )),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: selected.isNotEmpty ? _finish : null,
              icon: const Icon(Icons.check),
              label: Text('Done (${selected.length} selected)'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finish() async {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday-1));
    final key = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
    final plan = await repo.loadWeek(monday);
    final list = [...(plan[key] ?? <app.RoutineAction>[])];
    final ids = list.map((e)=>e.id).toSet();
    for (final a in selected.values){
      if (!ids.contains(a.id)) list.add(a);
    }
    plan[key] = list;
    await repo.saveWeek(monday, plan);
    
    // Apply auto-anchors and carry-over rules
    final settings = await repo.loadSettings();
    await repo.applySchedulingRules(settings);
    
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_)=> app.HomeScreen()),
      (_) => false,
    );
  }
}
