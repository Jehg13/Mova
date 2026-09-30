import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'package:mova/models/shared_goal.dart';
import 'package:mova/models/subscription.dart';
import 'package:mova/models/financial_account.dart';
import 'package:mova/models/scheduled_payment.dart';
import 'package:mova/services/receipt_storage.dart';

class DatabaseHelper {
  DatabaseHelper({this.databaseName});

  final String? databaseName;
  Database? _instanceDatabase;

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
    final databaseName = this.databaseName;
    if (databaseName != null) {
      if (_instanceDatabase != null) return _instanceDatabase!;
      _instanceDatabase = await _initDatabase(databaseName);
      return _instanceDatabase!;
    }
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

  Future<List<Map<String, Object?>>> getTransactionCategories() async {
    return (await database).rawQuery('''
      SELECT DISTINCT category AS name,
        CASE WHEN is_income = 1 THEN 'income' ELSE 'expense' END AS type
      FROM transactions
      ORDER BY type ASC, name COLLATE NOCASE ASC
    ''');
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

  Future<String?> getUserSetting(String key) async {
    final rows = await (await database).query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> setUserSetting(String key, String value) async {
    await (await database).insert('app_settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>> exportData() async {
    final db = await database;
    final transactions = await db.query('transactions');
    final exportedTransactions = <Map<String, dynamic>>[];
    for (final transaction in transactions) {
      final exported = Map<String, dynamic>.from(transaction);
      final imagePath = transaction['receipt_image_path'] as String?;
      if (imagePath != null && imagePath.isNotEmpty) {
        final image = await exportReceiptImageAsBase64(imagePath);
        exported['receipt_image_base64'] = image;
      }
      exportedTransactions.add(exported);
    }
    final goals = await db.query('goals');
    final exportedGoals = goals.map((goal) {
      final exported = Map<String, dynamic>.from(goal);
      final image = goal['image'];
      if (image is List<int>) {
        exported['image_base64'] = base64Encode(image);
        exported.remove('image');
      }
      return exported;
    }).toList();
    final settings = await db.query(
      'app_settings',
      where:
          "key NOT IN ('current_user_id', 'remembered_session', "
          "'security_mode', 'security_pin')",
    );
    final currentUser = await getCurrentUser();
    final profileImage = currentUser?['profile_image'];
    return {
      'format': 'mova_backup',
      'version': 2,
      'created_at': DateTime.now().toIso8601String(),
      'app_version': '1.0.0',
      'database_version': 16,
      'data': {
        'profile': currentUser == null
            ? null
            : {
                'name': currentUser['name'],
                if (profileImage is List<int>)
                  'image_base64': base64Encode(profileImage),
              },
        'transactions': exportedTransactions,
        'subscriptions': await db.query('subscriptions'),
        'subscription_payments': await db.query('subscription_payments'),
        'accounts': await db.query('accounts'),
        'account_transfers': await db.query('account_transfers'),
        'scheduled_payments': await db.query('scheduled_payments'),
        'scheduled_payment_history': await db.query(
          'scheduled_payment_history',
        ),
        'goals': exportedGoals,
        'goal_movements': await db.query('goal_movements'),
        'goal_participants': await db.query('goal_participants'),
        'goal_contributions': await db.query('goal_contributions'),
        'shopping_lists': await db.query('shopping_lists'),
        'shopping_products': await db.query('shopping_products'),
        'custom_categories': await db.query('custom_categories'),
        'app_settings': settings,
      },
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

  Future<int> importBackup(
    Map<String, dynamic> backup, {
    bool replaceExisting = false,
  }) async {
    final db = await database;
    final source = backup['data'] is Map
        ? Map<String, dynamic>.from(backup['data'] as Map)
        : backup;
    final rawTransactions = source['transactions'];
    final rawSubscriptions = source['subscriptions'];
    final rawPayments = source['subscription_payments'];
    final rawAccounts = source['accounts'];
    final rawTransfers = source['account_transfers'];
    final rawScheduledPayments = source['scheduled_payments'];
    final rawScheduledHistory = source['scheduled_payment_history'];
    final rawGoals = source['goals'];
    final rawGoalMovements = source['goal_movements'];
    final rawGoalParticipants = source['goal_participants'];
    final rawGoalContributions = source['goal_contributions'];
    final rawShoppingLists = source['shopping_lists'];
    final rawShoppingProducts = source['shopping_products'];
    final rawCategories = source['custom_categories'];
    final rawSettings = source['app_settings'];
    final rawProfile = source['profile'];
    final transactions = rawTransactions is List
        ? rawTransactions.whereType<Map>().toList()
        : const <Map>[];
    final subscriptions = rawSubscriptions is List
        ? rawSubscriptions.whereType<Map>().toList()
        : const <Map>[];
    final payments = rawPayments is List
        ? rawPayments.whereType<Map>().toList()
        : const <Map>[];
    final accounts = rawAccounts is List
        ? rawAccounts.whereType<Map>().toList()
        : const <Map>[];
    final transfers = rawTransfers is List
        ? rawTransfers.whereType<Map>().toList()
        : const <Map>[];
    final scheduledPayments = rawScheduledPayments is List
        ? rawScheduledPayments.whereType<Map>().toList()
        : const <Map>[];
    final scheduledHistory = rawScheduledHistory is List
        ? rawScheduledHistory.whereType<Map>().toList()
        : const <Map>[];
    final goals = rawGoals is List
        ? rawGoals.whereType<Map>().toList()
        : const <Map>[];
    final goalMovements = rawGoalMovements is List
        ? rawGoalMovements.whereType<Map>().toList()
        : const <Map>[];
    final goalParticipants = rawGoalParticipants is List
        ? rawGoalParticipants.whereType<Map>().toList()
        : const <Map>[];
    final goalContributions = rawGoalContributions is List
        ? rawGoalContributions.whereType<Map>().toList()
        : const <Map>[];
    final shoppingLists = rawShoppingLists is List
        ? rawShoppingLists.whereType<Map>().toList()
        : const <Map>[];
    final shoppingProducts = rawShoppingProducts is List
        ? rawShoppingProducts.whereType<Map>().toList()
        : const <Map>[];
    final categories = rawCategories is List
        ? rawCategories.whereType<Map>().toList()
        : const <Map>[];
    final settings = rawSettings is List
        ? rawSettings.whereType<Map>().toList()
        : const <Map>[];

    return db.transaction((txn) async {
      if (replaceExisting) {
        await txn.delete('scheduled_payment_history');
        await txn.delete('subscription_payments');
        await txn.delete('goal_contributions');
        await txn.delete('goal_participants');
        await txn.delete('goal_movements');
        await txn.delete('shopping_products');
        await txn.delete('transactions');
        await txn.delete('account_transfers');
        await txn.delete('scheduled_payments');
        await txn.delete('subscriptions');
        await txn.delete('accounts');
        await txn.delete('shopping_lists');
        await txn.delete('goals');
        if (rawCategories is List) await txn.delete('custom_categories');
        if (rawSettings is List) {
          await txn.delete(
            'app_settings',
            where:
                "key NOT IN ('current_user_id', 'remembered_session', "
                "'security_mode', 'security_pin')",
          );
        }
      }
      final transactionIds = <int, int>{};
      final subscriptionIds = <int, int>{};
      final accountIds = <int, int>{};
      final scheduledPaymentIds = <int, int>{};
      final transferIds = <int, int>{};
      final goalIds = <int, int>{};
      final shoppingListIds = <int, int>{};
      var importedTransactions = 0;

      for (final item in categories) {
        final name = item['name'] as String?;
        final type = item['type'] as String?;
        if (name == null ||
            name.trim().isEmpty ||
            (type != 'income' && type != 'expense')) {
          continue;
        }
        await txn.insert('custom_categories', {
          'name': name.trim(),
          'type': type,
          'emoji': item['emoji'] as String? ?? '📦',
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      for (final item in settings) {
        final key = item['key'] as String?;
        final value = item['value'] as String?;
        if (key == null ||
            value == null ||
            const {
              'current_user_id',
              'remembered_session',
              'security_mode',
              'security_pin',
            }.contains(key)) {
          continue;
        }
        await txn.insert('app_settings', {
          'key': key,
          'value': value,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      if (replaceExisting && rawProfile is Map) {
        final profileName = rawProfile['name'];
        final imageBase64 = rawProfile['image_base64'];
        final currentUserSetting = await txn.query(
          'app_settings',
          columns: ['value'],
          where: 'key = ?',
          whereArgs: ['current_user_id'],
          limit: 1,
        );
        final currentUserId = currentUserSetting.isEmpty
            ? null
            : int.tryParse(currentUserSetting.first['value'] as String);
        if (profileName is String &&
            profileName.trim().isNotEmpty &&
            currentUserId != null) {
          await txn.update(
            'users',
            {
              'name': profileName.trim(),
              if (imageBase64 is String)
                'profile_image': base64Decode(imageBase64),
            },
            where: 'id = ?',
            whereArgs: [currentUserId],
          );
        }
      }
      for (final item in goals) {
        final name = item['name'] as String?;
        final targetAmount = (item['target_amount'] as num?)?.toDouble();
        final savedAmount = (item['saved_amount'] as num?)?.toDouble();
        final createdAt = DateTime.tryParse(
          item['created_at'] as String? ?? '',
        );
        if (name == null ||
            name.trim().isEmpty ||
            targetAmount == null ||
            targetAmount <= 0 ||
            savedAmount == null ||
            savedAmount < 0 ||
            createdAt == null) {
          continue;
        }
        final imageBase64 = item['image_base64'] as String?;
        final image = imageBase64 == null ? null : base64Decode(imageBase64);
        final newId = await txn.insert('goals', {
          'name': name.trim(),
          'target_amount': targetAmount,
          'saved_amount': savedAmount,
          'icon': item['icon'] as String? ?? 'flag',
          'image': image,
          'created_at': createdAt.toIso8601String(),
          'shared_id': item['shared_id'] as String?,
          'is_shared': item['is_shared'] == 1 ? 1 : 0,
        });
        final oldId = item['id'];
        if (oldId is int) goalIds[oldId] = newId;
      }
      for (final item in shoppingLists) {
        final name = item['name'] as String?;
        final status = item['status'] as String? ?? 'current';
        final total = (item['total'] as num?)?.toDouble() ?? 0;
        final createdAt = DateTime.tryParse(
          item['created_at'] as String? ?? '',
        );
        if (name == null ||
            name.trim().isEmpty ||
            !{'current', 'completed'}.contains(status) ||
            total < 0 ||
            createdAt == null) {
          continue;
        }
        final newId = await txn.insert('shopping_lists', {
          'name': name.trim(),
          'status': status,
          'total': total,
          'store': item['store'] as String? ?? '',
          'budget': (item['budget'] as num?)?.toDouble(),
          'shopping_date': item['shopping_date'] as String?,
          'notes': item['notes'] as String? ?? '',
          'created_at': createdAt.toIso8601String(),
          'completed_at': item['completed_at'] as String?,
        });
        final oldId = item['id'];
        if (oldId is int) shoppingListIds[oldId] = newId;
      }

      for (final item in accounts) {
        final name = item['name'] as String?;
        final type = item['type'] as String?;
        final currency = item['currency'] as String?;
        final initialBalance = (item['initial_balance'] as num?)?.toDouble();
        final createdAt = DateTime.tryParse(
          item['created_at'] as String? ?? '',
        );
        if (name == null ||
            name.trim().isEmpty ||
            type == null ||
            !FinancialAccountType.values.any((value) => value.name == type) ||
            currency == null ||
            initialBalance == null ||
            initialBalance < 0 ||
            createdAt == null) {
          continue;
        }
        final newId = await txn.insert('accounts', {
          'name': name.trim(),
          'type': type,
          'currency': currency,
          'initial_balance': initialBalance,
          'institution': item['institution'] as String? ?? '',
          'last_four': item['last_four'] as String? ?? '',
          'icon': item['icon'] as String? ?? 'account_balance_wallet',
          'is_active': item['is_active'] == 0 ? 0 : 1,
          'credit_limit': (item['credit_limit'] as num?)?.toDouble(),
          'created_at': createdAt.toIso8601String(),
        });
        final oldId = item['id'];
        if (oldId is int) accountIds[oldId] = newId;
      }

      for (final item in scheduledPayments) {
        final name = item['name'] as String?;
        final amount = (item['amount'] as num?)?.toDouble();
        final currency = item['currency'] as String?;
        final type = item['payment_type'] as String?;
        final dueDate = DateTime.tryParse(item['due_date'] as String? ?? '');
        final frequency = item['frequency'] as String?;
        final accountId = item['account_id'] is int
            ? accountIds[item['account_id']]
            : null;
        final targetAccountId = item['target_account_id'] is int
            ? accountIds[item['target_account_id']]
            : null;
        final category = item['category'] as String?;
        final reminderDays = item['reminder_days'] as int? ?? 1;
        final status = item['status'] as String? ?? 'active';
        if (name == null ||
            name.trim().isEmpty ||
            amount == null ||
            amount <= 0 ||
            currency == null ||
            type == null ||
            !ScheduledPaymentType.values.any((value) => value.name == type) ||
            dueDate == null ||
            (frequency != null &&
                !SubscriptionFrequency.values.any(
                  (value) => value.name == frequency,
                )) ||
            (type == ScheduledPaymentType.recurring.name &&
                (frequency == null || category == null)) ||
            (type == ScheduledPaymentType.oneTime.name &&
                (frequency != null || category == null)) ||
            (type == ScheduledPaymentType.cardPayment.name &&
                targetAccountId == null) ||
            (type != ScheduledPaymentType.cardPayment.name &&
                targetAccountId != null) ||
            ![0, 1, 3, 7].contains(reminderDays) ||
            !ScheduledPaymentStatus.values.any(
              (value) => value.name == status,
            )) {
          continue;
        }
        final newId = await txn.insert('scheduled_payments', {
          'name': name.trim(),
          'amount': amount,
          'currency': currency,
          'payment_type': type,
          'due_date': ScheduledPayment.dateOnly(dueDate),
          'category': category,
          'frequency': frequency,
          'account_id': accountId,
          'target_account_id': targetAccountId,
          'reminder_days': reminderDays,
          'status': status,
          'notes': item['notes'] as String? ?? '',
          'created_at':
              item['created_at'] as String? ?? DateTime.now().toIso8601String(),
        });
        final oldId = item['id'];
        if (oldId is int) scheduledPaymentIds[oldId] = newId;
      }

      for (final item in transactions) {
        final amount = (item['amount'] as num?)?.toDouble();
        final date = DateTime.tryParse(item['date'] as String? ?? '');
        final category = item['category'] as String?;
        final description = item['description'] as String?;
        if (amount == null ||
            amount <= 0 ||
            date == null ||
            category == null ||
            description == null) {
          continue;
        }
        final accountId = item['account_id'] is int
            ? accountIds[item['account_id']]
            : null;
        final imageBase64 = item['receipt_image_base64'] as String?;
        final receiptImagePath = imageBase64 == null
            ? null
            : await persistReceiptImageBytes(base64Decode(imageBase64));
        final newId = await txn.insert('transactions', {
          'amount': amount,
          'is_income': item['is_income'] == 1 ? 1 : 0,
          'category': category,
          'description': description,
          'date': date.toIso8601String(),
          'note': item['note'] as String? ?? '',
          'subscription_id': null,
          'subscription_charge_date': null,
          'account_id': accountId,
          'currency': item['currency'] as String?,
          'scheduled_payment_id': item['scheduled_payment_id'] is int
              ? scheduledPaymentIds[item['scheduled_payment_id']]
              : null,
          'receipt_image_path': receiptImagePath,
          'receipt_items': item['receipt_items'] as String?,
          'receipt_reference': item['receipt_reference'] as String?,
        });
        final oldId = item['id'];
        if (oldId is int) transactionIds[oldId] = newId;
        importedTransactions++;
      }

      for (final item in subscriptions) {
        final name = item['name'] as String?;
        final amount = (item['amount'] as num?)?.toDouble();
        final currency = item['currency'] as String?;
        final category = item['category'] as String?;
        final frequency = item['frequency'] as String?;
        final nextChargeDate = DateTime.tryParse(
          item['next_charge_date'] as String? ?? '',
        );
        final status = item['status'] as String? ?? 'active';
        final reminderDays = item['reminder_days'] as int? ?? 1;
        final billingDay =
            item['billing_day'] as int? ?? nextChargeDate?.day ?? 1;
        if (name == null ||
            name.trim().isEmpty ||
            amount == null ||
            amount <= 0 ||
            currency == null ||
            category == null ||
            frequency == null ||
            !SubscriptionFrequency.values.any(
              (value) => value.name == frequency,
            ) ||
            nextChargeDate == null ||
            billingDay < 1 ||
            billingDay > 31 ||
            !SubscriptionStatus.values.any((value) => value.name == status) ||
            ![0, 1, 3, 7].contains(reminderDays)) {
          continue;
        }
        final newId = await txn.insert('subscriptions', {
          'name': name.trim(),
          'description': item['description'] as String? ?? '',
          'amount': amount,
          'currency': currency,
          'category': category,
          'frequency': frequency,
          'next_charge_date': Subscription.dateOnly(nextChargeDate),
          'billing_day': billingDay,
          'account_id': item['account_id'] is int
              ? accountIds[item['account_id']]
              : null,
          'account_label': item['account_label'] as String? ?? '',
          'status': status,
          'reminder_days': reminderDays,
          'created_at':
              item['created_at'] as String? ?? DateTime.now().toIso8601String(),
          'updated_at': item['updated_at'] as String?,
          'notes': item['notes'] as String? ?? '',
        });
        final oldId = item['id'];
        if (oldId is int) subscriptionIds[oldId] = newId;
      }

      for (final item in transactions) {
        final oldTransactionId = item['id'];
        final oldSubscriptionId = item['subscription_id'];
        if (oldTransactionId is! int || oldSubscriptionId is! int) continue;
        final newTransactionId = transactionIds[oldTransactionId];
        final newSubscriptionId = subscriptionIds[oldSubscriptionId];
        final chargeDate = item['subscription_charge_date'] as String?;
        if (newTransactionId == null ||
            newSubscriptionId == null ||
            chargeDate == null) {
          continue;
        }
        await txn.update(
          'transactions',
          {
            'subscription_id': newSubscriptionId,
            'subscription_charge_date': chargeDate,
          },
          where: 'id = ?',
          whereArgs: [newTransactionId],
        );
      }

      for (final item in payments) {
        final oldSubscriptionId = item['subscription_id'];
        final oldTransactionId = item['transaction_id'];
        final subscriptionId = oldSubscriptionId is int
            ? subscriptionIds[oldSubscriptionId]
            : null;
        final transactionId = oldTransactionId is int
            ? transactionIds[oldTransactionId]
            : null;
        final amount = (item['amount'] as num?)?.toDouble();
        final dueDate = DateTime.tryParse(item['due_date'] as String? ?? '');
        final paidAt = DateTime.tryParse(item['paid_at'] as String? ?? '');
        final currency = item['currency'] as String?;
        if (subscriptionId == null ||
            transactionId == null ||
            amount == null ||
            amount <= 0 ||
            dueDate == null ||
            paidAt == null ||
            currency == null) {
          continue;
        }
        await txn.insert('subscription_payments', {
          'subscription_id': subscriptionId,
          'amount': amount,
          'currency': currency,
          'due_date': Subscription.dateOnly(dueDate),
          'paid_at': paidAt.toIso8601String(),
          'account_label': item['account_label'] as String? ?? '',
          'transaction_id': transactionId,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      for (final item in transfers) {
        final fromId = item['from_account_id'];
        final toId = item['to_account_id'];
        final fromAccount = fromId is int ? accountIds[fromId] : null;
        final toAccount = toId is int ? accountIds[toId] : null;
        final amount = (item['amount'] as num?)?.toDouble();
        final date = DateTime.tryParse(item['date'] as String? ?? '');
        final currency = item['currency'] as String?;
        if (fromAccount == null ||
            toAccount == null ||
            fromAccount == toAccount ||
            amount == null ||
            amount <= 0 ||
            date == null ||
            currency == null) {
          continue;
        }
        final newTransferId = await txn.insert('account_transfers', {
          'from_account_id': fromAccount,
          'to_account_id': toAccount,
          'amount': amount,
          'currency': currency,
          'date': date.toIso8601String(),
          'description': item['description'] as String? ?? '',
        });
        final oldTransferId = item['id'];
        if (oldTransferId is int) transferIds[oldTransferId] = newTransferId;
      }

      for (final item in scheduledHistory) {
        final oldScheduledId = item['scheduled_payment_id'];
        final scheduledPaymentId = oldScheduledId is int
            ? scheduledPaymentIds[oldScheduledId]
            : null;
        final amount = (item['amount'] as num?)?.toDouble();
        final dueDate = DateTime.tryParse(item['due_date'] as String? ?? '');
        final paidAt = DateTime.tryParse(item['paid_at'] as String? ?? '');
        final currency = item['currency'] as String?;
        final status = item['status'] as String?;
        final oldTransactionId = item['transaction_id'];
        final oldTransferId = item['transfer_id'];
        final transactionId = oldTransactionId is int
            ? transactionIds[oldTransactionId]
            : null;
        final transferId = oldTransferId is int
            ? transferIds[oldTransferId]
            : null;
        if (scheduledPaymentId == null ||
            amount == null ||
            amount <= 0 ||
            dueDate == null ||
            paidAt == null ||
            currency == null ||
            (status != 'paid' && status != 'cancelled')) {
          continue;
        }
        await txn.insert('scheduled_payment_history', {
          'scheduled_payment_id': scheduledPaymentId,
          'amount': amount,
          'currency': currency,
          'due_date': ScheduledPayment.dateOnly(dueDate),
          'paid_at': paidAt.toIso8601String(),
          'status': status,
          'transaction_id': transactionId,
          'transfer_id': transferId,
          'account_id': item['account_id'] is int
              ? accountIds[item['account_id']]
              : null,
          'created_at':
              item['created_at'] as String? ?? DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      for (final item in goalMovements) {
        final oldGoalId = item['goal_id'];
        final goalId = oldGoalId is int ? goalIds[oldGoalId] : null;
        final amount = (item['amount'] as num?)?.toDouble();
        final type = item['type'] as String?;
        final createdAt = DateTime.tryParse(
          item['created_at'] as String? ?? '',
        );
        if (goalId == null ||
            amount == null ||
            amount <= 0 ||
            type == null ||
            createdAt == null) {
          continue;
        }
        await txn.insert('goal_movements', {
          'goal_id': goalId,
          'amount': amount,
          'type': type,
          'created_at': createdAt.toIso8601String(),
        });
      }
      for (final item in goalParticipants) {
        final oldGoalId = item['goal_id'];
        final goalId = oldGoalId is int ? goalIds[oldGoalId] : null;
        final participantId = item['participant_id'] as String?;
        final name = item['name'] as String?;
        final createdAt = DateTime.tryParse(
          item['created_at'] as String? ?? '',
        );
        if (goalId == null ||
            participantId == null ||
            name == null ||
            createdAt == null) {
          continue;
        }
        await txn.insert('goal_participants', {
          'goal_id': goalId,
          'participant_id': participantId,
          'name': name,
          'created_at': createdAt.toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      for (final item in goalContributions) {
        final oldGoalId = item['goal_id'];
        final goalId = oldGoalId is int ? goalIds[oldGoalId] : null;
        final contributionId = item['contribution_id'] as String?;
        final contributor = item['contributor'] as String?;
        final amount = (item['amount'] as num?)?.toDouble();
        final createdAt = DateTime.tryParse(
          item['created_at'] as String? ?? '',
        );
        if (goalId == null ||
            contributionId == null ||
            contributor == null ||
            amount == null ||
            amount <= 0 ||
            createdAt == null) {
          continue;
        }
        await txn.insert('goal_contributions', {
          'goal_id': goalId,
          'contribution_id': contributionId,
          'contributor': contributor,
          'amount': amount,
          'created_at': createdAt.toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      for (final item in shoppingProducts) {
        final oldListId = item['list_id'];
        final listId = oldListId is int ? shoppingListIds[oldListId] : null;
        final name = item['name'] as String?;
        final quantity = (item['quantity'] as num?)?.toDouble();
        final unitPrice = (item['unit_price'] as num?)?.toDouble();
        final subtotal = (item['subtotal'] as num?)?.toDouble();
        if (listId == null ||
            name == null ||
            name.trim().isEmpty ||
            quantity == null ||
            quantity <= 0 ||
            unitPrice == null ||
            unitPrice < 0 ||
            subtotal == null ||
            subtotal < 0) {
          continue;
        }
        await txn.insert('shopping_products', {
          'list_id': listId,
          'name': name.trim(),
          'unit': item['unit'] as String? ?? 'unidad',
          'quantity': quantity,
          'unit_price': unitPrice,
          'price_unit': item['price_unit'] as String? ?? 'unidad',
          'is_purchased': item['is_purchased'] == 1 ? 1 : 0,
          'subtotal': subtotal,
          'note': item['note'] as String? ?? '',
        });
      }
      return importedTransactions;
    });
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

  Future<Database> _initDatabase([String name = 'mova.db']) async {
    final databasePath = await getDatabasesPath();

    final path = join(databasePath, name);

    return await openDatabase(
      path,
      version: 16,
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
        await _createSubscriptionTables(db);
        await _createAccountTables(db);
        await _createScheduledPaymentTables(db);
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
        if (oldVersion < 13) {
          await _addColumnIfMissing(
            db,
            'transactions',
            'subscription_id',
            'INTEGER',
          );
          await _addColumnIfMissing(
            db,
            'transactions',
            'subscription_charge_date',
            'TEXT',
          );
          await _createSubscriptionTables(db);
        }
        if (oldVersion < 14) {
          await _addColumnIfMissing(
            db,
            'transactions',
            'account_id',
            'INTEGER',
          );
          await _addColumnIfMissing(db, 'transactions', 'currency', 'TEXT');
          await _addColumnIfMissing(
            db,
            'subscriptions',
            'account_id',
            'INTEGER',
          );
          await _createAccountTables(db);
        }
        if (oldVersion < 15) {
          await _addColumnIfMissing(
            db,
            'transactions',
            'scheduled_payment_id',
            'INTEGER',
          );
          await _createScheduledPaymentTables(db);
        }
        if (oldVersion < 16) {
          await _addReceiptColumns(db);
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
      await txn.delete('account_transfers');
      await txn.delete('accounts');
      await txn.delete('shopping_products');
      await txn.delete('shopping_lists');
      await txn.delete('subscription_payments');
      await txn.delete('subscriptions');
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
    int? subscriptionId,
    DateTime? subscriptionChargeDate,
    int? accountId,
    String? currency,
    String? receiptImagePath,
    String? receiptItems,
    String? receiptReference,
  }) async {
    final db = await database;
    return db.transaction((txn) async {
      var transactionCurrency = currency;
      if (accountId != null) {
        final accountRows = await txn.query(
          'accounts',
          where: 'id = ? AND is_active = 1',
          whereArgs: [accountId],
          limit: 1,
        );
        if (accountRows.isEmpty) {
          throw StateError('La cuenta seleccionada no está activa.');
        }
        final account = FinancialAccount.fromMap(accountRows.first);
        transactionCurrency ??= account.currency;
        if (transactionCurrency != account.currency) {
          throw StateError(
            'El movimiento debe usar la moneda de la cuenta seleccionada.',
          );
        }
        if (account.type == FinancialAccountType.creditCard) {
          if (isIncome) {
            throw StateError(
              'Los ingresos no se pueden registrar en una tarjeta de crédito.',
            );
          }
          final limit = account.creditLimit;
          if (limit != null && amount > account.availableCredit) {
            throw StateError('El movimiento supera el crédito disponible.');
          }
        }
      }

      return txn.insert('transactions', {
        'amount': amount,
        'is_income': isIncome ? 1 : 0,
        'category': category,
        'description': description,
        'date': date.toIso8601String(),
        'note': note,
        'subscription_id': subscriptionId,
        'subscription_charge_date': subscriptionChargeDate == null
            ? null
            : Subscription.dateOnly(subscriptionChargeDate),
        'account_id': accountId,
        'currency': transactionCurrency,
        'receipt_image_path': receiptImagePath,
        'receipt_items': receiptItems,
        'receipt_reference': receiptReference,
      });
    });
  }

  Future<List<Map<String, dynamic>>> findPossibleDuplicateReceipts({
    required double amount,
    required DateTime date,
    required String merchant,
    String? reference,
  }) async {
    final db = await database;
    final dateOnly = date.toIso8601String().substring(0, 10);
    final rows = await db.query(
      'transactions',
      where: 'is_income = 0 AND date LIKE ? AND ABS(amount - ?) < 0.011',
      whereArgs: ['$dateOnly%', amount],
      orderBy: 'id DESC',
    );
    final normalizedMerchant = merchant.trim().toLowerCase();
    final normalizedReference = reference?.trim().toLowerCase();
    return rows.where((row) {
      final description = (row['description'] as String? ?? '')
          .trim()
          .toLowerCase();
      final note = (row['note'] as String? ?? '').trim().toLowerCase();
      final storedReference = (row['receipt_reference'] as String? ?? '')
          .trim()
          .toLowerCase();
      if (normalizedReference != null &&
          normalizedReference.isNotEmpty &&
          storedReference == normalizedReference) {
        return true;
      }
      return normalizedMerchant.isNotEmpty &&
          (description == normalizedMerchant ||
              description.contains(normalizedMerchant) ||
              normalizedMerchant.contains(description) ||
              note.contains(normalizedMerchant));
    }).toList();
  }

  Future<void> attachReceiptToTransaction({
    required int transactionId,
    required double amount,
    required DateTime date,
    required String imagePath,
    required String items,
    String? reference,
  }) async {
    if (imagePath.trim().isEmpty) {
      throw ArgumentError('La ruta del comprobante es obligatoria.');
    }
    final db = await database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'transactions',
        where: 'id = ? AND is_income = 0',
        whereArgs: [transactionId],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw StateError(
          'No se encontró el gasto para asociar el comprobante.',
        );
      }
      final row = rows.first;
      final storedDate = DateTime.tryParse(row['date'] as String? ?? '');
      if (((row['amount'] as num).toDouble() - amount).abs() >= 0.011 ||
          storedDate == null ||
          storedDate.year != date.year ||
          storedDate.month != date.month ||
          storedDate.day != date.day) {
        throw StateError(
          'El importe o la fecha ya no coinciden con el gasto seleccionado.',
        );
      }
      if ((row['receipt_image_path'] as String?)?.isNotEmpty == true) {
        throw StateError('El gasto seleccionado ya tiene un comprobante.');
      }
      await txn.update(
        'transactions',
        {
          'receipt_image_path': imagePath,
          'receipt_items': items,
          'receipt_reference': reference,
        },
        where: 'id = ?',
        whereArgs: [transactionId],
      );
    });
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    final db = await database;
    return db.query('transactions', orderBy: 'date DESC, id DESC');
  }

  Future<List<Map<String, dynamic>>> getTransactionsInPeriod({
    required DateTime from,
    required DateTime to,
  }) async {
    if (!from.isBefore(to)) {
      throw ArgumentError.value(to, 'to', 'Must be after from.');
    }
    final db = await database;
    return db.query(
      'transactions',
      where: 'date >= ? AND date < ?',
      whereArgs: [_dateOnly(from), _dateOnly(to)],
      orderBy: 'date DESC, id DESC',
    );
  }

  Future<List<Map<String, Object?>>> getRecentFinancialMovements({
    int limit = 20,
  }) async {
    if (limit < 1) {
      throw ArgumentError.value(limit, 'limit', 'Must be positive.');
    }
    final db = await database;
    return db.rawQuery(
      '''
      SELECT id, amount, is_income, category, description, date, currency,
        account_id, NULL AS target_account_id,
        'transaction' AS movement_type
      FROM transactions
      UNION ALL
      SELECT id, amount, NULL AS is_income, 'Transferencia' AS category,
        description, date, currency, from_account_id AS account_id,
        to_account_id AS target_account_id,
        'account_transfer' AS movement_type
      FROM account_transfers
      ORDER BY date DESC, id DESC
      LIMIT ?
      ''',
      [limit],
    );
  }

  Future<int> createFinancialAccount(FinancialAccount account) async {
    if (account.name.trim().isEmpty) {
      throw ArgumentError('El nombre de la cuenta es obligatorio.');
    }
    if (account.initialBalance < 0 ||
        (account.type == FinancialAccountType.creditCard &&
            account.creditLimit != null &&
            (account.creditLimit! <= 0 ||
                account.initialBalance > account.creditLimit!))) {
      throw ArgumentError('Revisa el saldo inicial y el límite de crédito.');
    }
    return (await database).insert('accounts', {
      ...account.toDatabaseMap(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateFinancialAccount(FinancialAccount account) async {
    if (account.name.trim().isEmpty || account.initialBalance < 0) {
      throw ArgumentError('Revisa el nombre y el saldo inicial.');
    }
    final current = await getFinancialAccount(account.id);
    if (current == null) throw StateError('La cuenta ya no existe.');
    if (account.type != current.type || account.currency != current.currency) {
      final activity = await getFinancialAccountActivity(account.id);
      if (activity.isNotEmpty) {
        throw StateError(
          'No se puede cambiar el tipo o la moneda de una cuenta con movimientos.',
        );
      }
    }
    if (account.type == FinancialAccountType.creditCard &&
        account.creditLimit != null &&
        (account.creditLimit! <= 0 || account.creditLimit! < current.balance)) {
      throw ArgumentError('El límite de crédito debe cubrir la deuda actual.');
    }
    await (await database).update(
      'accounts',
      account.toDatabaseMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<void> setFinancialAccountActive(int id, bool active) async {
    await (await database).update(
      'accounts',
      {'is_active': active ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<FinancialAccount?> getFinancialAccount(int id) async {
    final db = await database;
    final rows = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return FinancialAccount.fromMap({
      ...rows.first,
      'balance': await _calculateFinancialAccountBalance(
        db,
        rows.first['id'] as int,
        rows.first['type'] as String,
        (rows.first['initial_balance'] as num).toDouble(),
        rows.first['currency'] as String,
      ),
    });
  }

  Future<List<FinancialAccount>> getFinancialAccounts({
    bool includeInactive = true,
  }) async {
    final rows = await (await database).query(
      'accounts',
      where: includeInactive ? null : 'is_active = 1',
      orderBy: 'is_active DESC, type ASC, name COLLATE NOCASE ASC',
    );
    final accounts = <FinancialAccount>[];
    for (final row in rows) {
      accounts.add(
        FinancialAccount.fromMap({
          ...row,
          'balance': await _calculateFinancialAccountBalance(
            await database,
            row['id'] as int,
            row['type'] as String,
            (row['initial_balance'] as num).toDouble(),
            row['currency'] as String,
          ),
        }),
      );
    }
    return accounts;
  }

  Future<double> _calculateFinancialAccountBalance(
    DatabaseExecutor db,
    int accountId,
    String type,
    double initialBalance,
    String currency,
  ) async {
    final transactions = await db.query(
      'transactions',
      columns: ['amount', 'is_income', 'category'],
      where: 'account_id = ? AND (currency IS NULL OR currency = ?)',
      whereArgs: [accountId, currency],
    );
    var balance = initialBalance;
    for (final transaction in transactions) {
      final category = transaction['category'] as String;
      if (_isSavingsAllocationCategory(category)) continue;
      final amount = (transaction['amount'] as num).toDouble();
      final isIncome = transaction['is_income'] == 1;
      if (type == FinancialAccountType.creditCard.name) {
        balance += isIncome ? -amount : amount;
      } else {
        balance += isIncome ? amount : -amount;
      }
    }
    final transfers = await db.query(
      'account_transfers',
      columns: ['from_account_id', 'to_account_id', 'amount'],
      where: '(from_account_id = ? OR to_account_id = ?) AND currency = ?',
      whereArgs: [accountId, accountId, currency],
    );
    for (final transfer in transfers) {
      final amount = (transfer['amount'] as num).toDouble();
      if (transfer['from_account_id'] == accountId) {
        balance -= amount;
      } else if (type == FinancialAccountType.creditCard.name) {
        balance -= amount;
      } else {
        balance += amount;
      }
    }
    return balance;
  }

  bool _isSavingsAllocationCategory(String category) =>
      savingsDepositCategories.contains(category) ||
      savingsWithdrawalCategories.contains(category);

  String _dateOnly(DateTime date) => DateTime(
    date.year,
    date.month,
    date.day,
  ).toIso8601String().substring(0, 10);

  Future<List<Map<String, Object?>>> getFinancialAccountActivity(
    int accountId,
  ) async {
    final db = await database;
    final transactions = await db.rawQuery(
      '''
      SELECT t.*, 'transaction' AS activity_type
      FROM transactions t
      WHERE t.account_id = ?
      ORDER BY t.date DESC, t.id DESC
      ''',
      [accountId],
    );
    final transfers = await db.rawQuery(
      '''
      SELECT tr.*, fa.name AS from_name, ta.name AS to_name,
        'transfer' AS activity_type
      FROM account_transfers tr
      JOIN accounts fa ON fa.id = tr.from_account_id
      JOIN accounts ta ON ta.id = tr.to_account_id
      WHERE tr.from_account_id = ? OR tr.to_account_id = ?
      ORDER BY tr.date DESC, tr.id DESC
      ''',
      [accountId, accountId],
    );
    final activity = [...transactions, ...transfers];
    activity.sort((a, b) {
      final dateA = DateTime.tryParse(
        a['date'] as String? ?? a['paid_at'] as String? ?? '',
      );
      final dateB = DateTime.tryParse(
        b['date'] as String? ?? b['paid_at'] as String? ?? '',
      );
      if (dateA == null || dateB == null) return 0;
      return dateB.compareTo(dateA);
    });
    return activity;
  }

  Future<void> transferBetweenAccounts({
    required int fromAccountId,
    required int toAccountId,
    required double amount,
    required DateTime date,
    String description = '',
  }) async {
    if (fromAccountId == toAccountId || amount <= 0) {
      throw ArgumentError('Selecciona cuentas distintas y un importe válido.');
    }
    final db = await database;
    await db.transaction((txn) async {
      final fromRows = await txn.query(
        'accounts',
        where: 'id = ? AND is_active = 1',
        whereArgs: [fromAccountId],
        limit: 1,
      );
      final toRows = await txn.query(
        'accounts',
        where: 'id = ? AND is_active = 1',
        whereArgs: [toAccountId],
        limit: 1,
      );
      if (fromRows.isEmpty || toRows.isEmpty) {
        throw StateError('Ambas cuentas deben estar activas.');
      }
      final from = FinancialAccount.fromMap({
        ...fromRows.first,
        'balance': await _calculateFinancialAccountBalance(
          txn,
          fromAccountId,
          fromRows.first['type'] as String,
          (fromRows.first['initial_balance'] as num).toDouble(),
          fromRows.first['currency'] as String,
        ),
      });
      final to = FinancialAccount.fromMap({
        ...toRows.first,
        'balance': await _calculateFinancialAccountBalance(
          txn,
          toAccountId,
          toRows.first['type'] as String,
          (toRows.first['initial_balance'] as num).toDouble(),
          toRows.first['currency'] as String,
        ),
      });
      if (from.type == FinancialAccountType.creditCard) {
        throw StateError('No se puede transferir dinero desde una tarjeta.');
      }
      if (from.currency != to.currency) {
        throw StateError(
          'Las cuentas deben tener la misma moneda; MOVA no convierte divisas.',
        );
      }
      if (amount > from.balance) {
        throw StateError('La cuenta origen no tiene saldo suficiente.');
      }
      if (to.type == FinancialAccountType.creditCard && amount > to.balance) {
        throw StateError('El pago supera la deuda actual de la tarjeta.');
      }
      await txn.insert('account_transfers', {
        'from_account_id': fromAccountId,
        'to_account_id': toAccountId,
        'amount': amount,
        'currency': from.currency,
        'date': date.toIso8601String(),
        'description': description.trim(),
      });
    });
  }

  Future<Map<String, Map<String, double>>> getFinancialOverview({
    required String homeCurrency,
    bool includeUnassignedTransactions = false,
  }) async {
    final accounts = await getFinancialAccounts(includeInactive: false);
    final assets = <String, double>{};
    final debts = <String, double>{};
    for (final account in accounts) {
      if (account.type == FinancialAccountType.creditCard) {
        debts.update(
          account.currency,
          (value) => value + account.balance,
          ifAbsent: () => account.balance,
        );
      } else {
        assets.update(
          account.currency,
          (value) => value + account.balance,
          ifAbsent: () => account.balance,
        );
      }
    }
    if (includeUnassignedTransactions) {
      final unassignedTransactions = await (await database).query(
        'transactions',
        columns: const ['amount', 'is_income', 'category', 'currency'],
        where: 'account_id IS NULL',
      );
      for (final transaction in unassignedTransactions) {
        final category = transaction['category'] as String;
        if (_isSavingsAllocationCategory(category)) continue;
        final currency = transaction['currency'] as String? ?? homeCurrency;
        final amount = (transaction['amount'] as num).toDouble();
        final signedAmount = transaction['is_income'] == 1 ? amount : -amount;
        assets.update(
          currency,
          (value) => value + signedAmount,
          ifAbsent: () => signedAmount,
        );
      }
    }
    final goals = await getGoals();
    final allocatedToGoals = goals.fold<double>(
      0,
      (total, goal) => total + (goal['saved_amount'] as num).toDouble(),
    );
    final savings = await getUnassignedSavings();
    final allocated = <String, double>{};
    final generalSavings = <String, double>{};
    final goalSavings = <String, double>{};
    if (savings + allocatedToGoals != 0) {
      allocated[homeCurrency] = savings + allocatedToGoals;
    }
    if (savings != 0) generalSavings[homeCurrency] = savings;
    if (allocatedToGoals != 0) goalSavings[homeCurrency] = allocatedToGoals;
    final available = Map<String, double>.from(assets);
    for (final entry in allocated.entries) {
      available.update(
        entry.key,
        (value) => value - entry.value,
        ifAbsent: () => -entry.value,
      );
    }
    return {
      'assets': assets,
      'allocated_savings': allocated,
      'general_savings': generalSavings,
      'goal_allocations': goalSavings,
      'available': available,
      'credit_debt': debts,
    };
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

  Future<int> createSubscription(Subscription subscription) async {
    final db = await database;
    if (subscription.accountId != null) {
      final account = await getFinancialAccount(subscription.accountId!);
      if (account == null ||
          !account.isActive ||
          account.currency != subscription.currency) {
        throw StateError(
          'La cuenta asociada debe estar activa y usar la moneda seleccionada.',
        );
      }
    }
    return db.insert('subscriptions', {
      ...subscription.toDatabaseMap(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Subscription?> getSubscription(int id) async {
    final rows = await (await database).query(
      'subscriptions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Subscription.fromMap(rows.first);
  }

  Future<List<Subscription>> getSubscriptions({
    SubscriptionStatus? status,
  }) async {
    final rows = await (await database).query(
      'subscriptions',
      where: status == null ? null : 'status = ?',
      whereArgs: status == null ? null : [status.name],
      orderBy: 'CASE status WHEN \'active\' THEN 0 WHEN \'paused\' THEN 1 ELSE 2 END, next_charge_date ASC, name COLLATE NOCASE ASC',
    );
    return rows.map(Subscription.fromMap).toList(growable: false);
  }

  Future<void> updateSubscription(Subscription subscription) async {
    if (subscription.accountId != null) {
      final account = await getFinancialAccount(subscription.accountId!);
      if (account == null ||
          !account.isActive ||
          account.currency != subscription.currency) {
        throw StateError(
          'La cuenta asociada debe estar activa y usar la moneda seleccionada.',
        );
      }
    }
    final values = subscription.toDatabaseMap();
    values['updated_at'] = DateTime.now().toIso8601String();
    await (await database).update(
      'subscriptions',
      values,
      where: 'id = ?',
      whereArgs: [subscription.id],
    );
  }

  Future<void> setSubscriptionStatus(int id, SubscriptionStatus status) async {
    await (await database).update(
      'subscriptions',
      {'status': status.name, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteSubscription(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'subscription_payments',
        where: 'subscription_id = ?',
        whereArgs: [id],
      );
      await txn.update(
        'transactions',
        {'subscription_id': null, 'subscription_charge_date': null},
        where: 'subscription_id = ?',
        whereArgs: [id],
      );
      await txn.delete('subscriptions', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<Subscription>> getUpcomingSubscriptions({
    DateTime? from,
    int days = 30,
  }) async {
    final start = DateTime(
      from?.year ?? DateTime.now().year,
      from?.month ?? DateTime.now().month,
      from?.day ?? DateTime.now().day,
    );
    final end = start.add(Duration(days: days));
    final rows = await (await database).query(
      'subscriptions',
      where: 'status = ? AND next_charge_date >= ? AND next_charge_date < ?',
      whereArgs: [
        SubscriptionStatus.active.name,
        Subscription.dateOnly(start),
        Subscription.dateOnly(end),
      ],
      orderBy: 'next_charge_date ASC, name COLLATE NOCASE ASC',
    );
    return rows.map(Subscription.fromMap).toList(growable: false);
  }

  Future<void> _validateScheduledPaymentAccounts(
    DatabaseExecutor executor,
    ScheduledPayment payment,
  ) async {
    if (payment.type == ScheduledPaymentType.recurring &&
        payment.frequency == null) {
      throw ArgumentError('Selecciona una frecuencia válida.');
    }
    if (payment.type == ScheduledPaymentType.oneTime &&
        payment.frequency != null) {
      throw ArgumentError('Un pago único no debe tener frecuencia.');
    }
    if (payment.reminderDays != 0 &&
        payment.reminderDays != 1 &&
        payment.reminderDays != 3 &&
        payment.reminderDays != 7) {
      throw ArgumentError('Selecciona un recordatorio válido.');
    }
    if (payment.name.trim().isEmpty ||
        payment.amount <= 0 ||
        payment.currency.trim().isEmpty) {
      throw ArgumentError('Revisa el nombre y el importe del pago.');
    }
    if (payment.type != ScheduledPaymentType.cardPayment &&
        (payment.category == null || payment.category!.trim().isEmpty)) {
      throw ArgumentError('Selecciona una categoría para este pago.');
    }

    if (payment.accountId != null) {
      final rows = await executor.query(
        'accounts',
        where: 'id = ? AND is_active = 1',
        whereArgs: [payment.accountId],
        limit: 1,
      );
      if (rows.isEmpty || rows.first['currency'] != payment.currency) {
        throw StateError(
          'La cuenta debe estar activa y usar la moneda del pago.',
        );
      }
      if (payment.type != ScheduledPaymentType.cardPayment &&
          rows.first['type'] == FinancialAccountType.creditCard.name) {
        throw StateError('Elige una cuenta de débito para pagar este gasto.');
      }
    }

    if (payment.type == ScheduledPaymentType.cardPayment) {
      if (payment.targetAccountId == null ||
          payment.targetAccountId == payment.accountId) {
        throw ArgumentError('Selecciona la tarjeta que vas a pagar.');
      }
      final rows = await executor.query(
        'accounts',
        where: 'id = ? AND is_active = 1 AND type = ?',
        whereArgs: [
          payment.targetAccountId,
          FinancialAccountType.creditCard.name,
        ],
        limit: 1,
      );
      if (rows.isEmpty || rows.first['currency'] != payment.currency) {
        throw StateError(
          'La tarjeta debe estar activa y usar la moneda del pago.',
        );
      }
    } else if (payment.targetAccountId != null) {
      throw ArgumentError(
        'Sólo los pagos de tarjeta llevan una tarjeta destino.',
      );
    }
  }

  Future<int> createScheduledPayment(ScheduledPayment payment) async {
    final db = await database;
    await _validateScheduledPaymentAccounts(db, payment);
    return db.insert('scheduled_payments', {
      ...payment.toDatabaseMap(),
      'status': ScheduledPaymentStatus.active.name,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateScheduledPayment(ScheduledPayment payment) async {
    final db = await database;
    await _validateScheduledPaymentAccounts(db, payment);
    final current = await getScheduledPayment(payment.id);
    if (current == null) throw StateError('El pago programado ya no existe.');
    final history = await db.query(
      'scheduled_payment_history',
      columns: ['id'],
      where: 'scheduled_payment_id = ?',
      whereArgs: [payment.id],
      limit: 1,
    );
    if (history.isNotEmpty &&
        (current.type != payment.type ||
            current.currency != payment.currency ||
            current.frequency != payment.frequency)) {
      throw StateError(
        'No se puede cambiar el tipo, moneda o frecuencia después de registrar pagos.',
      );
    }
    await db.update(
      'scheduled_payments',
      payment.toDatabaseMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  Future<ScheduledPayment?> getScheduledPayment(int id) async {
    final rows = await (await database).query(
      'scheduled_payments',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : ScheduledPayment.fromMap(rows.first);
  }

  Future<List<ScheduledPayment>> getScheduledPayments({
    bool includeCancelled = false,
  }) async {
    final rows = await (await database).query(
      'scheduled_payments',
      where: includeCancelled ? null : 'status = ?',
      whereArgs: includeCancelled ? null : [ScheduledPaymentStatus.active.name],
      orderBy: 'due_date ASC, name COLLATE NOCASE ASC',
    );
    return rows.map(ScheduledPayment.fromMap).toList(growable: false);
  }

  Future<void> cancelScheduledPayment(int id) async {
    final updated = await (await database).update(
      'scheduled_payments',
      {'status': ScheduledPaymentStatus.cancelled.name},
      where: 'id = ? AND status = ?',
      whereArgs: [id, ScheduledPaymentStatus.active.name],
    );
    if (updated == 0) {
      throw StateError('El pago ya no está pendiente.');
    }
  }

  Future<int?> findPotentialDuplicateScheduledPaymentExpense(int id) async {
    final payment = await getScheduledPayment(id);
    if (payment == null ||
        payment.type == ScheduledPaymentType.cardPayment ||
        payment.category == null) {
      return null;
    }
    final due = ScheduledPayment.dateOnly(payment.dueDate);
    final accountCondition = payment.accountId == null
        ? 'account_id IS NULL'
        : '(account_id = ? OR account_id IS NULL)';
    final args = <Object?>[
      payment.category,
      payment.amount,
      if (payment.accountId != null) payment.accountId,
      due,
      ScheduledPayment.dateOnly(payment.dueDate.add(const Duration(days: 1))),
    ];
    final rows = await (await database).query(
      'transactions',
      columns: ['id'],
      where:
          '''
        is_income = 0 AND subscription_id IS NULL
        AND scheduled_payment_id IS NULL AND category = ?
        AND ABS(amount - ?) < 0.005
        AND $accountCondition AND date >= ? AND date < ?
      ''',
      whereArgs: args,
      orderBy: 'id DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['id'] as int;
  }

  Future<void> recordScheduledPayment({
    required int id,
    required DateTime expectedDueDate,
    int? existingTransactionId,
    int? accountId,
    DateTime? paidAt,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'scheduled_payments',
        where: 'id = ? AND status = ?',
        whereArgs: [id, ScheduledPaymentStatus.active.name],
        limit: 1,
      );
      if (rows.isEmpty) throw StateError('El pago no está pendiente.');
      final payment = ScheduledPayment.fromMap(rows.first);
      final due = ScheduledPayment.dateOnly(payment.dueDate);
      if (due != ScheduledPayment.dateOnly(expectedDueDate)) {
        throw StateError('El próximo pago ya fue actualizado.');
      }
      final alreadyPaid = await txn.query(
        'scheduled_payment_history',
        columns: ['id'],
        where: 'scheduled_payment_id = ? AND due_date = ?',
        whereArgs: [id, due],
        limit: 1,
      );
      if (alreadyPaid.isNotEmpty) {
        throw StateError('Este pago ya fue registrado.');
      }
      final paymentDate = paidAt ?? DateTime.now();
      final sourceAccountId = accountId ?? payment.accountId;
      int? transactionId;
      int? transferId;

      if (payment.type == ScheduledPaymentType.cardPayment) {
        if (sourceAccountId == null) {
          throw StateError('Selecciona la cuenta desde la que se pagará.');
        }
        final accounts = await txn.query(
          'accounts',
          where: 'id IN (?, ?) AND is_active = 1',
          whereArgs: [sourceAccountId, payment.targetAccountId],
        );
        if (accounts.length != 2) {
          throw StateError('La cuenta y la tarjeta deben estar activas.');
        }
        final sourceRow = accounts.firstWhere(
          (row) => row['id'] == sourceAccountId,
        );
        final targetRow = accounts.firstWhere(
          (row) => row['id'] == payment.targetAccountId,
        );
        if (sourceRow['type'] == FinancialAccountType.creditCard.name ||
            targetRow['type'] != FinancialAccountType.creditCard.name ||
            sourceRow['currency'] != payment.currency ||
            targetRow['currency'] != payment.currency) {
          throw StateError('La cuenta y la tarjeta no son compatibles.');
        }
        final sourceBalance = await _calculateFinancialAccountBalance(
          txn,
          sourceAccountId,
          sourceRow['type'] as String,
          (sourceRow['initial_balance'] as num).toDouble(),
          payment.currency,
        );
        final cardDebt = await _calculateFinancialAccountBalance(
          txn,
          payment.targetAccountId!,
          targetRow['type'] as String,
          (targetRow['initial_balance'] as num).toDouble(),
          payment.currency,
        );
        if (sourceBalance < payment.amount || cardDebt < payment.amount) {
          throw StateError(
            'Verifica el saldo disponible y la deuda actual de la tarjeta.',
          );
        }
        transferId = await txn.insert('account_transfers', {
          'from_account_id': sourceAccountId,
          'to_account_id': payment.targetAccountId,
          'amount': payment.amount,
          'currency': payment.currency,
          'date': paymentDate.toIso8601String(),
          'description': 'Pago de tarjeta: ${payment.name}',
        });
      } else {
        if (sourceAccountId != null) {
          final accountRows = await txn.query(
            'accounts',
            where: 'id = ? AND is_active = 1',
            whereArgs: [sourceAccountId],
            limit: 1,
          );
          if (accountRows.isEmpty ||
              accountRows.first['type'] ==
                  FinancialAccountType.creditCard.name ||
              accountRows.first['currency'] != payment.currency) {
            throw StateError(
              'La cuenta de pago debe estar activa y usar la moneda correcta.',
            );
          }
        }
        if (existingTransactionId != null) {
          final category = payment.category!;
          final accountCondition = sourceAccountId == null
              ? 'account_id IS NULL'
              : '(account_id = ? OR account_id IS NULL)';
          final args = <Object?>[
            existingTransactionId,
            category,
            payment.amount,
            ?sourceAccountId,
            due,
            ScheduledPayment.dateOnly(
              payment.dueDate.add(const Duration(days: 1)),
            ),
          ];
          final matching = await txn.query(
            'transactions',
            columns: ['id', 'account_id'],
            where:
                '''
              id = ? AND is_income = 0 AND subscription_id IS NULL
              AND scheduled_payment_id IS NULL AND category = ?
              AND ABS(amount - ?) < 0.005
              AND $accountCondition AND date >= ? AND date < ?
            ''',
            whereArgs: args,
            limit: 1,
          );
          if (matching.isEmpty) {
            throw StateError('El movimiento no coincide con este pago.');
          }
          transactionId = existingTransactionId;
          final movementAccountId = matching.first['account_id'] as int?;
          if (movementAccountId == null && sourceAccountId != null) {
            await txn.update(
              'transactions',
              {'account_id': sourceAccountId, 'currency': payment.currency},
              where: 'id = ?',
              whereArgs: [existingTransactionId],
            );
          }
          await txn.update(
            'transactions',
            {'scheduled_payment_id': id},
            where: 'id = ?',
            whereArgs: [existingTransactionId],
          );
        } else {
          transactionId = await txn.insert('transactions', {
            'amount': payment.amount,
            'is_income': 0,
            'category': payment.category,
            'description': payment.name,
            'date': paymentDate.toIso8601String(),
            'note': payment.notes,
            'subscription_id': null,
            'subscription_charge_date': null,
            'account_id': sourceAccountId,
            'currency': payment.currency,
            'scheduled_payment_id': id,
          });
        }
      }

      await txn.insert('scheduled_payment_history', {
        'scheduled_payment_id': id,
        'amount': payment.amount,
        'currency': payment.currency,
        'due_date': due,
        'paid_at': paymentDate.toIso8601String(),
        'status': 'paid',
        'transaction_id': transactionId,
        'transfer_id': transferId,
        'account_id': sourceAccountId,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (payment.frequency == null) {
        await txn.update(
          'scheduled_payments',
          {'status': ScheduledPaymentStatus.completed.name},
          where: 'id = ?',
          whereArgs: [id],
        );
      } else {
        await txn.update(
          'scheduled_payments',
          {
            'due_date': ScheduledPayment.dateOnly(
              ScheduledPayment.nextFutureDate(
                payment.dueDate,
                payment.frequency!,
                after: paymentDate,
              ),
            ),
            'account_id': sourceAccountId,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    });
  }

  Future<List<Map<String, Object?>>> getScheduledPaymentHistory() async =>
      (await database).rawQuery('''
        SELECT h.*, p.name, p.payment_type, p.category, p.frequency,
          a.name AS account_name, ca.name AS card_name,
          t.description AS transaction_description
        FROM scheduled_payment_history h
        JOIN scheduled_payments p ON p.id = h.scheduled_payment_id
        LEFT JOIN accounts a ON a.id = h.account_id
        LEFT JOIN accounts ca ON ca.id = p.target_account_id
        LEFT JOIN transactions t ON t.id = h.transaction_id
        ORDER BY h.paid_at DESC, h.id DESC
      ''');

  Future<double> getSubscriptionMonthlySpend({String? currency}) async {
    final rows = await (await database).rawQuery(
      '''
      SELECT COALESCE(SUM(amount * CASE frequency
        WHEN 'weekly' THEN 52.0 / 12
        WHEN 'biweekly' THEN 26.0 / 12
        WHEN 'monthly' THEN 1
        WHEN 'bimonthly' THEN 1.0 / 2
        WHEN 'quarterly' THEN 1.0 / 3
        WHEN 'semiannual' THEN 1.0 / 6
        WHEN 'annual' THEN 1.0 / 12
        ELSE 0 END), 0) AS total
      FROM subscriptions
      WHERE status = ? ${currency == null ? '' : 'AND currency = ?'}
      ''',
      currency == null
          ? [SubscriptionStatus.active.name]
          : [SubscriptionStatus.active.name, currency],
    );
    return (rows.first['total'] as num).toDouble();
  }

  Future<Map<String, double>> getSubscriptionMonthlySpendByCurrency() async {
    final rows = await (await database).rawQuery(
      '''
      SELECT currency, COALESCE(SUM(amount * CASE frequency
        WHEN 'weekly' THEN 52.0 / 12
        WHEN 'biweekly' THEN 26.0 / 12
        WHEN 'monthly' THEN 1
        WHEN 'bimonthly' THEN 1.0 / 2
        WHEN 'quarterly' THEN 1.0 / 3
        WHEN 'semiannual' THEN 1.0 / 6
        WHEN 'annual' THEN 1.0 / 12
        ELSE 0 END), 0) AS total
      FROM subscriptions
      WHERE status = ?
      GROUP BY currency
      ORDER BY currency
    ''',
      [SubscriptionStatus.active.name],
    );
    return {
      for (final row in rows)
        row['currency'] as String: (row['total'] as num).toDouble(),
    };
  }

  Future<double> getSubscriptionAnnualSpend({String? currency}) async =>
      (await getSubscriptionMonthlySpend(currency: currency)) * 12;

  Future<int?> findPotentialDuplicateSubscriptionExpense(int id) async {
    final subscription = await getSubscription(id);
    if (subscription == null) return null;
    final date = Subscription.dateOnly(subscription.nextChargeDate);
    final accountCondition = subscription.accountId == null
        ? 'account_id IS NULL'
        : '(account_id = ? OR account_id IS NULL)';
    final whereArgs = <Object?>[
      subscription.category,
      subscription.amount,
      if (subscription.accountId != null) subscription.accountId,
      date,
      Subscription.dateOnly(
        subscription.nextChargeDate.add(const Duration(days: 1)),
      ),
    ];
    final rows = await (await database).query(
      'transactions',
      columns: ['id'],
      where:
          '''
        is_income = 0 AND subscription_id IS NULL AND category = ?
        AND ABS(amount - ?) < 0.005
        AND $accountCondition
        AND date >= ? AND date < ?
      ''',
      whereArgs: whereArgs,
      orderBy: 'id DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['id'] as int;
  }

  Future<void> recordSubscriptionPayment(
    int id, {
    required DateTime expectedChargeDate,
    int? existingTransactionId,
    DateTime? paidAt,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'subscriptions',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) throw StateError('La suscripción ya no existe.');
      final subscription = Subscription.fromMap(rows.first);
      if (subscription.status != SubscriptionStatus.active) {
        throw StateError('Solo se pueden pagar suscripciones activas.');
      }

      final dueDate = Subscription.dateOnly(subscription.nextChargeDate);
      if (dueDate != Subscription.dateOnly(expectedChargeDate)) {
        throw StateError('El próximo cobro ya fue actualizado.');
      }
      final paymentDate = paidAt ?? DateTime.now();
      if (subscription.accountId != null) {
        final accountRows = await txn.query(
          'accounts',
          where: 'id = ? AND is_active = 1',
          whereArgs: [subscription.accountId],
          limit: 1,
        );
        if (accountRows.isEmpty ||
            accountRows.first['currency'] != subscription.currency) {
          throw StateError(
            'La cuenta asociada debe estar activa y usar la moneda de la suscripción.',
          );
        }
        if (accountRows.first['type'] == FinancialAccountType.creditCard.name) {
          final balance = await _calculateFinancialAccountBalance(
            txn,
            subscription.accountId!,
            accountRows.first['type'] as String,
            (accountRows.first['initial_balance'] as num).toDouble(),
            accountRows.first['currency'] as String,
          );
          final limit =
              (accountRows.first['credit_limit'] as num?)?.toDouble() ?? 0;
          if (subscription.amount > limit - balance) {
            throw StateError('El cobro supera el crédito disponible.');
          }
        }
      }
      final transactionId =
          existingTransactionId ??
          await txn.insert('transactions', {
            'amount': subscription.amount,
            'is_income': 0,
            'category': subscription.category,
            'description': 'Suscripción: ${subscription.name}',
            'date': paymentDate.toIso8601String(),
            'note': subscription.accountLabel.isEmpty
                ? subscription.notes
                : subscription.accountLabel,
            'subscription_id': id,
            'subscription_charge_date': dueDate,
            'account_id': subscription.accountId,
            'currency': subscription.currency,
          });

      if (existingTransactionId != null) {
        final accountCondition = subscription.accountId == null
            ? 'account_id IS NULL'
            : '(account_id = ? OR account_id IS NULL)';
        final matchingArgs = <Object?>[
          existingTransactionId,
          subscription.category,
          subscription.amount,
          if (subscription.accountId != null) subscription.accountId,
          dueDate,
          Subscription.dateOnly(
            subscription.nextChargeDate.add(const Duration(days: 1)),
          ),
        ];
        final matchingRows = await txn.query(
          'transactions',
          columns: ['id'],
          where:
              '''
            id = ? AND is_income = 0 AND subscription_id IS NULL
            AND category = ? AND ABS(amount - ?) < 0.005
            AND $accountCondition
            AND date >= ? AND date < ?
          ''',
          whereArgs: matchingArgs,
          limit: 1,
        );
        if (matchingRows.isEmpty) {
          throw StateError('El movimiento no coincide con este cobro.');
        }
        await txn.update(
          'transactions',
          {
            'subscription_id': id,
            'subscription_charge_date': dueDate,
            'account_id': subscription.accountId,
            'currency': subscription.currency,
          },
          where: 'id = ?',
          whereArgs: [existingTransactionId],
        );
      }

      await txn.insert('subscription_payments', {
        'subscription_id': id,
        'amount': subscription.amount,
        'currency': subscription.currency,
        'due_date': dueDate,
        'paid_at': paymentDate.toIso8601String(),
        'account_label': subscription.accountLabel,
        'transaction_id': transactionId,
      });

      await txn.update(
        'subscriptions',
        {
          'next_charge_date': Subscription.dateOnly(
            Subscription.nextFutureDate(
              subscription.nextChargeDate,
              subscription.frequency,
              after: paymentDate,
              billingDay: subscription.billingDay,
            ),
          ),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<List<Map<String, Object?>>> getSubscriptionHistory(int id) async {
    return (await database).rawQuery(
      '''
      SELECT p.*, t.description, t.category
      FROM subscription_payments p
      JOIN transactions t ON t.id = p.transaction_id
      WHERE p.subscription_id = ?
      ORDER BY p.paid_at DESC, p.id DESC
    ''',
      [id],
    );
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
        note TEXT NOT NULL DEFAULT '',
        subscription_id INTEGER,
        subscription_charge_date TEXT,
        account_id INTEGER,
        currency TEXT,
        scheduled_payment_id INTEGER,
        receipt_image_path TEXT,
        receipt_items TEXT,
        receipt_reference TEXT
      )
    ''');
  }

  Future<void> _addReceiptColumns(DatabaseExecutor db) async {
    await _addColumnIfMissing(db, 'transactions', 'receipt_image_path', 'TEXT');
    await _addColumnIfMissing(db, 'transactions', 'receipt_items', 'TEXT');
    await _addColumnIfMissing(db, 'transactions', 'receipt_reference', 'TEXT');
  }

  Future<void> _createSubscriptionTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS subscriptions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        amount REAL NOT NULL CHECK(amount > 0),
        currency TEXT NOT NULL DEFAULT 'MXN',
        category TEXT NOT NULL,
        frequency TEXT NOT NULL CHECK(frequency IN (
          'weekly', 'biweekly', 'monthly', 'bimonthly',
          'quarterly', 'semiannual', 'annual'
        )),
        next_charge_date TEXT NOT NULL,
        billing_day INTEGER NOT NULL DEFAULT 1
          CHECK(billing_day BETWEEN 1 AND 31),
        account_id INTEGER,
        account_label TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT 'active'
          CHECK(status IN ('active', 'paused', 'cancelled')),
        reminder_days INTEGER NOT NULL DEFAULT 1
          CHECK(reminder_days IN (0, 1, 3, 7)),
        created_at TEXT NOT NULL,
        updated_at TEXT,
        notes TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS subscription_payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subscription_id INTEGER NOT NULL,
        amount REAL NOT NULL CHECK(amount > 0),
        currency TEXT NOT NULL,
        due_date TEXT NOT NULL,
        paid_at TEXT NOT NULL,
        account_label TEXT NOT NULL DEFAULT '',
        transaction_id INTEGER NOT NULL UNIQUE,
        UNIQUE(subscription_id, due_date)
      )
    ''');
  }

  Future<void> _createAccountTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS accounts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL CHECK(type IN (
          'cash', 'bank', 'debitCard', 'creditCard', 'savings'
        )),
        currency TEXT NOT NULL,
        initial_balance REAL NOT NULL DEFAULT 0 CHECK(initial_balance >= 0),
        institution TEXT NOT NULL DEFAULT '',
        last_four TEXT NOT NULL DEFAULT '',
        icon TEXT NOT NULL DEFAULT 'account_balance_wallet',
        is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
        credit_limit REAL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS account_transfers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        from_account_id INTEGER NOT NULL,
        to_account_id INTEGER NOT NULL,
        amount REAL NOT NULL CHECK(amount > 0),
        currency TEXT NOT NULL,
        date TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        CHECK(from_account_id != to_account_id),
        FOREIGN KEY(from_account_id) REFERENCES accounts(id),
        FOREIGN KEY(to_account_id) REFERENCES accounts(id)
      )
    ''');
  }

  Future<void> _createScheduledPaymentTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS scheduled_payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount REAL NOT NULL CHECK(amount > 0),
        currency TEXT NOT NULL,
        payment_type TEXT NOT NULL CHECK(payment_type IN (
          'recurring', 'oneTime', 'cardPayment'
        )),
        due_date TEXT NOT NULL,
        category TEXT,
        frequency TEXT CHECK(frequency IS NULL OR frequency IN (
          'weekly', 'biweekly', 'monthly', 'bimonthly',
          'quarterly', 'semiannual', 'annual'
        )),
        account_id INTEGER,
        target_account_id INTEGER,
        reminder_days INTEGER NOT NULL DEFAULT 1
          CHECK(reminder_days IN (0, 1, 3, 7)),
        status TEXT NOT NULL DEFAULT 'active'
          CHECK(status IN ('active', 'cancelled', 'completed')),
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        CHECK(
          (payment_type = 'recurring' AND frequency IS NOT NULL)
          OR (payment_type = 'oneTime' AND frequency IS NULL)
          OR payment_type = 'cardPayment'
        ),
        CHECK(
          (payment_type = 'cardPayment' AND target_account_id IS NOT NULL)
          OR (payment_type != 'cardPayment' AND target_account_id IS NULL)
        ),
        FOREIGN KEY(account_id) REFERENCES accounts(id),
        FOREIGN KEY(target_account_id) REFERENCES accounts(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS scheduled_payment_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        scheduled_payment_id INTEGER NOT NULL,
        amount REAL NOT NULL CHECK(amount > 0),
        currency TEXT NOT NULL,
        due_date TEXT NOT NULL,
        paid_at TEXT NOT NULL,
        status TEXT NOT NULL CHECK(status IN ('paid', 'cancelled')),
        transaction_id INTEGER UNIQUE,
        transfer_id INTEGER,
        account_id INTEGER,
        created_at TEXT NOT NULL,
        UNIQUE(scheduled_payment_id, due_date),
        FOREIGN KEY(scheduled_payment_id) REFERENCES scheduled_payments(id),
        FOREIGN KEY(transaction_id) REFERENCES transactions(id),
        FOREIGN KEY(transfer_id) REFERENCES account_transfers(id),
        FOREIGN KEY(account_id) REFERENCES accounts(id)
      )
    ''');
  }

  Future<void> _addColumnIfMissing(
    DatabaseExecutor db,
    String table,
    String column,
    String definition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    if (columns.any((item) => item['name'] == column)) return;
    await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
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
