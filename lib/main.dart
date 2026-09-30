import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'screens/splash_screen.dart';
import 'database/database_helper.dart';
import 'services/theme_controller.dart';
import 'services/notification_service.dart';
import 'services/currency_controller.dart';
import 'services/language_controller.dart';
import 'services/mova_localizations.dart';
import 'services/backup_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
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
  appLanguageController = LanguageController(DatabaseHelper());
  await appLanguageController.load();
  runApp(const MovaApp());
}

class MovaApp extends StatefulWidget {
  const MovaApp({super.key});

  @override
  State<MovaApp> createState() => _MovaAppState();
}

class _MovaAppState extends State<MovaApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _runAutomaticBackup();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _runAutomaticBackup();
  }

  Future<void> _runAutomaticBackup() async {
    try {
      await BackupManager().runAutomaticBackupIfDue();
    } catch (error) {
      debugPrint('No se pudo realizar el backup automático: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        appCurrencyController,
        appLanguageController,
      ]),
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: appLanguageController.language.locale,
        supportedLocales: const [Locale('es'), Locale('en'), Locale('pt')],
        localizationsDelegates: const [
          MovaLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: movaLightTheme(),
        darkTheme: movaDarkTheme(),
        themeMode: ThemeMode.light,
        home: SplashScreen(),
      ),
    );
  }
}
