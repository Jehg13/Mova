import 'package:mova/models/managed_backup.dart';

class BackupManager {
  Future<String> createBackup({
    BackupKind kind = BackupKind.manual,
    Map<String, dynamic>? data,
  }) => _unsupportedString();

  Future<List<ManagedBackup>> listBackups() async => const [];

  Future<void> deleteBackup(ManagedBackup backup) => _unsupported();

  Future<bool> get automaticEnabled async => false;

  Future<void> setAutomaticEnabled(bool value) => _unsupported();

  Future<String> get automaticFrequency async => 'weekly';

  Future<void> setAutomaticFrequency(String value) => _unsupported();

  Future<int> get retentionCount async => 5;

  Future<void> setRetentionCount(int value) => _unsupported();

  Future<DateTime?> get lastAutomaticBackup async => null;

  Future<DateTime?> get nextAutomaticBackup async => null;

  Future<bool> runAutomaticBackupIfDue({DateTime? now}) async => false;

  Future<void> _unsupported() => Future.error(
    UnsupportedError(
      'Los backups guardados localmente no están disponibles en web.',
    ),
  );

  Future<String> _unsupportedString() => Future.error(
    UnsupportedError(
      'Los backups guardados localmente no están disponibles en web.',
    ),
  );
}
