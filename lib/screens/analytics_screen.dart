import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mova/database/database_helper.dart';
import 'package:mova/services/currency_controller.dart';
import 'package:mova/services/mova_localizations.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _database = DatabaseHelper();
  String _period = 'this_month';
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

  ({DateTime start, DateTime end}) _rangeFor(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'today':
        final start = DateTime(now.year, now.month, now.day);
        return (start: start, end: start.add(const Duration(days: 1)));
      case 'this_week':
        final start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));
        return (start: start, end: start.add(const Duration(days: 7)));
      case 'previous_week':
        final end = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));
        return (start: end.subtract(const Duration(days: 7)), end: end);
      case 'previous_month':
        final start = DateTime(now.year, now.month - 1, 1);
        return (start: start, end: DateTime(now.year, now.month, 1));
      case 'this_year':
        final start = DateTime(now.year);
        return (start: start, end: DateTime(now.year + 1));
      case 'previous_year':
        final start = DateTime(now.year - 1);
        return (start: start, end: DateTime(now.year));
      default:
        final start = DateTime(now.year, now.month, 1);
        return (start: start, end: DateTime(now.year, now.month + 1, 1));
    }
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
                child: Text(
                  movaText('No se pudo cargar el análisis: ${snapshot.error}'),
                ),
              );
            }
            final range = _rangeFor(_period);
            var transactions = (snapshot.data ?? []).where((row) {
              final date = DateTime.tryParse(row['date'] as String? ?? '');
              return date != null &&
                  !date.isBefore(range.start) &&
                  date.isBefore(range.end);
            }).toList();
            var displayedPeriod = _period;
            if (transactions.isEmpty &&
                {
                  'previous_week',
                  'previous_month',
                  'previous_year',
                }.contains(_period)) {
              final currentRange = _rangeFor(
                _period == 'previous_week'
                    ? 'this_week'
                    : _period == 'previous_year'
                    ? 'this_year'
                    : 'this_month',
              );
              transactions = (snapshot.data ?? []).where((row) {
                final date = DateTime.tryParse(row['date'] as String? ?? '');
                return date != null &&
                    !date.isBefore(currentRange.start) &&
                    date.isBefore(currentRange.end);
              }).toList();
              displayedPeriod =
                  '${context.l10n.text(_period)} · ${context.l10n.text('showing_current_period')}';
            }
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
                  _PeriodBanner(period: displayedPeriod),
                  const SizedBox(height: 14),
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
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 390;
        final selector = Container(
          height: 44,
          padding: const EdgeInsets.only(left: 11, right: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFD8E1EB)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A0C2340),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: period,
              isDense: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF0C2340),
                size: 20,
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 8,
              menuMaxHeight: 180,
              style: const TextStyle(
                color: Color(0xFF102A43),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              selectedItemBuilder: (context) => [
                _PeriodOptionLabel(label: l10n.text('today'), selected: true),
                _PeriodOptionLabel(
                  label: l10n.text('this_week'),
                  selected: true,
                ),
                _PeriodOptionLabel(
                  label: l10n.text('previous_week'),
                  selected: true,
                ),
                _PeriodOptionLabel(
                  label: l10n.text('this_month'),
                  selected: true,
                ),
                _PeriodOptionLabel(
                  label: l10n.text('previous_month'),
                  selected: true,
                ),
                _PeriodOptionLabel(
                  label: l10n.text('this_year'),
                  selected: true,
                ),
                _PeriodOptionLabel(
                  label: l10n.text('previous_year'),
                  selected: true,
                ),
              ],
              items: [
                DropdownMenuItem(
                  value: 'today',
                  child: _PeriodOptionLabel(label: l10n.text('today')),
                ),
                DropdownMenuItem(
                  value: 'this_week',
                  child: _PeriodOptionLabel(label: l10n.text('this_week')),
                ),
                DropdownMenuItem(
                  value: 'previous_week',
                  child: _PeriodOptionLabel(label: l10n.text('previous_week')),
                ),
                DropdownMenuItem(
                  value: 'this_month',
                  child: _PeriodOptionLabel(label: l10n.text('this_month')),
                ),
                DropdownMenuItem(
                  value: 'previous_month',
                  child: _PeriodOptionLabel(label: l10n.text('previous_month')),
                ),
                DropdownMenuItem(
                  value: 'this_year',
                  child: _PeriodOptionLabel(label: l10n.text('this_year')),
                ),
                DropdownMenuItem(
                  value: 'previous_year',
                  child: _PeriodOptionLabel(label: l10n.text('previous_year')),
                ),
              ],
              onChanged: onChanged,
            ),
          ),
        );
        final title = Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.text('analysis'),
                style: TextStyle(
                  color: Color(0xFF102A43),
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                l10n.text('analysis_subtitle'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
          ),
        );
        return narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0C2340), Color(0xFF36577D)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.insights_rounded,
                          color: Colors.white,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 12),
                      title,
                    ],
                  ),
                  const SizedBox(height: 12),
                  selector,
                ],
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0C2340), Color(0xFF36577D)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      color: Colors.white,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  title,
                  selector,
                ],
              );
      },
    );
  }
}

