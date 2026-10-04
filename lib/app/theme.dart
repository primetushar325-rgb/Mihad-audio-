import 'package:flutter/material.dart';

/// MIHAD AUDIO's dark, premium visual identity: near-black / charcoal
/// backgrounds, a teal-to-violet accent gradient, and high-contrast text.
class MihadColors {
  static const background = Color(0xFF0A0B0F);
  static const surface = Color(0xFF14161D);
  static const surfaceElevated = Color(0xFF1C1F29);
  static const accentPrimary = Color(0xFF00E5A8);
  static const accentSecondary = Color(0xFF6C5CE7);
  static const textPrimary = Color(0xFFF5F6FA);
  static const textSecondary = Color(0xFFA0A4B8);
  static const danger = Color(0xFFFF6B6B);

  static const brandGradient = LinearGradient(
    colors: [accentPrimary, accentSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

ThemeData buildMihadTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: MihadColors.background,
    colorScheme: base.colorScheme.copyWith(
      brightness: Brightness.dark,
      primary: MihadColors.accentPrimary,
      secondary: MihadColors.accentSecondary,
      surface: MihadColors.surface,
      error: MihadColors.danger,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: MihadColors.textPrimary,
      displayColor: MihadColors.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: MihadColors.background,
      elevation: 0,
      centerTitle: false,
      foregroundColor: MihadColors.textPrimary,
    ),
    cardTheme: CardThemeData(
      color: MihadColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: MihadColors.accentPrimary,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: MihadColors.textPrimary,
        side: const BorderSide(color: Color(0xFF2A2E3A)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    iconTheme: const IconThemeData(color: MihadColors.textPrimary),
    sliderTheme: SliderThemeData(
      activeTrackColor: MihadColors.accentPrimary,
      inactiveTrackColor: const Color(0xFF2A2E3A),
      thumbColor: MihadColors.accentPrimary,
      overlayColor: MihadColors.accentPrimary.withValues(alpha: 0.15),
    ),
    dividerColor: const Color(0xFF22252F),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: MihadColors.surfaceElevated,
      contentTextStyle: TextStyle(color: MihadColors.textPrimary),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
