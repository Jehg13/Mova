import 'package:mova/models/backup_preview.dart';

enum BackupKind { manual, automatic, preRestore }

class ManagedBackup {
  const ManagedBackup({
    required this.path,
    required this.name,
    required this.kind,
    this.preview,
    this.error,
  });

  final String path;
  final String name;
  final BackupKind kind;
  final BackupPreview? preview;
  final String? error;
}
