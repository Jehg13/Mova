import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mova/database/database_helper.dart';
import 'package:mova/models/nivo_response.dart';
import 'package:mova/screens/nivo_screen.dart';
import 'package:mova/services/nivo_engine.dart';
import 'package:mova/services/nivo_repository.dart';
import 'package:mova/services/mova_localizations.dart';

Widget _localizedApp(Widget home, {Locale locale = const Locale('es')}) =>
    MaterialApp(
      locale: locale,
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

  testWidgets('clickable questions traverse Nivo to SQLite', (tester) async {
    const databaseName = 'nivo_screen_test.db';
    late DatabaseHelper database;
    await tester.runAsync(() async {
      final databasePath = join(await getDatabasesPath(), databaseName);
      await deleteDatabase(databasePath);
      database = DatabaseHelper(databaseName: databaseName);
      await database.insertTransaction(
        amount: 123.45,
        isIncome: false,
        category: 'Comida',
        description: 'Comida de prueba',
        date: DateTime.now(),
        currency: 'MXN',
      );
      await database.addUnassignedSavings(50);
    });
    final engine = NivoEngine(
      repository: NivoRepository(databaseHelper: database),
    );
    const expenseQuestion = '¿Cuánto gasté este mes?';
    const categoryQuestion = '¿Cuánto gasté en Comida este mes?';
    const comparisonQuestion =
        '¿Cuánto gasté este mes comparado con el anterior?';
    late Map<String, NivoResponse> answers;
    await tester.runAsync(() async {
      answers = {
        expenseQuestion: await engine.ask(expenseQuestion),
        categoryQuestion: await engine.ask(categoryQuestion),
        comparisonQuestion: await engine.ask(comparisonQuestion),
      };
    });
    final requestedQuestions = <String>[];

    await tester.pumpWidget(
      _localizedApp(
        NivoScreen(
          engine: engine,
          onAsk: (question) {
            requestedQuestions.add(question);
            return Future.value(answers[question]!);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hola, soy Nivo'), findsOneWidget);
    expect(find.text('¿Cuánto gasté este mes?'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byKey(const Key('nivo-send')), findsNothing);

    await tester.tap(find.text('¿Cuánto gasté este mes?'));
    await _pumpUntilFound(tester, find.text('Este mes has gastado \$123.45.'));
    expect(find.text('Este mes has gastado \$123.45.'), findsOneWidget);
    expect(find.byKey(const Key('nivo-conversation')), findsOneWidget);
    expect(find.text(categoryQuestion), findsOneWidget);
    await tester.tap(find.text(categoryQuestion));
    await _pumpUntilFound(
      tester,
      find.text('Este mes has gastado \$123.45 en Comida.'),
    );
    expect(find.text(comparisonQuestion), findsOneWidget);
    expect(requestedQuestions, [expenseQuestion, categoryQuestion]);

    final comparisonOption = find.text(comparisonQuestion);
    await tester.ensureVisible(comparisonOption);
    await tester.pumpAndSettle();
    await tester.tap(comparisonOption);
    await _pumpUntilFound(
      tester,
      find.textContaining('Comparado con el periodo anterior'),
    );
    expect(
      find.textContaining('Comparado con el periodo anterior'),
      findsOneWidget,
    );
    expect(find.text('¿Cuánto tengo disponible?'), findsNothing);
    expect(requestedQuestions, [
      expenseQuestion,
      categoryQuestion,
      comparisonQuestion,
    ]);

    await tester.runAsync(() async {
      await (await database.database).close();
      await deleteDatabase(join(await getDatabasesPath(), databaseName));
    });
  });

  test(
    'Nivo labels, questions, and live answers follow the selected language',
    () {
      final english = MovaLocalizations(const Locale('en'));
      final portuguese = MovaLocalizations(const Locale('pt'));

      expect(english.nivoText('Hola, soy Nivo'), 'Hi, I’m Nivo');
      expect(
        english.nivoText('¿Cuánto gasté en Comida este mes?'),
        'How much did I spend on Food this month?',
      );
      expect(
        english.nivoText('Este mes has gastado \$123.45 en Comida.'),
        'This month you spent \$123.45 on Food.',
      );
      expect(
        portuguese.nivoText('Tu saldo disponible actualmente es de \$500.00.'),
        'Seu saldo disponível atual é \$500.00.',
      );
      expect(
        portuguese.nivoText('¿Cómo va mi meta de Coche?'),
        'Como está o progresso da minha meta Coche?',
      );
      expect(
        MovaLocalizations(const Locale('es')).nivoText('Hola, soy Nivo'),
        'Hola, soy Nivo',
      );
    },
  );

  testWidgets('Nivo screen renders suggested questions in the app language', (
    tester,
  ) async {
    await tester.pumpWidget(
      _localizedApp(const NivoScreen(), locale: const Locale('en')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hi, I’m Nivo'), findsOneWidget);
    expect(find.text('Try asking'), findsOneWidget);
    expect(find.text('How much did I spend this month?'), findsOneWidget);
    expect(find.text('¿Cuánto gasté este mes?'), findsNothing);
  });
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 60; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsOneWidget);
}
