import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mova/database/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  test('register and login flow works with SQLite', () async {
    final dbPath = join(await getDatabasesPath(), 'mova.db');
    await deleteDatabase(dbPath);

    final db = DatabaseHelper();
    await db.database;

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
    );
    expect(transactionId, greaterThan(0));

    final transactions = await db.getTransactions();
    expect(transactions, hasLength(1));
    expect(transactions.first['amount'], 150.50);
    expect(transactions.first['is_income'], 0);
    expect(transactions.first['category'], 'Comida');

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
  });
}
