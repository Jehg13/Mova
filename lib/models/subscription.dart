enum SubscriptionFrequency {
  weekly,
  biweekly,
  monthly,
  bimonthly,
  quarterly,
  semiannual,
  annual,
}

enum SubscriptionStatus { active, paused, cancelled }

class Subscription {
  const Subscription({
    required this.id,
    required this.name,
    required this.description,
    required this.amount,
    required this.currency,
    required this.category,
    required this.frequency,
    required this.nextChargeDate,
    required this.billingDay,
    required this.accountId,
    required this.accountLabel,
    required this.status,
    required this.reminderDays,
    required this.createdAt,
    required this.notes,
  });

  final int id;
  final String name;
  final String description;
  final double amount;
  final String currency;
  final String category;
  final SubscriptionFrequency frequency;
  final DateTime nextChargeDate;
  final int billingDay;
  final int? accountId;
  final String accountLabel;
  final SubscriptionStatus status;
  final int reminderDays;
  final DateTime createdAt;
  final String notes;

  factory Subscription.fromMap(Map<String, Object?> row) {
    return Subscription(
      id: row['id'] as int,
      name: row['name'] as String,
      description: row['description'] as String? ?? '',
      amount: (row['amount'] as num).toDouble(),
      currency: row['currency'] as String,
      category: row['category'] as String,
      frequency: SubscriptionFrequency.values.byName(
        row['frequency'] as String,
      ),
      nextChargeDate: DateTime.parse(row['next_charge_date'] as String),
      billingDay:
          row['billing_day'] as int? ??
          DateTime.parse(row['next_charge_date'] as String).day,
      accountId: row['account_id'] as int?,
      accountLabel: row['account_label'] as String? ?? '',
      status: SubscriptionStatus.values.byName(row['status'] as String),
      reminderDays: row['reminder_days'] as int,
      createdAt: DateTime.parse(row['created_at'] as String),
      notes: row['notes'] as String? ?? '',
    );
  }

  Map<String, Object?> toDatabaseMap() => {
    'name': name.trim(),
    'description': description.trim(),
    'amount': amount,
    'currency': currency,
    'category': category,
    'frequency': frequency.name,
    'next_charge_date': _dateOnly(nextChargeDate),
    'billing_day': billingDay,
    'account_id': accountId,
    'account_label': accountLabel.trim(),
    'status': status.name,
    'reminder_days': reminderDays,
    'notes': notes.trim(),
  };

  static String dateOnly(DateTime date) => _dateOnly(date);

  static DateTime nextDate(
    DateTime scheduledDate,
    SubscriptionFrequency frequency, {
    int? billingDay,
  }) {
    switch (frequency) {
      case SubscriptionFrequency.weekly:
        return scheduledDate.add(const Duration(days: 7));
      case SubscriptionFrequency.biweekly:
        return scheduledDate.add(const Duration(days: 14));
      case SubscriptionFrequency.monthly:
        return _addMonths(scheduledDate, 1, billingDay ?? scheduledDate.day);
      case SubscriptionFrequency.bimonthly:
        return _addMonths(scheduledDate, 2, billingDay ?? scheduledDate.day);
      case SubscriptionFrequency.quarterly:
        return _addMonths(scheduledDate, 3, billingDay ?? scheduledDate.day);
      case SubscriptionFrequency.semiannual:
        return _addMonths(scheduledDate, 6, billingDay ?? scheduledDate.day);
      case SubscriptionFrequency.annual:
        return _addMonths(scheduledDate, 12, billingDay ?? scheduledDate.day);
    }
  }

  static DateTime nextFutureDate(
    DateTime scheduledDate,
    SubscriptionFrequency frequency, {
    required DateTime after,
    int? billingDay,
  }) {
    var next = nextDate(scheduledDate, frequency, billingDay: billingDay);
    while (!next.isAfter(DateTime(after.year, after.month, after.day))) {
      next = nextDate(next, frequency, billingDay: billingDay);
    }
    return next;
  }

  static DateTime _addMonths(DateTime date, int months, int billingDay) {
    final monthIndex = date.year * 12 + date.month - 1 + months;
    final year = monthIndex ~/ 12;
    final month = monthIndex % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, billingDay > lastDay ? lastDay : billingDay);
  }

  static String _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day).toIso8601String();
}
