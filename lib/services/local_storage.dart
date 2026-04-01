import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/habit.dart';

/// Used for GUEST mode only — authenticated users store data in Supabase.
class LocalStorage {
  static const _key = 'habits_v3';

  static Future<List<Habit>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = json.decode(raw) as List;
    return list.map((e) => Habit.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> save(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, json.encode(habits.map((h) => h.toJson()).toList()));
  }
}
