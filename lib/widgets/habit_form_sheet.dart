import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/habit.dart';

class HabitFormSheet extends StatefulWidget {
  final Habit? habit;
  final void Function(Habit) onSave;
  final String? initialName;             // ← this is what was missing

  const HabitFormSheet({
    super.key,
    this.habit,
    required this.onSave,
    this.initialName,
  });

  @override
  State<HabitFormSheet> createState() => _HabitFormSheetState();
}

class _HabitFormSheetState extends State<HabitFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late String _selectedColor;
  late String _selectedIcon;

  final _colors = [
    '#6366F1', '#10B981', '#F59E0B', '#EF4444',
    '#8B5CF6', '#EC4899', '#14B8A6', '#F97316',
  ];
  final _icons = [
    'star', 'code', 'book', 'fitness',
    'music', 'heart', 'run', 'coffee', 'study',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: widget.habit?.name ?? widget.initialName ?? '');
    _descCtrl = TextEditingController(text: widget.habit?.description ?? '');
    _selectedColor = widget.habit?.color ?? '#6366F1';
    _selectedIcon = widget.habit?.icon ?? 'star';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

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

  Color _parseColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) return;
    final habit = Habit(
      id: widget.habit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: widget.habit?.userId ?? '',
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      color: _selectedColor,
      icon: _selectedIcon,
      completionHistory: widget.habit?.completionHistory ?? {},
    );
    widget.onSave(habit);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = _parseColor(_selectedColor);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            widget.habit == null ? 'New Habit' : 'Edit Habit',
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: kText),
          ),
          const SizedBox(height: 20),

          // Name field
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'E.g., Read 20 pages',
              prefixIcon: Icon(Icons.edit_rounded, size: 18, color: kSubtext),
            ),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 12),

          // Description field
          TextField(
            controller: _descCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Description (optional)',
              prefixIcon: Icon(Icons.notes_rounded, size: 18, color: kSubtext),
            ),
          ),
          const SizedBox(height: 24),

          // Color picker
          const Text('Color',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: kText, fontSize: 14)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _colors.map((c) {
              final isSelected = c == _selectedColor;
              final col = _parseColor(c);
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: col,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: col.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Icon picker
          const Text('Icon',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: kText, fontSize: 14)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _icons.map((icon) {
              final isSelected = icon == _selectedIcon;
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = icon),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected ? selectedColor : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: selectedColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                        : null,
                  ),
                  child: Icon(
                    _iconData(icon),
                    color: isSelected ? Colors.white : kSubtext,
                    size: 22,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // Save button — updates color to match selected habit color
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: _save,
              child: Text(
                widget.habit == null ? 'Create Habit' : 'Save Changes',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}