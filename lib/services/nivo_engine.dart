import 'package:mova/models/financial_account.dart';
import 'package:mova/models/nivo_query.dart';
import 'package:mova/models/nivo_response.dart';
import 'package:mova/models/receipt_scan_draft.dart';
import 'package:mova/models/subscription.dart';
import 'package:mova/services/nivo_actions.dart';
import 'package:mova/services/nivo_parser.dart';
import 'package:mova/services/nivo_repository.dart';
import 'package:mova/services/receipt_storage.dart';

class NivoEngine {
  NivoEngine({
    NivoRepository? repository,
    NivoParser? parser,
    DateTime Function()? clock,
  }) : _repository = repository ?? NivoRepository(),
       _clock = clock ?? DateTime.now,
       _parser = parser ?? NivoParser();

  final NivoRepository _repository;
  final NivoParser _parser;
  final DateTime Function() _clock;
  _PendingNivoAction? _pendingAction;
  List<String>? _pendingGoalQuery;

  Future<List<String>> suggestedQuestions([
    NivoResponse? previousResponse,
  ]) async {
    if (previousResponse == null) {
      return const [
        '¿Cuánto gasté este mes?',
        '¿Cuánto tengo disponible?',
        '¿Cómo van mis metas?',
        '¿Qué pagos tengo próximos?',
      ];
    }

    final pendingAction = _pendingAction;
    if (pendingAction != null) {
      switch (pendingAction.step) {
        case _PendingActionStep.confirm:
        case _PendingActionStep.duplicate:
          return const ['Sí', 'No'];
        case _PendingActionStep.category:
          final categories = await _repository.getCategories();
          final type = pendingAction.intent == NivoIntent.crearIngreso
              ? 'income'
              : 'expense';
          return categories
              .where((category) => category['type'] == type)
              .map((category) => category['name'] as String)
              .toList();
        case _PendingActionStep.goal:
          final goals = await _repository.getGoals();
          return goals.map((goal) => goal['name'] as String).toList();
        case _PendingActionStep.account:
          final accounts = await _repository.getAccounts(
            includeInactive: false,
          );
          return [
            ...accounts.map((account) => account.name),
            if (pendingAction.intent == NivoIntent.crearIngreso) 'Sin cuenta',
          ];
        case _PendingActionStep.shoppingList:
          final lists = await _repository.databaseHelper.getShoppingLists();
          return lists.map((list) => list['name'] as String).toList();
        case _PendingActionStep.amount:
        case _PendingActionStep.product:
        case _PendingActionStep.ready:
          return const ['Cancelar'];
      }
    }
    final pendingGoals = _pendingGoalQuery;
    if (pendingGoals != null) return pendingGoals;

    final intent = previousResponse.intent;
    switch (intent) {
      case NivoIntent.consultarBalance:
      case NivoIntent.consultarCuentas:
        final accounts = previousResponse.data['accounts'];
        final accountQuestions = accounts is List
            ? accounts
                  .whereType<FinancialAccount>()
                  .map((account) => '¿Cuál es el saldo de ${account.name}?')
                  .toList()
            : <String>[];
        if (accountQuestions.isEmpty) {
          final storedAccounts = await _repository.getAccounts(
            includeInactive: false,
          );
          accountQuestions.addAll(
            storedAccounts.map(
              (account) => '¿Cuál es el saldo de ${account.name}?',
            ),
          );
        }
        return [
          ...accountQuestions.take(3),
          '¿Cuánto gasté este mes?',
          '¿Cuánto llevo ahorrado?',
        ];
      case NivoIntent.consultarGastos:
      case NivoIntent.consultarCategoria:
        final range = _periodRange(NivoPeriod.thisMonth, _dayStart(_clock()));
        final categoryTotals = await _repository.getExpensesByCategory(
          from: range.$1,
          to: range.$2,
        );
        final selectedCategory = previousResponse.data['category'] as String?;
        final categories =
            categoryTotals.entries
                .where((entry) => entry.key != selectedCategory)
                .map(
                  (entry) => MapEntry(
                    entry.key,
                    entry.value.values.fold<double>(0, (a, b) => a + b),
                  ),
                )
                .toList()
              ..sort((a, b) => b.value.compareTo(a.value));
        return [
          ...categories
              .take(3)
              .map((entry) => '¿Cuánto gasté en ${entry.key} este mes?'),
          '¿Cuánto gasté este mes comparado con el anterior?',
          '¿Cuánto gasté en promedio este mes?',
        ];
      case NivoIntent.consultarIngresos:
        return const [
          '¿Cuánto gasté este mes?',
          '¿Cuánto tengo disponible?',
          '¿Cuánto llevo ahorrado?',
        ];
      case NivoIntent.consultarAhorro:
      case NivoIntent.consultarMeta:
      case NivoIntent.aportarMeta:
      case NivoIntent.crearMeta:
        final names = _goalNames(previousResponse);
        return [
          ...names.take(4).map((name) => '¿Cómo va mi meta de $name?'),
          '¿Cuánto llevo ahorrado?',
          '¿Cuánto tengo disponible?',
        ];
      case NivoIntent.consultarSuscripciones:
        return const [
          '¿Qué pagos tengo esta semana?',
          '¿Qué pagos tengo próximos?',
          '¿Cuánto gasté este mes?',
        ];
      case NivoIntent.consultarPagosProximos:
        return const [
          '¿Qué pagos tengo esta semana?',
          '¿Qué pagos tengo próximamente?',
          '¿Cuáles son mis suscripciones activas?',
        ];
      case NivoIntent.consultarPresupuesto:
        return const [
          '¿Cuánto gasté este mes?',
          '¿Cuánto gasté este mes comparado con el anterior?',
          '¿Cuánto tengo disponible?',
        ];
      case NivoIntent.crearGasto:
        return const [
          '¿Cuánto gasté este mes?',
          '¿Cuánto gasté en comida este mes?',
          '¿Cuánto tengo disponible?',
        ];
      case NivoIntent.crearIngreso:
        return const [
          '¿Cuánto dinero tengo?',
          '¿Cuánto recibí este mes?',
          '¿Cuánto llevo ahorrado?',
        ];
      case NivoIntent.agregarAhorro:
        return const [
          '¿Cuánto llevo ahorrado?',
          '¿Cómo van mis metas?',
          '¿Cuánto tengo disponible?',
        ];
      case NivoIntent.agregarProductoLista:
      case NivoIntent.accionDestructiva:
      case null:
        return const [
          '¿Cuánto tengo disponible?',
          '¿Cuánto gasté este mes?',
          '¿Cómo van mis metas?',
        ];
    }
  }

  List<String> _goalNames(NivoResponse response) {
    final goal = response.data['goal'];
    if (goal is Map && goal['name'] is String) {
      return [goal['name'] as String];
    }
    final goals = response.data['goals'];
    if (goals is! List) return const [];
    return goals
        .whereType<Map>()
        .map((item) => item['name'])
        .whereType<String>()
        .toList();
  }

