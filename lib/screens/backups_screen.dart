import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mova/database/database_helper.dart';
import 'package:mova/models/backup_preview.dart';
import 'package:mova/models/managed_backup.dart';
import 'package:mova/services/backup_codec.dart';
import 'package:mova/services/backup_manager.dart';
import 'package:mova/services/currency_controller.dart';
import 'package:mova/services/language_controller.dart';
import 'package:mova/services/mova_localizations.dart';
import 'package:mova/services/scheduled_payment_reminder_service.dart';
import 'package:mova/services/subscription_reminder_service.dart';
import 'package:mova/widgets/mova_design_system.dart';
import 'package:share_plus/share_plus.dart';

class BackupsScreen extends StatefulWidget {
  const BackupsScreen({this.openImportOnStart = false, super.key});

  final bool openImportOnStart;

  @override
  State<BackupsScreen> createState() => _BackupsScreenState();
}

class _BackupsScreenState extends State<BackupsScreen> {
  final _manager = BackupManager();
  List<ManagedBackup> _backups = const [];
  bool _enabled = false;
  bool _busy = false;
  String _frequency = 'weekly';
  int _retention = 5;
  DateTime? _lastBackup;
  DateTime? _nextBackup;
  bool _importStarted = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() => super.dispose();

  Future<void> _load() async {
    try {
      final values = await Future.wait([
        _manager.listBackups(),
        _manager.automaticEnabled,
        _manager.automaticFrequency,
        _manager.retentionCount,
        _manager.lastAutomaticBackup,
        _manager.nextAutomaticBackup,
      ]);
      if (!mounted) return;
      setState(() {
        _backups = values[0] as List<ManagedBackup>;
        _enabled = values[1] as bool;
        _frequency = values[2] as String;
        _retention = values[3] as int;
        _lastBackup = values[4] as DateTime?;
        _nextBackup = values[5] as DateTime?;
      });
      if (widget.openImportOnStart && !_importStarted) {
        _importStarted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _importFile();
        });
      }
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _runAutomaticBackup() async {
    try {
      final created = await _manager.runAutomaticBackupIfDue();
      if (created && mounted) await _load();
    } catch (error) {
      debugPrint('No se pudo realizar el backup automático: $error');
    }
  }

