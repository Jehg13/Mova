import 'package:flutter/material.dart';
import 'package:mova/database/database_helper.dart';

class MovaLanguage {
  const MovaLanguage({
    required this.code,
    required this.label,
    required this.nativeLabel,
    required this.locale,
  });

  final String code;
  final String label;
  final String nativeLabel;
  final Locale locale;
}

const movaLanguages = <MovaLanguage>[
  MovaLanguage(
    code: 'es',
    label: 'Español',
    nativeLabel: 'Español',
    locale: Locale('es'),
  ),
  MovaLanguage(
    code: 'en',
    label: 'Inglés',
    nativeLabel: 'English',
    locale: Locale('en'),
  ),
  MovaLanguage(
    code: 'pt',
    label: 'Portugués',
    nativeLabel: 'Português',
    locale: Locale('pt'),
  ),
];

class LanguageController extends ChangeNotifier {
  LanguageController(this._database);

  final DatabaseHelper _database;
  String code = 'es';

  MovaLanguage get language => movaLanguages.firstWhere(
    (item) => item.code == code,
    orElse: () => movaLanguages.first,
  );

  Future<void> load() async {
    final stored = await _database.getLanguage();
    if (movaLanguages.any((item) => item.code == stored)) {
      code = stored;
    }
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    if (!movaLanguages.any((item) => item.code == value) || value == code) {
      return;
    }
    code = value;
    notifyListeners();
    await _database.setLanguage(value);
  }
}

late LanguageController appLanguageController;
