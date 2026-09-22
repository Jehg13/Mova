import 'package:flutter/material.dart';

import 'package:mova/database/database_helper.dart';

class CurrencyDefinition {
  const CurrencyDefinition({
    required this.code,
    required this.name,
    required this.symbol,
  });

  final String code;
  final String name;
  final String symbol;
}

const movaCurrencies = <CurrencyDefinition>[
  CurrencyDefinition(code: 'MXN', name: 'Peso mexicano', symbol: '\$'),
  CurrencyDefinition(code: 'USD', name: 'Dólar estadounidense', symbol: 'US\$'),
  CurrencyDefinition(code: 'EUR', name: 'Euro', symbol: '€'),
  CurrencyDefinition(code: 'CAD', name: 'Dólar canadiense', symbol: 'CA\$'),
  CurrencyDefinition(code: 'GBP', name: 'Libra esterlina', symbol: '£'),
];

class CurrencyController extends ChangeNotifier {
  CurrencyController(this._database);

  final DatabaseHelper _database;
  String code = 'MXN';

  CurrencyDefinition get definition => movaCurrencies.firstWhere(
    (currency) => currency.code == code,
    orElse: () => movaCurrencies.first,
  );

  String format(num value) => '${definition.symbol}${value.toStringAsFixed(2)}';

  Future<void> load() async {
    final stored = await _database.getCurrency();
    if (movaCurrencies.any((currency) => currency.code == stored)) {
      code = stored;
    }
    notifyListeners();
  }

  Future<void> setCurrency(String value) async {
    if (!movaCurrencies.any((currency) => currency.code == value)) return;
    code = value;
    notifyListeners();
    await _database.setCurrency(value);
  }
}

late CurrencyController appCurrencyController;
