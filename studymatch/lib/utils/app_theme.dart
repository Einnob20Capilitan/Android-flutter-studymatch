import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color bgDark = Color(0xFF0D0B1E);
  static const Color bgCard = Color(0xFF1A1730);
  static const Color bgCardLight = Color(0xFF221E3A);
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFF9D5FF3);
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color accent = Color(0xFFAD46FF);
  static const Color accentGlow = Color(0xFF6D28D9);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B8CC);
  static const Color textMuted = Color(0xFF6B6B8A);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color divider = Color(0xFF2D2A4A);
  static const Color inputBg = Color(0xFF1E1B38);
  static const Color chipBg = Color(0xFF2D1F5E);
  static const Color chipSelected = Color(0xFF6D28D9);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: bgCard,
        error: error,
        onPrimary: textPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
      ),
      fontFamily: 'Poppins',
      textTheme: const TextTheme(
        displayLarge:
            TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        displayMedium:
            TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(
            color: textPrimary, fontWeight: FontWeight.bold, fontSize: 28),
        headlineMedium: TextStyle(
            color: textPrimary, fontWeight: FontWeight.w600, fontSize: 22),
        headlineSmall: TextStyle(
            color: textPrimary, fontWeight: FontWeight.w600, fontSize: 18),
        titleLarge: TextStyle(
            color: textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
        titleMedium: TextStyle(
            color: textPrimary, fontWeight: FontWeight.w500, fontSize: 14),
        bodyLarge: TextStyle(color: textSecondary, fontSize: 14),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 13),
        labelLarge: TextStyle(
            color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: divider),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: const TextStyle(color: textMuted, fontFamily: 'Poppins'),
        hintStyle: const TextStyle(color: textMuted, fontFamily: 'Poppins'),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: divider, width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: chipBg,
        selectedColor: chipSelected,
        labelStyle: const TextStyle(
            color: textPrimary, fontSize: 12, fontFamily: 'Poppins'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        foregroundColor: textPrimary,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 18,
          fontFamily: 'Poppins',
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgCard,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(color: divider, thickness: 1),
    );
  }
}

class AppConstants {
  static const List<String> subjects = [
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'English',
    'Computer Science',
    'History',
    'Geography',
    'Economics',
    'Psychology',
    'Literature',
    'Statistics',
    'Calculus',
    'Algebra',
    'Organic Chemistry',
    'Programming',
  ];

  static const List<String> learningStyles = [
    'Visual',
    'Auditory',
    'Kinesthetic',
    'Reading/Writing',
  ];

  static const List<String> studyStyles = [
    'Group',
    'Individual',
  ];

  static const List<String> timeBlocks = [
    'Morning (6am-9pm)',
    'Morning (10am-12pm)',
    'Afternoon (1pm-4pm)',
    'Evening (5pm-8pm)',
    'Night (8pm-11pm)',
    'Late Night (11pm-2am)',
  ];

  static const List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> collegeEnrollments = [
    'CTO',
    'CAS',
    'COE',
    'CBE',
    'CCJE'
  ];
  static const List<String> bioOptions = ['STEM', 'ABM', 'HUMSS', 'GAS'];
  static const List<String> genderOptions = [
    'Male',
    'Female',
    'Non-Binary',
    'Prefer not to say'
  ];
}