  Future<NivoResponse> ask(String question) async {
    final pending = _pendingAction;
    if (pending != null) {
      return _continuePendingAction(pending, question);
    }
    final pendingGoals = _pendingGoalQuery;
    if (pendingGoals != null) {
      return _answerPendingGoal(question, pendingGoals);
    }
    final initial = _parser.parse(question);
    if (initial.intent == NivoIntent.accionDestructiva) {
      return NivoResponse(
        text:
            'No ejecutaré una acción destructiva a partir de una frase detectada. '
            'La eliminación de registros no está habilitada en Nivo.',
        confidence: initial.confidence,
        intent: initial.intent,
        requiresClarification: true,
      );
    }
    final intent = initial.intent;
    final needsGoals =
        intent == NivoIntent.consultarMeta || intent == NivoIntent.aportarMeta;
    final needsAccounts =
        intent == NivoIntent.consultarCuentas ||
        intent == NivoIntent.crearGasto ||
        intent == NivoIntent.crearIngreso;
    final needsShoppingLists = intent == NivoIntent.agregarProductoLista;
    final context = await Future.wait<Object?>([
      _repository.getCategories(),
      if (needsGoals) _repository.getGoals(),
      if (needsAccounts) _repository.getAccounts(),
      if (needsShoppingLists) _repository.databaseHelper.getShoppingLists(),
    ]);
    final allCategories = context[0] as List<Map<String, dynamic>>;
    final categoryType = intent == NivoIntent.crearIngreso
        ? 'income'
        : 'expense';
    final categories = allCategories
        .where((category) => category['type'] == categoryType)
        .map((category) => category['name'] as String)
        .toList();
    final entityDataIndex = 1;
    final goals = needsGoals
        ? (context[entityDataIndex] as List<Map<String, dynamic>>).map(
            (goal) => goal['name'] as String,
          )
        : const <String>[];
    final accountDataIndex = entityDataIndex + (needsGoals ? 1 : 0);
    final accounts = needsAccounts
        ? (context[accountDataIndex] as List<FinancialAccount>)
              .where((account) => account.isActive)
              .map((account) => account.name)
              .toList()
        : const <String>[];
    final listDataIndex = accountDataIndex + (needsAccounts ? 1 : 0);
    final lists = needsShoppingLists
        ? (context[listDataIndex] as List<Map<String, dynamic>>)
              .map((list) => list['name'] as String)
              .toList()
        : const <String>[];
    final parsed = _parser.parse(
      question,
      categories: categories,
      goals: goals,
      accounts: accounts,
      shoppingLists: lists,
    );

    if (parsed.intent == NivoIntent.consultarMeta &&
        parsed.entities.goal == null) {
      final storedGoals =
          context[entityDataIndex] as List<Map<String, dynamic>>;
      if (storedGoals.isEmpty) {
        return _response(
          NivoIntent.consultarMeta,
          parsed.confidence,
          'Aún no tienes metas registradas.',
          {'goals': storedGoals},
        );
      }
      if (_asksForAllGoals(question)) {
        return _answerAllGoals(storedGoals, parsed.confidence);
      }
      if (storedGoals.length == 1) {
        return _answerGoal(storedGoals.single, parsed.confidence);
      }
      final names = storedGoals.map((goal) => goal['name'] as String).toList();
      _pendingGoalQuery = names;
      return NivoResponse(
        text:
            '¿De cuál de tus metas quieres consultar el progreso? '
            '${names.join(', ')}.',
        confidence: parsed.confidence,
        intent: NivoIntent.consultarMeta,
        requiresClarification: true,
      );
    }

    if (_isActionIntent(parsed.intent)) {
      final action = _pendingFromParse(parsed);
      if (action.intent == NivoIntent.accionDestructiva) {
        return NivoResponse(
          text:
              'No ejecutaré una acción destructiva a partir de una frase detectada. '
              'La eliminación de registros no está habilitada en Nivo.',
          confidence: parsed.confidence,
          intent: parsed.intent,
          requiresClarification: true,
        );
      }
      return _prepareAction(
        action,
        _ActionContext(
          categories: categories,
          goals: needsGoals
              ? context[entityDataIndex] as List<Map<String, dynamic>>
              : const [],
          accounts: needsAccounts
              ? context[accountDataIndex] as List<FinancialAccount>
              : const [],
          lists: needsShoppingLists
              ? context[listDataIndex] as List<Map<String, dynamic>>
              : const [],
        ),
      );
    }
    if (parsed.requiresClarification || parsed.intent == null) {
      return NivoResponse(
        text:
            parsed.clarification ??
            'No entendí la consulta. ¿Puedes darme un poco más de detalle?',
        confidence: parsed.confidence,
        intent: parsed.intent,
        requiresClarification: true,
      );
    }
    return _answer(parsed);
  }

  Future<NivoResponse> _answerPendingGoal(
    String answer,
    List<String> goalNames,
  ) async {
    final normalized = NivoParser.normalize(answer);
    final selectedName = goalNames.where(
      (name) => NivoParser.normalize(name) == normalized,
    );
    if (selectedName.isEmpty) {
      return NivoResponse(
        text:
            'No encontré esa meta. Elige una de estas: ${goalNames.join(', ')}.',
        confidence: NivoConfidence.medium,
        intent: NivoIntent.consultarMeta,
        requiresClarification: true,
      );
    }

    final selected = selectedName.first;
    _pendingGoalQuery = null;
    final goals = await _repository.getGoals();
    for (final goal in goals) {
      if (NivoParser.normalize(goal['name'] as String) ==
          NivoParser.normalize(selected)) {
        return _answerGoal(goal, NivoConfidence.high);
      }
    }
    return NivoResponse(
      text: 'No encontré esa meta en tus datos actuales.',
      confidence: NivoConfidence.medium,
      intent: NivoIntent.consultarMeta,
      requiresClarification: true,
    );
  }

  bool _asksForAllGoals(String question) {
    final text = NivoParser.normalize(question);
    return text.contains('mis metas') ||
        text.contains('todas las metas') ||
        text.contains('todas mis metas') ||
        text.contains('como van las metas') ||
        text.contains('como van mis objetivos');
  }

  Future<NivoResponse> _answerAllGoals(
    List<Map<String, dynamic>> goals,
    NivoConfidence confidence,
  ) async {
    final currency = await _repositoryCurrency();
    final details = goals
        .map((goal) {
          final saved = (goal['saved_amount'] as num).toDouble();
          final target = (goal['target_amount'] as num).toDouble();
          final progress = target > 0 ? saved / target * 100 : 0.0;
          return '${goal['name']}: ${_money(saved, currency)} de '
              '${_money(target, currency)} (${progress.toStringAsFixed(0)}%)';
        })
        .join('; ');
    return _response(
      NivoIntent.consultarMeta,
      confidence,
      'Tienes ${goals.length} ${goals.length == 1 ? 'meta' : 'metas'}: $details.',
      {'goals': goals},
    );
  }

