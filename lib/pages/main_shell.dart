import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../models/habit.dart';
import '../services/supabase_service.dart';
import '../services/local_storage.dart';
import 'dashboard_page.dart';
import 'analytics_page.dart';
import 'habits_page.dart';
import 'profile_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  List<Habit> _habits = [];
  bool _loading = true;
  bool _isGuest = true;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    _isGuest = prefs.getBool('is_guest_mode') ?? true;

    List<Habit> habits = [];
    if (_isGuest) {
      habits = await LocalStorage.load();
    } else {
      try {
        habits = await SupabaseService.fetchHabits();
      } catch (_) {
        habits = await LocalStorage.load();
      }
    }

    if (mounted) {
      setState(() {
        _habits = habits;
        _loading = false;
      });
    }
  }

  Future<void> _saveHabits() async {
    if (_isGuest) {
      await LocalStorage.save(_habits);
    }
    // For logged-in users, individual operations already call Supabase
  }

  void _toggleHabit(String id) async {
    setState(() {
      final habit = _habits.firstWhere((h) => h.id == id);
      final key = habit.todayKey;
      habit.completionHistory[key] = !(habit.completionHistory[key] ?? false);
    });
    if (!_isGuest) {
      final habit = _habits.firstWhere((h) => h.id == id);
      await SupabaseService.toggleHabitCompletion(habit);
    } else {
      await _saveHabits();
    }
  }

  void _addHabit(Habit habit) async {
    if (_isGuest) {
      setState(() => _habits.add(habit));
      await _saveHabits();
    } else {
      try {
        final created = await SupabaseService.createHabit(habit);
        setState(() => _habits.add(created));
      } catch (_) {
        setState(() => _habits.add(habit));
      }
    }
  }

  void _updateHabit(Habit updated) async {
    setState(() {
      final idx = _habits.indexWhere((h) => h.id == updated.id);
      if (idx >= 0) _habits[idx] = updated;
    });
    if (!_isGuest) {
      await SupabaseService.updateHabit(updated);
    } else {
      await _saveHabits();
    }
  }

  void _deleteHabit(String id) async {
    setState(() => _habits.removeWhere((h) => h.id == id));
    if (!_isGuest) {
      await SupabaseService.deleteHabit(id);
    } else {
      await _saveHabits();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome_rounded, color: kPrimary, size: 40),
              SizedBox(height: 16),
              CircularProgressIndicator(color: kPrimary, strokeWidth: 2),
            ],
          ),
        ),
      );
    }

    final pages = [
      DashboardPage(habits: _habits, onToggle: _toggleHabit, onAddHabit: _addHabit),
      AnalyticsPage(habits: _habits),
      HabitsPage(habits: _habits, onAdd: _addHabit, onUpdate: _updateHabit, onDelete: _deleteHabit),
      ProfilePage(habits: _habits, isGuest: _isGuest),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_rounded, label: 'Today', index: 0, current: _index, onTap: (i) => setState(() => _index = i)),
                _NavItem(icon: Icons.bar_chart_rounded, label: 'Analytics', index: 1, current: _index, onTap: (i) => setState(() => _index = i)),
                _NavItem(icon: Icons.checklist_rounded, label: 'Habits', index: 2, current: _index, onTap: (i) => setState(() => _index = i)),
                _NavItem(icon: Icons.person_rounded, label: 'Profile', index: 3, current: _index, onTap: (i) => setState(() => _index = i)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final void Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active ? kPrimaryLight : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: active ? kPrimary : kSubtext, size: 22),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? kPrimary : kSubtext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
