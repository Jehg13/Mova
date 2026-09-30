import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:mova/database/database_helper.dart';
import 'package:mova/models/backup_preview.dart';
import 'package:mova/models/managed_backup.dart';
import 'package:mova/services/backup_codec.dart';
import 'package:mova/services/backup_schedule.dart';

class BackupManager {
  BackupManager({
    this.rootDirectory,
    this.exportDataProvider,
    this.settingReader,
    this.settingWriter,
    DatabaseHelper? database,
  }) : _database = database ?? DatabaseHelper();

  final Directory? rootDirectory;
  final DatabaseHelper _database;
  final Future<Map<String, dynamic>> Function()? exportDataProvider;
  final Future<String?> Function(String key)? settingReader;
  final Future<void> Function(String key, String value)? settingWriter;

  Future<Directory> get backupDirectory async {
    final root = rootDirectory ?? await getApplicationDocumentsDirectory();
    final directory = Directory(path.join(root.path, 'mova_backups'));
    await directory.create(recursive: true);
    return directory;
  }

  Future<String> createBackup({
    BackupKind kind = BackupKind.manual,
    Map<String, dynamic>? data,
  }) async {
    final payload =
        data ?? await (exportDataProvider?.call() ?? _database.exportData());
    final directory = await backupDirectory;
    final now = DateTime.now();
    final stamp =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}-'
        '${now.minute.toString().padLeft(2, '0')}-'
        '${now.second.toString().padLeft(2, '0')}-'
        '${now.microsecond.toString().padLeft(6, '0')}';
    final prefix = switch (kind) {
      BackupKind.manual => 'mova_backup',
      BackupKind.automatic => 'mova_auto',
      BackupKind.preRestore => 'mova_pre_restore',
    };
    final file = File(path.join(directory.path, '${prefix}_$stamp.json'));
    final contents = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    if (contents.length > BackupCodec.maxBytes) {
      throw StateError('El backup supera el tamaño máximo permitido.');
    }
    await file.writeAsBytes(contents, flush: true);
    if (kind == BackupKind.automatic) {
      await _setSetting('backup_auto_last_at', now.toIso8601String());
      await _rotateAutomaticBackups();
    }
    return file.path;
  }

  Future<List<ManagedBackup>> listBackups() async {
    final directory = await backupDirectory;
    final results = <ManagedBackup>[];
    await for (final entity in directory.list()) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.json')) {
        continue;
      }
      final name = path.basename(entity.path);
      final kind = name.startsWith('mova_auto_')
          ? BackupKind.automatic
          : name.startsWith('mova_pre_restore_')
          ? BackupKind.preRestore
          : BackupKind.manual;
      BackupPreview? preview;
      String? error;
      try {
        preview = BackupCodec.decodeBytes(await entity.readAsBytes());
      } on BackupFormatException catch (exception) {
        error = exception.message;
      }
      results.add(
        ManagedBackup(
          path: entity.path,
          name: name,
          kind: kind,
          preview: preview,
          error: error,
        ),
      );
    }
    results.sort(
      (a, b) => (b.preview?.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(
            a.preview?.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          ),
    );
    return results;
  }

  Future<void> deleteBackup(ManagedBackup backup) => File(backup.path).delete();

  Future<bool> get automaticEnabled async =>
      await _getSetting('backup_auto_enabled') == 'true';

  Future<void> setAutomaticEnabled(bool value) async {
    await _setSetting('backup_auto_enabled', value.toString());
  }

  Future<String> get automaticFrequency async =>
      await _getSetting('backup_auto_frequency') ?? 'weekly';

  Future<void> setAutomaticFrequency(String value) async {
    if (!{'daily', 'weekly', 'monthly'}.contains(value)) {
      throw ArgumentError.value(value, 'value', 'Frecuencia no compatible');
    }
    await _setSetting('backup_auto_frequency', value);
  }

  Future<int> get retentionCount async =>
      int.tryParse(await _getSetting('backup_auto_retention') ?? '') ?? 5;

  Future<void> setRetentionCount(int value) async {
    if (!{3, 5, 10}.contains(value)) {
      throw ArgumentError.value(value, 'value', 'Retención no compatible');
    }
    await _setSetting('backup_auto_retention', value.toString());
  }

  Future<DateTime?> get lastAutomaticBackup async {
    final raw = await _getSetting('backup_auto_last_at');
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<DateTime?> get nextAutomaticBackup async {
    final last = await lastAutomaticBackup;
    final frequency = await automaticFrequency;
    return last == null ? null : BackupSchedule.next(last, frequency);
  }

  Future<bool> runAutomaticBackupIfDue({DateTime? now}) async {
    if (!await automaticEnabled) return false;
    final current = now ?? DateTime.now();
    final last = await lastAutomaticBackup;
    final frequency = await automaticFrequency;
    if (!BackupSchedule.isDue(last: last, frequency: frequency, now: current)) {
      return false;
    }
    await createBackup(kind: BackupKind.automatic);
    return true;
  }

  Future<void> _rotateAutomaticBackups() async {
    final retention = await retentionCount;
    final backups = (await listBackups())
        .where((backup) => backup.kind == BackupKind.automatic)
        .toList();
    for (final backup in backups.skip(retention)) {
      await File(backup.path).delete();
    }
  }

  Future<String?> _getSetting(String key) =>
      settingReader?.call(key) ?? _database.getUserSetting(key);

  Future<void> _setSetting(String key, String value) =>
      settingWriter?.call(key, value) ?? _database.setUserSetting(key, value);
}
