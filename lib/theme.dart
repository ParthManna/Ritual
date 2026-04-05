import 'package:flutter/material.dart';

const kPrimary = Color(0xFF6366F1);
const kPrimaryDark = Color(0xFF4F46E5);
const kPrimaryLight = Color(0xFFEEF2FF);
const kGreen = Color(0xFF10B981);
const kGreenLight = Color(0xFFECFDF5);
const kOrange = Color(0xFFF59E0B);
const kOrangeLight = Color(0xFFFFFBEB);
const kBackground = Color(0xFFF8F7FF);
const kCard = Colors.white;
const kText = Color(0xFF1E1B4B);
const kSubtext = Color(0xFF6B7280);
const kBorder = Color(0xFFF1F1F1);

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: kBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: kBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: kText,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        fontFamily: 'Poppins',
      ),
      iconTheme: IconThemeData(color: kText),
    ),
    cardTheme: const CardTheme( // Changed back to CardTheme
      color: kCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        side: BorderSide(color: kBorder),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kPrimary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: kSubtext),
    ),
  );
}
