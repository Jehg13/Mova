import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mova/database/database_helper.dart';
import 'package:mova/models/financial_account.dart';
import 'package:mova/models/scheduled_payment.dart';
import 'package:mova/models/subscription.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  test('register and login flow works with SQLite', () async {
    SharedPreferences.setMockInitialValues({});
    final dbPath = join(await getDatabasesPath(), 'mova.db');
    await deleteDatabase(dbPath);

    final db = DatabaseHelper();
    await db.database;
    final cashAccountId = await db.createFinancialAccount(
      FinancialAccount(
        id: 0,
        name: 'Efectivo',
        type: FinancialAccountType.cash,
        currency: 'MXN',
        initialBalance: 500,
        institution: '',
        lastFour: '',
        icon: 'payments',
        isActive: true,
        creditLimit: null,
        createdAt: DateTime(2026, 9, 30),
      ),
    );

    final insertedId = await db.insertUser('Ana', 'ana@test.com', '12345678');
    expect(insertedId, greaterThan(0));

    final validUser = await db.loginUser('ana@test.com', '12345678');
    expect(validUser, isNotNull);
    expect(validUser!['email'], 'ana@test.com');

    final invalidUser = await db.loginUser('ana@test.com', 'wrongpass');
    expect(invalidUser, isNull);

    final transactionId = await db.insertTransaction(
      amount: 150.50,
      isIncome: false,
      category: 'Comida',
      description: 'Comida de prueba',
      date: DateTime(2026, 8, 18),
      note: 'Nota de prueba',
      receiptItems: jsonEncode(['Cafe americano 45.00']),
      receiptReference: 'AB12345',
    );
    expect(transactionId, greaterThan(0));

    final transactions = await db.getTransactions();
    expect(transactions, hasLength(1));
    expect(transactions.first['amount'], 150.50);
    expect(transactions.first['is_income'], 0);
    expect(transactions.first['category'], 'Comida');
    expect(
      transactions.first['receipt_items'],
      jsonEncode(['Cafe americano 45.00']),
    );
    expect(transactions.first['receipt_reference'], 'AB12345');
    expect(
      await db.findPossibleDuplicateReceipts(
        amount: 150.50,
        date: DateTime(2026, 8, 18),
        merchant: 'Comida de prueba',
        reference: 'AB12345',
      ),
      hasLength(1),
    );

    final shoppingListId = await db.createShoppingList('Despensa');
    await db.addShoppingProduct(
      listId: shoppingListId,
      name: 'Arroz',
      unit: 'kg',
      quantity: 2,
      unitPrice: 3.25,
    );
    var shoppingProducts = await db.getShoppingProducts(shoppingListId);
    expect(shoppingProducts.single['subtotal'], 6.5);
    var shoppingList = await db.getShoppingList(shoppingListId);
    expect(shoppingList!['total'], 6.5);
    await db.finalizeShoppingList(shoppingListId);
    shoppingList = await db.getShoppingList(shoppingListId);
    expect(shoppingList!['status'], 'completed');
    expect(
      (await db.getTransactions()).any(
        (transaction) =>
            transaction['category'] == 'Compras' &&
            transaction['amount'] == 6.5,
      ),
      isTrue,
    );

    final goalId = await db.insertGoal(
      name: 'Viaje',
      targetAmount: 1000,
      savedAmount: 0,
      icon: 'none',
    );
    expect(goalId, greaterThan(0));

    var goals = await db.getGoals();
    expect(goals.single['saved_amount'], 0);
    expect(goals.single['icon'], 'none');

    await db.updateGoalSavedAmount(goalId, 60);
    await db.updateGoalSavedAmount(goalId, 25);

    final movements = await db.getGoalMovements(goalId);
    expect(movements, hasLength(2));
    expect(movements[0]['type'], 'withdrawal');
    expect(movements[0]['amount'], 35);
    expect(movements[1]['type'], 'deposit');
    expect(movements[1]['amount'], 60);

    var summary = await db.getTransactionSummary();
    expect(summary['savings'], 25);

    await db.deleteGoal(goalId);
    goals = await db.getGoals();
    expect(goals, isEmpty);
    summary = await db.getTransactionSummary();
    expect(summary['savings'], 0);

    final allTransactions = await db.getTransactions();
    expect(
      allTransactions.any(
        (transaction) =>
            transaction['category'] == 'Devolución de meta' &&
            transaction['amount'] == 25 &&
            transaction['is_income'] == 1,
      ),
      isTrue,
    );

    final rememberedUser = await db.loginUser(
      'ana@test.com',
      '12345678',
      rememberMe: true,
    );
    expect(rememberedUser, isNotNull);
    expect(await db.hasRememberedSession(), isTrue);

    await db.logout();
    expect(await db.hasRememberedSession(), isFalse);

    final subscriptionId = await db.createSubscription(
      Subscription(
        id: 0,
        name: 'Netflix',
        description: '',
        amount: 219,
        currency: 'MXN',
        category: 'Entretenimiento',
        frequency: SubscriptionFrequency.monthly,
        nextChargeDate: DateTime(2026, 10, 15),
        billingDay: 15,
        accountId: cashAccountId,
        accountLabel: 'Visa •••• 4582',
        status: SubscriptionStatus.active,
        reminderDays: 1,
        createdAt: DateTime(2026, 9, 30),
        notes: '',
      ),
    );
    final subscription = await db.getSubscription(subscriptionId);
    expect(subscription?.name, 'Netflix');
    expect(await db.getSubscriptionMonthlySpend(currency: 'MXN'), 219);
    expect(await db.getSubscriptionAnnualSpend(currency: 'MXN'), 2628);

    final manuallyRecordedId = await db.insertTransaction(
      amount: 219,
      isIncome: false,
      category: 'Entretenimiento',
      description: 'Pago Netflix tarjeta',
      date: DateTime(2026, 10, 15),
      accountId: cashAccountId,
      currency: 'MXN',
    );
    expect(
      await db.findPotentialDuplicateSubscriptionExpense(subscriptionId),
      manuallyRecordedId,
    );
    await db.recordSubscriptionPayment(
      subscriptionId,
      expectedChargeDate: DateTime(2026, 10, 15),
      existingTransactionId: manuallyRecordedId,
      paidAt: DateTime(2026, 10, 15),
    );
    final paidTransaction = (await db.getTransactions()).singleWhere(
      (transaction) => transaction['id'] == manuallyRecordedId,
    );
    expect(paidTransaction['subscription_id'], subscriptionId);
    expect((await db.getSubscriptionHistory(subscriptionId)), hasLength(1));
    expect(
      (await db.getSubscription(subscriptionId))?.nextChargeDate,
      DateTime(2026, 11, 15),
    );
    expect((await db.getFinancialAccount(cashAccountId))?.balance, 281);
    await expectLater(
      db.recordSubscriptionPayment(
        subscriptionId,
        expectedChargeDate: DateTime(2026, 10, 15),
      ),
      throwsA(isA<StateError>()),
    );
    expect(await db.getSubscriptionHistory(subscriptionId), hasLength(1));

    final bankAccountId = await db.createFinancialAccount(
      FinancialAccount(
        id: 0,
        name: 'Banco',
        type: FinancialAccountType.bank,
        currency: 'MXN',
        initialBalance: 0,
        institution: 'BBVA',
        lastFour: '',
        icon: 'account_balance',
        isActive: true,
        creditLimit: null,
        createdAt: DateTime(2026, 9, 30),
      ),
    );
    await db.transferBetweenAccounts(
      fromAccountId: cashAccountId,
      toAccountId: bankAccountId,
      amount: 20,
      date: DateTime(2026, 10, 15),
    );
    expect((await db.getFinancialAccount(cashAccountId))?.balance, 261);
    expect((await db.getFinancialAccount(bankAccountId))?.balance, 20);

    await db.insertTransaction(
      amount: 25,
      isIncome: false,
      category: 'Ahorro sin meta',
      description: 'Asignación a ahorro',
      date: DateTime(2026, 10, 15),
      accountId: cashAccountId,
      currency: 'MXN',
    );
    expect((await db.getFinancialAccount(cashAccountId))?.balance, 261);
    final accountOverview = await db.getFinancialOverview(homeCurrency: 'MXN');
    expect(accountOverview['available']?['MXN'], 256);

    final creditAccountId = await db.createFinancialAccount(
      FinancialAccount(
        id: 0,
        name: 'Tarjeta',
        type: FinancialAccountType.creditCard,
        currency: 'MXN',
        initialBalance: 100,
        institution: 'Visa',
        lastFour: '4582',
        icon: 'credit_card',
        isActive: true,
        creditLimit: 500,
        createdAt: DateTime(2026, 9, 30),
      ),
    );
    await db.insertTransaction(
      amount: 50,
      isIncome: false,
      category: 'Compras',
      description: 'Compra con tarjeta',
      date: DateTime(2026, 10, 15),
      accountId: creditAccountId,
      currency: 'MXN',
    );
    expect((await db.getFinancialAccount(creditAccountId))?.balance, 150);
    await expectLater(
      db.insertTransaction(
        amount: 10,
        isIncome: true,
        category: 'Reembolso',
        description: 'Ingreso a tarjeta',
        date: DateTime(2026, 10, 15),
        accountId: creditAccountId,
        currency: 'MXN',
      ),
      throwsA(isA<StateError>()),
    );

    final oneTimeId = await db.createScheduledPayment(
      ScheduledPayment(
        id: 0,
        name: 'Reparación del auto',
        amount: 30,
        currency: 'MXN',
        type: ScheduledPaymentType.oneTime,
        dueDate: DateTime(2026, 10, 5),
        reminderDays: 3,
        status: ScheduledPaymentStatus.active,
        createdAt: DateTime(2026, 9, 30),
        category: 'Transporte',
        accountId: cashAccountId,
      ),
    );
    await db.recordScheduledPayment(
      id: oneTimeId,
      expectedDueDate: DateTime(2026, 10, 5),
      paidAt: DateTime(2026, 10, 5),
    );
    expect(
      (await db.getScheduledPayment(oneTimeId))?.status,
      ScheduledPaymentStatus.completed,
    );
    expect((await db.getFinancialAccount(cashAccountId))?.balance, 231);
    await expectLater(
      db.recordScheduledPayment(
        id: oneTimeId,
        expectedDueDate: DateTime(2026, 10, 5),
      ),
      throwsA(isA<StateError>()),
    );

    final recurringId = await db.createScheduledPayment(
      ScheduledPayment(
        id: 0,
        name: 'Internet',
        amount: 25,
        currency: 'MXN',
        type: ScheduledPaymentType.recurring,
        dueDate: DateTime(2026, 10, 15),
        reminderDays: 1,
        status: ScheduledPaymentStatus.active,
        createdAt: DateTime(2026, 9, 30),
        category: 'Servicios',
        frequency: SubscriptionFrequency.monthly,
        accountId: cashAccountId,
      ),
    );
    await db.recordScheduledPayment(
      id: recurringId,
      expectedDueDate: DateTime(2026, 10, 15),
      paidAt: DateTime(2026, 10, 15),
    );
    expect(
      (await db.getScheduledPayment(recurringId))?.dueDate,
      DateTime(2026, 11, 15),
    );
    await expectLater(
      db.recordScheduledPayment(
        id: recurringId,
        expectedDueDate: DateTime(2026, 10, 15),
      ),
      throwsA(isA<StateError>()),
    );

    final manualScheduledExpense = await db.insertTransaction(
      amount: 55,
      isIncome: false,
      category: 'Servicios',
      description: 'Pago de servicio registrado manualmente',
      date: DateTime(2026, 10, 20),
      currency: 'MXN',
    );
    final duplicatePaymentId = await db.createScheduledPayment(
      ScheduledPayment(
        id: 0,
        name: 'Servicio ya pagado',
        amount: 55,
        currency: 'MXN',
        type: ScheduledPaymentType.oneTime,
        dueDate: DateTime(2026, 10, 20),
        reminderDays: 0,
        status: ScheduledPaymentStatus.active,
        createdAt: DateTime(2026, 9, 30),
        category: 'Servicios',
      ),
    );
    expect(
      await db.findPotentialDuplicateScheduledPaymentExpense(
        duplicatePaymentId,
      ),
      manualScheduledExpense,
    );
    final countBeforeLink = (await db.getTransactions()).length;
    await db.recordScheduledPayment(
      id: duplicatePaymentId,
      expectedDueDate: DateTime(2026, 10, 20),
      existingTransactionId: manualScheduledExpense,
      paidAt: DateTime(2026, 10, 20),
    );
    expect((await db.getTransactions()).length, countBeforeLink);

    final cardPaymentId = await db.createScheduledPayment(
      ScheduledPayment(
        id: 0,
        name: 'Pago Visa',
        amount: 50,
        currency: 'MXN',
        type: ScheduledPaymentType.cardPayment,
        dueDate: DateTime(2026, 10, 10),
        reminderDays: 1,
        status: ScheduledPaymentStatus.active,
        createdAt: DateTime(2026, 9, 30),
        accountId: cashAccountId,
        targetAccountId: creditAccountId,
      ),
    );
    final countBeforeCardPayment = (await db.getTransactions()).length;
    await db.recordScheduledPayment(
      id: cardPaymentId,
      expectedDueDate: DateTime(2026, 10, 10),
      paidAt: DateTime(2026, 10, 10),
    );
    expect((await db.getTransactions()).length, countBeforeCardPayment);
    expect((await db.getFinancialAccount(cashAccountId))?.balance, 156);
    expect((await db.getFinancialAccount(creditAccountId))?.balance, 100);

    await db.setSubscriptionStatus(subscriptionId, SubscriptionStatus.paused);
    expect(await db.getUpcomingSubscriptions(), isEmpty);
    expect(
      (await db.getSubscription(subscriptionId))?.status,
      SubscriptionStatus.paused,
    );
    await db.setSubscriptionStatus(subscriptionId, SubscriptionStatus.active);
    await db.setSubscriptionStatus(
      subscriptionId,
      SubscriptionStatus.cancelled,
    );
    expect(await db.getUpcomingSubscriptions(), isEmpty);
    expect(await db.getSubscriptionHistory(subscriptionId), hasLength(1));

    await db.addCustomCategory(name: 'Salud', type: 'expense', emoji: '🩺');
    await db.setCurrency('MXN');
    await db.setLanguage('es');
    await db.setUserSetting('backup_auto_enabled', 'true');
    final backupGoalId = await db.insertGoal(
      name: 'Fondo de emergencia',
      targetAmount: 5000,
      savedAmount: 0,
      icon: 'shield',
    );
    await db.updateGoalSavedAmount(backupGoalId, 300);

    final backup = await db.exportData();
    final backupData = backup['data'] as Map<String, dynamic>;
    expect(jsonEncode(backup), isNot(contains('12345678')));
    final importedMovementCount = await db.importBackup(backup);
    expect(importedMovementCount, (backupData['transactions'] as List).length);
    expect(
      (await db.getTransactions()).any(
        (transaction) =>
            transaction['receipt_reference'] == 'AB12345' &&
            transaction['receipt_items'] ==
                jsonEncode(['Cafe americano 45.00']),
      ),
      isTrue,
    );
    final importedSubscription = (await db.getSubscriptions()).singleWhere(
      (item) => item.id != subscriptionId && item.name == 'Netflix',
    );
    final importedAccount = await db.getFinancialAccount(
      importedSubscription.accountId!,
    );
    expect(importedAccount?.name, 'Efectivo');
    final importedHistory = await db.getSubscriptionHistory(
      importedSubscription.id,
    );
    expect(importedHistory, hasLength(1));
    expect(await db.getScheduledPaymentHistory(), hasLength(8));
    final importedPaymentTransaction = (await db.getTransactions()).singleWhere(
      (transaction) =>
          transaction['id'] == importedHistory.single['transaction_id'],
    );
    expect(
      importedPaymentTransaction['subscription_id'],
      importedSubscription.id,
    );
    final transactionCountBeforeReceiptAttachment =
        (await db.getTransactions()).length;
    await db.attachReceiptToTransaction(
      transactionId: transactionId,
      amount: 150.50,
      date: DateTime(2026, 8, 18),
      imagePath: 'receipt-test-path.jpg',
      items: jsonEncode(['Cafe americano 45.00']),
      reference: 'AB12345',
    );
    expect(
      (await db.getTransactions()).length,
      transactionCountBeforeReceiptAttachment,
    );

    await db.deleteSubscription(subscriptionId);
    expect(await db.getSubscription(subscriptionId), isNull);
    expect(await db.getSubscriptionHistory(subscriptionId), isEmpty);
    expect(
      (await db.getTransactions()).singleWhere(
        (transaction) => transaction['id'] == manuallyRecordedId,
      )['subscription_id'],
      isNull,
    );

    expect(
      Subscription.nextDate(
        DateTime(2026, 1, 31),
        SubscriptionFrequency.monthly,
        billingDay: 31,
      ),
      DateTime(2026, 2, 28),
    );
    expect(
      Subscription.nextDate(
        DateTime(2026, 2, 28),
        SubscriptionFrequency.monthly,
        billingDay: 31,
      ),
      DateTime(2026, 3, 31),
    );
    final backupMovementCount = (backupData['transactions'] as List).length;
    final replacedCount = await db.importBackup(backup, replaceExisting: true);
    expect(replacedCount, (backupData['transactions'] as List).length);
    expect((await db.getTransactions()).length, backupMovementCount);
    expect(
      (await db.getFinancialAccounts()).map((account) => account.name),
      contains('Efectivo'),
    );
    expect(
      (await db.getCustomCategories()).any(
        (category) => category['name'] == 'Salud',
      ),
      isTrue,
    );
    expect(await db.getUserSetting('backup_auto_enabled'), 'true');
    expect(
      (await db.getGoals()).map((goal) => goal['name']),
      contains('Fondo de emergencia'),
    );
  });
}
