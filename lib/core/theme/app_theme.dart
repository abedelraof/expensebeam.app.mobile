import 'package:flutter/material.dart';

class AppTheme {
  // ── Color Tokens (aligned with auth screen palette) ───────────────────
  // Dark navy  → primary / header background
  static const primary       = Color(0xFF1B2A4A);
  // Bright blue → accent: buttons, active nav, links, focus borders
  static const accent        = Color(0xFF2B7BE0);
  // Emerald-500 → success: income, positive values
  static const success       = Color(0xFF10B981);
  // Rose-500    → danger: overspent, errors, negative values
  static const danger        = Color(0xFFF43F5E);
  // Amber-400   → warning: budget thresholds, caution
  static const warning       = Color(0xFFF59E0B);
  // Muted blue-grey → secondary text, icons
  static const textSecondary = Color(0xFF8A8D9A);

  // Light surfaces
  static const bgLight   = Color(0xFFF5F7FA);  // matches auth _fieldFill
  static const cardLight = Color(0xFFFFFFFF);

  // Dark surfaces
  static const bgDark   = Color(0xFF0A0F2C);   // matches auth _gradientTop
  static const cardDark = Color(0xFF1A2657);   // matches auth _gradientMid

  // Field border (light mode) — matches auth _fieldBorder
  static const fieldBorder = Color(0xFFE8ECF0);

  /// Header / drawer gradient — matches auth screen background exactly
  static const headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A0F2C), Color(0xFF1A2657), Color(0xFF2B4FA8)],
    stops: [0.0, 0.5, 1.0],
  );

  /// Login gradient (top-left → bottom-right for the auth screen)
  static const loginGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A0F2C), Color(0xFF1A2657), Color(0xFF2B4FA8)],
    stops: [0.0, 0.5, 1.0],
  );

  static ThemeData get light {
    final cs = ColorScheme(
      brightness: Brightness.light,
      primary: accent,
      onPrimary: Colors.white,
      primaryContainer: accent.withValues(alpha: 0.12),
      onPrimaryContainer: primary,
      secondary: primary,
      onSecondary: Colors.white,
      secondaryContainer: primary.withValues(alpha: 0.08),
      onSecondaryContainer: primary,
      tertiary: success,
      onTertiary: Colors.white,
      tertiaryContainer: success.withValues(alpha: 0.12),
      onTertiaryContainer: success,
      error: danger,
      onError: Colors.white,
      errorContainer: danger.withValues(alpha: 0.12),
      onErrorContainer: danger,
      surface: cardLight,
      onSurface: primary,
      surfaceContainerHighest: bgLight,
      onSurfaceVariant: textSecondary,
      outline: fieldBorder,
      outlineVariant: fieldBorder.withValues(alpha: 0.6),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: bgDark,
      onInverseSurface: Colors.white,
      inversePrimary: accent,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: bgLight,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 1,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgLight,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: fieldBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: fieldBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accent, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: danger)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: danger, width: 1.5)),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
        prefixIconColor: textSecondary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: accent.withValues(alpha: 0.1),
        labelStyle: const TextStyle(color: accent),
        side: BorderSide(color: accent.withValues(alpha: 0.3)),
      ),
      dividerTheme: const DividerThemeData(color: fieldBorder, thickness: 1),
      listTileTheme: const ListTileThemeData(iconColor: textSecondary),
      iconTheme: const IconThemeData(color: textSecondary),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: accent),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? accent : Colors.grey),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? accent.withValues(alpha: 0.4)
                : Colors.grey.withValues(alpha: 0.3)),
      ),
    );
  }

  static ThemeData get dark {
    final cs = ColorScheme(
      brightness: Brightness.dark,
      primary: accent,
      onPrimary: Colors.white,
      primaryContainer: accent.withValues(alpha: 0.2),
      onPrimaryContainer: Colors.white,
      secondary: const Color(0xFF6B8CAE),
      onSecondary: Colors.white,
      secondaryContainer: primary.withValues(alpha: 0.4),
      onSecondaryContainer: Colors.white,
      tertiary: success,
      onTertiary: Colors.white,
      tertiaryContainer: success.withValues(alpha: 0.2),
      onTertiaryContainer: Colors.white,
      error: danger,
      onError: Colors.white,
      errorContainer: danger.withValues(alpha: 0.2),
      onErrorContainer: Colors.white,
      surface: cardDark,
      onSurface: Colors.white,
      surfaceContainerHighest: bgDark,
      onSurfaceVariant: textSecondary,
      outline: textSecondary.withValues(alpha: 0.4),
      outlineVariant: textSecondary.withValues(alpha: 0.2),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: cardLight,
      onInverseSurface: primary,
      inversePrimary: accent,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: bgDark,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Color(0xFF0A0F2C),
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: textSecondary.withValues(alpha: 0.3))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: textSecondary.withValues(alpha: 0.3))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accent, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: danger)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: danger, width: 1.5)),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
        prefixIconColor: textSecondary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: accent.withValues(alpha: 0.15),
        labelStyle: const TextStyle(color: accent),
        side: BorderSide(color: accent.withValues(alpha: 0.3)),
      ),
      dividerTheme: DividerThemeData(
          color: textSecondary.withValues(alpha: 0.15), thickness: 1),
      listTileTheme: const ListTileThemeData(iconColor: textSecondary),
      iconTheme: const IconThemeData(color: textSecondary),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: accent),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? accent : Colors.grey),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? accent.withValues(alpha: 0.4)
                : Colors.grey.withValues(alpha: 0.3)),
      ),
    );
  }
}
