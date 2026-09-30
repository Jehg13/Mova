import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mova/services/backup_codec.dart';

void main() {
  Map<String, dynamic> currentBackup({
    List<Map<String, Object?>> transactions = const [],
  }) {
    return {
      'format': 'mova_backup',
      'version': 2,
      'created_at': '2026-09-30T10:00:00.000',
      'app_version': '1.0.0',
      'database_version': 16,
      'data': {
        'profile': null,
        'transactions': transactions,
        'subscriptions': <Object>[],
        'subscription_payments': <Object>[],
        'accounts': <Object>[],
        'account_transfers': <Object>[],
        'scheduled_payments': <Object>[],
        'scheduled_payment_history': <Object>[],
        'goals': <Object>[],
        'goal_movements': <Object>[],
        'goal_participants': <Object>[],
        'goal_contributions': <Object>[],
        'shopping_lists': <Object>[],
        'shopping_products': <Object>[],
        'custom_categories': <Object>[],
        'app_settings': <Object>[],
      },
    };
  }

  List<int> bytes(Map<String, dynamic> data) => utf8.encode(jsonEncode(data));

  test('validates and summarizes a MOVA backup', () {
    final preview = BackupCodec.decodeBytes(
      bytes(
        currentBackup(
          transactions: [
            {
              'amount': 100,
              'is_income': 0,
              'category': 'Comida',
              'description': 'Café',
              'date': '2026-09-30T09:00:00.000',
            },
            {
              'amount': 500,
              'is_income': 1,
              'category': 'Sueldo',
              'description': 'Nómina',
              'date': '2026-09-30T09:00:00.000',
            },
          ],
        ),
      ),
    );

    expect(preview.version, 2);
    expect(preview.expenses, 1);
    expect(preview.income, 1);
    expect(preview.movements, 2);
    expect(preview.createdAt, DateTime(2026, 9, 30, 10));
  });

  test('accepts the previous flat JSON backup format', () {
    final preview = BackupCodec.decodeBytes(
      bytes({
        'version': 1,
        'exported_at': '2026-09-29T12:30:00.000',
        'transactions': [
          {
            'amount': 50,
            'is_income': 0,
            'category': 'Hogar',
            'description': 'Internet',
            'date': '2026-09-29T10:00:00.000',
          },
        ],
      }),
    );

    expect(preview.version, 1);
    expect(preview.expenses, 1);
  });

  test('rejects invalid JSON, malformed records, and future versions', () {
    expect(
      () => BackupCodec.decodeBytes(utf8.encode('{bad json')),
      throwsA(isA<BackupFormatException>()),
    );
    expect(
      () => BackupCodec.decodeBytes(
        bytes(
          currentBackup(
            transactions: [
              {
                'amount': -1,
                'is_income': 0,
                'category': 'Comida',
                'description': 'Inválido',
                'date': '2026-09-30',
              },
            ],
          ),
        ),
      ),
      throwsA(isA<BackupFormatException>()),
    );
    final incompatible = currentBackup()..['version'] = 3;
    expect(
      () => BackupCodec.decodeBytes(bytes(incompatible)),
      throwsA(isA<BackupFormatException>()),
    );
  });
}
