import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'package:mova/models/shared_goal.dart';

class DatabaseHelper {
  static const savingsDepositCategories = {
    'Ahorro',
    'Ahorro normal',
    'Ahorro sin meta',
    'Ahorro en meta',
  };
  static const savingsWithdrawalCategories = {
    'Devolución de meta',
    'Retiro de ahorro sin meta',
    'Ahorro en meta',
  };

  static bool isSavingsDeposit(Map<String, dynamic> transaction) {
    return transaction['is_income'] == 0 &&
        savingsDepositCategories.contains(transaction['category']);
  }

  static bool isSavingsWithdrawal(Map<String, dynamic> transaction) {
    return transaction['is_income'] == 1 &&
        savingsWithdrawalCategories.contains(transaction['category']);
  }

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();

    return _database!;
  }

  Future<double?> getMonthlyBudget() async {
    final rows = await (await database).query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['monthly_budget'],
      limit: 1,
    );
    final value = rows.isEmpty
        ? null
        : double.tryParse(rows.first['value'] as String);
    return value;
  }

  Future<void> setMonthlyBudget(double? amount) async {
    final db = await database;
    if (amount == null) {
      await db.delete(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['monthly_budget'],
      );
      return;
    }

    await db.insert('app_settings', {
      'key': 'monthly_budget',
      'value': amount.toString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String> getBudgetPeriod() async {
    final rows = await (await database).query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['budget_period'],
      limit: 1,
    );
    final value = rows.isEmpty ? null : rows.first['value'] as String?;
    return value == 'weekly' ? 'weekly' : 'monthly';
  }

  Future<void> setBudgetPeriod(String period) async {
    await (await database).insert('app_settings', {
      'key': 'budget_period',
      'value': period == 'weekly' ? 'weekly' : 'monthly',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String> getCurrency() async {
    final rows = await (await database).query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['currency'],
      limit: 1,
    );
    return rows.isEmpty ? 'MXN' : (rows.first['value'] as String? ?? 'MXN');
  }

  Future<void> setCurrency(String currency) async {
    await (await database).insert('app_settings', {
      'key': 'currency',
      'value': currency,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String> getLanguage() async {
    final rows = await (await database).query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['language'],
      limit: 1,
    );
    return rows.isEmpty ? 'es' : (rows.first['value'] as String? ?? 'es');
  }

  Future<void> setLanguage(String language) async {
    await (await database).insert('app_settings', {
      'key': 'language',
      'value': language,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getCustomCategories() async {
    return (await database).query(
      'custom_categories',
      orderBy: 'type ASC, name COLLATE NOCASE ASC',
    );
  }

  Future<int> addCustomCategory({
    required String name,
    required String type,
    String emoji = '📦',
  }) async {
    return (await database).insert('custom_categories', {
      'name': name.trim(),
      'type': type,
      'emoji': emoji,
    });
  }

  Future<void> deleteCustomCategory(int id) async {
    await (await database).delete(
      'custom_categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<String?> getSecurityMode() async {
    final rows = await (await database).query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['security_mode'],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<String?> getSecurityPin() async {
    final rows = await (await database).query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['security_pin'],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> setSecurity({required String mode, String? pin}) async {
    final db = await database;
    await db.insert('app_settings', {
      'key': 'security_mode',
      'value': mode,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    if (pin == null) {
      await db.delete(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['security_pin'],
      );
    } else {
      await db.insert('app_settings', {
        'key': 'security_pin',
        'value': pin,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<String?> getThemeMode() async {
    final rows = await (await database).query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['theme_mode'],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> setThemeMode(String mode) async {
    await (await database).insert('app_settings', {
      'key': 'theme_mode',
      'value': mode,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> getNotificationsEnabled() async {
    final rows = await (await database).query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['notifications_enabled'],
      limit: 1,
    );
    return rows.isEmpty || rows.first['value'] == 'true';
  }

  Future<bool> getNotificationOption(String key) async {
    final rows = await (await database).query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty || rows.first['value'] == 'true';
  }

  Future<void> setNotificationOption(String key, bool enabled) async {
    await (await database).insert('app_settings', {
      'key': key,
      'value': enabled.toString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>> exportData() async {
    final db = await database;
    return {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'transactions': await db.query('transactions'),
      'goals': await db.query('goals'),
      'goal_movements': await db.query('goal_movements'),
      'shopping_lists': await db.query('shopping_lists'),
      'shopping_products': await db.query('shopping_products'),
    };
  }

  Future<int> importTransactions(List<dynamic> values) async {
    final db = await database;
    var count = 0;
    for (final item in values) {
      if (item is! Map) continue;
      final amount = (item['amount'] as num?)?.toDouble();
      final date = item['date'] as String?;
      final category = item['category'] as String?;
      final description = item['description'] as String?;
      if (amount == null ||
          amount <= 0 ||
          date == null ||
          category == null ||
          description == null) {
        continue;
      }
      await db.insert('transactions', {
        'amount': amount,
        'is_income': item['is_income'] == 1 ? 1 : 0,
        'category': category,
        'description': description,
        'date': date,
        'note': item['note'] as String? ?? '',
      });
      count++;
    }
    return count;
  }

  Future<void> setShoppingProductPurchased(int id, bool purchased) async {
    final db = await database;
    await db.update(
      'shopping_products',
      {'is_purchased': purchased ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(databasePath, 'mova.db');

    return await openDatabase(
      path,
      version: 12,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        profile_image BLOB
        )
     ''');
        await _createTransactionsTable(db);
        await _createGoalsTable(db);
        await _createGoalMovementsTable(db);
        await _createShoppingTables(db);
        await _createSharedGoalTables(db);
        await _createSettingsTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createTransactionsTable(db);
        }
        if (oldVersion < 3) {
          await _createGoalsTable(db);
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE goals ADD COLUMN image BLOB');
        }
        if (oldVersion < 5) {
          await _createGoalMovementsTable(db);
        }
        if (oldVersion < 6) {
          await _createShoppingTables(db);
        }
        if (oldVersion < 7) {
          await _upgradeShoppingTables(db);
        }
        if (oldVersion < 8) {
          await db.execute("ALTER TABLE goals ADD COLUMN shared_id TEXT");
          await db.execute(
            "ALTER TABLE goals ADD COLUMN is_shared INTEGER NOT NULL DEFAULT 0",
          );
          await _createSharedGoalTables(db);
          await db.execute(
            'CREATE UNIQUE INDEX IF NOT EXISTS goals_shared_id_unique ON goals(shared_id)',
          );
        }
        if (oldVersion < 9) {
          await db.execute(
            "ALTER TABLE shopping_products ADD COLUMN price_unit TEXT NOT NULL DEFAULT 'unidad'",
          );
        }
        if (oldVersion < 10) {
          await db.execute(
            "ALTER TABLE shopping_products ADD COLUMN is_purchased INTEGER NOT NULL DEFAULT 0",
          );
        }
        if (oldVersion < 11) {
          await _createSettingsTables(db);
        }
        if (oldVersion < 12) {
          await db.execute('ALTER TABLE users ADD COLUMN profile_image BLOB');
        }
      },
    );
  }

  Future<int> insertUser(String name, String email, String password) async {
    final db = await database;

    return db.insert('users', {
      'name': name,
      'email': email,
      'password': password,
    });
  }

  Future<Map<String, dynamic>?> loginUser(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'LOWER(email) = LOWER(?) AND password = ?',
      whereArgs: [email.trim(), password],
      limit: 1,
    );

    if (result.isNotEmpty) {
      final userId = result.first['id'] as int;
      await db.insert('app_settings', {
        'key': 'current_user_id',
        'value': userId.toString(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await db.insert('app_settings', {
        'key': 'remembered_session',
        'value': rememberMe ? '1' : '0',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      final preferences = await _getPreferences();
      if (preferences != null) {
        await preferences.setInt('mova_current_user_id', userId);
        await preferences.setBool('mova_remembered_session', rememberMe);
      }
      return result.first;
    }
    return null;
  }

  Future<bool> hasRememberedSession() async {
    final preferences = await _getPreferences();
    if (preferences != null) {
      final remembered = preferences.getBool('mova_remembered_session');
      final rememberedUserId = preferences.getInt('mova_current_user_id');
      if (remembered == true && rememberedUserId != null) {
        return true;
      }
    }

    final db = await database;
    final rows = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['remembered_session'],
      limit: 1,
    );
    final dbRemembered = rows.isNotEmpty && rows.first['value'] == '1';
    if (dbRemembered) {
      final setting = await db.query(
        'app_settings',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: ['current_user_id'],
        limit: 1,
      );
      final userId = setting.isEmpty
          ? null
          : int.tryParse(setting.first['value'] as String);
      if (userId != null) {
        if (preferences != null) {
          await preferences.setInt('mova_current_user_id', userId);
          await preferences.setBool('mova_remembered_session', true);
        }
        return true;
      }
    }
    return false;
  }

  Future<void> logout() async {
    final db = await database;
    await db.delete(
      'app_settings',
      where: 'key IN (?, ?)',
      whereArgs: ['current_user_id', 'remembered_session'],
    );
    final preferences = await _getPreferences();
    if (preferences != null) {
      await preferences.remove('mova_current_user_id');
      await preferences.remove('mova_remembered_session');
    }
  }

  Future<SharedPreferences?> _getPreferences() async {
    try {
      return await SharedPreferences.getInstance();
    } on MissingPluginException {
      return null;
    }
  }

  Future<void> deleteAccount() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('goal_contributions');
      await txn.delete('goal_participants');
      await txn.delete('goal_movements');
      await txn.delete('shopping_products');
      await txn.delete('shopping_lists');
      await txn.delete('transactions');
      await txn.delete('goals');
      await txn.delete('custom_categories');
      await txn.delete('app_settings');
      await txn.delete('users');
    });

    final preferences = await _getPreferences();
    if (preferences != null) {
      await preferences.remove('mova_current_user_id');
      await preferences.remove('mova_remembered_session');
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final db = await database;
    final setting = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['current_user_id'],
      limit: 1,
    );
    final id = setting.isEmpty
        ? null
        : int.tryParse(setting.first['value'] as String);
    final rows = id == null
        ? await db.query('users', limit: 1)
        : await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<bool> updateUserName(int id, String name) async {
    final updated = await (await database).update(
      'users',
      {'name': name.trim()},
      where: 'id = ?',
      whereArgs: [id],
    );
    return updated > 0;
  }

  Future<bool> updateUserProfileImage(int id, Uint8List? image) async {
    final updated = await (await database).update(
      'users',
      {'profile_image': image},
      where: 'id = ?',
      whereArgs: [id],
    );
    return updated > 0;
  }

  Future<bool> updatePassword(String email, String newPassword) async {
    final db = await database;
    final updated = await db.update(
      'users',
      {'password': newPassword},
      where: 'LOWER(email) = LOWER(?)',
      whereArgs: [email.trim()],
    );
    return updated > 0;
  }

  Future<bool> userExists(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      columns: ['id'],
      where: 'LOWER(email) = LOWER(?)',
      whereArgs: [email.trim()],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<int> insertTransaction({
    required double amount,
    required bool isIncome,
    required String category,
    required String description,
    required DateTime date,
    String note = '',
  }) async {
    final db = await database;

    return db.insert('transactions', {
      'amount': amount,
      'is_income': isIncome ? 1 : 0,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'note': note,
    });
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    final db = await database;
    return db.query('transactions', orderBy: 'date DESC, id DESC');
  }

  Future<Map<String, double>> getTransactionSummary() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE
          WHEN is_income = 1
            AND category NOT IN (
              'Devolución de meta', 'Retiro de ahorro sin meta', 'Ahorro en meta'
            )
            THEN amount ELSE 0 END), 0) AS income,
        COALESCE(SUM(CASE
          WHEN is_income = 0
            AND category NOT IN ('Ahorro', 'Ahorro normal', 'Ahorro sin meta', 'Ahorro en meta')
            THEN amount ELSE 0 END), 0) AS expenses,
        COALESCE(SUM(CASE
          WHEN is_income = 0 AND category IN ('Ahorro', 'Ahorro normal', 'Ahorro sin meta', 'Ahorro en meta')
            THEN amount
          WHEN is_income = 1 AND category IN (
            'Devolución de meta', 'Retiro de ahorro sin meta', 'Ahorro en meta'
          )
            THEN -amount
          ELSE 0 END), 0) AS savings
      FROM transactions
    ''');
    final row = result.first;
    return {
      'income': (row['income'] as num).toDouble(),
      'expenses': (row['expenses'] as num).toDouble(),
      'savings': (row['savings'] as num).toDouble(),
    };
  }

  Future<double> getAvailableBalance() async {
    final summary = await getTransactionSummary();
    return summary['income']! - summary['expenses']! - summary['savings']!;
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return db.query('users');
  }

  Future<int> insertGoal({
    required String name,
    required double targetAmount,
    required double savedAmount,
    required String icon,
    Uint8List? image,
    String? sharedId,
    bool isShared = false,
  }) async {
    final db = await database;
    return db.transaction((txn) async {
      final id = await txn.insert('goals', {
        'name': name,
        'target_amount': targetAmount,
        'saved_amount': savedAmount,
        'icon': icon,
        'image': image,
        'created_at': DateTime.now().toIso8601String(),
        'shared_id': sharedId,
        'is_shared': isShared ? 1 : 0,
      });
      if (savedAmount > 0) {
        await _insertGoalMovement(txn, id, savedAmount, 'deposit');
        await _insertGoalTransaction(
          txn,
          savedAmount,
          'Ahorro en meta',
          'Ahorro inicial: $name',
          false,
        );
      }

      return id;
    });
  }

  Future<Map<String, dynamic>?> getGoalBySharedId(String sharedId) async {
    final rows = await (await database).query(
      'goals',
      where: 'shared_id = ?',
      whereArgs: [sharedId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> convertGoalToShared(int goalId) async {
    final id = newSharedId();
    await (await database).update(
      'goals',
      {'shared_id': id, 'is_shared': 1},
      where: 'id = ?',
      whereArgs: [goalId],
    );
    return goalId;
  }

  Future<int> importSharedGoal(SharedGoalPayload payload) async {
    final existing = await getGoalBySharedId(payload.id);
    if (existing != null) return existing['id'] as int;
    return insertGoal(
      name: payload.name,
      targetAmount: payload.targetAmount,
      savedAmount: 0,
      icon: payload.icon,
      sharedId: payload.id,
      isShared: true,
    );
  }

  Future<String?> ensureGoalShared(int goalId) async {
    final db = await database;
    final rows = await db.query(
      'goals',
      columns: ['shared_id'],
      where: 'id = ?',
      whereArgs: [goalId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final current = rows.first['shared_id'] as String?;
    if (current != null && current.isNotEmpty) return current;
    final id = newSharedId();
    await db.update(
      'goals',
      {'shared_id': id, 'is_shared': 1},
      where: 'id = ?',
      whereArgs: [goalId],
    );
    return id;
  }

  Future<int> addContribution(ContributionPayload contribution) async {
    final db = await database;
    final goal = await getGoalBySharedId(contribution.goalId);
    if (goal == null) throw StateError('No existe la meta compartida');
    return db.transaction((txn) async {
      final existing = await txn.query(
        'goal_contributions',
        columns: ['id'],
        where: 'contribution_id = ?',
        whereArgs: [contribution.contributionId],
        limit: 1,
      );
      if (existing.isNotEmpty) return 0;
      final result = await txn.insert('goal_contributions', {
        'contribution_id': contribution.contributionId,
        'goal_id': goal['id'],
        'contributor': contribution.contributor,
        'amount': contribution.amount,
        'created_at': DateTime.now().toIso8601String(),
      });
      await txn.update(
        'goals',
        {
          'saved_amount':
              (goal['saved_amount'] as num).toDouble() + contribution.amount,
        },
        where: 'id = ?',
        whereArgs: [goal['id']],
      );
      await _insertGoalMovement(
        txn,
        goal['id'] as int,
        contribution.amount,
        'deposit',
      );
      return result;
    });
  }

  Future<List<Map<String, dynamic>>> getContributions(int goalId) async =>
      (await database).query(
        'goal_contributions',
        where: 'goal_id = ?',
        whereArgs: [goalId],
        orderBy: 'created_at DESC',
      );

  Future<List<Map<String, dynamic>>> getGoals() async {
    final db = await database;
    return db.query('goals', orderBy: 'created_at DESC, id DESC');
  }

  Future<double> getUnassignedSavings() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT COALESCE(SUM(CASE
        WHEN is_income = 0 AND category = 'Ahorro sin meta' THEN amount
        WHEN is_income = 1 AND category = 'Retiro de ahorro sin meta' THEN -amount
        ELSE 0
      END), 0) AS total
      FROM transactions
    ''');
    return (rows.first['total'] as num).toDouble();
  }

  Future<void> addUnassignedSavings(double amount) async {
    await insertTransaction(
      amount: amount,
      isIncome: false,
      category: 'Ahorro sin meta',
      description: 'Aporte de ahorro sin meta',
      date: DateTime.now(),
    );
  }

  Future<void> withdrawUnassignedSavings(double amount) async {
    final available = await getUnassignedSavings();
    if (amount <= 0 || amount > available) {
      throw StateError('El retiro supera el ahorro disponible');
    }
    await insertTransaction(
      amount: amount,
      isIncome: true,
      category: 'Retiro de ahorro sin meta',
      description: 'Retiro de ahorro sin meta',
      date: DateTime.now(),
    );
  }

  Future<int> updateGoalSavedAmount(int id, double savedAmount) async {
    final db = await database;
    final current = await db.query(
      'goals',
      columns: ['saved_amount'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (current.isEmpty) return 0;
    final previous = (current.first['saved_amount'] as num).toDouble();
    final difference = savedAmount - previous;
    return db.transaction((txn) async {
      final result = await txn.update(
        'goals',
        {'saved_amount': savedAmount},
        where: 'id = ?',
        whereArgs: [id],
      );
      if (difference != 0) {
        await _insertGoalMovement(
          txn,
          id,
          difference.abs(),
          difference > 0 ? 'deposit' : 'withdrawal',
        );
        final goal = await txn.query(
          'goals',
          columns: ['name'],
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );
        final name = goal.first['name'] as String;
        await _insertGoalTransaction(
          txn,
          difference.abs(),
          'Ahorro en meta',
          difference > 0 ? 'Ahorro para meta: $name' : 'Retiro de meta: $name',
          difference < 0,
        );
      }
      return result;
    });
  }

  Future<void> deleteGoal(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      final goals = await txn.query(
        'goals',
        columns: ['name', 'saved_amount'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (goals.isEmpty) return;
      final goal = goals.first;
      final saved = (goal['saved_amount'] as num).toDouble();
      final name = goal['name'] as String;

      if (saved > 0) {
        await _insertGoalTransaction(
          txn,
          saved,
          'Devolución de meta',
          'Dinero devuelto al eliminar meta: $name',
          true,
        );
      }
      await txn.delete('goal_movements', where: 'goal_id = ?', whereArgs: [id]);
      await txn.delete('goals', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<Map<String, dynamic>>> getGoalMovements(int goalId) async {
    final db = await database;
    return db.query(
      'goal_movements',
      where: 'goal_id = ?',
      whereArgs: [goalId],
      orderBy: 'created_at DESC, id DESC',
    );
  }

  Future<int> createShoppingList(
    String name, {
    String store = '',
    double? budget,
    DateTime? shoppingDate,
    String notes = '',
  }) async {
    final db = await database;
    return db.insert('shopping_lists', {
      'name': name.trim(),
      'status': 'current',
      'total': 0,
      'store': store.trim(),
      'budget': budget,
      'shopping_date': shoppingDate?.toIso8601String(),
      'notes': notes.trim(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getShoppingLists({
    bool history = false,
  }) async {
    final db = await database;
    return db.query(
      'shopping_lists',
      where: 'status = ?',
      whereArgs: [history ? 'completed' : 'current'],
      orderBy: 'created_at DESC, id DESC',
    );
  }

  Future<Map<String, dynamic>?> getShoppingList(int id) async {
    final db = await database;
    final rows = await db.query(
      'shopping_lists',
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> deleteShoppingList(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'shopping_products',
        where: 'list_id = ?',
        whereArgs: [id],
      );
      await txn.delete('shopping_lists', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<Map<String, dynamic>>> getShoppingProducts(int listId) async {
    final db = await database;
    return db.query(
      'shopping_products',
      where: 'list_id = ?',
      whereArgs: [listId],
      orderBy: 'id ASC',
    );
  }

  Future<int> addShoppingProduct({
    required int listId,
    required String name,
    required String unit,
    required double quantity,
    double? unitPrice,
    String priceUnit = 'unidad',
    String note = '',
  }) async {
    final db = await database;
    final subtotal = _calculateShoppingSubtotal(
      quantity,
      unit,
      unitPrice,
      priceUnit,
    );
    final id = await db.insert('shopping_products', {
      'list_id': listId,
      'name': name.trim(),
      'unit': unit.trim().isEmpty ? 'unidad' : unit.trim(),
      'quantity': quantity,
      'unit_price': unitPrice ?? 0,
      'price_unit': priceUnit,
      'subtotal': subtotal,
      'note': note.trim(),
    });
    await _refreshShoppingTotal(db, listId);
    return id;
  }

  Future<int> updateShoppingProduct({
    required int id,
    required String name,
    required String unit,
    required double quantity,
    double? unitPrice,
    String priceUnit = 'unidad',
    String note = '',
  }) async {
    final db = await database;
    final rows = await db.query(
      'shopping_products',
      columns: ['list_id'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return 0;
    final listId = rows.first['list_id'] as int;
    final result = await db.update(
      'shopping_products',
      {
        'name': name.trim(),
        'unit': unit.trim().isEmpty ? 'unidad' : unit.trim(),
        'quantity': quantity,
        'unit_price': unitPrice ?? 0,
        'subtotal': _calculateShoppingSubtotal(
          quantity,
          unit,
          unitPrice,
          priceUnit,
        ),
        'price_unit': priceUnit,
        'note': note.trim(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    await _refreshShoppingTotal(db, listId);
    return result;
  }

  double _calculateShoppingSubtotal(
    double quantity,
    String quantityUnit,
    double? price,
    String priceUnit,
  ) {
    if (price == null || price <= 0) return 0;
    final quantityFactor = _shoppingUnitFactor(quantityUnit);
    final priceFactor = _shoppingUnitFactor(priceUnit);
    if (quantityFactor == null ||
        priceFactor == null ||
        _shoppingUnitGroup(quantityUnit) != _shoppingUnitGroup(priceUnit)) {
      return quantity * price;
    }
    return quantity * quantityFactor / priceFactor * price;
  }

  String? _shoppingUnitGroup(String unit) {
    final normalized = unit.trim().toLowerCase();
    if (const [
      'gramo',
      'gramos',
      'kilogramo',
      'kilogramos',
      'kilo',
      'kilos',
    ].contains(normalized)) {
      return 'weight';
    }
    if (const [
      'mililitro',
      'mililitros',
      'litro',
      'litros',
    ].contains(normalized)) {
      return 'volume';
    }
    if (const [
      'milimetro',
      'milimetros',
      'centimetro',
      'centimetros',
      'metro',
      'metros',
    ].contains(normalized)) {
      return 'length';
    }
    if (_shoppingUnitFactor(unit) != null) return 'count';
    return null;
  }

  double? _shoppingUnitFactor(String unit) {
    switch (unit.trim().toLowerCase()) {
      case 'gramo':
      case 'gramos':
        return 1;
      case 'kilogramo':
      case 'kilogramos':
      case 'kilo':
      case 'kilos':
        return 1000;
      case 'mililitro':
      case 'mililitros':
        return 1;
      case 'litro':
      case 'litros':
        return 1000;
      case 'milimetro':
      case 'milimetros':
        return 1;
      case 'centimetro':
      case 'centimetros':
        return 10;
      case 'metro':
      case 'metros':
        return 1000;
      case 'pieza':
      case 'piezas':
      case 'unidad':
      case 'unidades':
      case 'tapa':
      case 'tapas':
      case 'paquete':
      case 'paquetes':
      case 'caja':
      case 'cajas':
      case 'cartón':
      case 'cartones':
      case 'bolsa':
      case 'bolsas':
      case 'botella':
      case 'botellas':
      case 'lata':
      case 'latas':
      case 'frasco':
      case 'frascos':
      case 'rollo':
      case 'rollos':
      case 'sobre':
      case 'sobres':
      case 'charola':
      case 'charolas':
      case 'bandeja':
      case 'bandejas':
      case 'racimo':
      case 'racimos':
      case 'manojo':
      case 'manojos':
        return 1;
      case 'docena':
        return 12;
      case 'media docena':
        return 6;
      default:
        return null;
    }
  }

  Future<void> deleteShoppingProduct(int id) async {
    final db = await database;
    final rows = await db.query(
      'shopping_products',
      columns: ['list_id'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return;
    final listId = rows.first['list_id'] as int;
    await db.delete('shopping_products', where: 'id = ?', whereArgs: [id]);
    await _refreshShoppingTotal(db, listId);
  }

  Future<void> updateShoppingListName(int id, String name) async {
    final db = await database;
    await db.update(
      'shopping_lists',
      {'name': name.trim()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> finalizeShoppingList(int id) async {
    final db = await database;
    final rows = await db.query(
      'shopping_lists',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty || rows.first['status'] == 'completed') return;
    final total = (rows.first['total'] as num).toDouble();
    await db.transaction((txn) async {
      await txn.update(
        'shopping_lists',
        {
          'status': 'completed',
          'completed_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      if (total > 0) {
        await txn.insert('transactions', {
          'amount': total,
          'is_income': 0,
          'category': 'Compras',
          'description': 'Lista de compras: ${rows.first['name']}',
          'date': DateTime.now().toIso8601String(),
          'note': '',
        });
      }
    });
  }

  Future<void> _createTransactionsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        is_income INTEGER NOT NULL,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT ''
      )
    ''');
  }

  Future<void> _createGoalsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS goals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        saved_amount REAL NOT NULL DEFAULT 0,
        icon TEXT NOT NULL DEFAULT 'flag',
        image BLOB,
        created_at TEXT NOT NULL
        ,shared_id TEXT UNIQUE
        ,is_shared INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createSharedGoalTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS goal_participants(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        goal_id INTEGER NOT NULL,
        participant_id TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(goal_id) REFERENCES goals(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS goal_contributions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contribution_id TEXT NOT NULL UNIQUE,
        goal_id INTEGER NOT NULL,
        contributor TEXT NOT NULL,
        amount REAL NOT NULL CHECK(amount > 0),
        created_at TEXT NOT NULL,
        FOREIGN KEY(goal_id) REFERENCES goals(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createGoalMovementsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS goal_movements(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        goal_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(goal_id) REFERENCES goals(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createShoppingTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS shopping_lists(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'current',
        total REAL NOT NULL DEFAULT 0,
        store TEXT NOT NULL DEFAULT '',
        budget REAL,
        shopping_date TEXT,
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        completed_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS shopping_products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        list_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        unit TEXT NOT NULL DEFAULT 'unidad',
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        price_unit TEXT NOT NULL DEFAULT 'unidad',
        is_purchased INTEGER NOT NULL DEFAULT 0,
        subtotal REAL NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        FOREIGN KEY(list_id) REFERENCES shopping_lists(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createSettingsTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS custom_categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        emoji TEXT NOT NULL DEFAULT '📦',
        UNIQUE(name, type)
      )
    ''');
  }

  Future<void> _upgradeShoppingTables(DatabaseExecutor db) async {
    await db.execute(
      "ALTER TABLE shopping_lists ADD COLUMN store TEXT NOT NULL DEFAULT ''",
    );
    await db.execute("ALTER TABLE shopping_lists ADD COLUMN budget REAL");
    await db.execute(
      "ALTER TABLE shopping_lists ADD COLUMN shopping_date TEXT",
    );
    await db.execute(
      "ALTER TABLE shopping_lists ADD COLUMN notes TEXT NOT NULL DEFAULT ''",
    );
    await db.execute(
      "ALTER TABLE shopping_products ADD COLUMN note TEXT NOT NULL DEFAULT ''",
    );
  }

  Future<void> _refreshShoppingTotal(DatabaseExecutor db, int listId) async {
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(subtotal), 0) AS total FROM shopping_products WHERE list_id = ?',
      [listId],
    );
    await db.update(
      'shopping_lists',
      {'total': (result.first['total'] as num).toDouble()},
      where: 'id = ?',
      whereArgs: [listId],
    );
  }

  Future<void> _insertGoalMovement(
    DatabaseExecutor db,
    int goalId,
    double amount,
    String type,
  ) async {
    await db.insert('goal_movements', {
      'goal_id': goalId,
      'amount': amount,
      'type': type,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _insertGoalTransaction(
    DatabaseExecutor db,
    double amount,
    String category,
    String description,
    bool isIncome,
  ) async {
    await db.insert('transactions', {
      'amount': amount,
      'is_income': isIncome ? 1 : 0,
      'category': category,
      'description': description,
      'date': DateTime.now().toIso8601String(),
      'note': '',
    });
  }
}
