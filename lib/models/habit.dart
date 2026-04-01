import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class Habit {
  String id;
  String userId;
  String name;
  String description;
  String color;
  String icon;
  Map<String, bool> completionHistory;
  DateTime? createdAt;

  Habit({
    required this.id,
    required this.userId,
    required this.name,
    this.description = '',
    this.color = '#6366F1',
    this.icon = 'star',
    Map<String, bool>? completionHistory,
    this.createdAt,
  }) : completionHistory = completionHistory ?? {};

  String get todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  bool get isCompletedToday => completionHistory[todayKey] == true;

  int get currentStreak {
    int streak = 0;
    DateTime day = DateTime.now();
    while (true) {
      final key = DateFormat('yyyy-MM-dd').format(day);
      if (completionHistory[key] == true) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  int get longestStreak {
    final keys = completionHistory.keys
        .where((k) => completionHistory[k] == true)
        .toList()
      ..sort();
    int longest = 0;
    int current = 0;
    DateTime? prev;
    for (final key in keys) {
      final day = DateFormat('yyyy-MM-dd').parse(key);
      if (prev == null || day.difference(prev).inDays == 1) {
        current++;
      } else {
        longest = max(longest, current);
        current = 1;
      }
      prev = day;
    }
    return max(longest, current);
  }

  int get totalCompletions => completionHistory.values.where((v) => v).length;

  double get completionRate30d {
    int count = 0;
    for (int i = 0; i < 30; i++) {
      final key = DateFormat('yyyy-MM-dd')
          .format(DateTime.now().subtract(Duration(days: i)));
      if (completionHistory[key] == true) count++;
    }
    return count / 30;
  }

  Color get colorValue {
    final hex = color.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'description': description,
    'color': color,
    'icon': icon,
    'history': completionHistory,
    'created_at': createdAt?.toIso8601String(),
  };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'] as String,
    userId: json['user_id'] as String? ?? '',
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    color: json['color'] as String? ?? '#6366F1',
    icon: json['icon'] as String? ?? 'star',
    completionHistory: json['history'] != null
        ? Map<String, bool>.from(json['history'] as Map)
        : {},
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'] as String)
        : null,
  );

  Habit copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? color,
    String? icon,
    Map<String, bool>? completionHistory,
    DateTime? createdAt,
  }) {
    return Habit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      completionHistory: completionHistory ?? Map.from(this.completionHistory),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
