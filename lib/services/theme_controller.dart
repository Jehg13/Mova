import 'package:flutter/material.dart';
import 'package:mova/database/database_helper.dart';

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
      seedColor: const Color(0xFF0C2340),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF1F5F9),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF1F5F9),
      foregroundColor: Color(0xFF0C2340),
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    useMaterial3: true,
  );
}

ThemeData movaDarkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF5BC0D8),
      brightness: Brightness.dark,
      surface: const Color(0xFF142B45),
    ),
    scaffoldBackgroundColor: const Color(0xFF081A2B),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF081A2B),
      foregroundColor: Color(0xFFE6F4F8),
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF142B45),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Color(0xFF142B45),
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF1B3856),
    ),
    useMaterial3: true,
  );
}
