import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mova/database/database_helper.dart';
import 'package:mova/models/financial_account.dart';
import 'package:mova/models/scheduled_payment.dart';
import 'package:mova/models/subscription.dart';
import 'package:mova/services/nivo_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  test('reads existing MOVA financial data without changing it', () async {
    const databaseName = 'nivo_repository_test.db';
    final dbPath = join(await getDatabasesPath(), databaseName);
    await deleteDatabase(dbPath);

    final database = DatabaseHelper(databaseName: databaseName);
    final repository = NivoRepository(databaseHelper: database);
    final today = DateTime(2026, 9, 30);
    final cashId = await database.createFinancialAccount(
      FinancialAccount(
        id: 0,
        name: 'Efectivo',
        type: FinancialAccountType.cash,
        currency: 'MXN',
        initialBalance: 2000,
        institution: '',
        lastFour: '',
        icon: 'payments',
        isActive: true,
        creditLimit: null,
        createdAt: today,
      ),
    );
    final bankId = await database.createFinancialAccount(
      FinancialAccount(
        id: 0,
        name: 'Banco',
        type: FinancialAccountType.bank,
        currency: 'MXN',
        initialBalance: 0,
        institution: '',
        lastFour: '',
        icon: 'account_balance',
        isActive: true,
        creditLimit: null,
        createdAt: today,
      ),
    );
    await database.insertTransaction(
      amount: 100,
      isIncome: false,
      category: 'Comida',
      description: 'Comida',
      date: today,
      currency: 'MXN',
    );
    await database.insertTransaction(
      amount: 800,
      isIncome: true,
      category: 'Sueldo',
      description: 'Sueldo',
      date: today,
      currency: 'MXN',
    );
    await database.addUnassignedSavings(50);
    await database.withdrawUnassignedSavings(10);
    final goalId = await database.insertGoal(
      name: 'Viaje',
      targetAmount: 500,
      savedAmount: 120,
      icon: 'flight',
    );
    await database.addCustomCategory(
      name: 'Mascotas',
      type: 'expense',
      emoji: '🐾',
    );
    await database.setMonthlyBudget(1000);
    await database.setBudgetPeriod('weekly');
    await database.createSubscription(
      Subscription(
        id: 0,
        name: 'Música',
        description: '',
        amount: 129,
        currency: 'MXN',
        category: 'Entretenimiento',
        frequency: SubscriptionFrequency.monthly,
        nextChargeDate: DateTime(2026, 10, 5),
        billingDay: 5,
        accountId: cashId,
        accountLabel: 'Efectivo',
        status: SubscriptionStatus.active,
        reminderDays: 1,
        createdAt: today,
        notes: '',
      ),
    );
    await database.createScheduledPayment(
      ScheduledPayment(
        id: 0,
        name: 'Internet',
        amount: 499,
        currency: 'MXN',
        type: ScheduledPaymentType.oneTime,
        dueDate: DateTime(2026, 10, 10),
        reminderDays: 1,
        status: ScheduledPaymentStatus.active,
        createdAt: today,
        category: 'Servicios',
        accountId: cashId,
      ),
    );
    await database.transferBetweenAccounts(
      fromAccountId: cashId,
      toAccountId: bankId,
      amount: 25,
      date: today.add(const Duration(days: 1)),
    );

    final periodStart = DateTime(2026, 9, 1);
    final periodEnd = DateTime(2026, 10, 1);
    expect(
      await repository.getExpensesByPeriod(from: periodStart, to: periodEnd),
      {'MXN': 100},
    );
    expect(
      await repository.getIncomeByPeriod(from: periodStart, to: periodEnd),
      {'MXN': 800},
    );
    expect(
      await repository.getExpensesByCategory(from: periodStart, to: periodEnd),
      {
        'Comida': {'MXN': 100},
      },
    );
    expect(await repository.getAvailableBalance(), {'MXN': 1840});

    final recentMovements = await repository.getRecentMovements(limit: 2);
    expect(recentMovements, hasLength(2));
    expect(recentMovements.first['movement_type'], 'account_transfer');

    final accounts = await repository.getAccounts();
    expect(accounts, hasLength(2));
    final goals = await repository.getGoals();
    expect(goals.single['id'], goalId);
    expect(goals.single['saved_amount'], 120);
    expect(await repository.getSavingsOverview(), {
      'currency': 'MXN',
      'unassigned': 40,
      'goals': 120,
      'total': 160,
    });
    expect((await repository.getActiveSubscriptions()).single.name, 'Música');

    final upcoming = await repository.getUpcomingPayments(
      from: today,
      days: 30,
    );
    expect(upcoming.map((payment) => payment.name), ['Música', 'Internet']);
    expect(upcoming.first.source, PaymentSource.subscription);
    expect(upcoming.last.accountLabel, 'Efectivo');

    final budget = await repository.getBudget();
    expect(budget.amount, 1000);
    expect(budget.period, 'weekly');
    final categories = await repository.getCategories();
    expect(
      categories.any(
        (category) =>
            category['name'] == 'Mascotas' && category['type'] == 'expense',
      ),
      isTrue,
    );
    expect(
      categories.any(
        (category) =>
            category['name'] == 'Transporte' && category['type'] == 'expense',
      ),
      isTrue,
    );

    final transactionCount = (await database.getTransactions()).length;
    await repository.getExpensesByPeriod(from: periodStart, to: periodEnd);
    expect((await database.getTransactions()).length, transactionCount);
    await (await database.database).close();
    await deleteDatabase(dbPath);
  });
}