  Future<void> _createBackup() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final filePath = await _manager.createBackup();
      if (!mounted) return;
      await _load();
      await _showCreatedDialog(filePath);
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showCreatedDialog(String filePath) async {
    final context = this.context;
    final name = filePath.split(RegExp(r'[/\\]')).last;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.text('backup_created')),
        content: SelectableText(name),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _saveFile(filePath, name);
            },
            child: Text(dialogContext.l10n.text('backup_save_file')),
          ),
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _shareFile(filePath, name);
            },
            icon: const Icon(Icons.share_outlined),
            label: Text(dialogContext.l10n.text('backup_share')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(dialogContext.l10n.text('close')),
          ),
        ],
      ),
    );
  }

  Future<void> _saveFile(String sourcePath, String fileName) async {
    final l10n = context.l10n;
    try {
      final file = XFile(sourcePath);
      if (await file.length() > BackupCodec.maxBytes) {
        if (mounted) _showMessage(l10n.text('backup_too_large'));
        return;
      }
      final bytes = await file.readAsBytes();
      final savedUri = await FilePicker.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: 'application/json',
        dialogTitle: l10n.text('backup_save_file'),
      );
      if (!mounted || savedUri == null) return;
      _showMessage(l10n.text('backup_file_saved'));
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _shareFile(String sourcePath, String fileName) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(sourcePath, mimeType: 'application/json')],
          subject: fileName,
        ),
      );
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _importFile() async {
    if (_busy) return;
    final l10n = context.l10n;
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        dialogTitle: l10n.text('backup_import'),
      );
      if (result.isEmpty || !mounted) return;
      final selected = result.first;
      if ((await selected.length() ?? 0) > BackupCodec.maxBytes) {
        _showMessage(l10n.text('backup_too_large'));
        return;
      }
      final bytes = await selected.readAsBytes();
      final preview = BackupCodec.decodeBytes(bytes);
      await _confirmRestore(preview);
    } on BackupFormatException catch (error) {
      if (mounted) {
        final key = error.message.contains('incompatible')
            ? 'backup_incompatible'
            : 'backup_invalid';
        _showMessage(l10n.text(key));
      }
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _restoreManaged(ManagedBackup backup) async {
    final l10n = context.l10n;
    try {
      final preview = BackupCodec.decodeBytes(
        await XFile(backup.path).readAsBytes(),
      );
      if (mounted) await _confirmRestore(preview);
    } on BackupFormatException {
      if (mounted) _showMessage(l10n.text('backup_invalid'));
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _confirmRestore(BackupPreview preview) async {
    final l10n = context.l10n;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.text('backup_restore')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dialogContext.l10n.text('backup_restore_warning')),
              const SizedBox(height: 8),
              Text(dialogContext.l10n.text('backup_before_restore')),
              const SizedBox(height: 16),
              _previewRows(dialogContext, preview),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.l10n.text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.l10n.text('backup_restore_confirm')),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _manager.createBackup(kind: BackupKind.preRestore);
      final imported = await DatabaseHelper().importBackup(
        preview.payload,
        replaceExisting: true,
      );
      await appCurrencyController.load();
      await appLanguageController.load();
      await SubscriptionReminderService().syncAll();
      await ScheduledPaymentReminderService().syncAll();
      if (!mounted) return;
      await _load();
      _showMessage(
        '${l10n.text('backup_restored')} · '
        '$imported ${l10n.text('backup_transactions').toLowerCase()}',
      );
    } catch (error) {
      debugPrint('Falló la restauración de backup: $error');
      if (mounted) {
        _showMessage(l10n.text('backup_failed'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteBackup(ManagedBackup backup) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.text('backup_delete')),
        content: Text(dialogContext.l10n.text('backup_delete_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.l10n.text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.l10n.text('backup_delete')),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    try {
      await _manager.deleteBackup(backup);
      await _load();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _setAutomatic(bool enabled) async {
    try {
      await _manager.setAutomaticEnabled(enabled);
      if (enabled) await _runAutomaticBackup();
      await _load();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _setFrequency(String? value) async {
    if (value == null) return;
    try {
      await _manager.setAutomaticFrequency(value);
      await _load();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _setRetention(int? value) async {
    if (value == null) return;
    try {
      await _manager.setRetentionCount(value);
      await _load();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Widget _previewRows(BuildContext context, BackupPreview preview) {
    final l10n = context.l10n;
    return Column(
      children: [
        _summaryRow(l10n.text('backup_version'), preview.version.toString()),
        _summaryRow(l10n.text('backup_transactions'), '${preview.movements}'),
        _summaryRow(
          '${l10n.text('expense')} · ${l10n.text('income')}',
          '${preview.expenses} · ${preview.income}',
        ),
        _summaryRow(l10n.text('backup_goals'), '${preview.goals}'),
        _summaryRow(l10n.text('backup_accounts'), '${preview.accounts}'),
        _summaryRow(
          l10n.text('backup_subscriptions'),
          '${preview.subscriptions}',
        ),
        _summaryRow(
          l10n.text('backup_last'),
          _formatDate(context, preview.createdAt),
        ),
      ],
    );
  }

  Widget _summaryRow(String title, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(title)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );

  String _frequencyLabel(BuildContext context, String value) {
    final key = switch (value) {
      'daily' => 'backup_daily',
      'monthly' => 'backup_monthly',
      _ => 'backup_weekly',
    };
    return context.l10n.text(key);
  }

  String _kindLabel(BuildContext context, BackupKind kind) {
    final key = switch (kind) {
      BackupKind.manual => 'backup_manual',
      BackupKind.automatic => 'backup_automatic',
      BackupKind.preRestore => 'backup_pre_restore',
    };
    return context.l10n.text(key);
  }

  String _formatDate(BuildContext context, DateTime? value) {
    if (value == null) return '—';
    final date = MaterialLocalizations.of(context).formatShortDate(value);
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(value));
    return '$date · $time';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(Object error) {
    debugPrint('Error en el gestor de backups: $error');
    _showMessage(context.l10n.text('backup_failed'));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: MovaDesign.canvas,
      appBar: AppBar(
        title: Text(l10n.text('backups_title')),
        backgroundColor: MovaDesign.canvas,
        foregroundColor: const Color(0xFF102A43),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: l10n.text('backup_import'),
            onPressed: _busy ? null : _importFile,
            icon: const Icon(Icons.file_open_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: [
            Text(
              l10n.text('backups_subtitle'),
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _createBackup,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_to_drive_outlined),
                label: Text(l10n.text('backup_create_now')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C2340),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _busy ? null : _importFile,
              icon: const Icon(Icons.file_open_outlined),
              label: Text(l10n.text('backup_import')),
            ),
            const SizedBox(height: 20),
            _sectionCard(
              title: l10n.text('backup_auto_title'),
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.text('backup_auto_enabled')),
                    value: _enabled,
                    onChanged: _busy ? null : _setAutomatic,
                  ),
                  if (_enabled) ...[
                    DropdownButtonFormField<String>(
                      initialValue: _frequency,
                      decoration: InputDecoration(
                        labelText: l10n.text('backup_frequency'),
                      ),
                      items: [
                        for (final frequency in ['daily', 'weekly', 'monthly'])
                          DropdownMenuItem(
                            value: frequency,
                            child: Text(_frequencyLabel(context, frequency)),
                          ),
                      ],
                      onChanged: _busy ? null : _setFrequency,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: _retention,
                      decoration: InputDecoration(
                        labelText: l10n.text('backup_retention'),
                      ),
                      items: [
                        for (final count in [3, 5, 10])
                          DropdownMenuItem(
                            value: count,
                            child: Text('$count ${l10n.text('backup_count')}'),
                          ),
                      ],
                      onChanged: _busy ? null : _setRetention,
                    ),
                    const SizedBox(height: 12),
                    _summaryRow(
                      l10n.text('backup_last'),
                      _formatDate(context, _lastBackup),
                    ),
                    _summaryRow(
                      l10n.text('backup_next'),
                      _formatDate(context, _nextBackup),
                    ),
                    _summaryRow(
                      l10n.text('backup_location'),
                      l10n.text('backup_location_local'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.text('backup_local_note'),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.text('backup_my_files'),
              style: const TextStyle(
                color: Color(0xFF102A43),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            if (_backups.isEmpty)
              _sectionCard(
                child: Text(
                  l10n.text('backup_empty'),
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              )
            else
              ..._backups.map((backup) => _backupTile(context, backup)),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({String? title, required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
        ],
        child,
      ],
    ),
  );

  Widget _backupTile(BuildContext context, ManagedBackup backup) {
    final preview = backup.preview;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE8F0F7),
          child: Icon(Icons.backup_outlined, color: Color(0xFF0C2340)),
        ),
        title: Text(
          backup.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF102A43),
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            preview == null
                ? context.l10n.text('backup_invalid')
                : '${_kindLabel(context, backup.kind)} · '
                      '${_formatDate(context, preview.createdAt)}\n'
                      '${preview.expenses} ${context.l10n.text('expenses').toLowerCase()} · '
                      '${preview.income} ${context.l10n.text('income').toLowerCase()}',
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            switch (action) {
              case 'restore':
                _restoreManaged(backup);
                break;
              case 'share':
                _shareFile(backup.path, backup.name);
                break;
              case 'save':
                _saveFile(backup.path, backup.name);
                break;
              case 'delete':
                _deleteBackup(backup);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'restore',
              enabled: backup.preview != null,
              child: Text(context.l10n.text('backup_restore')),
            ),
            PopupMenuItem(
              value: 'share',
              child: Text(context.l10n.text('backup_share')),
            ),
            PopupMenuItem(
              value: 'save',
              child: Text(context.l10n.text('backup_save_file')),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text(context.l10n.text('backup_delete')),
            ),
          ],
        ),
      ),
    );
  }
}
