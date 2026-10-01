import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mova/database/database_helper.dart';
import 'package:mova/models/financial_account.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  test(
    'moving cash to savings debits the source and preserves availability',
    () async {
      const databaseName = 'financial_data_refresh_test.db';
      final databasePath = join(await getDatabasesPath(), databaseName);
      await deleteDatabase(databasePath);
      final database = DatabaseHelper(databaseName: databaseName);

      try {
        final accountId = await database.createFinancialAccount(
          FinancialAccount(
            id: 0,
            name: 'Cuenta de prueba',
            type: FinancialAccountType.cash,
            currency: 'MXN',
            initialBalance: 0,
            institution: '',
            lastFour: '',
            icon: 'account_balance',
            isActive: true,
            creditLimit: null,
            createdAt: DateTime(2026),
          ),
        );
        var notifiedVersion = DatabaseHelper.financialDataVersion.value;
        void listener() {
          notifiedVersion = DatabaseHelper.financialDataVersion.value;
        }

        DatabaseHelper.financialDataVersion.addListener(listener);
        final versionBeforeTransaction = notifiedVersion;
        try {
          await database.insertTransaction(
            amount: 8500,
            isIncome: true,
            category: 'Sueldo',
            description: 'Pago de prueba',
            date: DateTime(2026, 9, 30),
            accountId: accountId,
            currency: 'MXN',
          );
          expect(notifiedVersion, greaterThan(versionBeforeTransaction));
          final accounts = await database.getFinancialAccounts();
          expect(accounts.single.balance, 8500);

          await database.moveToUnassignedSavings(7000, accountId: accountId);
          expect(
            (await database.getFinancialAccount(accountId))!.balance,
            1500,
          );
          expect(await database.getUnassignedSavings(), 7000);
          expect(
            (await database.getUnassignedSavingsByAccount())[accountId],
            7000,
          );
          var overview = await database.getFinancialOverview(
            homeCurrency: 'MXN',
          );
          expect(overview['assets']!['MXN'], 8500);
          expect(overview['available']!['MXN'], 1500);

          await database.withdrawUnassignedSavings(500, accountId: accountId);
          expect(
            (await database.getFinancialAccount(accountId))!.balance,
            2000,
          );
          expect(await database.getUnassignedSavings(), 6500);
          overview = await database.getFinancialOverview(homeCurrency: 'MXN');
          expect(overview['assets']!['MXN'], 8500);
          expect(overview['available']!['MXN'], 2000);

          await expectLater(
            database.moveToUnassignedSavings(2500, accountId: accountId),
            throwsA(isA<StateError>()),
          );
        } finally {
          DatabaseHelper.financialDataVersion.removeListener(listener);
        }
      } finally {
        await (await database.database).close();
        await deleteDatabase(databasePath);
      }
    },
  );

  test(
    'keeps legacy savings unassigned without rewriting account history',
    () async {
      const databaseName = 'legacy_unassigned_savings_test.db';
      final databasePath = join(await getDatabasesPath(), databaseName);
      await deleteDatabase(databasePath);
      final database = DatabaseHelper(databaseName: databaseName);
      try {
        final accountId = await database.createFinancialAccount(
          FinancialAccount(
            id: 0,
            name: 'Cymez',
            type: FinancialAccountType.bank,
            currency: 'MXN',
            initialBalance: 17000,
            institution: '',
            lastFour: '',
            icon: 'account_balance',
            isActive: true,
            creditLimit: null,
            createdAt: DateTime(2026),
          ),
        );
        await database.addUnassignedSavings(7000);

        expect((await database.getFinancialAccount(accountId))!.balance, 17000);
        expect(await database.getUnassignedSavingsByAccount(), {null: 7000});
        final overview = await database.getFinancialOverview(
          homeCurrency: 'MXN',
        );
        expect(overview['assets']!['MXN'], 17000);
        expect(overview['available']!['MXN'], 10000);
      } finally {
        await (await database.database).close();
        await deleteDatabase(databasePath);
      }
    },
  );
}
