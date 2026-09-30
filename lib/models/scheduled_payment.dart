import 'subscription.dart';

enum ScheduledPaymentType { recurring, oneTime, cardPayment }

enum ScheduledPaymentStatus { active, cancelled, completed }

enum PaymentSource { subscription, scheduled }

class ScheduledPayment {
  const ScheduledPayment({
    required this.id,
    required this.name,
    required this.amount,
    required this.currency,
    required this.type,
    required this.dueDate,
    required this.reminderDays,
    required this.status,
    required this.createdAt,
    this.category,
    this.frequency,
    this.accountId,
    this.targetAccountId,
    this.notes = '',
  });

  final int id;
  final String name;
  final double amount;
  final String currency;
  final ScheduledPaymentType type;
  final DateTime dueDate;
  final int reminderDays;
  final ScheduledPaymentStatus status;
  final DateTime createdAt;
  final String? category;
  final SubscriptionFrequency? frequency;
  final int? accountId;
  final int? targetAccountId;
  final String notes;

  bool get isRecurring => frequency != null;

  factory ScheduledPayment.fromMap(Map<String, Object?> row) =>
      ScheduledPayment(
        id: row['id'] as int,
        name: row['name'] as String,
        amount: (row['amount'] as num).toDouble(),
        currency: row['currency'] as String,
        type: ScheduledPaymentType.values.byName(row['payment_type'] as String),
        dueDate: DateTime.parse(row['due_date'] as String),
        reminderDays: row['reminder_days'] as int,
        status: ScheduledPaymentStatus.values.byName(row['status'] as String),
        createdAt: DateTime.parse(row['created_at'] as String),
        category: row['category'] as String?,
        frequency: (row['frequency'] as String?) == null
            ? null
            : SubscriptionFrequency.values.byName(row['frequency'] as String),
        accountId: row['account_id'] as int?,
        targetAccountId: row['target_account_id'] as int?,
        notes: row['notes'] as String? ?? '',
      );

  Map<String, Object?> toDatabaseMap() => {
    'name': name.trim(),
    'amount': amount,
    'currency': currency,
    'payment_type': type.name,
    'due_date': dateOnly(dueDate),
    'reminder_days': reminderDays,
    'status': status.name,
    'category': category,
    'frequency': frequency?.name,
    'account_id': accountId,
    'target_account_id': targetAccountId,
    'notes': notes.trim(),
  };

  static String dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day).toIso8601String();

  static DateTime nextDate(DateTime date, SubscriptionFrequency frequency) =>
      Subscription.nextDate(date, frequency);

  static DateTime nextFutureDate(
    DateTime date,
    SubscriptionFrequency frequency, {
    required DateTime after,
  }) => Subscription.nextFutureDate(date, frequency, after: after);
}

class UpcomingPayment {
  const UpcomingPayment({
    required this.source,
    required this.id,
    required this.name,
    required this.amount,
    required this.currency,
    required this.dueDate,
    required this.reminderDays,
    this.category,
    this.frequency,
    this.type,
    this.accountId,
    this.accountLabel = '',
    this.targetAccountId,
  });

  final PaymentSource source;
  final int id;
  final String name;
  final double amount;
  final String currency;
  final DateTime dueDate;
  final int reminderDays;
  final String? category;
  final SubscriptionFrequency? frequency;
  final ScheduledPaymentType? type;
  final int? accountId;
  final String accountLabel;
  final int? targetAccountId;

  bool get isCardPayment => type == ScheduledPaymentType.cardPayment;
  bool get isOverdue {
    final today = DateTime.now();
    return DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
    ).isBefore(DateTime(today.year, today.month, today.day));
  }

  factory UpcomingPayment.fromSubscription(Subscription subscription) =>
      UpcomingPayment(
        source: PaymentSource.subscription,
        id: subscription.id,
        name: subscription.name,
        amount: subscription.amount,
        currency: subscription.currency,
        dueDate: subscription.nextChargeDate,
        reminderDays: subscription.reminderDays,
        category: subscription.category,
        frequency: subscription.frequency,
        accountId: subscription.accountId,
        accountLabel: subscription.accountLabel,
      );

  factory UpcomingPayment.fromScheduled(
    ScheduledPayment payment, {
    required String accountLabel,
  }) => UpcomingPayment(
    source: PaymentSource.scheduled,
    id: payment.id,
    name: payment.name,
    amount: payment.amount,
    currency: payment.currency,
    dueDate: payment.dueDate,
    reminderDays: payment.reminderDays,
    category: payment.category,
    frequency: payment.frequency,
    type: payment.type,
    accountId: payment.accountId,
    accountLabel: accountLabel,
    targetAccountId: payment.targetAccountId,
  );
}
