import 'package:mova/database/database_helper.dart';
import 'package:mova/models/financial_account.dart';
import 'package:mova/models/scheduled_payment.dart';
import 'package:mova/models/subscription.dart';
import 'package:mova/models/transaction_category_catalog.dart';

class NivoRepository {
  NivoRepository({DatabaseHelper? databaseHelper})
    : _database = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _database;

  DatabaseHelper get databaseHelper => _database;

  Future<Map<String, double>> getAvailableBalance({
    String? homeCurrency,
  }) async {
    final currency = homeCurrency ?? await _database.getCurrency();
    final overview = await _database.getFinancialOverview(
      homeCurrency: currency,
      includeUnassignedTransactions: true,
    );
    return overview['available']!;
  }

  Future<Map<String, double>> getExpensesByPeriod({
    required DateTime from,
    required DateTime to,
  }) async {
    final transactions = await _database.getTransactionsInPeriod(
      from: from,
      to: to,
    );
    final defaultCurrency = await _database.getCurrency();
    final totals = <String, double>{};
    for (final transaction in transactions) {
      if (transaction['is_income'] != 0 ||
          DatabaseHelper.isSavingsDeposit(transaction)) {
        continue;
      }
      _addAmount(
        totals,
        _currencyOf(transaction, defaultCurrency),
        (transaction['amount'] as num).toDouble(),
      );
    }
    return totals;
  }

  Future<Map<String, Map<String, double>>> getExpensesByCategory({
    required DateTime from,
    required DateTime to,
  }) async {
    final transactions = await _database.getTransactionsInPeriod(
      from: from,
      to: to,
    );
    final defaultCurrency = await _database.getCurrency();
    final totals = <String, Map<String, double>>{};
    for (final transaction in transactions) {
      if (transaction['is_income'] != 0 ||
          DatabaseHelper.isSavingsDeposit(transaction)) {
        continue;
      }
      final category = transaction['category'] as String;
      _addAmount(
        totals.putIfAbsent(category, () => <String, double>{}),
        _currencyOf(transaction, defaultCurrency),
        (transaction['amount'] as num).toDouble(),
      );
    }
    return totals;
  }

  Future<Map<String, double>> getIncomeByPeriod({
    required DateTime from,
    required DateTime to,
  }) async {
    final transactions = await _database.getTransactionsInPeriod(
      from: from,
      to: to,
    );
    final defaultCurrency = await _database.getCurrency();
    final totals = <String, double>{};
    for (final transaction in transactions) {
      if (transaction['is_income'] != 1 ||
          DatabaseHelper.isSavingsWithdrawal(transaction)) {
        continue;
      }
      _addAmount(
        totals,
        _currencyOf(transaction, defaultCurrency),
        (transaction['amount'] as num).toDouble(),
      );
    }
    return totals;
  }

  Future<Map<String, double>> getExpensesByMerchant({
    required String merchant,
    required DateTime from,
    required DateTime to,
  }) async {
    if (merchant.trim().isEmpty) {
      throw ArgumentError.value(merchant, 'merchant', 'Must not be empty.');
    }
    final transactions = await _database.getTransactionsInPeriod(
      from: from,
      to: to,
    );
    final defaultCurrency = await _database.getCurrency();
    final needle = merchant.toLowerCase();
    final totals = <String, double>{};
    for (final transaction in transactions) {
      final description = (transaction['description'] as String).toLowerCase();
      if (transaction['is_income'] != 0 ||
          DatabaseHelper.isSavingsDeposit(transaction) ||
          !description.contains(needle)) {
        continue;
      }
      _addAmount(
        totals,
        _currencyOf(transaction, defaultCurrency),
        (transaction['amount'] as num).toDouble(),
      );
    }
    return totals;
  }

  Future<List<Map<String, Object?>>> getRecentMovements({int limit = 20}) =>
      _database.getRecentFinancialMovements(limit: limit);

  Future<List<FinancialAccount>> getAccounts({bool includeInactive = true}) =>
      _database.getFinancialAccounts(includeInactive: includeInactive);

  Future<String> getCurrency() => _database.getCurrency();

  Future<List<Map<String, dynamic>>> getGoals() => _database.getGoals();

