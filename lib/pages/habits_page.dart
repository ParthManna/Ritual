import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../models/habit.dart';
import '../widgets/habit_form_sheet.dart';

class HabitsPage extends StatefulWidget {
  final List<Habit> habits;
  final void Function(Habit) onAdd;
  final void Function(Habit) onUpdate;
  final void Function(String) onDelete;

  const HabitsPage({
    super.key,
    required this.habits,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  String _sortBy = 'name';

  List<Habit> get _sortedHabits {
    final list = List<Habit>.from(widget.habits);
    switch (_sortBy) {
      case 'streak':
        list.sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
      case 'rate':
        list.sort((a, b) => b.completionRate30d.compareTo(a.completionRate30d));
      default:
        list.sort((a, b) => a.name.compareTo(b.name));
    }
    return list;
  }

  int get _completedToday =>
      widget.habits.where((h) => h.isCompletedToday).length;

  int get _bestStreak => widget.habits.isEmpty
      ? 0
      : widget.habits.map((h) => h.currentStreak).reduce((a, b) => a > b ? a : b);

  void _showAddDialog([String? initialName]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HabitFormSheet(onSave: widget.onAdd, initialName: initialName),
    );
  }

  Future<bool> _confirmDelete(Habit h) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: kCard,
        title: const Text('Delete Habit?',
            style: TextStyle(fontWeight: FontWeight.w800, color: kText)),
        content: Text(
          'Delete "${h.name}"? All history for this habit will be lost.',
          style: const TextStyle(color: kSubtext, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: kSubtext, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header (always visible, never overlaps) ─────────────────
            _buildHeader(),
            // ── Body ────────────────────────────────────────────────────
            Expanded(
              child: widget.habits.isEmpty
                  ? _buildEmptyState()
                  : _buildList(),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.habits.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text('New Habit',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      )
          : null,
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      color: kBackground,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'My Habits',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: kText,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: kPrimaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${widget.habits.length}',
              style: const TextStyle(
                  color: kPrimary, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _showAddDialog(),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [kPrimary, Color(0xFF818CF8)]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 4),
                  Text('Add',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── List (with summary + sort + cards) ──────────────────────────────────────

  Widget _buildList() {
    final sorted = _sortedHabits;
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
      children: [
        // Summary chips
        Row(
          children: [
            _SummaryChip(
              icon: Icons.list_alt_rounded,
              label: '${widget.habits.length} habits',
              color: kPrimary,
              bgColor: kPrimaryLight,
            ),
            const SizedBox(width: 8),
            _SummaryChip(
              icon: Icons.check_circle_rounded,
              label: '$_completedToday/${widget.habits.length} today',
              color: kGreen,
              bgColor: kGreenLight,
            ),
            const SizedBox(width: 8),
            _SummaryChip(
              icon: Icons.local_fire_department_rounded,
              label: '${_bestStreak}d best',
              color: kOrange,
              bgColor: kOrangeLight,
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Sort row
        Row(
          children: [
            const Text('Sort by',
                style: TextStyle(
                    color: kSubtext, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(width: 10),
            _SortChip(
                label: 'Name',
                value: 'name',
                current: _sortBy,
                onTap: () => setState(() => _sortBy = 'name')),
            const SizedBox(width: 6),
            _SortChip(
                label: 'Streak',
                value: 'streak',
                current: _sortBy,
                onTap: () => setState(() => _sortBy = 'streak')),
            const SizedBox(width: 6),
            _SortChip(
                label: 'Rate',
                value: 'rate',
                current: _sortBy,
                onTap: () => setState(() => _sortBy = 'rate')),
          ],
        ),
        const SizedBox(height: 12),
        // Habit cards
        ...sorted.map((h) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Dismissible(
            key: Key(h.id),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async {
              HapticFeedback.mediumImpact();
              return _confirmDelete(h);
            },
            onDismissed: (_) => widget.onDelete(h.id),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [Colors.red.shade300, Colors.red.shade500]),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_sweep_rounded,
                      color: Colors.white, size: 26),
                  SizedBox(height: 4),
                  Text('Delete',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            child: _HabitManageCard(
              habit: h,
              onEdit: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) =>
                    HabitFormSheet(habit: h, onSave: widget.onUpdate),
              ),
            ),
          ),
        )),
      ],
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 40, 32, 40),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                      color: kPrimaryLight, shape: BoxShape.circle),
                ),
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kPrimary, Color(0xFF818CF8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: kPrimary.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const Icon(Icons.add_task_rounded,
                      size: 40, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Text('No habits yet',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: kText,
                    letterSpacing: -0.5)),
            const SizedBox(height: 10),
            const Text(
              'Start with one small habit.\nConsistency compounds into transformation.',
              style: TextStyle(color: kSubtext, fontSize: 15, height: 1.55),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showAddDialog(),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Create First Habit',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: ['Exercise', 'Reading', 'Meditation', 'Journaling', 'Coding']
                  .map((s) => _SuggestionPill(
                  label: s, onTap: () => _showAddDialog(s)))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Habit Manage Card ────────────────────────────────────────────────────────

class _HabitManageCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onEdit;

  const _HabitManageCard({required this.habit, required this.onEdit});

  IconData _iconData(String name) {
    switch (name) {
      case 'code':    return Icons.code_rounded;
      case 'book':    return Icons.menu_book_rounded;
      case 'fitness': return Icons.fitness_center_rounded;
      case 'music':   return Icons.music_note_rounded;
      case 'heart':   return Icons.favorite_rounded;
      case 'run':     return Icons.directions_run_rounded;
      case 'coffee':  return Icons.coffee_rounded;
      case 'study':   return Icons.school_rounded;
      default:        return Icons.star_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rate = habit.completionRate30d;
    final hasStreak = habit.currentStreak > 0;

    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            // Main row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon badge
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: habit.colorValue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border:
                      Border.all(color: habit.colorValue.withOpacity(0.2)),
                    ),
                    child: Icon(_iconData(habit.icon),
                        color: habit.colorValue, size: 26),
                  ),
                  const SizedBox(width: 14),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                habit.name,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: kText,
                                    height: 1.1),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: onEdit,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: kPrimaryLight,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: kPrimary.withOpacity(0.15)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit_rounded,
                                        color: kPrimary, size: 13),
                                    SizedBox(width: 4),
                                    Text('Edit',
                                        style: TextStyle(
                                            color: kPrimary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (habit.description.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(habit.description,
                              style: const TextStyle(
                                  color: kSubtext, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _StatPill(
                              icon: Icons.local_fire_department_rounded,
                              label: hasStreak
                                  ? '${habit.currentStreak}d streak'
                                  : 'No streak',
                              color: hasStreak ? kOrange : kSubtext,
                              bgColor:
                              hasStreak ? kOrangeLight : Colors.grey.shade50,
                            ),
                            const SizedBox(width: 6),
                            _StatPill(
                              icon: Icons.check_circle_rounded,
                              label: '${habit.totalCompletions} done',
                              color: kGreen,
                              bgColor: kGreenLight,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('30-day completion',
                          style: TextStyle(
                              color: kSubtext,
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                      Text('${(rate * 100).round()}%',
                          style: TextStyle(
                              color: habit.colorValue,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: rate,
                      backgroundColor: Colors.grey.shade100,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(habit.colorValue),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            // Color accent stripe
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  habit.colorValue,
                  habit.colorValue.withOpacity(0.25),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Small widgets ────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  const _StatPill(
      {required this.icon,
        required this.label,
        required this.color,
        required this.bgColor});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
        color: bgColor, borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 12),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w600, fontSize: 11)),
    ]),
  );
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  const _SummaryChip(
      {required this.icon,
        required this.label,
        required this.color,
        required this.bgColor});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.15)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 14),
      const SizedBox(width: 5),
      Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    ]),
  );
}

class _SortChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final VoidCallback onTap;
  const _SortChip(
      {required this.label,
        required this.value,
        required this.current,
        required this.onTap});
  @override
  Widget build(BuildContext context) {
    final active = value == current;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? kPrimary : kBorder),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : kSubtext,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12)),
      ),
    );
  }
}

class _SuggestionPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SuggestionPill({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.add_rounded, size: 14, color: kPrimary),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: kText, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    ),
  );
}