class _PeriodOptionLabel extends StatelessWidget {
  final String label;
  final bool selected;

  const _PeriodOptionLabel({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          selected
              ? Icons.calendar_month_rounded
              : label == 'Este mes'
              ? Icons.today_rounded
              : Icons.history_rounded,
          size: 17,
          color: selected ? const Color(0xFF0C2340) : const Color(0xFF64748B),
        ),
        const SizedBox(width: 9),
        Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF0C2340) : const Color(0xFF334E68),
            fontSize: 13,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PeriodBanner extends StatelessWidget {
  final String period;

  const _PeriodBanner({required this.period});

  @override
  Widget build(BuildContext context) {
    final periodLabel = context.l10n.text(period);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEF5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month_outlined,
            size: 18,
            color: Color(0xFF0C2340),
          ),
          const SizedBox(width: 9),
          Text(
            '${context.l10n.text('period_summary')}: $periodLabel',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E3A5F),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final String Function(num) money;

  const _SummaryCard({required this.transactions, required this.money});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    var income = 0.0;
    var expenses = 0.0;
    for (final transaction in transactions) {
      final amount = (transaction['amount'] as num).toDouble();
      if (transaction['is_income'] == 1 &&
          !DatabaseHelper.isSavingsWithdrawal(transaction)) {
        income += amount;
      } else if (transaction['is_income'] == 0 &&
          !DatabaseHelper.isSavingsDeposit(transaction)) {
        expenses += amount;
      }
    }
    final balance = income - expenses;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 19,
                color: Color(0xFF0C2340),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.text('period_summary'),
                style: TextStyle(
                  color: Color(0xFF102A43),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Stat(
                l10n.text('income'),
                money(income),
                const Color(0xFF0C2340),
              ),
              _Stat(
                l10n.text('expenses'),
                money(expenses),
                const Color(0xFF2563EB),
              ),
              _Stat(
                l10n.text('balance'),
                money(balance),
                const Color(0xFFD97706),
              ),
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
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.fromLTRB(10, 11, 8, 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withValues(alpha: .12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
            const SizedBox(height: 5),
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
    final l10n = context.l10n;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final days = List.generate(7, (index) {
      final day = todayOnly.subtract(Duration(days: 6 - index));
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
        if (transaction['is_income'] == 1 &&
            !DatabaseHelper.isSavingsWithdrawal(transaction)) {
          income += amount;
        } else if (transaction['is_income'] == 0 &&
            !DatabaseHelper.isSavingsDeposit(transaction)) {
          expense += amount;
        }
      }
      return _DayData(day, income, expense);
    });
    final hasActivity = days.any((day) => day.income > 0 || day.expense > 0);
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
              Expanded(
                child: Text(
                  l10n.text('daily_activity'),
                  style: TextStyle(
                    color: Color(0xFF102A43),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _Legend(
                color: const Color(0xFF0C2340),
                label: l10n.text('income'),
              ),
              const SizedBox(width: 10),
              _Legend(
                color: const Color(0xFF2563EB),
                label: l10n.text('expenses'),
              ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: days
                .map(
                  (day) => Text(
                    _weekdayLabel(day.day.weekday),
                    style: _ChartLabel.style,
                  ),
                )
                .toList(),
          ),
          if (!hasActivity)
            Padding(
              padding: EdgeInsets.only(top: 14),
              child: Center(
                child: Text(
                  l10n.text('no_period_movements'),
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _weekdayLabel(int weekday) {
    const labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return labels[weekday - 1];
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
    if (value <= 0) {
      return const SizedBox(width: 8);
    }
    return Container(
      width: 8,
      height: 112 * value / max,
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
      if (transaction['is_income'] == 1 ||
          DatabaseHelper.isSavingsDeposit(transaction)) {
        continue;
      }
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
          Text(
            context.l10n.text('expenses_by_category'),
            style: TextStyle(
              color: Color(0xFF102A43),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          if (categories.isEmpty)
            Text(
              context.l10n.text('no_period_expenses'),
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
        .where(
          (row) =>
              row['is_income'] == 0 && !DatabaseHelper.isSavingsDeposit(row),
        )
        .fold<double>(0, (sum, row) => sum + (row['amount'] as num).toDouble());
    final income = transactions
        .where(
          (row) =>
              row['is_income'] == 1 && !DatabaseHelper.isSavingsWithdrawal(row),
        )
        .fold<double>(0, (sum, row) => sum + (row['amount'] as num).toDouble());
    final message = transactions.isEmpty
        ? context.l10n.text('record_movements_recommendations')
        : income == 0
        ? movaText('Aún no hay ingresos registrados en este periodo.')
        : expenses > income
        ? movaText(
            'Tus gastos superan tus ingresos en ${money(expenses - income)}.',
          )
        : movaText('Tu balance positivo es de ${money(income - expenses)}.');
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x090C2340),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}