  Future<NivoResponse> _answerGoal(
    Map<String, dynamic> goal,
    NivoConfidence confidence,
  ) async {
    final saved = (goal['saved_amount'] as num).toDouble();
    final targetAmount = (goal['target_amount'] as num).toDouble();
    final progress = targetAmount > 0 ? saved / targetAmount * 100 : 0.0;
    final currency = await _repositoryCurrency();
    return _response(
      NivoIntent.consultarMeta,
      confidence,
      'Llevas ${_money(saved, currency)} de '
      '${_money(targetAmount, currency)} para tu '
      'meta ${goal['name']} (${progress.toStringAsFixed(0)}%).',
      {
        'goal': goal,
        'progress_percent': progress,
        'remaining': (targetAmount - saved).clamp(0, targetAmount),
      },
    );
  }

  static FinancialAccount? _findAccountById(
    int id,
    List<FinancialAccount> accounts,
  ) {
    for (final account in accounts) {
      if (account.id == id) return account;
    }
    return null;
  }

  static FinancialAccount? _defaultCashAccount(
    List<FinancialAccount> cashAccounts,
  ) {
    if (cashAccounts.length == 1) return cashAccounts.single;
    for (final account in cashAccounts) {
      if (NivoParser.normalize(account.name) == 'efectivo') return account;
    }
    return null;
  }

  Future<NivoResponse> proposeReceipt(ReceiptScanDraft draft) async {
    if (!draft.amount.isFinite || draft.amount <= 0) {
      return const NivoResponse(
        text: 'No pude preparar el comprobante: el importe no es válido.',
        confidence: NivoConfidence.low,
        requiresClarification: true,
      );
    }
    final context = await _loadActionContext(NivoIntent.crearGasto);
    final category = draft.categorySelected ? draft.category.trim() : '';
    final action = _PendingNivoAction(
      intent: NivoIntent.crearGasto,
      amount: draft.amount,
      category: category.isEmpty ? null : category,
      merchant: draft.merchant.trim().isEmpty ? null : draft.merchant.trim(),
      date: _dayStart(draft.date),
      accountId: draft.accountId,
      receiptImagePath: draft.imagePath,
      receiptItems: draft.items,
      receiptReference: draft.reference,
      requiresConfirmation: true,
    );
    return _prepareAction(action, context);
  }

  Future<_ActionContext> _loadActionContext(NivoIntent intent) async {
    final results = await Future.wait<Object>([
      _repository.getCategories(),
      if (intent == NivoIntent.aportarMeta) _repository.getGoals(),
      if (intent == NivoIntent.crearGasto ||
          intent == NivoIntent.crearIngreso ||
          intent == NivoIntent.agregarAhorro)
        _repository.getAccounts(),
      if (intent == NivoIntent.agregarProductoLista)
        _repository.databaseHelper.getShoppingLists(),
    ]);
    var index = 1;
    final goals = intent == NivoIntent.aportarMeta
        ? results[index++] as List<Map<String, dynamic>>
        : const <Map<String, dynamic>>[];
    final accounts =
        intent == NivoIntent.crearGasto ||
            intent == NivoIntent.crearIngreso ||
            intent == NivoIntent.agregarAhorro
        ? results[index++] as List<FinancialAccount>
        : const <FinancialAccount>[];
    final lists = intent == NivoIntent.agregarProductoLista
        ? results[index] as List<Map<String, dynamic>>
        : const <Map<String, dynamic>>[];
    final categoryType = intent == NivoIntent.crearIngreso
        ? 'income'
        : 'expense';
    return _ActionContext(
      categories: (results[0] as List<Map<String, dynamic>>)
          .where((category) => category['type'] == categoryType)
          .map((category) => category['name'] as String)
          .toList(),
      goals: goals,
      accounts: accounts.where((account) => account.isActive).toList(),
      lists: lists,
    );
  }

  _PendingNivoAction _pendingFromParse(NivoParseResult parsed) =>
      _PendingNivoAction(
        intent: parsed.intent!,
        amount: parsed.entities.amount,
        category: parsed.entities.category,
        merchant: parsed.entities.merchant,
        date: _dayStart(parsed.entities.date ?? _clock()),
        accountName: parsed.entities.account,
        goalName: parsed.entities.goal,
        product: parsed.entities.product,
        quantity: parsed.entities.quantity ?? 1,
        unit: parsed.entities.unit ?? 'unidad',
        shoppingListName: parsed.entities.shoppingList,
      );

  Future<NivoResponse> _continuePendingAction(
    _PendingNivoAction action,
    String answer,
  ) async {
    final normalized = NivoParser.normalize(answer);
    if (_isCancel(normalized)) {
      _pendingAction = null;
      return _actionResponse(
        action,
        'De acuerdo, no hice ningún cambio.',
        requiresClarification: false,
      );
    }
    if (action.step == _PendingActionStep.confirm) {
      if (_isYes(normalized)) {
        action.step = _PendingActionStep.ready;
        action.confirmed = true;
      } else if (_isNo(normalized)) {
        _pendingAction = null;
        return _actionResponse(
          action,
          'De acuerdo, no hice ningún cambio.',
          requiresClarification: false,
        );
      } else {
        return _actionResponse(
          action,
          'Responde “sí” para confirmar o “no” para cancelar.',
          requiresConfirmation: true,
        );
      }
    } else if (action.step == _PendingActionStep.duplicate) {
      if (_isYes(normalized)) {
        _pendingAction = null;
        return _actionResponse(
          action,
          'No registré el gasto porque confirmaste que es el mismo movimiento existente.',
          requiresClarification: false,
        );
      } else if (_isNo(normalized)) {
        action.step = _PendingActionStep.ready;
        action.requiresConfirmation = true;
        action.duplicateWasRejected = true;
      } else {
        return _actionResponse(
          action,
          '¿Es el mismo movimiento? Responde “sí” para no duplicarlo o “no” para continuar.',
          requiresConfirmation: true,
        );
      }
    } else {
      final context = await _loadActionContext(action.intent);
      final value = _parser.parse(
        answer,
        categories: context.categories,
        goals: context.goals.map((goal) => goal['name'] as String),
        accounts: context.accounts.map((account) => account.name),
        shoppingLists: context.lists.map((list) => list['name'] as String),
      );
      switch (action.step) {
        case _PendingActionStep.category:
          action.category = _canonical(
            value.entities.category ?? answer.trim(),
            context.categories,
          );
          break;
        case _PendingActionStep.amount:
          action.amount = value.entities.amount;
          break;
        case _PendingActionStep.goal:
          action.goalName = answer.trim();
          break;
        case _PendingActionStep.account:
          if (NivoParser.normalize(answer) == 'sin cuenta') {
            action.accountName = null;
            action.accountId = null;
          } else {
            action.accountName = answer.trim();
          }
          break;
        case _PendingActionStep.product:
          action.product = answer.trim();
          break;
        case _PendingActionStep.shoppingList:
          action.shoppingListName = answer.trim();
          break;
        case _PendingActionStep.confirm:
        case _PendingActionStep.duplicate:
        case _PendingActionStep.ready:
          break;
      }
      action.step = _PendingActionStep.ready;
      return _prepareAction(action, context);
    }
    final context = await _loadActionContext(action.intent);
    return _prepareAction(action, context);
  }

