import 'dart:convert';

import 'package:mova/database/database_helper.dart';

class CreateExpenseAction {
  const CreateExpenseAction(this._database);

  final DatabaseHelper _database;

  Future<int> execute({
    required double amount,
    required String category,
    required String description,
    required DateTime date,
    String note = '',
    int? accountId,
    String? currency,
    String? receiptImagePath,
    List<String> receiptItems = const [],
    String? receiptReference,
  }) {
    _validateAmount(amount);
    if (category.trim().isEmpty || description.trim().isEmpty) {
      throw ArgumentError('La categoría y la descripción son obligatorias.');
    }
    return _database.insertTransaction(
      amount: amount,
      isIncome: false,
      category: category,
      description: description,
      date: date,
      note: note,
      accountId: accountId,
      currency: currency,
      receiptImagePath: receiptImagePath,
      receiptItems: receiptItems.isEmpty ? null : jsonEncode(receiptItems),
      receiptReference: receiptReference,
    );
  }
}

class CreateIncomeAction {
  const CreateIncomeAction(this._database);

  final DatabaseHelper _database;

  Future<int> execute({
    required double amount,
    required String category,
    required String description,
    required DateTime date,
    int? accountId,
    String? currency,
  }) {
    _validateAmount(amount);
    if (category.trim().isEmpty || description.trim().isEmpty) {
      throw ArgumentError('La categoría y la descripción son obligatorias.');
    }
    return _database.insertTransaction(
      amount: amount,
      isIncome: true,
      category: category,
      description: description,
      date: date,
      accountId: accountId,
      currency: currency,
    );
  }
}

class AddSavingAction {
  const AddSavingAction(this._database);

  final DatabaseHelper _database;

  Future<void> execute(double amount, {required int accountId}) {
    _validateAmount(amount);
    return _database.moveToUnassignedSavings(amount, accountId: accountId);
  }
}

class AddGoalContributionAction {
  const AddGoalContributionAction(this._database);

  final DatabaseHelper _database;

  Future<int> execute({
    required Map<String, dynamic> goal,
    required double amount,
  }) {
    _validateAmount(amount);
    final id = goal['id'];
    final saved = goal['saved_amount'];
    if (id is! int || saved is! num) {
      throw StateError('No se pudo validar la meta seleccionada.');
    }
    return _database.updateGoalSavedAmount(id, saved.toDouble() + amount);
  }
}

class CreateGoalAction {
  const CreateGoalAction(this._database);

  final DatabaseHelper _database;

  Future<int> execute({required String name, required double targetAmount}) {
    _validateAmount(targetAmount);
    if (name.trim().isEmpty) {
      throw ArgumentError('El nombre de la meta es obligatorio.');
    }
    return _database.insertGoal(
      name: name.trim(),
      targetAmount: targetAmount,
      savedAmount: 0,
      icon: 'savings',
    );
  }
}

class AddShoppingItemAction {
  const AddShoppingItemAction(this._database);

  final DatabaseHelper _database;

  Future<int> execute({
    required int listId,
    required String name,
    required String unit,
    required double quantity,
  }) async {
    _validateAmount(quantity);
    if (name.trim().isEmpty) {
      throw ArgumentError('El nombre del producto es obligatorio.');
    }
    final list = await _database.getShoppingList(listId);
    if (list == null || list['status'] != 'current') {
      throw StateError('La lista seleccionada ya no está disponible.');
    }
    return _database.addShoppingProduct(
      listId: listId,
      name: name.trim(),
      unit: unit.trim().isEmpty ? 'unidad' : unit.trim(),
      quantity: quantity,
    );
  }
}

void _validateAmount(double amount) {
  if (!amount.isFinite || amount <= 0) {
    throw ArgumentError('El monto debe ser mayor que cero.');
  }
}
