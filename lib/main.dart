import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'screens/splash_screen.dart';
import 'database/database_helper.dart';
import 'services/theme_controller.dart';
import 'services/notification_service.dart';
import 'services/currency_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    databaseFactory = databaseFactoryFfi;
  }

  appCurrencyController = CurrencyController(DatabaseHelper());
  await appCurrencyController.load();
  runApp(const MovaApp());
}

class MovaApp extends StatelessWidget {
  const MovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appCurrencyController,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: movaLightTheme(),
        darkTheme: movaDarkTheme(),
        themeMode: ThemeMode.light,
        home: const SplashScreen(),
      ),
    );
  }
}