  Future<NivoResponse> _prepareAction(
    _PendingNivoAction action,
    _ActionContext context,
  ) async {
    if (action.intent == NivoIntent.crearGasto ||
        action.intent == NivoIntent.crearIngreso ||
        action.intent == NivoIntent.agregarAhorro ||
        action.intent == NivoIntent.aportarMeta ||
        action.intent == NivoIntent.crearMeta) {
      if (action.amount == null ||
          !action.amount!.isFinite ||
          action.amount! <= 0) {
        return _requestField(
          action,
          _PendingActionStep.amount,
          action.intent == NivoIntent.crearMeta
              ? '¿Cuál es el monto objetivo de la meta?'
              : '¿Qué importe quieres registrar?',
        );
      }
    }
    if (action.intent == NivoIntent.crearGasto ||
        action.intent == NivoIntent.crearIngreso ||
        action.intent == NivoIntent.agregarAhorro) {
      if (action.intent == NivoIntent.crearGasto ||
          action.intent == NivoIntent.crearIngreso) {
        final category = _canonical(action.category, context.categories);
        if (category == null) {
          return _requestField(
            action,
            _PendingActionStep.category,
            '¿En qué categoría quieres registrarlo? No asignaré una categoría que no hayas indicado.',
          );
        }
        action.category = category;
      }
      if (action.intent == NivoIntent.crearIngreso &&
          action.accountId == null &&
          action.accountName == null) {
        final cashAccounts = context.accounts
            .where((account) => account.type == FinancialAccountType.cash)
            .toList();
        final defaultCash = _defaultCashAccount(cashAccounts);
        if (defaultCash != null) {
          action.accountId = defaultCash.id;
          action.accountName = defaultCash.name;
          action.currency = defaultCash.currency;
        } else if (cashAccounts.length > 1) {
          return _requestField(
            action,
            _PendingActionStep.account,
            '¿En cuál cuenta de efectivo quieres registrar el ingreso? '
            '${cashAccounts.map((account) => account.name).join(', ')}.',
          );
        }
      }
      if (action.intent == NivoIntent.agregarAhorro) {
        final homeCurrency = await _repository.databaseHelper.getCurrency();
        final eligibleAccounts =
            (await _repository.getAccounts(includeInactive: false))
                .where(
                  (account) =>
                      account.type != FinancialAccountType.creditCard &&
                      account.currency == homeCurrency,
                )
                .toList();
        if (action.accountId == null && action.accountName == null) {
          if (eligibleAccounts.isEmpty) {
            _pendingAction = null;
            return _actionResponse(
              action,
              'Necesitas una cuenta activa en la moneda principal para apartar el ahorro.',
              requiresClarification: true,
            );
          }
          if (eligibleAccounts.length == 1) {
            action.accountId = eligibleAccounts.single.id;
            action.accountName = eligibleAccounts.single.name;
          } else {
            return _requestField(
              action,
              _PendingActionStep.account,
              '¿De qué cuenta aparto el dinero? ${eligibleAccounts.map((account) => account.name).join(', ')}.',
            );
          }
        }
        final selectedAccount = action.accountId == null
            ? _findAccount(action.accountName!, eligibleAccounts)
            : _findAccountById(action.accountId!, eligibleAccounts);
        if (selectedAccount == null) {
          action.accountId = null;
          action.accountName = null;
          return _requestField(
            action,
            _PendingActionStep.account,
            'Elige una cuenta activa en la moneda principal desde la que apartar el dinero.',
          );
        }
        action.accountId = selectedAccount.id;
        action.accountName = selectedAccount.name;
        action.currency = selectedAccount.currency;
      }
      if (action.intent == NivoIntent.crearGasto ||
          action.intent == NivoIntent.crearIngreso) {
        if (action.accountId != null) {
          final selectedAccount = _findAccountById(
            action.accountId!,
            context.accounts,
          );
          if (selectedAccount == null) {
            action.accountName = null;
            action.accountId = null;
            return _requestField(
              action,
              _PendingActionStep.account,
              'La cuenta asociada al comprobante ya no está activa. ¿Qué cuenta quieres usar o prefieres “sin cuenta”?',
            );
          }
          action.currency = selectedAccount.currency;
        }
        if (action.accountName != null && action.accountId == null) {
          final account = _findAccount(action.accountName!, context.accounts);
          if (account == null) {
            return _requestField(
              action,
              _PendingActionStep.account,
              'No encontré esa cuenta activa. ¿Qué cuenta quieres usar? Puedes omitirla respondiendo “sin cuenta”.',
            );
          }
          action.accountId = account.id;
          action.accountName = account.name;
          action.currency = account.currency;
        }
      }
    }
    if (action.intent == NivoIntent.aportarMeta) {
      final goal = _findGoal(action.goalName, context.goals);
      if (goal == null) {
        if (context.goals.isEmpty) {
          _pendingAction = null;
          return _actionResponse(
            action,
            'No tienes metas creadas todavía. Crea una meta antes de aportar.',
            requiresClarification: true,
          );
        }
        if (action.goalName == null || action.goalName!.trim().isEmpty) {
          return _requestField(
            action,
            _PendingActionStep.goal,
            '¿A cuál de tus metas quieres agregar el dinero?',
          );
        }
        return _requestField(
          action,
          _PendingActionStep.goal,
          'No encontré esa meta. ¿Cuál de estas quieres elegir: '
          '${context.goals.map((goal) => goal['name']).join(', ')}?',
        );
      }
      action.goalName = goal['name'] as String;
    }
    if (action.intent == NivoIntent.crearMeta &&
        (action.goalName == null || action.goalName!.trim().isEmpty)) {
      return _requestField(
        action,
        _PendingActionStep.goal,
        '¿Cómo quieres llamar a la meta?',
      );
    }
    if (action.intent == NivoIntent.agregarProductoLista) {
      if (action.product == null || action.product!.trim().isEmpty) {
        return _requestField(
          action,
          _PendingActionStep.product,
          '¿Qué producto quieres agregar?',
        );
      }
      var list = _findList(action.shoppingListName, context.lists);
      final currentLists = context.lists
          .where((item) => item['status'] == 'current')
          .toList();
      if (list == null && action.shoppingListName != null) {
        return _requestField(
          action,
          _PendingActionStep.shoppingList,
          'No encontré esa lista actual. ¿A cuál lista quieres agregarlo?',
        );
      }
      if (list == null && currentLists.length == 1) {
        list = currentLists.single;
      }
      if (list == null && currentLists.isEmpty) {
        _pendingAction = null;
        return _actionResponse(
          action,
          'No hay una lista de compras actual. Crea una en MOVA y luego puedo agregar el producto.',
          requiresClarification: true,
        );
      }
      if (list == null) {
        return _requestField(
          action,
          _PendingActionStep.shoppingList,
          '¿A cuál lista quieres agregarlo? '
          '${currentLists.map((item) => item['name']).join(', ')}.',
        );
      }
      action.listId = list['id'] as int;
      action.shoppingListName = list['name'] as String;
    }

    if (action.intent == NivoIntent.crearGasto) {
      final duplicates = await _repository.databaseHelper
          .findPossibleDuplicateReceipts(
            amount: action.amount!,
            date: action.date,
            merchant: action.merchant ?? '',
            reference: action.receiptReference,
          );
      if (duplicates.isNotEmpty && !action.duplicateWasRejected) {
        action.duplicate = duplicates.first;
        action.requiresConfirmation = true;
        action.step = _PendingActionStep.duplicate;
        _pendingAction = action;
        final duplicate = duplicates.first;
        return _actionResponse(
          action,
          'Encontré un movimiento similar de ${_money(action.amount!, await _repository.getCurrency())}'
          '${action.merchant == null ? '' : ' en ${_pretty(action.merchant!)}'}'
          ' del ${_dayMonth(action.date)}. ¿Es el mismo movimiento?',
          requiresConfirmation: true,
          data: {'possible_duplicate': duplicate},
        );
      }
    }
    if (action.requiresConfirmation && !action.confirmed) {
      action.step = _PendingActionStep.confirm;
      _pendingAction = action;
      final currency = action.currency ?? await _repository.getCurrency();
      return _actionResponse(
        action,
        '${_proposalText(action, currency)} ¿Quieres que lo haga? Responde sí o no.',
        requiresConfirmation: true,
      );
    }
    return _executeAction(action);
  }

