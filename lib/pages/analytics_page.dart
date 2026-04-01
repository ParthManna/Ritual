import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../theme.dart';
import '../models/habit.dart';

class AnalyticsPage extends StatelessWidget {
  final List<Habit> habits;
  const AnalyticsPage({super.key, required this.habits});

  // ── Computed stats ──────────────────────────────────────────────────────────

  int get _totalCompletedToday =>
      habits.where((h) => h.isCompletedToday).length;

  int get _bestStreak =>
      habits.isEmpty ? 0 : habits.map((h) => h.longestStreak).reduce(max);

  int get _totalStreaks =>
      habits.fold(0, (sum, h) => sum + h.currentStreak);

  int get _totalCompletionsAllTime =>
      habits.fold(0, (sum, h) => sum + h.totalCompletions);

  double get _weeklyRate {
    if (habits.isEmpty) return 0;
    int count = 0;
    for (int i = 0; i < 7; i++) {
      final key = DateFormat('yyyy-MM-dd')
          .format(DateTime.now().subtract(Duration(days: i)));
      count += habits.where((h) => h.completionHistory[key] == true).length;
    }
    return count / (habits.length * 7);
  }

  int get _weeklyTotal =>
      _weeklyData.map((d) => d['count'] as int).fold(0, (a, b) => a + b);

  List<Map<String, dynamic>> get _weeklyData {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final key = DateFormat('yyyy-MM-dd').format(day);
      final completions =
          habits.where((h) => h.completionHistory[key] == true).length;
      return {
        'day': days[day.weekday - 1],
        'count': completions,
        'total': habits.length,
      };
    });
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
            // ── Fixed header — no overlap ─────────────────────────────────
            _buildHeader(),
            // ── Scrollable content ────────────────────────────────────────
            Expanded(
              child: habits.isEmpty ? _buildEmptyState() : _buildContent(),
            ),
          ],
        ),
      ),
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analytics',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: kText,
                  letterSpacing: -0.6,
                ),
              ),
              Text(
                'Track your consistency',
                style: TextStyle(color: kSubtext, fontSize: 13),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: kPrimaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 12, color: kPrimary),
                const SizedBox(width: 5),
                Text(
                  DateFormat('MMM d').format(DateTime.now()),
                  style: const TextStyle(
                      color: kPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Content ──────────────────────────────────────────────────────────────────

  Widget _buildContent() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      children: [
        _buildHighlightBanner(),
        const SizedBox(height: 16),
        _buildStatsGrid(),
        const SizedBox(height: 16),
        _buildWeeklyChart(),
        const SizedBox(height: 16),
        _buildHabitBreakdown(),
      ],
    );
  }

  // ── Highlight banner (weekly score + circular progress) ──────────────────────

  Widget _buildHighlightBanner() {
    final pct = (_weeklyRate * 100).round();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimary, Color(0xFF818CF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly Score',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  '$pct%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _BannerPill(
                        icon: Icons.check_circle_rounded,
                        label: '$_weeklyTotal done'),
                    const SizedBox(width: 8),
                    _BannerPill(
                        icon: Icons.local_fire_department_rounded,
                        label: '${_bestStreak}d best'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 68,
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _weeklyRate,
                  strokeWidth: 7,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                Text(
                  '$pct%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats grid ───────────────────────────────────────────────────────────────

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _StatCard(
          label: 'Best Streak',
          value: '$_bestStreak',
          unit: 'days',
          icon: Icons.local_fire_department_rounded,
          color: kOrange,
          bgColor: kOrangeLight,
        ),
        _StatCard(
          label: 'Done Today',
          value: '$_totalCompletedToday',
          unit: 'of ${habits.length} habits',
          icon: Icons.check_circle_rounded,
          color: kGreen,
          bgColor: kGreenLight,
        ),
        _StatCard(
          label: 'Active Streaks',
          value: '$_totalStreaks',
          unit: 'total days',
          icon: Icons.emoji_events_rounded,
          color: const Color(0xFF8B5CF6),
          bgColor: const Color(0xFFF5F3FF),
        ),
        _StatCard(
          label: 'All Time',
          value: '$_totalCompletionsAllTime',
          unit: 'completions',
          icon: Icons.star_rounded,
          color: kPrimary,
          bgColor: kPrimaryLight,
        ),
      ],
    );
  }

  // ── Weekly bar chart ─────────────────────────────────────────────────────────

  Widget _buildWeeklyChart() {
    final data = _weeklyData;
    final maxY = habits.isNotEmpty ? habits.length.toDouble() : 3.0;

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('This Week',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: kText)),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kPrimaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$_weeklyTotal done',
                    style: const TextStyle(
                        color: kPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Daily completions',
              style: TextStyle(color: kSubtext, fontSize: 12)),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY == 0 ? 3 : maxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => kPrimary,
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      '${rod.toY.toInt()}',
                      const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= data.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            data[idx]['day'] as String,
                            style: const TextStyle(
                                fontSize: 11,
                                color: kSubtext,
                                fontWeight: FontWeight.w600),
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(data.length, (i) {
                  final count = (data[i]['count'] as int).toDouble();
                  final total = (data[i]['total'] as int).toDouble();
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: count,
                        gradient: const LinearGradient(
                          colors: [kPrimary, Color(0xFF818CF8)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: total > 0 ? total : 1,
                          color: kPrimaryLight,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Habit breakdown ──────────────────────────────────────────────────────────

  Widget _buildHabitBreakdown() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Habit Breakdown',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800, color: kText)),
              const Spacer(),
              const Text('30-day rate',
                  style: TextStyle(
                      color: kSubtext,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 16),
          ...habits.map((h) => _buildHabitRow(h)),
        ],
      ),
    );
  }

  Widget _buildHabitRow(Habit h) {
    final rate = h.completionRate30d;
    final pct = (rate * 100).round();
    final hasStreak = h.currentStreak > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    color: h.colorValue, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  h.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: kText,
                      fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasStreak) ...[
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: kOrangeLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department_rounded,
                          color: kOrange, size: 11),
                      const SizedBox(width: 2),
                      Text('${h.currentStreak}d',
                          style: const TextStyle(
                              color: kOrange,
                              fontWeight: FontWeight.w700,
                              fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text('$pct%',
                  style: TextStyle(
                      color: h.colorValue,
                      fontSize: 13,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          // Gradient progress bar
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: rate.clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [h.colorValue, h.colorValue.withOpacity(0.6)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [kPrimary, Color(0xFF818CF8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: kPrimary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8)),
                ],
              ),
              child: const Icon(Icons.bar_chart_rounded,
                  size: 42, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text('No data yet',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: kText,
                    letterSpacing: -0.4)),
            const SizedBox(height: 8),
            const Text(
              'Add some habits and start checking them off\nto see your analytics here.',
              style: TextStyle(color: kSubtext, fontSize: 14, height: 1.55),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: kText,
                  letterSpacing: -0.5,
                  height: 1)),
          const SizedBox(height: 2),
          Text(unit,
              style: const TextStyle(
                  color: kSubtext, fontSize: 10, fontWeight: FontWeight.w500)),
          const SizedBox(height: 1),
          Text(label,
              style: const TextStyle(
                  color: kText, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─── Banner pill ──────────────────────────────────────────────────────────────

class _BannerPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _BannerPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 11),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
