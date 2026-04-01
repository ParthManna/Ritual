import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../theme.dart';
import '../models/habit.dart';
import '../widgets/habit_card.dart';
import '../widgets/habit_form_sheet.dart';

class DashboardPage extends StatefulWidget {
  final List<Habit> habits;
  final void Function(String id) onToggle;
  final void Function(Habit habit) onAddHabit;

  const DashboardPage({
    super.key,
    required this.habits,
    required this.onToggle,
    required this.onAddHabit,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTime _focusedDay = DateTime.now();

  int get _completedToday => widget.habits.where((h) => h.isCompletedToday).length;
  double get _progressRate => widget.habits.isEmpty ? 0 : _completedToday / widget.habits.length;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get _dateLabel => DateFormat('EEEE, MMMM d').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildProgressCard(),
                const SizedBox(height: 20),
                _buildCalendar(),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Today's Habits",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kText)),
                    GestureDetector(
                      onTap: () => _showAddDialog(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: kPrimaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, size: 16, color: kPrimary),
                            SizedBox(width: 4),
                            Text('Add', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (widget.habits.isEmpty)
                  _buildEmptyState()
                else
                  ...widget.habits.map((h) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: HabitCard(habit: h, onTap: () => widget.onToggle(h.id)),
                  )),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 130,
      floating: false,
      pinned: true,
      backgroundColor: kBackground,
      scrolledUnderElevation: 0,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          color: kBackground,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_greeting.',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: kText,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        _dateLabel,
                        style: const TextStyle(color: kSubtext, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Streak badge
                  if (widget.habits.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [kPrimary, Color(0xFF818CF8)]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '$_completedToday/${widget.habits.length}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      title: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: kPrimary, size: 20),
          const SizedBox(width: 8),
          const Text('Ritual', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kPrimary)),
          const Spacer(),
          if (widget.habits.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: kPrimaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$_completedToday/${widget.habits.length}',
                style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final int pct = (_progressRate * 100).round();
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimary, Color(0xFF818CF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Daily Progress',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
              Text(
                '$pct%',
                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, height: 1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progressRate,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _progressRate == 1.0
                    ? 'Perfect day! Keep it up.'
                    : widget.habits.isEmpty
                    ? 'Add your first habit below.'
                    : '$_completedToday of ${widget.habits.length} completed',
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, fontWeight: FontWeight.w500),
              ),
              if (_progressRate == 1.0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Done', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: TableCalendar(
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.week,
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: kText),
            leftChevronIcon: Icon(Icons.chevron_left_rounded, color: kSubtext),
            rightChevronIcon: Icon(Icons.chevron_right_rounded, color: kSubtext),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: kSubtext, fontSize: 12, fontWeight: FontWeight.w600),
            weekendStyle: TextStyle(color: kSubtext, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          calendarStyle: const CalendarStyle(
            todayDecoration: BoxDecoration(color: kPrimaryLight, shape: BoxShape.circle),
            todayTextStyle: TextStyle(color: kPrimary, fontWeight: FontWeight.bold),
            selectedDecoration: BoxDecoration(color: kPrimary, shape: BoxShape.circle),
            markerDecoration: BoxDecoration(color: kGreen, shape: BoxShape.circle),
            outsideDaysVisible: false,
          ),
          onPageChanged: (d) => setState(() => _focusedDay = d),
          eventLoader: (day) {
            final key = DateFormat('yyyy-MM-dd').format(day);
            return widget.habits.any((h) => h.completionHistory[key] == true) ? [true] : [];
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: kPrimaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_task_rounded, size: 36, color: kPrimary),
          ),
          const SizedBox(height: 16),
          const Text('No habits yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kText)),
          const SizedBox(height: 8),
          const Text(
            'Start small — one habit changes everything.',
            style: TextStyle(color: kSubtext),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 0,
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add First Habit', style: TextStyle(fontWeight: FontWeight.w700)),
            onPressed: () => _showAddDialog(context),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HabitFormSheet(onSave: (habit) => widget.onAddHabit(habit)),
    );
  }
}
