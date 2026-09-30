import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz_data.initializeTimeZones();
    if (kIsWeb) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );
    await _plugin.initialize(settings: settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'mova_reminders',
        'Recordatorios de Mova',
        channelDescription: 'Avisos de presupuesto, metas y compras',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  static Future<void> scheduleSubscriptionReminder({
    required int subscriptionId,
    required String title,
    required String body,
    required DateTime chargeDate,
    required int reminderDays,
  }) async {
    if (!_supportsScheduledNotifications) return;
    final reminderDate = DateTime(
      chargeDate.year,
      chargeDate.month,
      chargeDate.day,
      9,
    ).subtract(Duration(days: reminderDays));
    final scheduledDate = reminderDate.isAfter(DateTime.now())
        ? reminderDate
        : DateTime.now().add(const Duration(minutes: 1));
    final localDate = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      scheduledDate.hour,
      scheduledDate.minute,
    );
    final scheduled = tz.TZDateTime.from(localDate.toUtc(), tz.UTC);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'mova_subscriptions',
        'Cobros de suscripciones',
        channelDescription: 'Avisos de próximos cobros de suscripciones',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.zonedSchedule(
      id: _subscriptionNotificationId(subscriptionId),
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> cancelSubscriptionReminder(int subscriptionId) async {
    if (!_supportsScheduledNotifications) return;
    await _plugin.cancel(id: _subscriptionNotificationId(subscriptionId));
  }

  static Future<void> schedulePaymentReminder({
    required int paymentId,
    required String title,
    required String body,
    required DateTime dueDate,
    required int reminderDays,
  }) async {
    if (!_supportsScheduledNotifications) return;
    final reminderDate = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      9,
    ).subtract(Duration(days: reminderDays));
    final scheduledDate = reminderDate.isAfter(DateTime.now())
        ? reminderDate
        : DateTime.now().add(const Duration(minutes: 1));
    final localDate = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      scheduledDate.hour,
      scheduledDate.minute,
    );
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'mova_upcoming_payments',
        'Próximos pagos',
        channelDescription: 'Avisos de pagos programados',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.zonedSchedule(
      id: _paymentNotificationId(paymentId),
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(localDate.toUtc(), tz.UTC),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> cancelPaymentReminder(int paymentId) async {
    if (!_supportsScheduledNotifications) return;
    await _plugin.cancel(id: _paymentNotificationId(paymentId));
  }

  static bool get _supportsScheduledNotifications =>
      !kIsWeb &&
      {
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      }.contains(defaultTargetPlatform);

  static int _subscriptionNotificationId(int subscriptionId) =>
      100000000 + subscriptionId;

  static int _paymentNotificationId(int paymentId) => 200000000 + paymentId;
}
