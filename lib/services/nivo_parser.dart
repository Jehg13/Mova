import 'package:mova/models/nivo_query.dart';

class NivoParser {
  NivoParseResult parse(
    String input, {
    Iterable<String> categories = const [],
    Iterable<String> accounts = const [],
    Iterable<String> goals = const [],
    Iterable<String> shoppingLists = const [],
  }) {
    final text = normalize(input);
    if (text.isEmpty) {
      return _unclear('¿Qué información financiera quieres consultar?');
    }

    final actionIntent = _detectActionIntent(text);
    final category = _findKnownEntity(text, categories) ?? _categoryAlias(text);
    final account =
        _findKnownEntity(text, accounts) ??
        _capturedEntity(
          text,
          r'\bcuenta(?:\s+de)?\s+(.+?)(?=\s+(?:este|esta|del|para|con|por)\b|$)',
        );
    final savingForGoal = _containsAny(text, [
      'ahorrado para',
      'ahorro para',
      'ahorrando para',
    ]);
    final goal =
        _findKnownEntity(text, goals) ??
        _capturedEntity(
          text,
          r'\bmeta\s+(?:de|del|para)\s+(.+?)(?=\s+(?:este|esta|del|para|con|por)\b|$)',
        ) ??
        (actionIntent == NivoIntent.crearMeta
            ? _capturedEntity(
                text,
                r'\bmeta\s+(?:llamada\s+)?(.+?)(?=\s+(?:de|para)\s+\$?\d|$)',
              )?.replaceFirst(RegExp(r'^(?:de|del|para)\s+'), '')
            : null) ??
        (savingForGoal
            ? _capturedEntity(
                text,
                r'\bpara\s+(?:mi\s+)?(.+?)(?=\s+(?:este|esta|del|con|por)\b|$)',
              )
            : null);
    final frequency = _frequency(text);
    final date = _date(text);
    final period = _period(text, date);
    final amount = actionIntent == NivoIntent.agregarProductoLista
        ? null
        : _amount(
            text.replaceAll(RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{4}\b'), ' '),
          );
    final shopping = _shoppingEntities(text, shoppingLists);
    final merchant = _merchant(text, category, account, goal);
    final entities = NivoEntities(
      category: category,
      amount: amount,
      date: date,
      period: period,
      account: account,
      goal: goal,
      merchant: merchant,
      frequency: frequency,
      quantity: shopping.quantity,
      unit: shopping.unit,
      product: shopping.product,
      shoppingList: shopping.list,
      comparePeriods: _containsAny(text, [
        'comparar',
        'compara',
        'comparacion',
        'comparativa',
        'comparado',
        'comparada',
        'contra',
        ' vs ',
      ]),
      average: _containsAny(text, [
        'promedio',
        'promedio diario',
        'en promedio',
      ]),
    );

    if (date == null &&
        RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{4}\b').hasMatch(text)) {
      return _unclear(
        'No pude interpretar esa fecha. ¿Puedes escribirla como día/mes/año?',
        entities: entities,
      );
    }
    final intent = actionIntent ?? _detectIntent(text, category, goal);
    if (intent == null) {
      return _unclear(_unknownQuestion(text), entities: entities);
    }
    if (intent == NivoIntent.consultarMeta && goal == null) {
      return NivoParseResult(
        intent: intent,
        entities: entities,
        confidence: NivoConfidence.medium,
        clarification: '¿De cuál de tus metas quieres consultar el progreso?',
      );
    }
    if (intent == NivoIntent.consultarCategoria && category == null) {
      return NivoParseResult(
        intent: intent,
        entities: entities,
        confidence: NivoConfidence.medium,
        clarification: '¿Qué categoría quieres consultar?',
      );
    }
    final effectivePeriod =
        period ??
        (intent == NivoIntent.consultarGastos ||
                intent == NivoIntent.consultarIngresos ||
                intent == NivoIntent.consultarCategoria
            ? NivoPeriod.thisMonth
            : null);
    final resolvedEntities = NivoEntities(
      category: category,
      amount: amount,
      date: date,
      period: effectivePeriod,
      account: account,
      goal: goal,
      merchant: merchant,
      frequency: frequency,
      quantity: entities.quantity,
      unit: entities.unit,
      product: entities.product,
      shoppingList: entities.shoppingList,
      comparePeriods: entities.comparePeriods,
      average: entities.average,
    );
    return NivoParseResult(
      intent: intent,
      entities: resolvedEntities,
      confidence:
          period == null &&
              (intent == NivoIntent.consultarGastos ||
                  intent == NivoIntent.consultarIngresos ||
                  intent == NivoIntent.consultarCategoria ||
                  intent == NivoIntent.consultarPagosProximos)
          ? NivoConfidence.medium
          : NivoConfidence.high,
    );
  }

  static String normalize(String input) {
    const accents = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };
    var text = input.toLowerCase();
    for (final entry in accents.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }
    return text
        .replaceAll(RegExp(r'[¿?¡!;:()]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  NivoIntent? _detectActionIntent(String text) {
    if (_containsAny(text, [
      'elimina',
      'eliminar',
      'borra',
      'borrar',
      'vacía',
      'vacia',
      'vaciar',
    ])) {
      return NivoIntent.accionDestructiva;
    }
    final addVerb = _containsAny(text, [
      'agrega',
      'agregar',
      'añade',
      'anade',
      'añadir',
      'anadir',
      'aporta',
      'aportar',
      'deposita',
      'deposita',
      'pon ',
      'mete ',
    ]);
    if (RegExp(r'\b(?:crea|crear|nueva|nuevo)\s+(?:una?\s+)?meta\b')
        .hasMatch(text)) {
      return NivoIntent.crearMeta;
    }
    if (addVerb &&
        _containsAny(text, ['meta', 'objetivo']) &&
        !_containsAny(text, ['sin meta', 'sin objetivo'])) {
      return NivoIntent.aportarMeta;
    }
    if (addVerb && _containsAny(text, ['lista', 'lista de compras'])) {
      return NivoIntent.agregarProductoLista;
    }
    if (addVerb && _containsAny(text, ['ahorro', 'ahorros', 'ahorrar'])) {
      return NivoIntent.agregarAhorro;
    }
    final explicitCommand = _containsAny(text, [
      'registra',
      'registrar',
      'anota',
      'anotar',
      'guarda',
      'guardar',
    ]);
    if (explicitCommand &&
        _containsAny(text, [
          'ingreso',
          'recibi',
          'cobre',
          'nomina',
          'sueldo',
        ])) {
      return NivoIntent.crearIngreso;
    }
    if (explicitCommand &&
        _containsAny(text, ['gasto', 'gastos', 'gaste', 'compra'])) {
      return NivoIntent.crearGasto;
    }
    return null;
  }

  NivoIntent? _detectIntent(String text, String? category, String? goal) {
    if (_containsAny(text, ['suscripcion', 'suscripciones', 'streaming'])) {
      return NivoIntent.consultarSuscripciones;
    }
    if (_containsAny(text, ['presupuesto', 'presupuestado'])) {
      return NivoIntent.consultarPresupuesto;
    }
    if (_containsAny(text, ['meta', 'metas', 'objetivo', 'objetivos']) ||
        (goal != null &&
            _containsAny(text, ['ahorrado', 'ahorro', 'ahorrando']))) {
      return NivoIntent.consultarMeta;
    }
    if (_containsAny(text, ['pago', 'pagos', 'vencimiento', 'vencimientos']) &&
        _containsAny(text, [
          'proximo',
          'proximos',
          'tengo',
          'hay',
          'pendiente',
          'esta semana',
          'este mes',
          'hoy',
          'semana',
          'mes',
        ])) {
      return NivoIntent.consultarPagosProximos;
    }
    if (_containsAny(text, ['cuenta', 'cuentas', 'tarjeta', 'tarjetas'])) {
      return NivoIntent.consultarCuentas;
    }
    if (_containsAny(text, [
      'saldo',
      'balance',
      'dinero tengo',
      'disponible',
    ])) {
      return NivoIntent.consultarBalance;
    }
    if (_containsAny(text, [
      'ingreso',
      'ingresos',
      'gane',
      'recibi',
      'cobre',
    ])) {
      return NivoIntent.consultarIngresos;
    }
    if (_containsAny(text, [
      'gaste',
      'gasto',
      'gastos',
      'compras',
      'consumo',
    ])) {
      return category == null
          ? NivoIntent.consultarGastos
          : NivoIntent.consultarCategoria;
    }
    if (_containsAny(text, ['ahorrado', 'ahorro', 'ahorros', 'ahorre'])) {
      return NivoIntent.consultarAhorro;
    }
    if (category != null) return NivoIntent.consultarCategoria;
    return null;
  }

  NivoParseResult _unclear(String question, {NivoEntities? entities}) =>
      NivoParseResult(
        intent: null,
        entities: entities ?? const NivoEntities(),
        confidence: NivoConfidence.low,
        clarification: question,
      );

  String _unknownQuestion(String text) {
    if (_containsAny(text, ['cuanto', 'que', 'cual', 'como'])) {
      return '¿Quieres consultar saldo, gastos, ingresos, ahorros, metas o pagos próximos?';
    }
    return 'No entendí la consulta. ¿Qué dato de tus finanzas quieres conocer?';
  }

  String? _findKnownEntity(String text, Iterable<String> candidates) {
    final normalized =
        candidates.where((candidate) => candidate.trim().isNotEmpty).toList()
          ..sort((a, b) => b.length.compareTo(a.length));
    for (final candidate in normalized) {
      final value = normalize(candidate);
      final pattern =
          r'(^|[^a-z0-9])' + RegExp.escape(value) + r'(?=[^a-z0-9]|$)';
      if (RegExp(pattern).hasMatch(text)) {
        return candidate;
      }
    }
    return null;
  }

  String? _categoryAlias(String text) {
    const aliases = {
      'comida': 'Comida',
      'alimentos': 'Comida',
      'comer': 'Comida',
      'transporte': 'Transporte',
      'gasolina': 'Transporte',
      'compras': 'Compras',
      'hogar': 'Hogar',
      'renta': 'Hogar',
      'entretenimiento': 'Entretenimiento',
      'diversion': 'Entretenimiento',
      'ahorro': 'Ahorro',
      'nomina': 'Sueldo',
      'sueldo': 'Sueldo',
    };
    for (final entry in aliases.entries) {
      final pattern =
          r'(^|[^a-z0-9])' + RegExp.escape(entry.key) + r'(?=[^a-z0-9]|$)';
      if (RegExp(pattern).hasMatch(text)) {
        return entry.value;
      }
    }
    return null;
  }

  String? _capturedEntity(String text, String pattern) {
    final match = RegExp(pattern).firstMatch(text);
    final value = match?.group(1)?.trim();
    if (value == null || value.isEmpty) return null;
    return value
        .replaceAll(RegExp(r'\b(mi|mis|la|el|los|las)\b'), '')
        .replaceFirst(RegExp(r'[.,!?]+$'), '')
        .trim();
  }

  String? _merchant(
    String text,
    String? category,
    String? account,
    String? goal,
  ) {
    if (!_containsAny(text, [
      'compre',
      'pague',
      'gaste',
      'registra',
      'registrar',
      'anota',
      'guarda',
    ])) {
      return null;
    }
    final captured =
        _capturedEntity(
          text,
          r'\ben\s+(.+?)(?=\s+(?:este|esta|del|para|con|por|el|desde|comprando)\b|$)',
        ) ??
        _capturedEntity(
          text,
          r'\bde\s+([a-z][a-z0-9 &.-]*?)(?=\s+(?:el|este|esta|con|por|desde)\b|$)',
        );
    if (captured == null ||
        [
          category,
          account,
          goal,
        ].whereType<String>().any((entity) => normalize(entity) == captured)) {
      return null;
    }
    return captured;
  }

  ({double? quantity, String? unit, String? product, String? list})
  _shoppingEntities(String text, Iterable<String> lists) {
    final cleanedText = text.replaceFirst(RegExp(r'[.]+$'), '').trim();
    final match = RegExp(
      r'\b(?:agrega|agregar|añade|anade|añadir|anadir|pon|mete)\s+'
      r'(?:(\d+(?:[.,]\d+)?)\s+)?'
      r'(?:(kg|kilo(?:s)?|g|gramo(?:s)?|l|litro(?:s)?|ml|'
      r'piezas?|unidades?|paquetes?)\s+)?'
      r'(.+?)\s+(?:a|en)\s+(?:(?:mi|la|una)\s+)?lista'
      r'(?:\s+de\s+compras)?(?:\s+(.+))?$',
    ).firstMatch(cleanedText);
    if (match == null) {
      return (
        quantity: null,
        unit: null,
        product: null,
        list: _findKnownEntity(cleanedText, lists),
      );
    }
    var product = (match.group(3) ?? '').trim();
    product = product.replaceFirst(RegExp(r'^(?:de|del)\s+'), '').trim();
    final listText = match.group(4)?.trim();
    return (
      quantity:
          double.tryParse((match.group(1) ?? '').replaceAll(',', '.')) ??
          (match.group(1) == null ? 1 : null),
      unit: match.group(2),
      product: product.isEmpty ? null : product,
      list: _findKnownEntity(cleanedText, lists) ?? listText,
    );
  }

  String? _frequency(String text) {
    const frequencies = {
      'semanal': 'weekly',
      'quincenal': 'biweekly',
      'mensual': 'monthly',
      'bimestral': 'bimonthly',
      'trimestral': 'quarterly',
      'semestral': 'semiannual',
      'anual': 'annual',
    };
    for (final entry in frequencies.entries) {
      if (text.contains(entry.key)) return entry.value;
    }
    return null;
  }

  DateTime? _date(String text) {
    final match = RegExp(r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{4})\b')
        .firstMatch(text);
    if (match == null) return null;
    final date = DateTime(
      int.parse(match.group(3)!),
      int.parse(match.group(2)!),
      int.parse(match.group(1)!),
    );
    if (date.year != int.parse(match.group(3)!) ||
        date.month != int.parse(match.group(2)!) ||
        date.day != int.parse(match.group(1)!)) {
      return null;
    }
    return date;
  }

  NivoPeriod? _period(String text, DateTime? date) {
    if (date != null) return NivoPeriod.customDate;
    if (_containsAny(text, ['hoy', 'este dia'])) {
      return NivoPeriod.today;
    }
    if (_containsAny(text, ['esta semana'])) {
      return NivoPeriod.thisWeek;
    }
    if (_containsAny(text, ['semana pasada', 'la semana anterior'])) {
      return NivoPeriod.lastWeek;
    }
    if (_containsAny(text, ['este mes'])) {
      return NivoPeriod.thisMonth;
    }
    if (_containsAny(text, ['mes pasado', 'el mes anterior'])) {
      return NivoPeriod.lastMonth;
    }
    if (_containsAny(text, ['este ano', 'en el ano'])) {
      return NivoPeriod.thisYear;
    }
    if (_containsAny(text, ['ano pasado', 'el ano anterior'])) {
      return NivoPeriod.lastYear;
    }
    if (_containsAny(text, ['proximos 7 dias'])) {
      return NivoPeriod.nextSevenDays;
    }
    if (_containsAny(text, ['proxima semana', 'siguiente semana'])) {
      return NivoPeriod.nextSevenDays;
    }
    if (_containsAny(text, ['proximos 30 dias'])) {
      return NivoPeriod.nextThirtyDays;
    }
    if (_containsAny(text, ['proximo mes', 'siguiente mes'])) {
      return NivoPeriod.nextThirtyDays;
    }
    if (_containsAny(text, [
      'proximamente',
      'proximos pagos',
      'proximo pago',
      'siguientes pagos',
    ])) {
      return NivoPeriod.nextThirtyDays;
    }
    return null;
  }

  double? _amount(String text) {
    final match = RegExp(r'\$?\s*(\d[\d,.]*)').firstMatch(text);
    if (match == null) return null;
    var value = match.group(1)!;
    final decimalSeparator = _decimalSeparator(value);
    if (decimalSeparator == ',') {
      value = value.replaceAll('.', '').replaceFirst(',', '.');
    } else {
      value = value.replaceAll(',', '');
    }
    return double.tryParse(value);
  }

  String? _decimalSeparator(String value) {
    final comma = value.lastIndexOf(',');
    final dot = value.lastIndexOf('.');
    if (comma >= 0 && dot >= 0) return comma > dot ? ',' : '.';
    final separator = comma >= 0
        ? ','
        : dot >= 0
        ? '.'
        : null;
    if (separator == null) return null;
    final lastSeparator = value.lastIndexOf(separator);
    final trailingDigits = value.length - lastSeparator - 1;
    if (value.indexOf(separator) != lastSeparator) {
      return trailingDigits == 2 ? separator : null;
    }
    return trailingDigits == 3 ? null : separator;
  }

  bool _containsAny(String text, Iterable<String> words) =>
      words.any((word) => text.contains(word));
}
