import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mova/database/database_helper.dart';
import 'package:mova/services/currency_controller.dart';
import 'package:mova/services/mova_localizations.dart';
import 'package:mova/widgets/receipt_image_preview.dart';
import 'package:mova/widgets/mova_design_system.dart';

class MovementsScreen extends StatefulWidget {
  const MovementsScreen({super.key});

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  final _database = DatabaseHelper();
  late Future<List<Map<String, dynamic>>> _transactions;
  String _filter = 'Todos';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _transactions = _database.getTransactions();
  }

  bool _matchesFilter(Map<String, dynamic> transaction) {
    switch (_filter) {
      case 'Ingresos':
        return transaction['is_income'] == 1 &&
            !DatabaseHelper.isSavingsWithdrawal(transaction);
      case 'Gastos':
        return transaction['is_income'] == 0 &&
            !DatabaseHelper.isSavingsDeposit(transaction);
      case 'Ahorros':
        return DatabaseHelper.isSavingsDeposit(transaction) ||
            DatabaseHelper.isSavingsWithdrawal(transaction);
      default:
        return true;
    }
  }

  String _date(BuildContext context, String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return '';
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: MovaDesign.canvas,
      appBar: AppBar(
        title: Text(
          l10n.text('movements'),
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: MovaDesign.canvas,
        foregroundColor: MovaDesign.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _transactions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                movaText(
                  'No se pudieron cargar los movimientos: ${snapshot.error}',
                ),
              ),
            );
          }

          final transactions = (snapshot.data ?? [])
              .where(_matchesFilter)
              .toList();
          return RefreshIndicator(
            onRefresh: () async {
              setState(_load);
              await _transactions;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5F1F4),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.swap_vert_rounded,
                          color: MovaDesign.accent,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.text('financial_activity'),
                              style: const TextStyle(
                                color: MovaDesign.ink,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.text('movements'),
                              style: const TextStyle(
                                color: MovaDesign.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Todos', 'Ingresos', 'Gastos', 'Ahorros']
                        .map(
                          (filter) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              avatar: Icon(
                                filter == 'Ingresos'
                                    ? Icons.arrow_outward_rounded
                                    : filter == 'Gastos'
                                    ? Icons.south_west_rounded
                                    : filter == 'Ahorros'
                                    ? Icons.savings_outlined
                                    : Icons.tune_rounded,
                                size: 16,
                              ),
                              label: Text(
                                filter == 'Todos'
                                    ? l10n.text('all')
                                    : filter == 'Ingresos'
                                    ? l10n.text('income')
                                    : filter == 'Gastos'
                                    ? l10n.text('expenses')
                                    : l10n.text('savings'),
                              ),
                              selected: _filter == filter,
                              onSelected: (_) =>
                                  setState(() => _filter = filter),
                              selectedColor: const Color(0xFFE2F1F3),
                              labelStyle: TextStyle(
                                color: _filter == filter
                                    ? MovaDesign.navy
                                    : MovaDesign.muted,
                                fontWeight: FontWeight.w700,
                              ),
                              side: BorderSide(
                                color: _filter == filter
                                    ? const Color(0xFFB8DDE1)
                                    : MovaDesign.border,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 14),
                if (transactions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 56),
                    child: MovaEmptyState(
                      icon: Icons.receipt_long_rounded,
                      title: l10n.text('no_movements_filter'),
                      message: l10n.text('financial_activity'),
                    ),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Text(
                      l10n.text('financial_activity'),
                      style: const TextStyle(
                        color: MovaDesign.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ...transactions.asMap().entries.map(
                    (entry) => _MovementTile(
                      transaction: entry.value,
                      date: _date(
                        context,
                        entry.value['date'] as String? ?? '',
                      ),
                      showDivider: entry.key < transactions.length - 1,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final String date;
  final bool showDivider;

  const _MovementTile({
    required this.transaction,
    required this.date,
    required this.showDivider,
  });

  Future<void> _showReceipt(BuildContext context) async {
    final l10n = context.l10n;
    final rawItems = transaction['receipt_items'] as String?;
    List<String> items = const [];
    if (rawItems != null && rawItems.isNotEmpty) {
      try {
        items = List<String>.from(jsonDecode(rawItems) as List);
      } on FormatException {
        items = [rawItems];
      } on TypeError {
        items = [rawItems];
      }
    }
    final imagePath = transaction['receipt_image_path'] as String?;
    final reference = transaction['receipt_reference'] as String?;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          transaction['description'] as String? ?? l10n.text('expense'),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imagePath != null && imagePath.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ReceiptImagePreview(path: imagePath, height: 220),
                ),
              if (reference != null && reference.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('${l10n.text('receipt_reference')}: $reference'),
              ],
              if (items.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.text('receipt_items'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                ...items.map((item) => Text(item)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.text('close')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final savingsDeposit = DatabaseHelper.isSavingsDeposit(transaction);
    final savingsWithdrawal = DatabaseHelper.isSavingsWithdrawal(transaction);
    final isExpense = transaction['is_income'] == 0 && !savingsDeposit;
    final amount = (transaction['amount'] as num).toDouble();
    final color = isExpense
        ? MovaDesign.negative
        : savingsDeposit || savingsWithdrawal
        ? MovaDesign.navy
        : MovaDesign.positive;
    final prefix = isExpense || savingsWithdrawal ? '-' : '+';
    final label = savingsDeposit || savingsWithdrawal
        ? l10n.text('savings')
        : isExpense
        ? l10n.text('expense')
        : l10n.text('income_singular');
    final category = l10n.translate(transaction['category'] as String? ?? '');
    final description = transaction['description'] as String? ?? label;
    final icon = savingsDeposit || savingsWithdrawal
        ? Icons.savings_rounded
        : isExpense
        ? _expenseIcon(transaction['category'] as String? ?? '')
        : Icons.arrow_outward_rounded;
    final hasReceipt =
        (transaction['receipt_image_path'] as String?)?.isNotEmpty == true ||
        (transaction['receipt_items'] as String?)?.isNotEmpty == true;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: MovaDesign.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$category · $date',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: MovaDesign.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    movaText('$prefix${appCurrencyController.format(amount)}'),
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: TextStyle(
                      color: color.withValues(alpha: .8),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (hasReceipt)
                IconButton(
                  tooltip: l10n.text('receipt_view'),
                  onPressed: () => _showReceipt(context),
                  icon: const Icon(Icons.receipt_long_outlined, size: 19),
                ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 56, color: MovaDesign.border),
      ],
    );
  }
}

IconData _expenseIcon(String category) => switch (category) {
  'Comida' => Icons.restaurant_rounded,
  'Transporte' => Icons.directions_car_rounded,
  'Compras' => Icons.shopping_bag_rounded,
  'Hogar' => Icons.home_rounded,
  'Entretenimiento' => Icons.movie_rounded,
  'Salud' => Icons.health_and_safety_rounded,
  _ => Icons.south_west_rounded,
};
