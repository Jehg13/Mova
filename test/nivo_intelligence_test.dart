import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mova/database/database_helper.dart';
import 'package:mova/models/financial_account.dart';
import 'package:mova/models/nivo_query.dart';
import 'package:mova/models/scheduled_payment.dart';
import 'package:mova/models/subscription.dart';
import 'package:mova/services/nivo_engine.dart';
import 'package:mova/services/nivo_parser.dart';
import 'package:mova/services/nivo_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  group('NivoParser', () {
    final parser = NivoParser();

    test('recognizes common finance questions and extracts entities', () {
      final expenses = parser.parse('¿Cuánto gasté este mes?');
      expect(expenses.intent, NivoIntent.consultarGastos);
      expect(expenses.entities.period, NivoPeriod.thisMonth);
      expect(expenses.confidence, NivoConfidence.high);

      final category = parser.parse('¿Cuánto gasté en comida?');
      expect(category.intent, NivoIntent.consultarCategoria);
      expect(category.entities.category, 'Comida');

      expect(
        parser.parse('¿Cuánto dinero tengo?').intent,
        NivoIntent.consultarBalance,
      );
      expect(
        parser.parse('¿Cuánto llevo ahorrado?').intent,
        NivoIntent.consultarAhorro,
      );

      final payments = parser.parse('¿Qué pagos tengo esta semana?');
      expect(payments.intent, NivoIntent.consultarPagosProximos);
      expect(payments.entities.period, NivoPeriod.thisWeek);
      expect(
        parser.parse('¿Qué pagos hay la próxima semana?').entities.period,
        NivoPeriod.nextSevenDays,
      );
      final soon = parser.parse('¿Qué pagos tengo próximamente?');
      expect(soon.intent, NivoIntent.consultarPagosProximos);
      expect(soon.entities.period, NivoPeriod.nextThirtyDays);

      final comparison = parser.parse(
        '¿Cuánto gasté este mes comparado con el anterior?',
      );
      expect(comparison.entities.comparePeriods, isTrue);

      final goal = parser.parse(
        '¿Cuánto llevo ahorrado para mi coche?',
        goals: ['Coche'],
      );
      expect(goal.intent, NivoIntent.consultarMeta);
      expect(goal.entities.goal, 'Coche');
    });

    test('extracts amount, date, account and frequency', () {
      final result = parser.parse(
        'Pagué \$1,250 en supermercado el 12/10/2026 desde Visa mensual',
        accounts: ['Visa'],
      );
      expect(result.entities.amount, 1250);
      expect(result.entities.date, DateTime(2026, 10, 12));
      expect(result.entities.account, 'Visa');
      expect(result.entities.frequency, 'monthly');
      expect(result.entities.merchant, 'supermercado');

      expect(parser.parse('Gasté 1.250,50').entities.amount, 1250.5);
      final dateOnly = parser.parse('¿Cuánto gasté el 12/10/2026?');
      expect(dateOnly.entities.date, DateTime(2026, 10, 12));
      expect(dateOnly.entities.amount, isNull);
    });

    test('asks for clarification when the question is ambiguous', () {
      final result = parser.parse('¿Cuánto?');
      expect(result.confidence, NivoConfidence.low);
      expect(result.requiresClarification, isTrue);
      expect(result.clarification, contains('¿Quieres consultar'));

      final missingGoal = parser.parse('¿Cómo va mi meta?');
      expect(missingGoal.intent, NivoIntent.consultarMeta);
      expect(missingGoal.clarification, contains('¿De cuál'));

      final invalidDate = parser.parse('¿Cuánto gasté el 31/02/2026?');
      expect(invalidDate.requiresClarification, isTrue);
      expect(
        invalidDate.clarification,
        contains('No pude interpretar esa fecha'),
      );
    });
  });

  test('NivoEngine answers only from local SQLite data', () async {
    const databaseName = 'nivo_intelligence_test.db';
    final databasePath = join(await getDatabasesPath(), databaseName);
    await deleteDatabase(databasePath);
    final database = DatabaseHelper(databaseName: databaseName);
    final repository = NivoRepository(databaseHelper: database);
    final today = DateTime(2026, 9, 30);
    final engine = NivoEngine(repository: repository, clock: () => today);

    final cashId = await database.createFinancialAccount(
      FinancialAccount(
        id: 0,
        name: 'Efectivo',
        type: FinancialAccountType.cash,
        currency: 'MXN',
        initialBalance: 10000,
        institution: '',
        lastFour: '',
        icon: 'payments',
        isActive: true,
        creditLimit: null,
        createdAt: today,
      ),
    );
    await database.createFinancialAccount(
      FinancialAccount(
        id: 0,
        name: 'Banco USD',
        type: FinancialAccountType.bank,
        currency: 'USD',
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
      amount: 3420,
      isIncome: false,
      category: 'Comida',
      description: 'Despensa',
      date: DateTime(2026, 9, 10),
      accountId: cashId,
      currency: 'MXN',
    );
    await database.insertTransaction(
      amount: 8000,
      isIncome: true,
      category: 'Sueldo',
      description: 'Nómina',
      date: DateTime(2026, 9, 1),
      accountId: cashId,
      currency: 'MXN',
    );
    await database.addUnassignedSavings(500);
    await database.insertGoal(
      name: 'Coche',
      targetAmount: 10000,
      savedAmount: 4200,
      icon: 'car',
    );
    await database.createScheduledPayment(
      ScheduledPayment(
        id: 0,
        name: 'Internet',
        amount: 499,
        currency: 'MXN',
        type: ScheduledPaymentType.oneTime,
        dueDate: DateTime(2026, 10, 2),
        reminderDays: 1,
        status: ScheduledPaymentStatus.active,
        createdAt: today,
        category: 'Servicios',
        accountId: cashId,
      ),
    );
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
    await database.setMonthlyBudget(5000);

    final monthExpenses = await engine.ask('¿Cuánto gasté este mes?');
    expect(monthExpenses.text, contains('\$3,420'));
    expect(monthExpenses.data['totals'], {'MXN': 3420});

    final food = await engine.ask('¿Cuánto gasté en comida?');
    expect(food.text, contains('en Comida'));
    expect(food.text, contains('\$3,420'));

    final merchant = await engine.ask('¿Cuánto gasté en Despensa?');
    expect(merchant.text, contains('en despensa'));
    expect(merchant.data['merchant'], 'despensa');

    final balance = await engine.ask('¿Cuánto dinero tengo?');
    expect(balance.text, contains('Tu saldo disponible'));
    expect(balance.text, contains('\$9,880'));

    final savings = await engine.ask('¿Cuánto llevo ahorrado?');
    expect(savings.text, contains('\$4,700'));

    final payments = await engine.ask('¿Qué pagos tengo esta semana?');
    expect(payments.intent, NivoIntent.consultarPagosProximos);
    expect(payments.text, contains('Internet'));

    final goal = await engine.ask('¿Cuánto llevo ahorrado para mi coche?');
    expect(goal.text, contains('\$4,200 de \$10,000'));
    expect(goal.data['progress_percent'], 42);

    await database.setCurrency('EUR');
    final goalStatus = await engine.ask('¿Cómo va mi meta de coche?');
    expect(goalStatus.text, contains('€4,200 de €10,000 para tu meta Coche'));
    expect(goalStatus.data['progress_percent'], 42);

    await database.setCurrency('MXN');
    final budget = await engine.ask('¿Cómo va mi presupuesto?');
    expect(budget.text, contains('\$3,420 de tu presupuesto de \$5,000'));
    expect(budget.data['used_percent'], 68.4);

    await database.insertTransaction(
      amount: 1000,
      isIncome: false,
      category: 'Comida',
      description: 'Gasto del mes anterior',
      date: DateTime(2026, 8, 15),
      accountId: cashId,
      currency: 'MXN',
    );
    final comparison = await engine.ask(
      '¿Cuánto gasté este mes comparado con el anterior?',
    );
    expect(comparison.data['totals'], {'MXN': 3420});
    expect(comparison.data['previous_totals'], {'MXN': 1000});
    expect(comparison.data['difference'], {'MXN': 2420});

    final upcoming = await engine.ask('¿Qué pagos tengo próximamente?');
    expect(upcoming.intent, NivoIntent.consultarPagosProximos);
    expect(upcoming.text, contains('Internet'));
    expect(upcoming.text, contains('Música'));

    final unclear = await engine.ask('¿Cuánto?');
    expect(unclear.requiresClarification, isTrue);
    expect(unclear.confidence, NivoConfidence.low);

    final transactionCount = (await database.getTransactions()).length;
    await engine.ask('¿Cuánto gasté en comida?');
    expect((await database.getTransactions()).length, transactionCount);
    await (await database.database).close();
    await deleteDatabase(databasePath);
  });
}
