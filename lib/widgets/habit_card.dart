import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/habit.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onTap;

  const HabitCard({super.key, required this.habit, required this.onTap});

  IconData _iconData(String name) {
    switch (name) {
      case 'code': return Icons.code_rounded;
      case 'book': return Icons.menu_book_rounded;
      case 'fitness': return Icons.fitness_center_rounded;
      case 'music': return Icons.music_note_rounded;
      case 'heart': return Icons.favorite_rounded;
      case 'run': return Icons.directions_run_rounded;
      case 'coffee': return Icons.coffee_rounded;
      case 'study': return Icons.school_rounded;
      default: return Icons.star_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = habit.isCompletedToday;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: done ? kGreenLight : kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: done ? kGreen.withOpacity(0.35) : kBorder,
          width: done ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Check button
                GestureDetector(
                  onTap: onTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: done ? kGreen : Colors.grey.shade100,
                      shape: BoxShape.circle,
                      boxShadow: done
                          ? [BoxShadow(color: kGreen.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                          : null,
                    ),
                    child: Icon(
                      done ? Icons.check_rounded : Icons.circle_outlined,
                      color: done ? Colors.white : Colors.grey.shade400,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Icon badge
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: habit.colorValue.withOpacity(done ? 0.08 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_iconData(habit.icon), color: habit.colorValue, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: done ? kSubtext : kText,
                          decoration: done ? TextDecoration.lineThrough : null,
                          decorationColor: kSubtext,
                        ),
                      ),
                      if (habit.description.isNotEmpty)
                        Text(
                          habit.description,
                          style: const TextStyle(color: kSubtext, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Streak
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department_rounded, color: kOrange, size: 16),
                        const SizedBox(width: 2),
                        Text(
                          '${habit.currentStreak}',
                          style: const TextStyle(color: kOrange, fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ],
                    ),
                    Text('streak', style: TextStyle(color: kSubtext.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
