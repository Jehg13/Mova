import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/managed_backup.dart';
import 'package:mova/services/backup_codec.dart';
import 'package:mova/services/backup_manager.dart';

void main() {
  late Directory root;
  late BackupManager manager;
  final settings = <String, String>{};
  final data = <String, dynamic>{
    'format': 'mova_backup',
    'version': 2,
    'created_at': '2026-09-30T10:00:00.000',
    'app_version': '1.0.0',
    'database_version': 16,
    'data': {
      'profile': null,
      'transactions': <Object>[],
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

  setUp(() async {
    root = await Directory.systemTemp.createTemp('mova_backup_test_');
    settings.clear();
    manager = BackupManager(
      rootDirectory: root,
      exportDataProvider: () async => data,
      settingReader: (key) async => settings[key],
      settingWriter: (key, value) async => settings[key] = value,
    );
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  test('creates a versioned backup file and can list and delete it', () async {
    final filePath = await manager.createBackup();
    final file = File(filePath);

    expect(await file.exists(), isTrue);
    expect(file.uri.pathSegments.last, startsWith('mova_backup_'));
    expect(
      BackupCodec.decodeBytes(await file.readAsBytes()).version,
      BackupCodec.currentVersion,
    );

    final backups = await manager.listBackups();
    expect(backups, hasLength(1));
    expect(backups.single.kind, BackupKind.manual);
    await manager.deleteBackup(backups.single);
    expect(await file.exists(), isFalse);
  });

  test('retention deletes only oldest automatic backups', () async {
    final manualPath = await manager.createBackup();
    await manager.setRetentionCount(3);

    for (var i = 0; i < 5; i++) {
      await manager.createBackup(kind: BackupKind.automatic);
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }

    final backups = await manager.listBackups();
    expect(
      backups.where((backup) => backup.kind == BackupKind.automatic),
      hasLength(3),
    );
    expect(
      backups.where((backup) => backup.kind == BackupKind.manual),
      hasLength(1),
    );
    expect(await File(manualPath).exists(), isTrue);
  });

  test('automatic backup respects configured frequency', () async {
    final now = DateTime(2026, 9, 30, 10);
    await manager.setAutomaticEnabled(true);
    await manager.setAutomaticFrequency('daily');
    settings['backup_auto_last_at'] = now.toIso8601String();

    expect(
      await manager.runAutomaticBackupIfDue(
        now: now.add(const Duration(hours: 23)),
      ),
      isFalse,
    );
    expect(
      await manager.runAutomaticBackupIfDue(
        now: now.add(const Duration(days: 1)),
      ),
      isTrue,
    );
    expect(
      (await manager.listBackups()).where(
        (backup) => backup.kind == BackupKind.automatic,
      ),
      hasLength(1),
    );
    expect(
      jsonDecode(
        await File((await manager.listBackups()).single.path).readAsString(),
      ),
      isA<Map>(),
    );
  });
}
