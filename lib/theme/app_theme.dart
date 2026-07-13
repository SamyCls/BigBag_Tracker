import 'package:flutter/material.dart';

/// Design system inspired by the "Delta Recycl" V3 web design handoff:
/// warm paper background, deep leaf-green accent, mono numerics,
/// large tappable targets for factory-floor tablet use.
class AppColors {
  AppColors._();

  // Light theme
  static const bg = Color(0xFFF4F2EC);
  static const paper = Color(0xFFFBFAF6);
  static const card = Color(0xFFFFFFFF);
  static const cardAlt = Color(0xFFF7F5EE);
  static const ink = Color(0xFF1A1D1C);
  static const inkMute = Color(0xFF6B6F6A);
  static const inkDim = Color(0xFF9A9D97);
  static const line = Color(0xFFE6E3D9);
  static const lineStrong = Color(0xFFC9C5B6);

  static const leaf = Color(0xFF16A34A);
  static const leafTint = Color(0xFFDCFCE7);
  static const leafDark = Color(0xFF166534);

  static const clay = Color(0xFFB8442A);
  static const clayTint = Color(0xFFF4DCD3);

  static const sun = Color(0xFFC17A2A);
  static const sunTint = Color(0xFFF2E4CF);

  // Dark theme
  static const bgDark = Color(0xFF14161A);
  static const paperDark = Color(0xFF1C1F24);
  static const cardDark = Color(0xFF23272E);
  static const cardAltDark = Color(0xFF2A2F37);
  static const inkOnDark = Color(0xFFF0EEE6);
  static const inkMuteDark = Color(0xFFA8ACA4);
  static const inkDimDark = Color(0xFF6B6F6A);
  static const lineDark = Color(0xFF333841);
  static const leafOnDark = Color(0xFF4ADE80);
  static const clayOnDark = Color(0xFFE07458);
  static const sunOnDark = Color(0xFFE0A05A);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.leaf,
        brightness: Brightness.light,
        primary: AppColors.leaf,
        surface: AppColors.card,
      ),
    );
    return base.copyWith(
      textTheme: _textTheme(base.textTheme, AppColors.ink, AppColors.inkMute),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.leaf,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          backgroundColor: AppColors.card,
          side: const BorderSide(color: AppColors.line),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.line, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.line, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.leaf, width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.paper,
        selectedItemColor: AppColors.leaf,
        unselectedItemColor: AppColors.inkMute,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.paper,
        selectedIconTheme: const IconThemeData(color: AppColors.leaf),
        selectedLabelTextStyle: const TextStyle(
          color: AppColors.leaf,
          fontWeight: FontWeight.w700,
        ),
        unselectedIconTheme: const IconThemeData(color: AppColors.inkMute),
        unselectedLabelTextStyle: const TextStyle(color: AppColors.inkMute),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.leafOnDark,
        brightness: Brightness.dark,
        primary: AppColors.leafOnDark,
        surface: AppColors.cardDark,
      ),
    );
    return base.copyWith(
      textTheme: _textTheme(
        base.textTheme,
        AppColors.inkOnDark,
        AppColors.inkMuteDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.paperDark,
        foregroundColor: AppColors.inkOnDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.lineDark),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lineDark,
        thickness: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.leafOnDark,
          foregroundColor: const Color(0xFF0D1F0F),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.inkOnDark,
          backgroundColor: AppColors.cardDark,
          side: const BorderSide(color: AppColors.lineDark),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.lineDark, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.leafOnDark, width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.paperDark,
        selectedItemColor: AppColors.leafOnDark,
        unselectedItemColor: AppColors.inkMuteDark,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.paperDark,
        selectedIconTheme: const IconThemeData(color: AppColors.leafOnDark),
        selectedLabelTextStyle: const TextStyle(
          color: AppColors.leafOnDark,
          fontWeight: FontWeight.w700,
        ),
        unselectedIconTheme: const IconThemeData(color: AppColors.inkMuteDark),
        unselectedLabelTextStyle: const TextStyle(color: AppColors.inkMuteDark),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, Color ink, Color mute) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        color: ink,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        color: ink,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      titleLarge: base.titleLarge?.copyWith(
        color: ink,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.titleMedium?.copyWith(
        color: ink,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.bodyLarge?.copyWith(color: ink),
      bodyMedium: base.bodyMedium?.copyWith(color: mute),
      labelLarge: base.labelLarge?.copyWith(
        color: ink,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// Mono-spaced numeric text style used for BB IDs, weights, counters —
/// mirrors the JetBrains Mono usage of the original design.
class AppTextStyles {
  AppTextStyles._();

  static const mono = TextStyle(
    fontFamily: 'monospace',
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static TextStyle monoWeight(double size, FontWeight weight, {Color? color}) =>
      TextStyle(
        fontFamily: 'monospace',
        fontFeatures: const [FontFeature.tabularFigures()],
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: -0.5,
      );
}
