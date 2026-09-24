import 'package:flutter/material.dart';
import 'package:mova/database/database_helper.dart';
import 'package:mova/services/currency_controller.dart';
import 'package:mova/services/mova_localizations.dart';

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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          l10n.text('movements'),
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFFF8FAFC),
        foregroundColor: const Color(0xFF102A43),
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
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0C2340), Color(0xFF36577D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x220C2340),
                        blurRadius: 16,
                        offset: Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.swap_vert_rounded,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.text('financial_activity'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
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
                              selectedColor: const Color(0xFFDCE7F2),
                              labelStyle: TextStyle(
                                color: _filter == filter
                                    ? const Color(0xFF0C2340)
                                    : const Color(0xFF64748B),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                if (transactions.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: Center(
                      child: Text(
                        l10n.text('no_movements_filter'),
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ),
                  )
                else
                  ...transactions.map(
                    (transaction) => _MovementTile(
                      transaction: transaction,
                      date: _date(
                        context,
                        transaction['date'] as String? ?? '',
                      ),
                    ),
                  ),
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

  const _MovementTile({required this.transaction, required this.date});

  @override
  Widget build(BuildContext context) {
    final savingsDeposit = DatabaseHelper.isSavingsDeposit(transaction);
    final savingsWithdrawal = DatabaseHelper.isSavingsWithdrawal(transaction);
    final isExpense = transaction['is_income'] == 0 && !savingsDeposit;
    final amount = (transaction['amount'] as num).toDouble();
    final color = isExpense ? const Color(0xFFB42318) : const Color(0xFF0C2340);
    final prefix = isExpense || savingsWithdrawal ? '-' : '+';
    final label = savingsDeposit || savingsWithdrawal
        ? 'Ahorro'
        : isExpense
        ? 'Gasto'
        : 'Ingreso';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: color.withValues(alpha: .1),
            child: Icon(
              savingsDeposit || savingsWithdrawal
                  ? Icons.savings_outlined
                  : isExpense
                  ? Icons.south_west_rounded
                  : Icons.arrow_outward_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['description'] as String? ?? label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF102A43),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${transaction['category']} · $date',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
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
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: .75),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