  Future<Map<String, Object>> getSavingsOverview() async {
    final results = await Future.wait<Object>([
      _database.getUnassignedSavings(),
      _database.getGoals(),
      _database.getCurrency(),
    ]);
    final generalSavings = results[0] as double;
    final goals = results[1] as List<Map<String, dynamic>>;
    final goalSavings = goals.fold<double>(
      0,
      (total, goal) => total + (goal['saved_amount'] as num).toDouble(),
    );
    return {
      'currency': results[2] as String,
      'unassigned': generalSavings,
      'goals': goalSavings,
      'total': generalSavings + goalSavings,
    };
  }

  Future<List<Subscription>> getActiveSubscriptions() =>
      _database.getSubscriptions(status: SubscriptionStatus.active);

  Future<List<UpcomingPayment>> getUpcomingPayments({
    DateTime? from,
    int days = 30,
  }) async {
    if (days < 0) {
      throw ArgumentError.value(days, 'days', 'Must not be negative.');
    }
    final start = _dayStart(from ?? DateTime.now());
    final end = start.add(Duration(days: days));
    final results = await Future.wait<Object>([
      _database.getUpcomingSubscriptions(from: start, days: days),
      _database.getScheduledPayments(),
      _database.getFinancialAccounts(),
    ]);
    final subscriptions = results[0] as List<Subscription>;
    final scheduledPayments = results[1] as List<ScheduledPayment>;
    final accounts = results[2] as List<FinancialAccount>;
    final accountById = {for (final account in accounts) account.id: account};
    final payments = <UpcomingPayment>[
      for (final subscription in subscriptions)
        UpcomingPayment.fromSubscription(subscription),
      for (final payment in scheduledPayments)
        if (!_dayStart(payment.dueDate).isBefore(start) &&
            _dayStart(payment.dueDate).isBefore(end))
          UpcomingPayment.fromScheduled(
            payment,
            accountLabel: _accountLabel(payment, accountById),
          ),
    ];
    payments.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return payments;
  }

  Future<({double? amount, String period})> getBudget() async {
    final results = await Future.wait<Object?>([
      _database.getMonthlyBudget(),
      _database.getBudgetPeriod(),
    ]);
    return (amount: results[0] as double?, period: results[1] as String);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final results = await Future.wait<Object>([
      _database.getCustomCategories(),
      _database.getTransactionCategories(),
    ]);
    final categories = <String, Map<String, dynamic>>{};
    for (final category in TransactionCategoryCatalog.income) {
      categories['income:${category['name']}'] = {
        ...category,
        'type': 'income',
      };
    }
    for (final category in TransactionCategoryCatalog.expense) {
      categories['expense:${category['name']}'] = {
        ...category,
        'type': 'expense',
      };
    }
    for (final category in results[0] as List<Map<String, dynamic>>) {
      final name = category['name'] as String;
      final type = category['type'] as String;
      categories['$type:$name'] = category;
    }
    for (final transaction in results[1] as List<Map<String, Object?>>) {
      final name = transaction['name'] as String;
      final type = transaction['type'] as String;
      categories.putIfAbsent(
        '$type:$name',
        () => {'name': name, 'type': type, 'emoji': '📦'},
      );
    }
    final result = categories.values.toList()
      ..sort((a, b) {
        final typeOrder = (a['type'] as String).compareTo(b['type'] as String);
        return typeOrder != 0
            ? typeOrder
            : (a['name'] as String).compareTo(b['name'] as String);
      });
    return result;
  }

  static DateTime _dayStart(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String _currencyOf(
    Map<String, dynamic> transaction,
    String defaultCurrency,
  ) {
    final currency = transaction['currency'] as String?;
    return currency == null || currency.isEmpty ? defaultCurrency : currency;
  }

  static void _addAmount(
    Map<String, double> totals,
    String currency,
    double amount,
  ) {
    totals.update(currency, (total) => total + amount, ifAbsent: () => amount);
  }

  static String _accountLabel(
    ScheduledPayment payment,
    Map<int, FinancialAccount> accounts,
  ) {
    final id = payment.type == ScheduledPaymentType.cardPayment
        ? payment.targetAccountId
        : payment.accountId;
    final account = id == null ? null : accounts[id];
    if (account == null) return '';
    return account.lastFour.isEmpty
        ? account.name
        : '${account.name} •••• ${account.lastFour}';
  }
}
