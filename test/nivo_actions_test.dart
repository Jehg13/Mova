import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mova/database/database_helper.dart';
import 'package:mova/models/financial_account.dart';
import 'package:mova/models/nivo_query.dart';
import 'package:mova/models/receipt_scan_draft.dart';
import 'package:mova/screens/nivo_screen.dart';
import 'package:mova/services/nivo_engine.dart';
import 'package:mova/services/nivo_parser.dart';
import 'package:mova/services/nivo_repository.dart';
import 'package:mova/services/mova_localizations.dart';

Widget _localizedApp(Widget home) => MaterialApp(
  locale: const Locale('es'),
  supportedLocales: const [Locale('es'), Locale('en'), Locale('pt')],
  localizationsDelegates: const [
    MovaLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: home,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  group('Nivo action parsing', () {
    final parser = NivoParser();

    test('recognizes financial and shopping action intents', () {
      expect(
        parser.parse('Registra un gasto de \$250 en comida').intent,
        NivoIntent.crearGasto,
      );
      expect(
        parser.parse('Registra que recibí \$8,000 de nómina').intent,
        NivoIntent.crearIngreso,
      );
      final shopping = parser.parse('Agrega 2 litros de leche a mi lista');
      expect(shopping.intent, NivoIntent.agregarProductoLista);
      expect(shopping.entities.quantity, 2);
      expect(shopping.entities.unit, 'litros');
      expect(shopping.entities.product, 'leche');
      expect(
        parser.parse('Elimina todos mis movimientos').intent,
        NivoIntent.accionDestructiva,
      );
    });
  });

  group('Nivo local actions', () {
    const databaseName = 'nivo_actions_test.db';
    late DatabaseHelper database;
    late NivoEngine engine;
    final now = DateTime(2026, 9, 30);

    setUp(() async {
      final databasePath = join(await getDatabasesPath(), databaseName);
      await deleteDatabase(databasePath);
      database = DatabaseHelper(databaseName: databaseName);
      engine = NivoEngine(
        repository: NivoRepository(databaseHelper: database),
        clock: () => now,
      );
    });

    tearDown(() async {
      await (await database.database).close();
      await deleteDatabase(join(await getDatabasesPath(), databaseName));
    });

    test('records a clearly specified expense through SQLite', () async {
      final response = await engine.ask(
        'Registra un gasto de \$250 en comida.',
      );

      expect(response.text, contains('Listo. Registré un gasto'));
      expect(response.text, contains('Comida'));
      final transactions = await database.getTransactions();
      expect(transactions, hasLength(1));
      expect(transactions.single['amount'], 250);
      expect(transactions.single['category'], 'Comida');
      expect(transactions.single['is_income'], 0);
    });

    test('distinguishes an empty database from a zero balance', () async {
      final empty = await engine.ask('¿Cuánto dinero tengo?');
      expect(empty.text, contains('Todavía no tienes movimientos'));
      expect(empty.data['balances'], isEmpty);

      await database.createFinancialAccount(
        FinancialAccount(
          id: 0,
          name: 'Cuenta',
          type: FinancialAccountType.bank,
          currency: 'MXN',
          initialBalance: 0,
          institution: '',
          lastFour: '',
          icon: 'account_balance',
          isActive: true,
          creditLimit: null,
          createdAt: now,
        ),
      );

      final zero = await engine.ask('¿Cuánto dinero tengo?');
      expect(zero.text, contains('Tu saldo disponible'));
      expect(zero.text, contains('\$0'));
      expect(zero.data['balances'], {'MXN': 0.0});
    });

    test(
      'refreshes available balance from SQLite after each movement',
      () async {
        final empty = await engine.ask('¿Cuánto dinero tengo?');
        expect(empty.text, contains('Todavía no tienes movimientos'));

        final income = await engine.ask(
          'Registra que recibí \$10,000 de nómina.',
        );
        expect(income.text, contains('Listo. Registré un ingreso'));
        expect((await database.getTransactions()).single['account_id'], isNull);

        var balance = await engine.ask('¿Cuánto dinero tengo?');
        expect(balance.data['balances'], {'MXN': 10000.0});
        expect(balance.text, contains('\$10,000'));

        final expense = await engine.ask(
          'Registra un gasto de \$2,500 en comida.',
        );
        expect(expense.text, contains('Listo. Registré un gasto'));
        balance = await engine.ask('¿Cuánto dinero tengo?');
        expect(balance.data['balances'], {'MXN': 7500.0});
        expect(balance.text, contains('\$7,500'));

        final secondIncome = await engine.ask(
          'Registra que recibí \$5,000 de nómina.',
        );
        expect(secondIncome.text, contains('Listo. Registré un ingreso'));

        final reopenedEngine = NivoEngine(
          repository: NivoRepository(databaseHelper: database),
          clock: () => now,
        );
        balance = await reopenedEngine.ask('¿Cuánto dinero tengo?');
        expect(balance.data['balances'], {'MXN': 12500.0});
        expect(balance.text, contains('\$12,500'));
        expect((await database.getTransactions()), hasLength(3));
      },
    );

    testWidgets('NivoScreen accepts queries only through predefined options', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await database.getCurrency();
      });
      await tester.pumpWidget(_localizedApp(NivoScreen(engine: engine)));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.byKey(const Key('nivo-send')), findsNothing);
      expect(find.text('¿Cuánto gasté este mes?'), findsOneWidget);
      expect(await tester.runAsync(database.getTransactions), isEmpty);
    });

    testWidgets('NivoScreen sends receipt drafts for a local proposal', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await database.getCurrency();
      });
      await tester.pumpWidget(
        _localizedApp(
          NivoScreen(
            engine: engine,
            initialReceiptDraft: ReceiptScanDraft(
              imagePath: 'local-receipt.jpg',
              merchant: 'Tienda',
              amount: 125,
              date: now,
              category: 'Otros',
              categorySelected: false,
              items: const ['Artículo'],
              reference: null,
              accountId: null,
            ),
          ),
        ),
      );
      for (var attempt = 0; attempt < 60; attempt++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
        if (find.textContaining('¿En qué categoría').evaluate().isNotEmpty) {
          break;
        }
      }

      expect(find.textContaining('¿En qué categoría'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Otros'), findsOneWidget);
      expect(await tester.runAsync(database.getTransactions), isEmpty);

      final categoryOption = find.text('Otros');
      await tester.ensureVisible(categoryOption);
      await tester.pumpAndSettle();
      await tester.tap(categoryOption);
      for (var attempt = 0; attempt < 60; attempt++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
        if (find.text('Sí').evaluate().isNotEmpty) break;
      }
      expect(find.text('Sí'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);
      expect(await tester.runAsync(database.getTransactions), isEmpty);
    });

    test(
      'asks for missing category, proposes, and waits for confirmation',
      () async {
        final clarification = await engine.ask(
          'Registra un gasto de \$450 en Walmart.',
        );
        expect(clarification.requiresClarification, isTrue);
        expect(clarification.text, contains('¿En qué categoría'));
        expect(await database.getTransactions(), isEmpty);

        final proposal = await engine.ask('Comida');
        expect(proposal.requiresConfirmation, isTrue);
        expect(proposal.text, contains('Walmart'));
        expect(await database.getTransactions(), isEmpty);

        final result = await engine.ask('Sí');
        expect(result.text, contains('Listo. Registré un gasto'));
        final transactions = await database.getTransactions();
        expect(transactions, hasLength(1));
        expect(transactions.single['description'], 'Compra en Walmart');
      },
    );

    test('records payroll income in the existing transaction table', () async {
      final cashId = await database.createFinancialAccount(
        FinancialAccount(
          id: 0,
          name: 'Efectivo',
          type: FinancialAccountType.cash,
          currency: 'MXN',
          initialBalance: 0,
          institution: '',
          lastFour: '',
          icon: 'payments',
          isActive: true,
          creditLimit: null,
          createdAt: now,
        ),
      );
      final response = await engine.ask(
        'Registra que recibí \$8,000 de nómina.',
      );
      expect(response.text, contains('ingreso de \$8,000'));
      expect(response.text, contains('Efectivo'));
      final transactions = await database.getTransactions();
      expect(transactions, hasLength(1));
      expect(transactions.single['is_income'], 1);
      expect(transactions.single['category'], 'Sueldo');
      expect(transactions.single['account_id'], cashId);
      expect((await database.getFinancialAccount(cashId))?.balance, 8000);
    });

    test('leaves income unassigned if no cash account exists', () async {
      await engine.ask('Registra que recibí \$800 de nómina.');

      final transactions = await database.getTransactions();
      expect(transactions.single['account_id'], isNull);
    });

    test(
      'contributes to an existing goal using its established operation',
      () async {
        final goalId = await database.insertGoal(
          name: 'Coche',
          targetAmount: 10000,
          savedAmount: 1000,
          icon: 'car',
        );

        final response = await engine.ask('Agrega \$500 a mi meta del coche.');

        expect(response.text, contains('Agregué \$500'));
        final goals = await database.getGoals();
        expect(goals.single['id'], goalId);
        expect(goals.single['saved_amount'], 1500);
        expect(await database.getGoalMovements(goalId), hasLength(2));
      },
    );

    test('creates a goal through the existing goals table', () async {
      final response = await engine.ask(
        'Crea una meta llamada Vacaciones de \$12,000.',
      );

      expect(response.text, contains('Creé tu meta Vacaciones'));
      final goals = await database.getGoals();
      expect(goals, hasLength(1));
      expect(goals.single['target_amount'], 12000);
      expect(goals.single['saved_amount'], 0);
    });

    test('adds general savings through MOVA savings handling', () async {
      final response = await engine.ask('Agrega \$300 a mi ahorro sin meta.');

      expect(response.text, contains('a tu ahorro sin meta'));
      expect(await database.getUnassignedSavings(), 300);
    });

    test(
      'adds a measured product to the existing active shopping list',
      () async {
        final listId = await database.createShoppingList('Semanal');

        final response = await engine.ask(
          'Agrega 2 litros de leche a mi lista.',
        );

        expect(response.text, contains('2 litros de leche'));
        final products = await database.getShoppingProducts(listId);
        expect(products, hasLength(1));
        expect(products.single['name'], 'leche');
        expect(products.single['unit'], 'litros');
        expect(products.single['quantity'], 2);
      },
    );

    test(
      'creates a local receipt proposal and never saves before approval',
      () async {
        final proposal = await engine.proposeReceipt(
          ReceiptScanDraft(
            imagePath: 'local-receipt.jpg',
            merchant: 'Walmart',
            amount: 684.50,
            date: now,
            category: 'Comida',
            categorySelected: true,
            items: const ['Leche', 'Pan'],
            reference: 'ticket-123',
            accountId: null,
          ),
        );

        expect(proposal.requiresConfirmation, isTrue);
        expect(proposal.text, contains('comprobante analizado'));
        expect(await database.getTransactions(), isEmpty);
      },
    );

    test(
      'does not reuse an OCR default category without user selection',
      () async {
        final clarification = await engine.proposeReceipt(
          ReceiptScanDraft(
            imagePath: 'local-receipt.jpg',
            merchant: 'Tienda',
            amount: 125,
            date: now,
            category: 'Otros',
            categorySelected: false,
            items: const ['Artículo'],
            reference: null,
            accountId: null,
          ),
        );

        expect(clarification.requiresClarification, isTrue);
        expect(clarification.text, contains('¿En qué categoría'));
        expect(await database.getTransactions(), isEmpty);
      },
    );

    test(
      'detects a possible receipt duplicate and never saves on yes',
      () async {
        await database.insertTransaction(
          amount: 684.50,
          isIncome: false,
          category: 'Comida',
          description: 'Compra en Walmart',
          date: now,
          receiptReference: 'ticket-123',
        );

        final possibleDuplicate = await engine.proposeReceipt(
          ReceiptScanDraft(
            imagePath: 'local-receipt.jpg',
            merchant: 'Walmart',
            amount: 684.50,
            date: now,
            category: 'Comida',
            categorySelected: true,
            items: const [],
            reference: 'ticket-123',
            accountId: null,
          ),
        );
        expect(possibleDuplicate.requiresConfirmation, isTrue);
        expect(possibleDuplicate.text, contains('movimiento similar'));
        expect(possibleDuplicate.data, contains('possible_duplicate'));

        final rejectedDuplicate = await engine.ask('Sí');
        expect(rejectedDuplicate.text, contains('No registré el gasto'));
        expect(await database.getTransactions(), hasLength(1));
      },
    );

    test(
      'reports SQLite validation errors without a success response',
      () async {
        final accountId = await database.createFinancialAccount(
          FinancialAccount(
            id: 0,
            name: 'Visa',
            type: FinancialAccountType.creditCard,
            currency: 'MXN',
            initialBalance: 0,
            institution: '',
            lastFour: '1234',
            icon: 'credit_card',
            isActive: true,
            creditLimit: 100,
            createdAt: now,
          ),
        );
        expect(accountId, greaterThan(0));

        final response = await engine.ask(
          'Registra un gasto de \$250 en comida con Visa.',
        );

        expect(response.text, contains('No pude completar'));
        expect(response.text, contains('No se confirmó ningún cambio'));
        expect(response.text, isNot(contains('Listo. Registré')));
        expect(await database.getTransactions(), isEmpty);
      },
    );

    test('allows credit cards without a configured limit', () async {
      final accountId = await database.createFinancialAccount(
        FinancialAccount(
          id: 0,
          name: 'Visa',
          type: FinancialAccountType.creditCard,
          currency: 'MXN',
          initialBalance: 0,
          institution: '',
          lastFour: '1234',
          icon: 'credit_card',
          isActive: true,
          creditLimit: null,
          createdAt: now,
        ),
      );

      await database.insertTransaction(
        amount: 250,
        isIncome: false,
        category: 'Comida',
        description: 'Compra',
        date: now,
        accountId: accountId,
        currency: 'MXN',
      );

      expect((await database.getFinancialAccount(accountId))?.balance, 250);
      expect(
        (await database.getFinancialAccount(accountId))?.creditLimit,
        isNull,
      );
    });

    test('never performs a destructive action from parser detection', () async {
      final goalId = await database.insertGoal(
        name: 'Coche',
        targetAmount: 10000,
        savedAmount: 500,
        icon: 'car',
      );

      final response = await engine.ask('Elimina mi meta Coche.');

      expect(response.text, contains('no está habilitada'));
      expect(await database.getGoals(), hasLength(1));
      expect((await database.getGoals()).single['id'], goalId);
    });

    test(
      'answers all-goal questions and handles a selected goal reply',
      () async {
        final noGoals = await engine.ask('¿Cómo van mis metas?');
        expect(noGoals.text, 'Aún no tienes metas registradas.');
        expect(noGoals.requiresClarification, isFalse);

        await database.insertGoal(
          name: 'Challenger 2015',
          targetAmount: 200000,
          savedAmount: 50000,
          icon: 'directions_car',
        );
        final secondGoal = await database.insertGoal(
          name: 'Viaje',
          targetAmount: 30000,
          savedAmount: 7500,
          icon: 'flight',
        );

        final overview = await engine.ask('¿Cómo van mis metas?');
        expect(overview.text, contains('Tienes 2 metas'));
        expect(overview.text, contains('Challenger 2015'));
        expect(overview.text, contains('Viaje'));

        final clarification = await engine.ask('¿Cómo va mi meta?');
        expect(clarification.requiresClarification, isTrue);
        expect(clarification.text, contains('Challenger 2015'));
        expect(clarification.text, contains('Viaje'));

        final selectedGoal = await engine.ask('Challenger 2015');
        expect(selectedGoal.text, contains('meta Challenger 2015'));
        expect(selectedGoal.text, contains('\$50,000 de \$200,000'));

        final goals = await database.getGoals();
        expect(goals, hasLength(2));
        expect(goals.first['id'], secondGoal);
      },
    );
  });
}
