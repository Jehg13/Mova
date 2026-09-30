import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mova/database/database_helper.dart';
import 'package:mova/models/financial_account.dart';
import 'package:mova/screens/accounts_screen.dart';
import 'package:mova/services/currency_controller.dart';
import 'package:mova/services/mova_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  appCurrencyController = CurrencyController(
    DatabaseHelper(databaseName: 'account_form_test.db'),
  );

  Widget buildForm({FinancialAccount? account}) => MaterialApp(
    locale: const Locale('es'),
    supportedLocales: const [Locale('es')],
    localizationsDelegates: const [
      MovaLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: FinancialAccountFormScreen(account: account),
  );

  testWidgets('new accounts cannot select cash as account type', (
    tester,
  ) async {
    await tester.pumpWidget(buildForm());
    await tester.pumpAndSettle();

    final dropdown = find.byType(DropdownButtonFormField<FinancialAccountType>);
    expect(dropdown, findsOneWidget);
    expect(find.text('Cuenta bancaria'), findsWidgets);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();

    expect(find.text('Efectivo'), findsNothing);
    expect(find.text('Cuenta bancaria'), findsWidgets);
  });

  testWidgets('existing cash account type remains visible and unchanged', (
    tester,
  ) async {
    final account = FinancialAccount(
      id: 1,
      name: 'Efectivo',
      type: FinancialAccountType.cash,
      currency: 'MXN',
      initialBalance: 0,
      institution: '',
      lastFour: '',
      icon: 'payments',
      isActive: true,
      creditLimit: null,
      createdAt: DateTime(2026),
    );
    await tester.pumpWidget(buildForm(account: account));
    await tester.pumpAndSettle();

    expect(find.text('Efectivo'), findsWidgets);
    expect(
      find.byType(DropdownButtonFormField<FinancialAccountType>),
      findsNothing,
    );
  });

  testWidgets('credit card form omits initial debt and credit limit fields', (
    tester,
  ) async {
    final account = FinancialAccount(
      id: 2,
      name: 'Tarjeta',
      type: FinancialAccountType.creditCard,
      currency: 'MXN',
      initialBalance: 250,
      institution: 'Banco',
      lastFour: '1234',
      icon: 'credit_card',
      isActive: true,
      creditLimit: 10000,
      createdAt: DateTime(2026),
    );
    await tester.pumpWidget(buildForm(account: account));
    await tester.pumpAndSettle();

    expect(find.text('Deuda actual de la tarjeta'), findsNothing);
    expect(find.text('Límite de crédito'), findsNothing);
    expect(find.text('Institución (opcional)'), findsOneWidget);
    expect(find.text('Últimos 4 dígitos (opcional)'), findsOneWidget);
    expect(find.text('Saldo inicial disponible'), findsNothing);
  });
}
