import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mova/database/database_helper.dart';
import 'package:mova/services/currency_controller.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _database = DatabaseHelper();
  String _period = 'Este mes';
  late Future<List<Map<String, dynamic>>> _transactions;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _transactions = _database.getTransactions();
  }

  void _refresh() {
    setState(_load);
  }

  DateTime _startDate() {
    final now = DateTime.now();
    if (_period == 'Mes anterior') {
      return DateTime(now.year, now.month - 1, 1);
    }
    return DateTime(now.year, now.month, 1);
  }

  String _money(num value) => appCurrencyController.format(value);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _transactions,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('No se pudo cargar el análisis: ${snapshot.error}'),
              );
            }
            final start = _startDate();
            final end = _period == 'Mes anterior'
                ? DateTime(start.year, start.month + 1, 1)
                : DateTime(start.year, start.month + 1, 1);
            final transactions = (snapshot.data ?? []).where((row) {
              final date = DateTime.tryParse(row['date'] as String? ?? '');
              return date != null &&
                  !date.isBefore(start) &&
                  date.isBefore(end);
            }).toList();
            return RefreshIndicator(
              onRefresh: () async {
                _refresh();
                await _transactions;
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                children: [
                  _Header(
                    period: _period,
                    onChanged: (value) {
                      if (value != null) setState(() => _period = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  _SummaryCard(transactions: transactions, money: _money),
                  const SizedBox(height: 16),
                  _DailyChartCard(transactions: transactions, money: _money),
                  const SizedBox(height: 20),
                  _CategorySection(transactions: transactions, money: _money),
                  const SizedBox(height: 20),
                  _InsightCard(transactions: transactions, money: _money),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String period;
  final ValueChanged<String?> onChanged;

  const _Header({required this.period, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Análisis',
            style: TextStyle(
              color: Color(0xFF102A43),
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        DropdownButton<String>(
          value: period,
          underline: const SizedBox(),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: const [
            DropdownMenuItem(value: 'Este mes', child: Text('Este mes')),
            DropdownMenuItem(
              value: 'Mes anterior',
              child: Text('Mes anterior'),
            ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final String Function(num) money;

  const _SummaryCard({required this.transactions, required this.money});

  @override
  Widget build(BuildContext context) {
    var income = 0.0;
    var expenses = 0.0;
    for (final transaction in transactions) {
      final amount = (transaction['amount'] as num).toDouble();
      if (transaction['is_income'] == 1) {
        income += amount;
      } else {
        expenses += amount;
      }
    }
    final balance = income - expenses;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen del periodo',
            style: TextStyle(
              color: Color(0xFF102A43),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Stat('Ingresos', money(income), const Color(0xFF0C2340)),
              _Stat('Gastos', money(expenses), const Color(0xFF2563EB)),
              _Stat('Balance', money(balance), const Color(0xFFD97706)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _Stat(this.title, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyChartCard extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final String Function(num) money;

  const _DailyChartCard({required this.transactions, required this.money});

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (index) {
      final day = DateTime.now().subtract(Duration(days: 6 - index));
      var income = 0.0;
      var expense = 0.0;
      for (final transaction in transactions) {
        final date = DateTime.tryParse(transaction['date'] as String? ?? '');
        if (date == null ||
            date.year != day.year ||
            date.month != day.month ||
            date.day != day.day) {
          continue;
        }
        final amount = (transaction['amount'] as num).toDouble();
        if (transaction['is_income'] == 1) {
          income += amount;
        } else {
          expense += amount;
        }
      }
      return _DayData(day, income, expense);
    });
    final maxValue = days.fold<double>(
      1,
      (maxValue, day) => math.max(maxValue, math.max(day.income, day.expense)),
    );
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Actividad diaria',
                  style: TextStyle(
                    color: Color(0xFF102A43),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const _Legend(color: Color(0xFF0C2340), label: 'Ingresos'),
              const SizedBox(width: 10),
              const _Legend(color: Color(0xFF2563EB), label: 'Gastos'),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days
                  .map(
                    (day) => Expanded(
                      child: _DayBars(day: day, max: maxValue),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('L', style: _ChartLabel.style),
              Text('M', style: _ChartLabel.style),
              Text('M', style: _ChartLabel.style),
              Text('J', style: _ChartLabel.style),
              Text('V', style: _ChartLabel.style),
              Text('S', style: _ChartLabel.style),
              Text('D', style: _ChartLabel.style),
            ],
          ),
          if (transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 14),
              child: Center(
                child: Text(
                  'No hay movimientos en este periodo.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayData {
  final DateTime day;
  final double income;
  final double expense;

  const _DayData(this.day, this.income, this.expense);
}

class _DayBars extends StatelessWidget {
  final _DayData day;
  final double max;

  const _DayBars({required this.day, required this.max});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _Bar(value: day.income, max: max, color: const Color(0xFF0C2340)),
        const SizedBox(width: 3),
        _Bar(value: day.expense, max: max, color: const Color(0xFF2563EB)),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final double value;
  final double max;
  final Color color;

  const _Bar({required this.value, required this.max, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: math.max(4, 112 * value / max),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
        ),
      ],
    );
  }
}

class _ChartLabel {
  static const style = TextStyle(color: Color(0xFF94A3B8), fontSize: 10);
}

class _CategorySection extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final String Function(num) money;

  const _CategorySection({required this.transactions, required this.money});

  @override
  Widget build(BuildContext context) {
    final totals = <String, double>{};
    for (final transaction in transactions) {
      if (transaction['is_income'] == 1) continue;
      final category = (transaction['category'] as String?)?.trim();
      if (category == null || category.isEmpty) continue;
      totals[category] =
          (totals[category] ?? 0) + (transaction['amount'] as num).toDouble();
    }
    final categories = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = categories.fold<double>(0, (sum, item) => sum + item.value);
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gastos por categoría',
            style: TextStyle(
              color: Color(0xFF102A43),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          if (categories.isEmpty)
            const Text(
              'Aún no hay gastos registrados en este periodo.',
              style: TextStyle(color: Color(0xFF64748B)),
            )
          else
            ...categories
                .take(6)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 13),
                    child: _CategoryRow(
                      name: item.key,
                      amount: money(item.value),
                      percentage: total == 0 ? 0 : item.value / total,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String name;
  final String amount;
  final double percentage;

  const _CategoryRow({
    required this.name,
    required this.amount,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  color: Color(0xFF334E68),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              amount,
              style: const TextStyle(
                color: Color(0xFF102A43),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(percentage * 100).round()}%',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percentage,
          minHeight: 7,
          borderRadius: BorderRadius.circular(8),
          backgroundColor: const Color(0xFFE2E8F0),
          color: const Color(0xFF0C2340),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final String Function(num) money;

  const _InsightCard({required this.transactions, required this.money});

  @override
  Widget build(BuildContext context) {
    final expenses = transactions
        .where((row) => row['is_income'] == 0)
        .fold<double>(0, (sum, row) => sum + (row['amount'] as num).toDouble());
    final income = transactions
        .where((row) => row['is_income'] == 1)
        .fold<double>(0, (sum, row) => sum + (row['amount'] as num).toDouble());
    final message = transactions.isEmpty
        ? 'Registra movimientos para obtener recomendaciones.'
        : income == 0
        ? 'Aún no hay ingresos registrados en este periodo.'
        : expenses > income
        ? 'Tus gastos superan tus ingresos en ${money(expenses - income)}.'
        : 'Tu balance positivo es de ${money(income - expenses)}.';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6FA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD4EEF3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF0C2340)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF1E3A5F), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }
}