  NivoResponse _requestField(
    _PendingNivoAction action,
    _PendingActionStep field,
    String prompt,
  ) {
    action.step = field;
    action.requiresConfirmation = true;
    _pendingAction = action;
    return _actionResponse(action, prompt, requiresClarification: true);
  }

  Future<NivoResponse> _executeAction(_PendingNivoAction action) async {
    final database = _repository.databaseHelper;
    String? persistedReceipt;
    try {
      final currency = action.currency ?? await _repository.getCurrency();
      final amount = action.amount ?? 0;
      switch (action.intent) {
        case NivoIntent.crearGasto:
          if (action.step == _PendingActionStep.confirm) {
            final duplicates = action.duplicateWasRejected
                ? <Map<String, dynamic>>[]
                : await database.findPossibleDuplicateReceipts(
                    amount: amount,
                    date: action.date,
                    merchant: action.merchant ?? '',
                    reference: action.receiptReference,
                  );
            if (duplicates.isNotEmpty) {
              action.duplicate = duplicates.first;
              action.step = _PendingActionStep.duplicate;
              action.requiresConfirmation = true;
              _pendingAction = action;
              return _actionResponse(
                action,
                'Encontré un movimiento similar registrado mientras esperábamos. '
                '¿Es el mismo movimiento?',
                requiresConfirmation: true,
                data: {'possible_duplicate': duplicates.first},
              );
            }
          }
          if (action.receiptImagePath != null) {
            persistedReceipt = await persistReceiptImage(
              action.receiptImagePath!,
            );
          }
          final description = action.merchant == null
              ? 'Gasto en ${action.category}'
              : 'Compra en ${_pretty(action.merchant!)}';
          final id = await CreateExpenseAction(database).execute(
            amount: amount,
            category: action.category!,
            description: description,
            date: action.date,
            accountId: action.accountId,
            currency: currency,
            receiptImagePath: persistedReceipt,
            receiptItems: action.receiptItems,
            receiptReference: action.receiptReference,
          );
          _pendingAction = null;
          return _actionResponse(
            action,
            'Listo. Registré un gasto de ${_money(amount, currency)} '
            'en ${action.category}${action.merchant == null ? '' : ' en ${_pretty(action.merchant!)}'}.',
            data: {'transaction_id': id},
          );
        case NivoIntent.crearIngreso:
          final id = await CreateIncomeAction(database).execute(
            amount: amount,
            category: action.category!,
            description: action.merchant == null
                ? 'Ingreso por ${action.category}'
                : _pretty(action.merchant!),
            date: action.date,
            accountId: action.accountId,
            currency: currency,
          );
          _pendingAction = null;
          return _actionResponse(
            action,
            'Listo. Registré un ingreso de ${_money(amount, currency)} '
            'por ${action.category}'
            '${action.accountName == null ? '' : ' en ${action.accountName}'}.',
            data: {'transaction_id': id},
          );
        case NivoIntent.agregarAhorro:
          await AddSavingAction(database)
              .execute(amount, accountId: action.accountId!);
          _pendingAction = null;
          return _actionResponse(
            action,
            'Listo. Agregué ${_money(amount, currency)} a tu ahorro sin meta.',
          );
        case NivoIntent.aportarMeta:
          final goal = _findGoal(action.goalName, await _repository.getGoals());
          if (goal == null) {
            throw StateError('La meta seleccionada ya no está disponible.');
          }
          final updated = await AddGoalContributionAction(database)
              .execute(goal: goal, amount: amount);
          if (updated == 0) {
            throw StateError('No se pudo actualizar la meta.');
          }
          _pendingAction = null;
          return _actionResponse(
            action,
            'Listo. Agregué ${_money(amount, currency)} '
            'a tu meta ${action.goalName}.',
          );
        case NivoIntent.crearMeta:
          final goalName = _pretty(action.goalName!);
          final id = await CreateGoalAction(database)
              .execute(name: goalName, targetAmount: amount);
          _pendingAction = null;
          return _actionResponse(
            action,
            'Listo. Creé tu meta $goalName con objetivo de '
            '${_money(amount, currency)}.',
            data: {'goal_id': id},
          );
        case NivoIntent.agregarProductoLista:
          final id = await AddShoppingItemAction(database).execute(
            listId: action.listId!,
            name: action.product!,
            unit: action.unit,
            quantity: action.quantity,
          );
          _pendingAction = null;
          final quantity = action.quantity == action.quantity.roundToDouble()
              ? action.quantity.toStringAsFixed(0)
              : action.quantity.toString();
          return _actionResponse(
            action,
            'Listo. Agregué $quantity ${action.unit} de ${action.product} '
            'a la lista ${action.shoppingListName}.',
            data: {'shopping_product_id': id},
          );
        case NivoIntent.accionDestructiva:
          _pendingAction = null;
          return _actionResponse(
            action,
            'No ejecuté ningún cambio. Las acciones destructivas no están habilitadas en Nivo.',
            requiresClarification: true,
          );
        case NivoIntent.consultarBalance:
        case NivoIntent.consultarGastos:
        case NivoIntent.consultarIngresos:
        case NivoIntent.consultarCategoria:
        case NivoIntent.consultarAhorro:
        case NivoIntent.consultarMeta:
        case NivoIntent.consultarCuentas:
        case NivoIntent.consultarSuscripciones:
        case NivoIntent.consultarPagosProximos:
        case NivoIntent.consultarPresupuesto:
          throw StateError(
            'El intent no corresponde a una acción de escritura.',
          );
      }
    } catch (error) {
      Object? cleanupFailure;
      if (persistedReceipt != null) {
        try {
          await deleteReceiptImage(persistedReceipt);
        } catch (cleanupError) {
          cleanupFailure = cleanupError;
        }
      }
      _pendingAction = null;
      return _actionResponse(
        action,
        'No pude completar la operación: $error. No se confirmó ningún cambio.'
        '${cleanupFailure == null ? '' : ' Tampoco pude limpiar el archivo temporal: $cleanupFailure'}',
        requiresClarification: true,
        isError: true,
      );
    }
  }

