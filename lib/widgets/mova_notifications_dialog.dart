import 'package:flutter/material.dart';
import 'package:mova/services/mova_localizations.dart';
import 'package:mova/database/database_helper.dart';

class MovaNotificationsDialog extends StatefulWidget {
  const MovaNotificationsDialog({super.key});

  @override
  State<MovaNotificationsDialog> createState() =>
      _MovaNotificationsDialogState();
}

class _MovaNotificationsDialogState extends State<MovaNotificationsDialog> {
  final _database = DatabaseHelper();
  bool _loading = true;
  bool _enabled = true;
  bool _budget = true;
  bool _goals = true;
  bool _shopping = true;
  String? _savingKey;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final values = await Future.wait([
      _database.getNotificationsEnabled(),
      _database.getNotificationOption('notification_budget'),
      _database.getNotificationOption('notification_goals'),
      _database.getNotificationOption('notification_shopping'),
    ]);
    if (!mounted) return;
    setState(() {
      _enabled = values[0];
      _budget = values[1];
      _goals = values[2];
      _shopping = values[3];
      _loading = false;
    });
  }

  Future<void> _set(String key, bool value) async {
    setState(() => _savingKey = key);
    try {
      await _database.setNotificationOption(key, value);
      if (!mounted) return;
      setState(() => _savingKey = null);
    } catch (_) {
      if (!mounted) return;
      setState(() => _savingKey = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(movaText('No se pudo guardar la preferencia.'))),
      );
    }
  }

  Future<void> _toggle(String key, bool value) async {
    setState(() {
      if (key == 'notifications_enabled') {
        _enabled = value;
      } else if (key == 'notification_budget') {
        _budget = value;
      } else if (key == 'notification_goals') {
        _goals = value;
      } else {
        _shopping = value;
      }
    });
    await _set(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 14),
          child: _loading
              ? SizedBox(
                  height: 260,
                  child: Center(child: CircularProgressIndicator()),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF0C2340), Color(0xFF36577D)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.text('notifications'),
                                style: TextStyle(
                                  color: Color(0xFF102A43),
                                  fontSize: 21,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                l10n.text('choose_notifications'),
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    SizedBox(height: 18),
                    Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _enabled ? Color(0xFFEAF6FA) : Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _enabled
                              ? Color(0xFFD4EEF3)
                              : Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _enabled
                                ? Icons.notifications_active_outlined
                                : Icons.notifications_off_outlined,
                            color: _enabled
                                ? Color(0xFF007C91)
                                : Color(0xFF64748B),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.text('allow_notifications'),
                                  style: TextStyle(
                                    color: Color(0xFF102A43),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  l10n.text('notifications_help'),
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _enabled,
                            activeTrackColor: Color(0xFF0C2340),
                            onChanged: _savingKey == 'notifications_enabled'
                                ? null
                                : (value) =>
                                      _toggle('notifications_enabled', value),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 18),
                    Text(
                      l10n.text('notification_types'),
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    SizedBox(height: 8),
                    _NotificationOption(
                      icon: Icons.account_balance_wallet_outlined,
                      title: l10n.text('personal_budget'),
                      subtitle: l10n.text('budget_help'),
                      value: _budget,
                      enabled: _enabled,
                      saving: _savingKey == 'notification_budget',
                      onChanged: (value) =>
                          _toggle('notification_budget', value),
                    ),
                    _NotificationOption(
                      icon: Icons.flag_outlined,
                      title: l10n.text('goals'),
                      subtitle: l10n.text('goals_help'),
                      value: _goals,
                      enabled: _enabled,
                      saving: _savingKey == 'notification_goals',
                      onChanged: (value) =>
                          _toggle('notification_goals', value),
                    ),
                    _NotificationOption(
                      icon: Icons.shopping_bag_outlined,
                      title: l10n.text('shopping_lists'),
                      subtitle: l10n.text('shopping_help'),
                      value: _shopping,
                      enabled: _enabled,
                      saving: _savingKey == 'notification_shopping',
                      onChanged: (value) =>
                          _toggle('notification_shopping', value),
                    ),
                    SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFF0C2340),
                        padding: EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(color: Color(0xFFD7E0EA)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(l10n.text('done')),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _NotificationOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final bool saving;
  final ValueChanged<bool> onChanged;

  const _NotificationOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.saving,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF36577D), size: 21),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Color(0xFF102A43),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
              ],
            ),
          ),
          if (saving)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch.adaptive(
              value: value,
              activeTrackColor: Color(0xFF0C2340),
              onChanged: enabled ? onChanged : null,
            ),
        ],
      ),
    );
  }
}
