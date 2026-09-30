import 'dart:convert';

import 'package:mova/models/backup_preview.dart';

class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BackupCodec {
  static const currentVersion = 2;
  static const maxBytes = 100 * 1024 * 1024;
  static const _listKeys = {
    'transactions',
    'subscriptions',
    'subscription_payments',
    'accounts',
    'account_transfers',
    'scheduled_payments',
    'scheduled_payment_history',
    'goals',
    'goal_movements',
    'goal_participants',
    'goal_contributions',
    'shopping_lists',
    'shopping_products',
    'custom_categories',
    'app_settings',
  };

  static BackupPreview decodeBytes(List<int> bytes) {
    if (bytes.isEmpty) {
      throw const BackupFormatException('El archivo está vacío.');
    }
    if (bytes.length > maxBytes) {
      throw const BackupFormatException(
        'El archivo supera el tamaño máximo permitido.',
      );
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const BackupFormatException('El archivo JSON está dañado.');
    }
    if (decoded is! Map) {
      throw const BackupFormatException(
        'El archivo no contiene un backup de MOVA.',
      );
    }
    final payload = Map<String, dynamic>.from(decoded);
    final version = payload['version'];
    final isCurrent =
        payload['format'] == 'mova_backup' &&
        version == currentVersion &&
        payload['data'] is Map;
    final isLegacy =
        payload['format'] == null &&
        version == 1 &&
        payload['transactions'] is List;
    if (!isCurrent && !isLegacy) {
      throw const BackupFormatException(
        'El backup es incompatible o tiene una versión no compatible.',
      );
    }
    final rawData = isCurrent ? payload['data'] as Map : payload;
    final data = Map<String, dynamic>.from(rawData);
    for (final key in _listKeys) {
      final value = data[key];
      if (isCurrent && value is! List) {
        throw BackupFormatException(
          'La sección "$key" no está presente o es inválida.',
        );
      }
      if (value != null && value is! List) {
        throw BackupFormatException(
          'La sección "$key" tiene un formato inválido.',
        );
      }
      if (value is List && value.any((item) => item is! Map)) {
        throw BackupFormatException(
          'La sección "$key" contiene registros inválidos.',
        );
      }
    }
    final transactions = _list(data, 'transactions');
    for (final transaction in transactions) {
      final amount = transaction['amount'];
      final date = transaction['date'];
      if (amount is! num ||
          amount <= 0 ||
          (transaction['is_income'] != 0 && transaction['is_income'] != 1) ||
          transaction['category'] is! String ||
          transaction['description'] is! String ||
          DateTime.tryParse(date is String ? date : '') == null) {
        throw const BackupFormatException(
          'El backup contiene un movimiento con datos inválidos.',
        );
      }
      _validateEncodedField(
        transaction,
        'receipt_image_base64',
        required: false,
      );
      if ((transaction['receipt_items'] != null &&
              transaction['receipt_items'] is! String) ||
          (transaction['receipt_reference'] != null &&
              transaction['receipt_reference'] is! String)) {
        throw const BackupFormatException(
          'El backup contiene metadatos de comprobante inválidos.',
        );
      }
    }
    for (final goal in _list(data, 'goals')) {
      final target = goal['target_amount'];
      final saved = goal['saved_amount'];
      if (goal['name'] is! String ||
          target is! num ||
          target <= 0 ||
          saved is! num ||
          saved < 0 ||
          DateTime.tryParse(
                goal['created_at'] is String
                    ? goal['created_at'] as String
                    : '',
              ) ==
              null) {
        throw const BackupFormatException(
          'El backup contiene una meta con datos inválidos.',
        );
      }
      _validateEncodedField(goal, 'image_base64', required: false);
    }
    for (final account in _list(data, 'accounts')) {
      final balance = account['initial_balance'];
      if (account['name'] is! String ||
          account['currency'] is! String ||
          account['type'] is! String ||
          balance is! num ||
          balance < 0) {
        throw const BackupFormatException(
          'El backup contiene una cuenta con datos inválidos.',
        );
      }
    }
    for (final category in _list(data, 'custom_categories')) {
      if (category['name'] is! String ||
          (category['type'] != 'income' && category['type'] != 'expense')) {
        throw const BackupFormatException(
          'El backup contiene una categoría con datos inválidos.',
        );
      }
    }
    for (final setting in _list(data, 'app_settings')) {
      if (setting['key'] is! String || setting['value'] is! String) {
        throw const BackupFormatException(
          'El backup contiene una preferencia con datos inválidos.',
        );
      }
    }
    if (data['profile'] != null && data['profile'] is! Map) {
      throw const BackupFormatException(
        'El backup contiene un perfil con formato inválido.',
      );
    }
    final profile = data['profile'];
    if (profile is Map) {
      _validateEncodedField(profile, 'image_base64', required: false);
    }
    final rawCreatedAt = isCurrent
        ? payload['created_at']
        : payload['exported_at'];
    final createdAt = rawCreatedAt is String
        ? DateTime.tryParse(rawCreatedAt)
        : null;
    if (isCurrent &&
        (payload['created_at'] is! String ||
            payload['database_version'] is! int ||
            payload['app_version'] is! String ||
            createdAt == null)) {
      throw const BackupFormatException(
        'Faltan metadatos requeridos del backup.',
      );
    }
    return BackupPreview(
      payload: payload,
      createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      version: version as int,
      expenses: transactions.where((item) => item['is_income'] == 0).length,
      income: transactions.where((item) => item['is_income'] == 1).length,
      goals: _list(data, 'goals').length,
      accounts: _list(data, 'accounts').length,
      subscriptions: _list(data, 'subscriptions').length,
    );
  }

  static List<Map> _list(Map<String, dynamic> data, String key) {
    final value = data[key];
    return value is List ? value.whereType<Map>().toList() : const [];
  }

  static void _validateEncodedField(
    Map<dynamic, dynamic> record,
    String key, {
    required bool required,
  }) {
    final encoded = record[key];
    if (encoded == null && !required) return;
    if (encoded is! String) {
      throw BackupFormatException('El campo "$key" tiene un formato inválido.');
    }
    try {
      base64Decode(encoded);
    } on FormatException {
      throw BackupFormatException('El campo "$key" está dañado.');
    }
  }
}