  NivoResponse _actionResponse(
    _PendingNivoAction action,
    String text, {
    bool requiresClarification = false,
    bool requiresConfirmation = false,
    bool isError = false,
    Map<String, Object?> data = const {},
  }) => NivoResponse(
    text: text,
    confidence: isError ? NivoConfidence.low : NivoConfidence.high,
    intent: action.intent,
    data: data,
    requiresClarification: requiresClarification,
    requiresConfirmation: requiresConfirmation,
  );

  String _proposalText(_PendingNivoAction action, String currency) {
    final amount = action.amount == null
        ? null
        : _money(action.amount!, currency);
    return switch (action.intent) {
      NivoIntent.crearGasto =>
        'Voy a registrar un gasto de $amount en ${action.category}'
            '${action.merchant == null ? '' : ' en ${_pretty(action.merchant!)}'}'
            '${action.receiptImagePath == null ? '' : ' con el comprobante analizado'}.',
      NivoIntent.crearIngreso =>
        'Voy a registrar un ingreso de $amount por ${action.category}.',
      NivoIntent.agregarAhorro =>
        'Voy a agregar $amount a tu ahorro sin meta desde ${action.accountName}.',
      NivoIntent.aportarMeta =>
        'Voy a agregar $amount a tu meta ${action.goalName}.',
      NivoIntent.crearMeta =>
        'Voy a crear la meta ${_pretty(action.goalName!)} con objetivo de $amount.',
      NivoIntent.agregarProductoLista =>
        'Voy a agregar ${action.quantity} ${action.unit} de ${action.product} '
            'a la lista ${action.shoppingListName}.',
      _ => 'Voy a realizar esta acción.',
    };
  }

  static bool _isActionIntent(NivoIntent? intent) => switch (intent) {
    NivoIntent.crearGasto ||
    NivoIntent.crearIngreso ||
    NivoIntent.agregarAhorro ||
    NivoIntent.aportarMeta ||
    NivoIntent.crearMeta ||
    NivoIntent.agregarProductoLista ||
    NivoIntent.accionDestructiva => true,
    _ => false,
  };

  static bool _isYes(String answer) => {
    'si',
    'sí',
    'confirmo',
    'confirmar',
    'correcto',
    'dale',
    'hazlo',
  }.contains(answer);

  static bool _isNo(String answer) =>
      {'no', 'cancelar', 'cancela', 'detener'}.contains(answer);
  static bool _isCancel(String answer) =>
      {'cancelar', 'cancela', 'detener'}.contains(answer);

  static String? _canonical(String? value, List<String> choices) {
    if (value == null) return null;
    for (final choice in choices) {
      if (NivoParser.normalize(choice) == NivoParser.normalize(value)) {
        return choice;
      }
    }
    return null;
  }

  static FinancialAccount? _findAccount(
    String name,
    List<FinancialAccount> accounts,
  ) {
    for (final account in accounts) {
      if (NivoParser.normalize(account.name) == NivoParser.normalize(name)) {
        return account;
      }
    }
    return null;
  }

  static Map<String, dynamic>? _findGoal(
    String? name,
    List<Map<String, dynamic>> goals,
  ) {
    if (name == null) return null;
    for (final goal in goals) {
      if (NivoParser.normalize(goal['name'] as String) ==
          NivoParser.normalize(name)) {
        return goal;
      }
    }
    return null;
  }

  static Map<String, dynamic>? _findList(
    String? name,
    List<Map<String, dynamic>> lists,
  ) {
    if (name == null) return null;
    for (final list in lists) {
      if (list['status'] == 'current' &&
          NivoParser.normalize(list['name'] as String) ==
              NivoParser.normalize(name)) {
        return list;
      }
    }
    return null;
  }

  static String _pretty(String value) => value
      .split(RegExp(r'\s+'))
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');

