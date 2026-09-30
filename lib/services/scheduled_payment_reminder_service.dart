import 'package:mova/database/database_helper.dart';
import 'package:mova/models/scheduled_payment.dart';
import 'package:mova/services/currency_controller.dart';
import 'package:mova/services/notification_service.dart';

class ScheduledPaymentReminderService {
  ScheduledPaymentReminderService({DatabaseHelper? database})
    : _database = database ?? DatabaseHelper();

  final DatabaseHelper _database;

  Future<void> syncAll() async {
    final enabled =
        await _database.getNotificationsEnabled() &&
        await _database.getNotificationOption('notification_payments');
    final payments = await _database.getScheduledPayments(
      includeCancelled: true,
    );
    for (final payment in payments) {
      if (!enabled || payment.status != ScheduledPaymentStatus.active) {
        await NotificationService.cancelPaymentReminder(payment.id);
      } else {
        await schedule(payment);
      }
    }
  }

  Future<void> schedule(ScheduledPayment payment) async {
    await NotificationService.cancelPaymentReminder(payment.id);
    if (payment.status != ScheduledPaymentStatus.active ||
        !await _database.getNotificationsEnabled() ||
        !await _database.getNotificationOption('notification_payments')) {
      return;
    }
    final today = DateTime.now();
    final due = DateTime(
      payment.dueDate.year,
      payment.dueDate.month,
      payment.dueDate.day,
    );
    if (due.isBefore(DateTime(today.year, today.month, today.day))) return;
    final currency = movaCurrencies.firstWhere(
      (item) => item.code == payment.currency,
      orElse: () => movaCurrencies.first,
    );
    final accountId = payment.targetAccountId ?? payment.accountId;
    final account = accountId == null
        ? null
        : await _database.getFinancialAccount(accountId);
    final accountLabel = account == null
        ? ''
        : '\n${account.name}${account.lastFour.isEmpty ? '' : ' •••• ${account.lastFour}'}';
    await NotificationService.schedulePaymentReminder(
      paymentId: payment.id,
      title: 'Próximo pago: ${payment.name}',
      body:
          '${currency.symbol}${payment.amount.toStringAsFixed(2)} ${payment.currency} · ${payment.dueDate.day}/${payment.dueDate.month}$accountLabel',
      dueDate: payment.dueDate,
      reminderDays: payment.reminderDays,
    );
  }

  Future<void> cancel(int id) => NotificationService.cancelPaymentReminder(id);
}
