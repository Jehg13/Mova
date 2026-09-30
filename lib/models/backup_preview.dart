class BackupPreview {
  const BackupPreview({
    required this.payload,
    required this.createdAt,
    required this.version,
    required this.expenses,
    required this.income,
    required this.goals,
    required this.accounts,
    required this.subscriptions,
  });

  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int version;
  final int expenses;
  final int income;
  final int goals;
  final int accounts;
  final int subscriptions;

  int get movements => expenses + income;
}
