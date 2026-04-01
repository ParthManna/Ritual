import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme.dart';
import 'pages/landing_page.dart';
import 'pages/main_shell.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Notification Service
  await NotificationService.init();

  await Supabase.initialize(
    url: 'https://vkodihbvbgbddjvctxwq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZrb2RpaGJ2YmdiZGRqdmN0eHdxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ5NzUzMDEsImV4cCI6MjA5MDU1MTMwMX0.svyf3nwYFDse70qWlDvfkcOHHtZQcfuUEaZFCiqRrWs',
  );

  final prefs = await SharedPreferences.getInstance();
  final bool isGuest = prefs.getBool('is_guest_mode') ?? false;

  // Also check if Supabase session is active
  final session = Supabase.instance.client.auth.currentSession;
  final bool isLoggedIn = session != null;

  // If previously logged in via Supabase but session expired, clear local flag
  if (!isLoggedIn && !isGuest) {
    await prefs.setBool('is_logged_in', false);
  }

  runApp(HabitTrackerApp(
    startWidget: (isLoggedIn || isGuest) ? const MainShell() : const LandingPage(),
  ));
}

class HabitTrackerApp extends StatelessWidget {
  final Widget startWidget;
  const HabitTrackerApp({super.key, required this.startWidget});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ritual',
      theme: AppTheme.light,
      home: startWidget,
    );
  }
}
