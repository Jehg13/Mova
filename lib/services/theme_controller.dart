import 'package:flutter/material.dart';
import 'package:mova/database/database_helper.dart';
import 'package:mova/widgets/mova_design_system.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this._database);

  final DatabaseHelper _database;
  ThemeMode mode = ThemeMode.system;

  Future<void> load() async {
    final stored = await _database.getThemeMode();
    mode = switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  Future<void> setMode(ThemeMode value) async {
    mode = value;
    notifyListeners();
    await _database.setThemeMode(switch (value) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }
}

late ThemeController appThemeController;

ThemeData movaLightTheme() {
  return ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: MovaDesign.navy,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: MovaDesign.canvas,
    appBarTheme: const AppBarTheme(
      backgroundColor: MovaDesign.canvas,
      foregroundColor: MovaDesign.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: MovaDesign.ink,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: MovaDesign.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(MovaDesign.radiusMedium),
        ),
        side: const BorderSide(color: MovaDesign.border),
      ),
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 2,
        shadowColor: const Color(0xFF0C2340).withValues(alpha: 0.2),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 1,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        foregroundColor: const Color(0xFF0C2340),
        side: const BorderSide(color: Color(0xFF39B8C8), width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        foregroundColor: const Color(0xFF16899B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(46, 46),
        padding: const EdgeInsets.all(11),
        foregroundColor: const Color(0xFF36577D),
        backgroundColor: const Color(0xFFEAF3F7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: MovaDesign.accent,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MovaDesign.radiusMedium),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: MovaDesign.navy,
      unselectedItemColor: MovaDesign.muted,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      unselectedLabelStyle: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
      showUnselectedLabels: true,
      elevation: 10,
      type: BottomNavigationBarType.fixed,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      hintStyle: const TextStyle(color: MovaDesign.muted),
      labelStyle: const TextStyle(color: MovaDesign.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MovaDesign.radiusSmall),
        borderSide: const BorderSide(color: MovaDesign.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MovaDesign.radiusSmall),
        borderSide: const BorderSide(color: MovaDesign.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MovaDesign.radiusSmall),
        borderSide: const BorderSide(color: MovaDesign.accent, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MovaDesign.radiusSmall),
        borderSide: const BorderSide(color: MovaDesign.negative),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFFE5F3F5),
      side: const BorderSide(color: MovaDesign.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      labelStyle: const TextStyle(
        color: MovaDesign.ink,
        fontWeight: FontWeight.w600,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: MovaDesign.border,
      thickness: 1,
      space: 1,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: MovaDesign.accent,
      linearTrackColor: Color(0xFFE7EDF3),
      circularTrackColor: Color(0xFFE7EDF3),
    ),
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        color: MovaDesign.ink,
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
      ),
      headlineSmall: TextStyle(
        color: MovaDesign.ink,
        fontSize: 25,
        fontWeight: FontWeight.w800,
        letterSpacing: -.5,
      ),
      titleLarge: TextStyle(
        color: MovaDesign.ink,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: TextStyle(
        color: MovaDesign.ink,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(color: MovaDesign.ink, fontSize: 15),
      bodyMedium: TextStyle(color: MovaDesign.ink, fontSize: 14),
      bodySmall: TextStyle(color: MovaDesign.muted, fontSize: 12),
      labelLarge: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    ),
    useMaterial3: true,
  );
}

ThemeData movaDarkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: MovaDesign.accent,
      brightness: Brightness.dark,
      surface: MovaDesign.darkSurface,
    ),
    scaffoldBackgroundColor: MovaDesign.darkCanvas,
    appBarTheme: const AppBarTheme(
      backgroundColor: MovaDesign.darkCanvas,
      foregroundColor: MovaDesign.darkText,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: MovaDesign.darkText,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: MovaDesign.darkSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(MovaDesign.radiusMedium),
        ),
        side: const BorderSide(color: MovaDesign.darkBorder),
      ),
      elevation: 0,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: MovaDesign.darkSurface,
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 2,
        shadowColor: MovaDesign.blueGlow,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 1,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        foregroundColor: MovaDesign.darkText,
        side: const BorderSide(color: MovaDesign.accent, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        foregroundColor: MovaDesign.accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(46, 46),
        padding: const EdgeInsets.all(11),
        foregroundColor: MovaDesign.darkText,
        backgroundColor: MovaDesign.darkElevatedSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: MovaDesign.accent,
      foregroundColor: MovaDesign.darkCanvas,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: MovaDesign.darkSurface,
      selectedItemColor: MovaDesign.darkText,
      unselectedItemColor: Color(0xFF91A7BA),
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      unselectedLabelStyle: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 10,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: MovaDesign.darkElevatedSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      hintStyle: const TextStyle(color: Color(0xFF91A7BA)),
      labelStyle: const TextStyle(color: Color(0xFFB6C8D7)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MovaDesign.radiusSmall),
        borderSide: const BorderSide(color: MovaDesign.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MovaDesign.radiusSmall),
        borderSide: const BorderSide(color: MovaDesign.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MovaDesign.radiusSmall),
        borderSide: const BorderSide(color: MovaDesign.accent, width: 1.6),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: MovaDesign.darkBorder,
      thickness: 1,
      space: 1,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: MovaDesign.accent,
      linearTrackColor: MovaDesign.darkElevatedSurface,
      circularTrackColor: MovaDesign.darkElevatedSurface,
    ),
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        color: MovaDesign.darkText,
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
      ),
      headlineSmall: TextStyle(
        color: MovaDesign.darkText,
        fontSize: 25,
        fontWeight: FontWeight.w800,
      ),
      titleLarge: TextStyle(
        color: MovaDesign.darkText,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: TextStyle(
        color: MovaDesign.darkText,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(color: MovaDesign.darkText, fontSize: 15),
      bodyMedium: TextStyle(color: Color(0xFFD0DDE7), fontSize: 14),
      bodySmall: TextStyle(color: Color(0xFF91A7BA), fontSize: 12),
      labelLarge: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    ),
    useMaterial3: true,
  );
}