  String _dayMonth(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Future<NivoResponse> _answer(NivoParseResult parsed) async {
    final intent = parsed.intent!;
    final entities = parsed.entities;
    final now = _dayStart(_clock());
    switch (intent) {
      case NivoIntent.consultarBalance:
        final balances = await _repository.getAvailableBalance();
        if (balances.isEmpty) {
          final movements = await _repository.getRecentMovements(limit: 1);
          final message = movements.isEmpty
              ? 'Todavía no tienes movimientos registrados.'
              : 'Tienes movimientos registrados, pero no hay saldo disponible en tus cuentas activas.';
          return _response(intent, parsed.confidence, message, {
            'balances': balances,
          });
        }
        return _response(
          intent,
          parsed.confidence,
          _formatBalances(
            balances,
            (currency, amount) =>
                'Tu saldo disponible actualmente es de ${_money(amount, currency)}.',
          ),
          {'balances': balances},
        );
      case NivoIntent.consultarGastos:
      case NivoIntent.consultarCategoria:
      case NivoIntent.consultarIngresos:
        return _answerTransactions(parsed, now);
      case NivoIntent.consultarAhorro:
        final savings = await _repository.getSavingsOverview();
        final currency = savings['currency'] as String;
        final total = savings['total'] as double;
        return _response(
          intent,
          parsed.confidence,
          total == 0
              ? 'Aún no tienes ahorro registrado.'
              : 'Llevas ${_money(total, currency)} ahorrados en total. '
                    'Hay ${_money(savings['unassigned'] as double, currency)} '
                    'sin asignar y ${_money(savings['goals'] as double, currency)} '
                    'en tus metas.',
          savings,
        );
      case NivoIntent.consultarMeta:
        final goals = await _repository.getGoals();
        final target = NivoParser.normalize(entities.goal ?? '');
        final matches = goals.where(
          (goal) => NivoParser.normalize(goal['name'] as String) == target,
        );
        if (matches.isEmpty) {
          return _clarify(
            intent,
            parsed.confidence,
            'No encontré esa meta. ¿Cuál de tus metas quieres consultar?',
          );
        }
        final goal = matches.first;
        final saved = (goal['saved_amount'] as num).toDouble();
        final targetAmount = (goal['target_amount'] as num).toDouble();
        final progress = targetAmount > 0 ? saved / targetAmount * 100 : 0.0;
        final currency = await _repositoryCurrency();
        return _response(
          intent,
          parsed.confidence,
          'Llevas ${_money(saved, currency)} de '
          '${_money(targetAmount, currency)} para tu '
          'meta ${goal['name']} (${progress.toStringAsFixed(0)}%).',
          {
            'goal': goal,
            'progress_percent': progress,
            'remaining': (targetAmount - saved).clamp(0, targetAmount),
          },
        );
      case NivoIntent.consultarCuentas:
        final accounts = await _repository.getAccounts();
        final requested = entities.account == null
            ? null
            : NivoParser.normalize(entities.account!);
        final selected = requested == null
            ? accounts
            : accounts
                  .where(
                    (account) =>
                        NivoParser.normalize(account.name) == requested,
                  )
                  .toList();
        if (selected.isEmpty) {
          return _clarify(
            intent,
            parsed.confidence,
            'No encontré esa cuenta. ¿Qué cuenta quieres consultar?',
          );
        }
        final text = selected
            .map(
              (account) =>
                  '${account.name}: ${_money(account.balance, account.currency)}'
                  '${account.type == FinancialAccountType.creditCard ? ' de deuda' : ''}',
            )
            .join('. ');
        return _response(intent, parsed.confidence, text, {
          'accounts': selected,
        });
      case NivoIntent.consultarSuscripciones:
        final subscriptions = await _repository.getActiveSubscriptions();
        if (subscriptions.isEmpty) {
          return _response(
            intent,
            parsed.confidence,
            'No tienes suscripciones activas.',
            {
              'subscriptions': subscriptions,
              'monthly_totals': <String, double>{},
            },
          );
        }
        final totals = <String, double>{};
        for (final subscription in subscriptions) {
          final monthly =
              subscription.amount *
              _monthlyFrequencyFactor(subscription.frequency);
          totals.update(
            subscription.currency,
            (total) => total + monthly,
            ifAbsent: () => monthly,
          );
        }
        return _response(
          intent,
          parsed.confidence,
          'Tienes ${subscriptions.length} suscripciones activas. '
          'Su costo estimado mensual es ${_formatValues(totals)}.',
          {'subscriptions': subscriptions, 'monthly_totals': totals},
        );
      case NivoIntent.consultarPagosProximos:
        final range = _periodRange(
          entities.period ?? NivoPeriod.nextThirtyDays,
          now,
          isUpcoming: true,
          date: entities.date,
        );
        final payments = await _repository.getUpcomingPayments(
          from: range.$1,
          days: range.$2.difference(range.$1).inDays,
        );
        if (payments.isEmpty) {
          return _response(
            intent,
            parsed.confidence,
            'No encontré pagos próximos en ese periodo.',
            {'payments': payments},
          );
        }
        final totals = <String, double>{};
        for (final payment in payments) {
          totals.update(
            payment.currency,
            (total) => total + payment.amount,
            ifAbsent: () => payment.amount,
          );
        }
        final details = payments
            .map(
              (payment) =>
                  '${payment.name}: ${_money(payment.amount, payment.currency)} '
                  'el ${_shortDate(payment.dueDate)}',
            )
            .join('; ');
        return _response(
          intent,
          parsed.confidence,
          'Tus próximos pagos son: $details. Total: ${_formatValues(totals)}.',
          {'payments': payments, 'totals': totals},
        );
      case NivoIntent.consultarPresupuesto:
        return _answerBudget(parsed, now);
      case NivoIntent.crearGasto:
      case NivoIntent.crearIngreso:
      case NivoIntent.agregarAhorro:
      case NivoIntent.aportarMeta:
      case NivoIntent.crearMeta:
      case NivoIntent.agregarProductoLista:
      case NivoIntent.accionDestructiva:
        return _clarify(
          intent,
          parsed.confidence,
          'No pude preparar esa acción. ¿Puedes darme más detalles?',
        );
    }
  }

  Future<NivoResponse> _answerTransactions(
    NivoParseResult parsed,
    DateTime now,
  ) async {
    final range = _periodRange(
      parsed.entities.period ?? NivoPeriod.thisMonth,
      now,
      date: parsed.entities.date,
    );
    final intent = parsed.intent!;
    final category = parsed.entities.category;
    final isIncome = intent == NivoIntent.consultarIngresos;
    final totals = category != null
        ? (await _repository.getExpensesByCategory(
                from: range.$1,
                to: range.$2,
              ))[category] ??
              <String, double>{}
        : parsed.entities.merchant != null && !isIncome
        ? await _repository.getExpensesByMerchant(
            merchant: parsed.entities.merchant!,
            from: range.$1,
            to: range.$2,
          )
        : isIncome
        ? await _repository.getIncomeByPeriod(from: range.$1, to: range.$2)
        : await _repository.getExpensesByPeriod(from: range.$1, to: range.$2);
    if (totals.isEmpty) {
      final subject = category == null
          ? parsed.entities.merchant != null && !isIncome
                ? 'gastos en ${parsed.entities.merchant}'
                : (isIncome ? 'ingresos' : 'gastos')
          : 'gastos de $category';
      return _response(
        intent,
        parsed.confidence,
        'No encontré $subject para ${_periodLabel(parsed.entities.period)}.',
        {'totals': totals, 'period': parsed.entities.period},
      );
    }
    if (parsed.entities.average) {
      final days = _elapsedDays(range.$1, range.$2, now);
      final averages = {
        for (final entry in totals.entries)
          entry.key: entry.value / (days == 0 ? 1 : days),
      };
      return _response(
        intent,
        parsed.confidence,
        'Tu promedio diario de ${category == null
            ? parsed.entities.merchant != null && !isIncome
                  ? 'gastos en ${parsed.entities.merchant}'
                  : (isIncome ? 'ingresos' : 'gastos')
            : 'gastos de $category'} '
        'es ${_formatValues(averages)} ${_periodLabel(parsed.entities.period)}.',
        {'totals': totals, 'daily_average': averages},
      );
    }
    var text = _formatBalances(
      totals,
      (currency, amount) =>
          '${_sentenceCase(_periodLabel(parsed.entities.period))} has ${isIncome ? 'recibido' : 'gastado'} '
          '${_money(amount, currency)}${category != null
              ? ' en $category'
              : parsed.entities.merchant == null
              ? ''
              : ' en ${parsed.entities.merchant}'}.',
    );
    final data = <String, Object?>{
      'totals': totals,
      'period': parsed.entities.period,
      ...?(category == null ? null : {'category': category}),
      ...?(parsed.entities.merchant == null
          ? null
          : {'merchant': parsed.entities.merchant}),
    };
    if (parsed.entities.comparePeriods) {
      final duration = range.$2.difference(range.$1);
      final previousRange = (range.$1.subtract(duration), range.$1);
      final previous = category == null && parsed.entities.merchant != null
          ? await _repository.getExpensesByMerchant(
              merchant: parsed.entities.merchant!,
              from: previousRange.$1,
              to: previousRange.$2,
            )
          : category == null
          ? isIncome
                ? await _repository.getIncomeByPeriod(
                    from: previousRange.$1,
                    to: previousRange.$2,
                  )
                : await _repository.getExpensesByPeriod(
                    from: previousRange.$1,
                    to: previousRange.$2,
                  )
          : (await _repository.getExpensesByCategory(
                  from: previousRange.$1,
                  to: previousRange.$2,
                ))[category] ??
                <String, double>{};
      final differences = <String, double>{};
      for (final currency in {...totals.keys, ...previous.keys}) {
        differences[currency] =
            (totals[currency] ?? 0) - (previous[currency] ?? 0);
      }
      text =
          '$text Comparado con el periodo anterior: ${_formatValues(differences)} de diferencia.';
      data['previous_totals'] = previous;
      data['difference'] = differences;
    }
    return _response(intent, parsed.confidence, text, data);
  }

  Future<NivoResponse> _answerBudget(
    NivoParseResult parsed,
    DateTime now,
  ) async {
    final budget = await _repository.getBudget();
    if (budget.amount == null) {
      return _response(
        parsed.intent!,
        parsed.confidence,
        'Todavía no tienes un presupuesto configurado.',
        {'budget': null},
      );
    }
    final range = budget.period == 'weekly'
        ? _periodRange(NivoPeriod.thisWeek, now)
        : _periodRange(NivoPeriod.thisMonth, now);
    final spent = await _repository.getExpensesByPeriod(
      from: range.$1,
      to: range.$2,
    );
    final currency = await _repositoryCurrency();
    final spentAmount = spent[currency] ?? 0;
    final remaining = budget.amount! - spentAmount;
    final percent = spentAmount / budget.amount! * 100;
    final text = remaining >= 0
        ? 'Has gastado ${_money(spentAmount, currency)} de tu presupuesto de '
              '${_money(budget.amount!, currency)}. Te quedan '
              '${_money(remaining, currency)} (${(100 - percent).clamp(0, 100).toStringAsFixed(0)}%).'
        : 'Has superado tu presupuesto de ${_money(budget.amount!, currency)} '
              'por ${_money(-remaining, currency)} (${percent.toStringAsFixed(0)}% utilizado).';
    return _response(parsed.intent!, parsed.confidence, text, {
      'budget': budget.amount,
      'period': budget.period,
      'spent': spentAmount,
      'remaining': remaining,
      'used_percent': percent,
    });
  }

  Future<String> _repositoryCurrency() => _repository.getCurrency();

  NivoResponse _clarify(
    NivoIntent intent,
    NivoConfidence confidence,
    String text,
  ) => NivoResponse(
    text: text,
    confidence: confidence,
    intent: intent,
    requiresClarification: true,
  );

  NivoResponse _response(
    NivoIntent intent,
    NivoConfidence confidence,
    String text,
    Map<String, Object?> data,
  ) => NivoResponse(
    text: text,
    confidence: confidence,
    intent: intent,
    data: data,
  );

  (DateTime, DateTime) _periodRange(
    NivoPeriod period,
    DateTime now, {
    bool isUpcoming = false,
    DateTime? date,
  }) {
    final today = _dayStart(now);
    switch (period) {
      case NivoPeriod.today:
        return (today, today.add(const Duration(days: 1)));
      case NivoPeriod.thisWeek:
        final start = today.subtract(Duration(days: today.weekday - 1));
        final end = start.add(const Duration(days: 7));
        return isUpcoming && start.isBefore(today)
            ? (today, end)
            : (start, end);
      case NivoPeriod.lastWeek:
        final end = today.subtract(Duration(days: today.weekday - 1));
        return (end.subtract(const Duration(days: 7)), end);
      case NivoPeriod.thisMonth:
        final start = DateTime(today.year, today.month);
        return (start, DateTime(today.year, today.month + 1));
      case NivoPeriod.lastMonth:
        final start = DateTime(today.year, today.month - 1);
        return (start, DateTime(today.year, today.month));
      case NivoPeriod.thisYear:
        return (DateTime(today.year), DateTime(today.year + 1));
      case NivoPeriod.lastYear:
        return (DateTime(today.year - 1), DateTime(today.year));
      case NivoPeriod.customDate:
        final selected = _dayStart(date ?? now);
        return (selected, selected.add(const Duration(days: 1)));
      case NivoPeriod.nextSevenDays:
        return (today, today.add(const Duration(days: 7)));
      case NivoPeriod.nextThirtyDays:
        return (today, today.add(const Duration(days: 30)));
    }
  }

  static DateTime _dayStart(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static int _elapsedDays(DateTime from, DateTime to, DateTime now) {
    final today = _dayStart(now);
    if (!today.isBefore(from) && today.isBefore(to)) {
      return today.difference(from).inDays + 1;
    }
    return to.difference(from).inDays.clamp(1, 1000000).toInt();
  }

  static String _periodLabel(NivoPeriod? period) => switch (period) {
    NivoPeriod.today => 'hoy',
    NivoPeriod.thisWeek => 'esta semana',
    NivoPeriod.lastWeek => 'la semana pasada',
    NivoPeriod.thisMonth => 'este mes',
    NivoPeriod.lastMonth => 'el mes pasado',
    NivoPeriod.thisYear => 'este año',
    NivoPeriod.lastYear => 'el año pasado',
    NivoPeriod.customDate => 'ese día',
    NivoPeriod.nextSevenDays => 'los próximos 7 días',
    NivoPeriod.nextThirtyDays => 'los próximos 30 días',
    null => 'este mes',
  };

  static String _sentenceCase(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  static String _formatBalances(
    Map<String, double> values,
    String Function(String, double) formatter,
  ) => values.entries
      .map((entry) => formatter(entry.key, entry.value))
      .join(' ');

  static String _formatValues(Map<String, double> values) =>
      values.entries.map((entry) => _money(entry.value, entry.key)).join(' y ');

  static String _money(double amount, String currency) {
    final sign = amount < 0 ? '-' : '';
    final absolute = amount.abs();
    final fixed = absolute.toStringAsFixed(2);
    final parts = fixed.split('.');
    final integer = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
    final decimals = parts[1] == '00' ? '' : '.${parts[1]}';
    final symbol = switch (currency) {
      'MXN' || 'USD' || 'CAD' || 'AUD' => '\$',
      'EUR' => '€',
      'GBP' => '£',
      _ => '$currency ',
    };
    return '$sign$symbol$integer$decimals';
  }

  static String _shortDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

  static double _monthlyFrequencyFactor(SubscriptionFrequency frequency) =>
      switch (frequency) {
        SubscriptionFrequency.weekly => 52 / 12,
        SubscriptionFrequency.biweekly => 26 / 12,
        SubscriptionFrequency.monthly => 1,
        SubscriptionFrequency.bimonthly => 1 / 2,
        SubscriptionFrequency.quarterly => 1 / 3,
        SubscriptionFrequency.semiannual => 1 / 6,
        SubscriptionFrequency.annual => 1 / 12,
      };
}

class _ActionContext {
  const _ActionContext({
    required this.categories,
    required this.goals,
    required this.accounts,
    required this.lists,
  });

  final List<String> categories;
  final List<Map<String, dynamic>> goals;
  final List<FinancialAccount> accounts;
  final List<Map<String, dynamic>> lists;
}

enum _PendingActionStep {
  ready,
  amount,
  category,
  goal,
  account,
  product,
  shoppingList,
  duplicate,
  confirm,
}

class _PendingNivoAction {
  _PendingNivoAction({
    required this.intent,
    this.amount,
    this.category,
    this.merchant,
    required this.date,
    this.accountId,
    this.accountName,
    this.goalName,
    this.product,
    this.quantity = 1,
    this.unit = 'unidad',
    this.shoppingListName,
    this.receiptImagePath,
    this.receiptItems = const [],
    this.receiptReference,
    this.requiresConfirmation = false,
  });

  final NivoIntent intent;
  double? amount;
  String? category;
  String? merchant;
  final DateTime date;
  int? accountId;
  String? accountName;
  String? currency;
  String? goalName;
  String? product;
  double quantity;
  String unit;
  String? shoppingListName;
  int? listId;
  final String? receiptImagePath;
  final List<String> receiptItems;
  final String? receiptReference;
  bool requiresConfirmation;
  bool confirmed = false;
  bool duplicateWasRejected = false;
  Map<String, dynamic>? duplicate;
  _PendingActionStep step = _PendingActionStep.ready;
}
