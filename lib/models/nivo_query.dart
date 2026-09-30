enum NivoIntent {
  consultarBalance,
  consultarGastos,
  consultarIngresos,
  consultarCategoria,
  consultarAhorro,
  consultarMeta,
  consultarCuentas,
  consultarSuscripciones,
  consultarPagosProximos,
  consultarPresupuesto,
  crearGasto,
  crearIngreso,
  agregarAhorro,
  aportarMeta,
  crearMeta,
  agregarProductoLista,
  accionDestructiva,
}

extension NivoIntentLabel on NivoIntent {
  String get id => switch (this) {
    NivoIntent.consultarBalance => 'consultar_balance',
    NivoIntent.consultarGastos => 'consultar_gastos',
    NivoIntent.consultarIngresos => 'consultar_ingresos',
    NivoIntent.consultarCategoria => 'consultar_categoria',
    NivoIntent.consultarAhorro => 'consultar_ahorro',
    NivoIntent.consultarMeta => 'consultar_meta',
    NivoIntent.consultarCuentas => 'consultar_cuentas',
    NivoIntent.consultarSuscripciones => 'consultar_suscripciones',
    NivoIntent.consultarPagosProximos => 'consultar_pagos_proximos',
    NivoIntent.consultarPresupuesto => 'consultar_presupuesto',
    NivoIntent.crearGasto => 'crear_gasto',
    NivoIntent.crearIngreso => 'crear_ingreso',
    NivoIntent.agregarAhorro => 'agregar_ahorro',
    NivoIntent.aportarMeta => 'aportar_meta',
    NivoIntent.crearMeta => 'crear_meta',
    NivoIntent.agregarProductoLista => 'agregar_producto_lista',
    NivoIntent.accionDestructiva => 'accion_destructiva',
  };
}

enum NivoConfidence { high, medium, low }

enum NivoPeriod {
  today,
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  thisYear,
  lastYear,
  customDate,
  nextSevenDays,
  nextThirtyDays,
}

class NivoEntities {
  const NivoEntities({
    this.category,
    this.amount,
    this.date,
    this.period,
    this.account,
    this.goal,
    this.merchant,
    this.frequency,
    this.quantity,
    this.unit,
    this.product,
    this.shoppingList,
    this.comparePeriods = false,
    this.average = false,
  });

  final String? category;
  final double? amount;
  final DateTime? date;
  final NivoPeriod? period;
  final String? account;
  final String? goal;
  final String? merchant;
  final String? frequency;
  final double? quantity;
  final String? unit;
  final String? product;
  final String? shoppingList;
  final bool comparePeriods;
  final bool average;
}

class NivoParseResult {
  const NivoParseResult({
    required this.intent,
    required this.entities,
    required this.confidence,
    this.clarification,
  });

  final NivoIntent? intent;
  final NivoEntities entities;
  final NivoConfidence confidence;
  final String? clarification;

  bool get requiresClarification =>
      confidence == NivoConfidence.low || clarification != null;
}
