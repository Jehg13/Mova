enum FinancialAccountType { cash, bank, debitCard, creditCard, savings }

class FinancialAccount {
  const FinancialAccount({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.initialBalance,
    required this.institution,
    required this.lastFour,
    required this.icon,
    required this.isActive,
    required this.creditLimit,
    required this.createdAt,
    this.balance = 0,
  });

  final int id;
  final String name;
  final FinancialAccountType type;
  final String currency;
  final double initialBalance;
  final String institution;
  final String lastFour;
  final String icon;
  final bool isActive;
  final double? creditLimit;
  final DateTime createdAt;
  final double balance;

  double get availableCredit => type == FinancialAccountType.creditCard
      ? ((creditLimit ?? 0) - balance).clamp(0, creditLimit ?? 0)
      : 0;

  factory FinancialAccount.fromMap(Map<String, Object?> row) =>
      FinancialAccount(
        id: row['id'] as int,
        name: row['name'] as String,
        type: FinancialAccountType.values.byName(row['type'] as String),
        currency: row['currency'] as String,
        initialBalance: (row['initial_balance'] as num).toDouble(),
        institution: row['institution'] as String? ?? '',
        lastFour: row['last_four'] as String? ?? '',
        icon: row['icon'] as String? ?? 'account_balance_wallet',
        isActive: row['is_active'] == 1,
        creditLimit: (row['credit_limit'] as num?)?.toDouble(),
        createdAt: DateTime.parse(row['created_at'] as String),
        balance:
            (row['balance'] as num?)?.toDouble() ??
            (row['initial_balance'] as num).toDouble(),
      );

  Map<String, Object?> toDatabaseMap() => {
    'name': name.trim(),
    'type': type.name,
    'currency': currency,
    'initial_balance': initialBalance,
    'institution': institution.trim(),
    'last_four': lastFour.trim(),
    'icon': icon,
    'is_active': isActive ? 1 : 0,
    'credit_limit': creditLimit,
  };
}
