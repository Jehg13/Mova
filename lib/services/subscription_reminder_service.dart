import 'package:mova/database/database_helper.dart';
import 'package:mova/models/subscription.dart';
import 'package:mova/services/currency_controller.dart';
import 'package:mova/services/notification_service.dart';

class SubscriptionReminderService {
  SubscriptionReminderService({DatabaseHelper? database})
    : _database = database ?? DatabaseHelper();

  final DatabaseHelper _database;

  Future<void> syncAll() async {
    final enabled =
        await _database.getNotificationsEnabled() &&
        await _database.getNotificationOption('notification_subscriptions');
    final subscriptions = await _database.getSubscriptions();
    for (final subscription in subscriptions) {
      if (!enabled || subscription.status != SubscriptionStatus.active) {
        await NotificationService.cancelSubscriptionReminder(subscription.id);
      } else {
        await schedule(subscription);
      }
    }
  }

  Future<void> schedule(Subscription subscription) async {
    await NotificationService.cancelSubscriptionReminder(subscription.id);
    if (subscription.status != SubscriptionStatus.active ||
        !await _database.getNotificationsEnabled() ||
        !await _database.getNotificationOption('notification_subscriptions')) {
      return;
    }
    final today = DateTime.now();
    final chargeDay = DateTime(
      subscription.nextChargeDate.year,
      subscription.nextChargeDate.month,
      subscription.nextChargeDate.day,
    );
    if (chargeDay.isBefore(DateTime(today.year, today.month, today.day))) {
      return;
    }
    final currency = movaCurrencies.firstWhere(
      (item) => item.code == subscription.currency,
      orElse: () => movaCurrencies.first,
    );
    final amount =
        '${currency.symbol}${subscription.amount.toStringAsFixed(2)}';
    final account = subscription.accountLabel.isEmpty
        ? ''
        : '\n${subscription.accountLabel}';
    await NotificationService.scheduleSubscriptionReminder(
      subscriptionId: subscription.id,
      title: 'Próximo cobro: ${subscription.name}',
      body: '$amount · ${_dateLabel(subscription.nextChargeDate)}$account',
      chargeDate: subscription.nextChargeDate,
      reminderDays: subscription.reminderDays,
    );
  }

  Future<void> cancel(int subscriptionId) =>
      NotificationService.cancelSubscriptionReminder(subscriptionId);

  String _dateLabel(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
