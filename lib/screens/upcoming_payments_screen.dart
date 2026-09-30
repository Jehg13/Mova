import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mova/database/database_helper.dart';
import 'package:mova/models/financial_account.dart';
import 'package:mova/models/scheduled_payment.dart';
import 'package:mova/models/subscription.dart';
import 'package:mova/services/currency_controller.dart';
import 'package:mova/services/mova_localizations.dart';
import 'package:mova/services/scheduled_payment_reminder_service.dart';
import 'package:mova/services/subscription_reminder_service.dart';
import 'package:mova/screens/subscriptions_screen.dart';
import 'package:mova/widgets/mova_design_system.dart';

class UpcomingPaymentsScreen extends StatefulWidget {
  const UpcomingPaymentsScreen({super.key});

  @override
  State<UpcomingPaymentsScreen> createState() => _UpcomingPaymentsScreenState();
}

class _UpcomingPaymentsScreenState extends State<UpcomingPaymentsScreen> {
  final _database = DatabaseHelper();
  final _paymentReminders = ScheduledPaymentReminderService();
  final _subscriptionReminders = SubscriptionReminderService();
  late Future<_PaymentsData> _data;
  bool _showHistory = false;
  String _typeFilter = 'all';
  String _statusFilter = 'all';
  String _timeFilter = 'all';
  String? _categoryFilter;
  int? _accountFilter;
  bool _paymentInProgress = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _data = _loadData();
  }

  Future<_PaymentsData> _loadData() async {
    final results = await Future.wait([
      _database.getScheduledPayments(),
      _database.getSubscriptions(status: SubscriptionStatus.active),
      _database.getFinancialAccounts(includeInactive: false),
      _database.getCustomCategories(),
      _database.getScheduledPaymentHistory(),
      _database.getSubscriptions(),
    ]);
    final scheduled = results[0] as List<ScheduledPayment>;
    final subscriptions = results[1] as List<Subscription>;
    final accounts = results[2] as List<FinancialAccount>;
    final categories = (results[3] as List<Map<String, dynamic>>)
        .where((item) => item['type'] == 'expense')
        .map((item) => item['name'] as String)
        .toSet();
    final scheduledHistory = results[4] as List<Map<String, Object?>>;
    final allSubscriptions = results[5] as List<Subscription>;
    final subscriptionHistory = <Map<String, Object?>>[];
    for (final subscription in allSubscriptions) {
      final rows = await _database.getSubscriptionHistory(subscription.id);
      subscriptionHistory.addAll(
        rows.map(
          (row) => {
            ...row,
            'subscription_name': subscription.name,
            'payment_type': 'subscription',
            'frequency': subscription.frequency.name,
          },
        ),
      );
    }
    final accountById = {for (final account in accounts) account.id: account};
    final payments = <UpcomingPayment>[
      for (final subscription in subscriptions)
        UpcomingPayment.fromSubscription(subscription),
      for (final payment in scheduled)
        UpcomingPayment.fromScheduled(
          payment,
          accountLabel: _accountLabel(payment, accountById),
        ),
    ]..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return _PaymentsData(
      scheduled: scheduled,
      subscriptions: subscriptions,
      accounts: accounts,
      categories: {..._defaultCategories, ...categories}.toList()..sort(),
      payments: payments,
      history: [...scheduledHistory, ...subscriptionHistory]
        ..sort((a, b) {
          final aDate = DateTime.tryParse(a['paid_at'] as String? ?? '');
          final bDate = DateTime.tryParse(b['paid_at'] as String? ?? '');
          return (bDate ?? DateTime(0)).compareTo(aDate ?? DateTime(0));
        }),
    );
  }

  static const _defaultCategories = {
    'Comida',
    'Transporte',
    'Compras',
    'Hogar',
    'Entretenimiento',
    'Suscripciones',
    'Servicios',
    'Salud',
    'Otros',
  };

  Future<void> _refresh() async {
    setState(_load);
    await _data;
  }

  Future<void> _openForm([ScheduledPayment? payment]) async {
    final data = await _data;
    if (!mounted) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ScheduledPaymentFormScreen(
          payment: payment,
          categories: data.categories,
        ),
      ),
    );
    if (saved == true && mounted) await _refresh();
  }

  Future<void> _openSubscription(UpcomingPayment item) async {
    final subscription = await _database.getSubscription(item.id);
    if (subscription == null || !mounted) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SubscriptionDetailsScreen(subscription: subscription),
      ),
    );
    if (mounted) await _refresh();
  }

  Future<void> _markPaid(UpcomingPayment payment, _PaymentsData data) async {
    if (_paymentInProgress) return;
    setState(() => _paymentInProgress = true);
    try {
      int? duplicateId;
      if (payment.source == PaymentSource.subscription) {
        duplicateId = await _database.findPotentialDuplicateSubscriptionExpense(
          payment.id,
        );
      } else if (!payment.isCardPayment) {
        duplicateId = await _database
            .findPotentialDuplicateScheduledPaymentExpense(payment.id);
      }
      if (!mounted) return;
      final result = await showDialog<_PaymentConfirmation>(
        context: context,
        builder: (_) => _PaymentConfirmationDialog(
          payment: payment,
          accounts: data.accounts,
          duplicateTransactionId: duplicateId,
        ),
      );
      if (result == null || !mounted) return;
      String? reminderError;
      if (payment.source == PaymentSource.subscription) {
        await _database.recordSubscriptionPayment(
          payment.id,
          expectedChargeDate: payment.dueDate,
          existingTransactionId: result.useExistingMovement
              ? duplicateId
              : null,
        );
        final updated = await _database.getSubscription(payment.id);
        try {
          if (updated != null) await _subscriptionReminders.schedule(updated);
        } catch (error) {
          reminderError = '$error';
        }
      } else {
        await _database.recordScheduledPayment(
          id: payment.id,
          expectedDueDate: payment.dueDate,
          existingTransactionId: result.useExistingMovement
              ? duplicateId
              : null,
          accountId: result.accountId,
        );
        final updated = await _database.getScheduledPayment(payment.id);
        try {
          if (updated != null) {
            await _paymentReminders.schedule(updated);
          } else {
            await _paymentReminders.cancel(payment.id);
          }
        } catch (error) {
          reminderError = '$error';
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reminderError == null
                ? context.l10n.text('payment_saved')
                : '${context.l10n.text('payment_saved')} '
                      '${context.l10n.text('reminder_schedule_error')}: $reminderError',
          ),
        ),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.l10n.text('payment_save_error')} $error'),
        ),
      );
    }
  }

  Future<void> _cancelPayment(ScheduledPayment payment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.text('cancel')),
        content: Text(context.l10n.text('payment_cancel_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.text('cancel')),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _database.cancelScheduledPayment(payment.id);
      String? reminderError;
      try {
        await _paymentReminders.cancel(payment.id);
      } catch (error) {
        reminderError = '$error';
      }
      if (!mounted) return;
      await _refresh();
      if (reminderError != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${context.l10n.text('payment_cancelled')} '
              '${context.l10n.text('reminder_schedule_error')}: $reminderError',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.l10n.text('payment_save_error')} $error'),
        ),
      );
    }
  }

  Future<void> _showFilters(_PaymentsData data) async {
    final result = await showModalBottomSheet<_PaymentFilters>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PaymentFiltersSheet(
        data: data,
        type: _typeFilter,
        status: _statusFilter,
        time: _timeFilter,
        category: _categoryFilter,
        accountId: _accountFilter,
      ),
    );
    if (result == null) return;
    setState(() {
      _typeFilter = result.type;
      _statusFilter = result.status;
      _timeFilter = result.time;
      _categoryFilter = result.category;
      _accountFilter = result.accountId;
      if (result.status == 'paid') _showHistory = true;
      if (result.status == 'pending' || result.status == 'overdue') {
        _showHistory = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: MovaDesign.canvas,
      appBar: AppBar(
        title: Text(l10n.text('upcoming_payments')),
        backgroundColor: MovaDesign.canvas,
        actions: [
          IconButton(
            tooltip: l10n.text('payment_filters'),
            onPressed: () async {
              final data = await _data;
              if (mounted) await _showFilters(data);
            },
            icon: const Icon(Icons.tune_rounded),
          ),
          IconButton(
            tooltip: l10n.text('add_payment'),
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      body: FutureBuilder<_PaymentsData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '${l10n.text('payment_load_error')} ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final data = snapshot.data!;
          final payments = _filteredPayments(data.payments);
          final history = _filteredHistory(data.history);
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
              children: [
                _PaymentSummary(data.payments),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9EEF5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _tabButton(l10n.text('upcoming_payments'), false),
                      _tabButton(l10n.text('payment_history'), true),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (!_showHistory) ...[
                  _TimeFilters(
                    selected: _timeFilter,
                    onSelected: (value) => setState(() => _timeFilter = value),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10, top: 4),
                    child: Text(
                      l10n.text('payment_not_expense_yet'),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (payments.isEmpty)
                    _EmptyPayments(onAdd: () => _openForm())
                  else
                    ..._groupPayments(payments).entries.expand((entry) {
                      final group = entry.value;
                      return [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
                          child: Text(
                            _dateHeading(context, group.first.dueDate),
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .5,
                            ),
                          ),
                        ),
                        ...group.map(
                          (payment) => _UpcomingPaymentCard(
                            payment: payment,
                            scheduled: payment.source == PaymentSource.scheduled
                                ? data.scheduled.firstWhere(
                                    (item) => item.id == payment.id,
                                  )
                                : null,
                            onTap: payment.source == PaymentSource.subscription
                                ? () => _openSubscription(payment)
                                : () => _openForm(
                                    data.scheduled.firstWhere(
                                      (item) => item.id == payment.id,
                                    ),
                                  ),
                            onPay: () => _markPaid(payment, data),
                            isPaying: _paymentInProgress,
                            onCancel: payment.source == PaymentSource.scheduled
                                ? () => _cancelPayment(
                                    data.scheduled.firstWhere(
                                      (item) => item.id == payment.id,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ];
                    }),
                ] else if (history.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Center(child: Text(l10n.text('no_payment_history'))),
                  )
                else
                  ...history.map((payment) => _PaymentHistoryCard(payment)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: const Color(0xFF0C2340),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.text('add_payment')),
      ),
    );
  }

  Widget _tabButton(String title, bool history) => Expanded(
    child: TextButton(
      onPressed: () => setState(() => _showHistory = history),
      style: TextButton.styleFrom(
        backgroundColor: _showHistory == history
            ? Colors.white
            : Colors.transparent,
        foregroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
      child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
  );

  List<UpcomingPayment> _filteredPayments(List<UpcomingPayment> all) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final startNextMonth = DateTime(now.year, now.month + 1, 1);
    final endNextMonth = DateTime(now.year, now.month + 2, 1);
    return all.where((payment) {
      final overdue = payment.isOverdue;
      final date = DateTime(
        payment.dueDate.year,
        payment.dueDate.month,
        payment.dueDate.day,
      );
      final typeMatches = switch (_typeFilter) {
        'subscription' => payment.source == PaymentSource.subscription,
        'recurring' =>
          payment.source == PaymentSource.scheduled &&
              payment.frequency != null &&
              !payment.isCardPayment,
        'card' => payment.isCardPayment,
        'oneTime' =>
          payment.source == PaymentSource.scheduled &&
              payment.type == ScheduledPaymentType.oneTime,
        _ => true,
      };
      final statusMatches = switch (_statusFilter) {
        'pending' => !overdue,
        'overdue' => overdue,
        _ => true,
      };
      final timeMatches = switch (_timeFilter) {
        '7' => !overdue && date.isBefore(today.add(const Duration(days: 7))),
        '30' => !overdue && date.isBefore(today.add(const Duration(days: 30))),
        'thisMonth' =>
          !overdue &&
              date.isBefore(nextMonth) &&
              date.month == today.month &&
              date.year == today.year,
        'nextMonth' =>
          !overdue &&
              !date.isBefore(startNextMonth) &&
              date.isBefore(endNextMonth),
        _ => true,
      };
      final categoryMatches =
          _categoryFilter == null || payment.category == _categoryFilter;
      final accountMatches =
          _accountFilter == null ||
          payment.accountId == _accountFilter ||
          payment.targetAccountId == _accountFilter;
      return typeMatches &&
          statusMatches &&
          timeMatches &&
          categoryMatches &&
          accountMatches;
    }).toList();
  }

  List<Map<String, Object?>> _filteredHistory(List<Map<String, Object?>> all) {
    if (_statusFilter == 'pending' || _statusFilter == 'overdue') {
      return const [];
    }
    return all.where((item) {
      final type = item['payment_type'] as String?;
      final typeMatches = switch (_typeFilter) {
        'subscription' => type == 'subscription',
        'recurring' => type == 'recurring',
        'card' => type == 'cardPayment',
        'oneTime' => type == 'oneTime',
        _ => true,
      };
      final categoryMatches =
          _categoryFilter == null || item['category'] == _categoryFilter;
      final accountMatches =
          _accountFilter == null || item['account_id'] == _accountFilter;
      return typeMatches && categoryMatches && accountMatches;
    }).toList();
  }
}

class _PaymentsData {
  const _PaymentsData({
    required this.scheduled,
    required this.subscriptions,
    required this.accounts,
    required this.categories,
    required this.payments,
    required this.history,
  });
  final List<ScheduledPayment> scheduled;
  final List<Subscription> subscriptions;
  final List<FinancialAccount> accounts;
  final List<String> categories;
  final List<UpcomingPayment> payments;
  final List<Map<String, Object?>> history;
}

String _accountLabel(
  ScheduledPayment payment,
  Map<int, FinancialAccount> accounts,
) {
  final id = payment.type == ScheduledPaymentType.cardPayment
      ? payment.targetAccountId
      : payment.accountId;
  final account = id == null ? null : accounts[id];
  if (account == null) return '';
  return account.lastFour.isEmpty
      ? account.name
      : '${account.name} •••• ${account.lastFour}';
}

Map<DateTime, List<UpcomingPayment>> _groupPayments(
  List<UpcomingPayment> payments,
) {
  final grouped = <DateTime, List<UpcomingPayment>>{};
  for (final payment in payments) {
    final day = DateTime(
      payment.dueDate.year,
      payment.dueDate.month,
      payment.dueDate.day,
    );
    grouped.putIfAbsent(day, () => []).add(payment);
  }
  return grouped;
}

String _dateHeading(BuildContext context, DateTime date) {
  final l10n = context.l10n;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final difference = day.difference(today).inDays;
  if (difference < 0) {
    return '${l10n.text('payment_status_overdue').toUpperCase()} · ${_shortDate(context, date)}';
  }
  if (difference == 0) return l10n.text('today').toUpperCase();
  if (difference == 1) return l10n.text('tomorrow').toUpperCase();
  if (difference < 7) {
    return l10n.text('days_count').replaceAll('{count}', '$difference');
  }
  return _shortDate(context, date);
}

String _shortDate(BuildContext context, DateTime date) {
  const months = {
    'es': [
      'ENE',
      'FEB',
      'MAR',
      'ABR',
      'MAY',
      'JUN',
      'JUL',
      'AGO',
      'SEP',
      'OCT',
      'NOV',
      'DIC',
    ],
    'en': [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ],
    'pt': [
      'JAN',
      'FEV',
      'MAR',
      'ABR',
      'MAI',
      'JUN',
      'JUL',
      'AGO',
      'SET',
      'OUT',
      'NOV',
      'DEZ',
    ],
  };
  final locale = Localizations.localeOf(context).languageCode;
  final month = (months[locale] ?? months['es']!)[date.month - 1];
  return '${date.day.toString().padLeft(2, '0')} $month';
}

class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary(this.payments);
  final List<UpcomingPayment> payments;

  Map<String, double> _totals(DateTime start, DateTime end) {
    final totals = <String, double>{};
    for (final payment in payments) {
      final day = DateTime(
        payment.dueDate.year,
        payment.dueDate.month,
        payment.dueDate.day,
      );
      if (payment.isOverdue || day.isBefore(start) || !day.isBefore(end)) {
        continue;
      }
      totals.update(
        payment.currency,
        (total) => total + payment.amount,
        ifAbsent: () => payment.amount,
      );
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final next7 = _totals(today, today.add(const Duration(days: 7)));
    final next30 = _totals(today, today.add(const Duration(days: 30)));
    final pending = <String, double>{};
    for (final item in payments) {
      pending.update(
        item.currency,
        (total) => total + item.amount,
        ifAbsent: () => item.amount,
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C2340),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.text('payments_summary'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryAmount(
                  title: context.l10n.text('payments_next_7_days'),
                  totals: next7,
                ),
              ),
              Expanded(
                child: _SummaryAmount(
                  title: context.l10n.text('payments_next_30_days'),
                  totals: next30,
                ),
              ),
              Expanded(
                child: _SummaryAmount(
                  title: context.l10n.text('payments_pending_total'),
                  totals: pending,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${context.l10n.text('money_committed')} · ${_currencyTotals(next30)}',
            style: const TextStyle(color: Color(0xFFD9E2F0), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SummaryAmount extends StatelessWidget {
  const _SummaryAmount({required this.title, required this.totals});
  final String title;
  final Map<String, double> totals;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          style: const TextStyle(color: Color(0xFFD9E2F0), fontSize: 10),
        ),
        const SizedBox(height: 4),
        Text(
          _currencyTotals(totals),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _UpcomingPaymentCard extends StatelessWidget {
  const _UpcomingPaymentCard({
    required this.payment,
    required this.scheduled,
    required this.onTap,
    required this.onPay,
    required this.onCancel,
    required this.isPaying,
  });
  final UpcomingPayment payment;
  final ScheduledPayment? scheduled;
  final VoidCallback onTap;
  final VoidCallback onPay;
  final VoidCallback? onCancel;
  final bool isPaying;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final overdue = payment.isOverdue;
    final label = payment.source == PaymentSource.subscription
        ? l10n.text('payment_type_subscription')
        : switch (payment.type!) {
            ScheduledPaymentType.recurring => l10n.text(
              'payment_type_recurring',
            ),
            ScheduledPaymentType.oneTime => l10n.text('payment_type_one_time'),
            ScheduledPaymentType.cardPayment => l10n.text('payment_type_card'),
          };
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: BorderSide(
          color: overdue ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 8, 12),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: overdue
                        ? const Color(0xFFFEF2F2)
                        : MovaDesign.canvas,
                    child: Icon(
                      payment.isCardPayment
                          ? Icons.credit_card_rounded
                          : payment.source == PaymentSource.subscription
                          ? Icons.autorenew_rounded
                          : Icons.event_note_rounded,
                      color: overdue
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF0C2340),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_formatMoney(payment.amount, payment.currency)} · $label',
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 12,
                          ),
                        ),
                        if (payment.accountLabel.isNotEmpty)
                          Text(
                            '${l10n.text('payment_method')}: ${payment.accountLabel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                            ),
                          )
                        else
                          Text(
                            '${l10n.text('payment_method')}: ${l10n.text('payment_method_unspecified')}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                            ),
                          ),
                        if (payment.category != null)
                          Text(
                            payment.category!,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _dateHeading(context, payment.dueDate),
                        style: TextStyle(
                          color: overdue
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF334155),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatMoney(payment.amount, payment.currency),
                        style: const TextStyle(
                          color: Color(0xFF0C2340),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  if (scheduled != null)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') onTap();
                        if (value == 'cancel') onCancel?.call();
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(l10n.text('edit_payment')),
                        ),
                        PopupMenuItem(
                          value: 'cancel',
                          child: Text(l10n.text('cancel')),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isPaying ? null : onPay,
                  icon: isPaying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(l10n.text('mark_payment_paid')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0C2340),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentHistoryCard extends StatelessWidget {
  const _PaymentHistoryCard(this.payment);
  final Map<String, Object?> payment;

  @override
  Widget build(BuildContext context) {
    final name =
        payment['subscription_name'] as String? ??
        payment['name'] as String? ??
        context.l10n.text('upcoming_payments');
    final currency = payment['currency'] as String? ?? 'MXN';
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0;
    final date = DateTime.tryParse(payment['paid_at'] as String? ?? '');
    final accountLabel =
        payment['card_name'] as String? ??
        payment['account_name'] as String? ??
        payment['account_label'] as String?;
    final subtitle = [
      if (date != null) _shortDate(context, date),
      context.l10n.text('payment_status_paid'),
      if (accountLabel != null && accountLabel.isNotEmpty) accountLabel,
    ].join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFDCFCE7),
          child: Icon(Icons.check_rounded, color: Color(0xFF15803D)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: Text(
          _formatMoney(amount, currency),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _EmptyPayments extends StatelessWidget {
  const _EmptyPayments({required this.onAdd});
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      children: [
        const Icon(Icons.event_available_outlined, size: 34),
        const SizedBox(height: 9),
        Text(context.l10n.text('no_scheduled_payments')),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: Text(context.l10n.text('add_payment')),
        ),
      ],
    ),
  );
}

class _PaymentConfirmation {
  const _PaymentConfirmation({
    required this.accountId,
    required this.useExistingMovement,
  });
  final int? accountId;
  final bool useExistingMovement;
}

class _PaymentConfirmationDialog extends StatefulWidget {
  const _PaymentConfirmationDialog({
    required this.payment,
    required this.accounts,
    required this.duplicateTransactionId,
  });
  final UpcomingPayment payment;
  final List<FinancialAccount> accounts;
  final int? duplicateTransactionId;

  @override
  State<_PaymentConfirmationDialog> createState() =>
      _PaymentConfirmationDialogState();
}

class _PaymentConfirmationDialogState
    extends State<_PaymentConfirmationDialog> {
  late int? _accountId;
  late bool _useExisting;

  List<FinancialAccount> get _availableAccounts => widget.accounts
      .where(
        (account) =>
            account.currency == widget.payment.currency &&
            account.type != FinancialAccountType.creditCard,
      )
      .toList();

  @override
  void initState() {
    super.initState();
    final validAccounts = _availableAccounts;
    _accountId =
        validAccounts.any((account) => account.id == widget.payment.accountId)
        ? widget.payment.accountId
        : validAccounts.firstOrNull?.id;
    _useExisting = widget.duplicateTransactionId != null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final payment = widget.payment;
    final cardPayment = payment.isCardPayment;
    final mustChooseAccount = cardPayment;
    return AlertDialog(
      title: Text(l10n.text('confirm_payment_title')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n
                  .text('confirm_payment_message')
                  .replaceAll(
                    '{amount}',
                    _formatMoney(payment.amount, payment.currency),
                  ),
            ),
            const SizedBox(height: 14),
            Text(l10n.text('payment_account_used')),
            const SizedBox(height: 6),
            DropdownButtonFormField<int?>(
              initialValue: _accountId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                if (!mustChooseAccount)
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(l10n.text('payment_method_unspecified')),
                  ),
                ..._availableAccounts.map(
                  (account) => DropdownMenuItem<int?>(
                    value: account.id,
                    child: Text(account.name),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _accountId = value),
            ),
            if (cardPayment)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${l10n.text('payment_card')}: ${payment.accountLabel}',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            if (widget.duplicateTransactionId != null) ...[
              const SizedBox(height: 14),
              Text(l10n.text('find_duplicate_payment')),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  _useExisting
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                title: Text(l10n.text('link_existing_movement')),
                onTap: () => setState(() => _useExisting = true),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  !_useExisting
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                title: Text(l10n.text('create_payment_movement')),
                onTap: () => setState(() => _useExisting = false),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.text('cancel')),
        ),
        FilledButton(
          onPressed: mustChooseAccount && _accountId == null
              ? null
              : () => Navigator.pop(
                  context,
                  _PaymentConfirmation(
                    accountId: _accountId,
                    useExistingMovement: _useExisting,
                  ),
                ),
          child: Text(l10n.text('mark_payment_paid')),
        ),
      ],
    );
  }
}

class _PaymentFilters {
  const _PaymentFilters({
    required this.type,
    required this.status,
    required this.time,
    required this.category,
    required this.accountId,
  });
  final String type;
  final String status;
  final String time;
  final String? category;
  final int? accountId;
}

class _PaymentFiltersSheet extends StatefulWidget {
  const _PaymentFiltersSheet({
    required this.data,
    required this.type,
    required this.status,
    required this.time,
    required this.category,
    required this.accountId,
  });
  final _PaymentsData data;
  final String type;
  final String status;
  final String time;
  final String? category;
  final int? accountId;

  @override
  State<_PaymentFiltersSheet> createState() => _PaymentFiltersSheetState();
}

class _PaymentFiltersSheetState extends State<_PaymentFiltersSheet> {
  late String _type;
  late String _status;
  late String _time;
  late String? _category;
  late int? _accountId;

  @override
  void initState() {
    super.initState();
    _type = widget.type;
    _status = widget.status;
    _time = widget.time;
    _category = widget.category;
    _accountId = widget.accountId;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.text('payment_filters'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _filterDropdown(
              title: l10n.text('payment_filter_type'),
              value: _type,
              options: {
                'all': l10n.text('payment_filter_all'),
                'subscription': l10n.text('payment_type_filter_subscription'),
                'recurring': l10n.text('payment_type_filter_recurring'),
                'card': l10n.text('payment_type_filter_card'),
                'oneTime': l10n.text('payment_type_filter_one_time'),
              },
              onChanged: (value) => setState(() => _type = value),
            ),
            _filterDropdown(
              title: l10n.text('payment_filter_status'),
              value: _status,
              options: {
                'all': l10n.text('all'),
                'pending': l10n.text('payment_status_pending'),
                'overdue': l10n.text('payment_status_overdue'),
                'paid': l10n.text('payment_status_paid'),
              },
              onChanged: (value) => setState(() => _status = value),
            ),
            _filterDropdown(
              title: l10n.text('payment_time_all'),
              value: _time,
              options: {
                'all': l10n.text('payment_time_all'),
                '7': l10n.text('payment_time_7_days'),
                '30': l10n.text('payment_time_30_days'),
                'thisMonth': l10n.text('payment_time_this_month'),
                'nextMonth': l10n.text('payment_time_next_month'),
              },
              onChanged: (value) => setState(() => _time = value),
            ),
            _filterDropdown(
              title: l10n.text('payment_filter_category'),
              value: _category ?? '',
              options: {
                '': l10n.text('all'),
                for (final category in widget.data.categories)
                  category: category,
              },
              onChanged: (value) =>
                  setState(() => _category = value.isEmpty ? null : value),
            ),
            _filterDropdown(
              title: l10n.text('payment_filter_account'),
              value: _accountId?.toString() ?? '',
              options: {
                '': l10n.text('all'),
                for (final account in widget.data.accounts)
                  '${account.id}': account.name,
              },
              onChanged: (value) => setState(
                () => _accountId = value.isEmpty ? null : int.parse(value),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  _PaymentFilters(
                    type: _type,
                    status: _status,
                    time: _time,
                    category: _category,
                    accountId: _accountId,
                  ),
                ),
                child: Text(l10n.text('done')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterDropdown({
    required String title,
    required String value,
    required Map<String, String> options,
    required ValueChanged<String> onChanged,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: DropdownButtonFormField<String>(
      initialValue: options.containsKey(value) ? value : options.keys.first,
      decoration: InputDecoration(
        labelText: title,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: options.entries
          .map(
            (entry) => DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value, maxLines: 1),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    ),
  );
}

class _TimeFilters extends StatelessWidget {
  const _TimeFilters({required this.selected, required this.onSelected});
  final String selected;
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final entry in {
          'all': context.l10n.text('payment_time_all'),
          '7': context.l10n.text('payment_time_7_days'),
          '30': context.l10n.text('payment_time_30_days'),
          'thisMonth': context.l10n.text('payment_time_this_month'),
          'nextMonth': context.l10n.text('payment_time_next_month'),
        }.entries)
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: selected == entry.key,
              onSelected: (_) => onSelected(entry.key),
            ),
          ),
      ],
    ),
  );
}

class ScheduledPaymentFormScreen extends StatefulWidget {
  const ScheduledPaymentFormScreen({
    super.key,
    this.payment,
    required this.categories,
  });
  final ScheduledPayment? payment;
  final List<String> categories;

  @override
  State<ScheduledPaymentFormScreen> createState() =>
      _ScheduledPaymentFormScreenState();
}

class _ScheduledPaymentFormScreenState
    extends State<ScheduledPaymentFormScreen> {
  final _database = DatabaseHelper();
  final _reminders = ScheduledPaymentReminderService();
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  late Future<List<FinancialAccount>> _accounts;
  late ScheduledPaymentType _type;
  late DateTime _dueDate;
  late String _currency;
  late String _category;
  late int _reminderDays;
  SubscriptionFrequency? _frequency;
  int? _accountId;
  int? _targetAccountId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final payment = widget.payment;
    _name.text = payment?.name ?? '';
    _amount.text = payment == null ? '' : _decimal(payment.amount);
    _notes.text = payment?.notes ?? '';
    _type = payment?.type ?? ScheduledPaymentType.recurring;
    _dueDate = payment?.dueDate ?? DateTime.now();
    _currency = payment?.currency ?? appCurrencyController.code;
    _category =
        payment?.category ??
        (widget.categories.contains('Servicios')
            ? 'Servicios'
            : widget.categories.firstOrNull ?? 'Otros');
    _reminderDays = payment?.reminderDays ?? 1;
    _frequency = payment?.frequency ?? SubscriptionFrequency.monthly;
    _repeatCard =
        payment?.type == ScheduledPaymentType.cardPayment &&
        payment?.frequency != null;
    _accountId = payment?.accountId;
    _targetAccountId = payment?.targetAccountId;
    _accounts = _database.getFinancialAccounts(includeInactive: false);
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _isCard => _type == ScheduledPaymentType.cardPayment;
  bool get _isOneTime => _type == ScheduledPaymentType.oneTime;

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _dueDate = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final payment = ScheduledPayment(
        id: widget.payment?.id ?? 0,
        name: _name.text.trim(),
        amount: double.parse(_amount.text.replaceAll(',', '.')),
        currency: _currency,
        type: _type,
        dueDate: _dueDate,
        reminderDays: _reminderDays,
        status: widget.payment?.status ?? ScheduledPaymentStatus.active,
        createdAt: widget.payment?.createdAt ?? DateTime.now(),
        category: _isCard ? null : _category,
        frequency: _isOneTime
            ? null
            : (_type == ScheduledPaymentType.recurring || _repeatCard)
            ? _frequency
            : null,
        accountId: _accountId,
        targetAccountId: _isCard ? _targetAccountId : null,
        notes: _notes.text.trim(),
      );
      final id = widget.payment == null
          ? await _database.createScheduledPayment(payment)
          : widget.payment!.id;
      if (widget.payment != null) {
        await _database.updateScheduledPayment(payment);
      }
      String? reminderError;
      try {
        final saved = await _database.getScheduledPayment(id);
        if (saved != null) await _reminders.schedule(saved);
      } catch (error) {
        reminderError = '$error';
      }
      if (!mounted) return;
      if (reminderError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${context.l10n.text('reminder_schedule_error')}: $reminderError',
            ),
          ),
        );
      }
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.l10n.text('payment_save_error')} $error'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _repeatCard = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: MovaDesign.canvas,
      appBar: AppBar(
        title: Text(
          l10n.text(widget.payment == null ? 'add_payment' : 'edit_payment'),
        ),
        backgroundColor: MovaDesign.canvas,
      ),
      body: FutureBuilder<List<FinancialAccount>>(
        future: _accounts,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(l10n.text('accounts_load_error')));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final accounts = snapshot.data!;
          final eligibleAccounts = accounts
              .where(
                (account) =>
                    account.currency == _currency &&
                    account.type != FinancialAccountType.creditCard &&
                    (account.type != FinancialAccountType.cash ||
                        account.id == _accountId),
              )
              .toList();
          final cards = accounts
              .where(
                (account) =>
                    account.currency == _currency &&
                    account.type == FinancialAccountType.creditCard,
              )
              .toList();
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              children: [
                _fieldLabel(l10n.text('payment_type')),
                DropdownButtonFormField<ScheduledPaymentType>(
                  initialValue: _type,
                  decoration: _inputDecoration(l10n.text('payment_type')),
                  items: ScheduledPaymentType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(_typeLabel(l10n, type)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _type = value;
                      _accountId = null;
                      _targetAccountId = null;
                      if (value == ScheduledPaymentType.oneTime) {
                        _frequency = null;
                        _repeatCard = false;
                      } else if (value == ScheduledPaymentType.recurring) {
                        _frequency ??= SubscriptionFrequency.monthly;
                      }
                    });
                  },
                ),
                const SizedBox(height: 15),
                _fieldLabel(l10n.text('payment_name')),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration(l10n.text('payment_name_hint')),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.text('required_field')
                      : null,
                ),
                const SizedBox(height: 15),
                _fieldLabel(l10n.text('amount')),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _amount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        decoration: _inputDecoration('0.00'),
                        validator: (value) {
                          final amount = double.tryParse(
                            (value ?? '').replaceAll(',', '.'),
                          );
                          return amount == null || amount <= 0
                              ? l10n.text('amount_must_be_positive')
                              : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: _currency,
                      items: movaCurrencies
                          .map(
                            (currency) => DropdownMenuItem(
                              value: currency.code,
                              child: Text(currency.code),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _currency = value;
                          _accountId = null;
                          _targetAccountId = null;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                if (!_isCard) ...[
                  _fieldLabel(l10n.text('payment_category')),
                  DropdownButtonFormField<String>(
                    initialValue: widget.categories.contains(_category)
                        ? _category
                        : widget.categories.first,
                    decoration: _inputDecoration(l10n.text('category')),
                    items: widget.categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _category = value);
                    },
                  ),
                  const SizedBox(height: 15),
                ],
                if (_isCard) ...[
                  _fieldLabel(l10n.text('payment_card')),
                  DropdownButtonFormField<int?>(
                    initialValue:
                        cards.any((account) => account.id == _targetAccountId)
                        ? _targetAccountId
                        : null,
                    decoration: _inputDecoration(l10n.text('payment_card')),
                    items: cards
                        .map(
                          (account) => DropdownMenuItem<int?>(
                            value: account.id,
                            child: Text(account.name),
                          ),
                        )
                        .toList(),
                    validator: (value) =>
                        value == null ? l10n.text('required_field') : null,
                    onChanged: (value) =>
                        setState(() => _targetAccountId = value),
                  ),
                  const SizedBox(height: 15),
                ],
                _fieldLabel(l10n.text('payment_account')),
                DropdownButtonFormField<int?>(
                  initialValue:
                      eligibleAccounts.any(
                        (account) => account.id == _accountId,
                      )
                      ? _accountId
                      : null,
                  decoration: _inputDecoration(
                    l10n.text('payment_method_unspecified'),
                  ),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(l10n.text('payment_method_unspecified')),
                    ),
                    ...eligibleAccounts.map(
                      (account) => DropdownMenuItem<int?>(
                        value: account.id,
                        enabled: account.type != FinancialAccountType.cash,
                        child: Text(account.name),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _accountId = value),
                ),
                const SizedBox(height: 15),
                _fieldLabel(l10n.text('payment_due_date')),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(_shortDate(context, _dueDate)),
                ),
                if (_type == ScheduledPaymentType.recurring ||
                    _type == ScheduledPaymentType.cardPayment) ...[
                  if (_type == ScheduledPaymentType.cardPayment)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.text('payment_type_recurring')),
                      value: _repeatCard,
                      onChanged: (value) => setState(() {
                        _repeatCard = value;
                        _frequency ??= SubscriptionFrequency.monthly;
                      }),
                    ),
                  if (_type == ScheduledPaymentType.recurring ||
                      _repeatCard) ...[
                    const SizedBox(height: 12),
                    _fieldLabel(l10n.text('payment_frequency_optional')),
                    DropdownButtonFormField<SubscriptionFrequency>(
                      initialValue: _frequency ?? SubscriptionFrequency.monthly,
                      decoration: _inputDecoration(l10n.text('frequency')),
                      items: SubscriptionFrequency.values
                          .map(
                            (frequency) => DropdownMenuItem(
                              value: frequency,
                              child: Text(_frequencyLabel(frequency, l10n)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _frequency = value),
                    ),
                  ],
                ],
                const SizedBox(height: 15),
                _fieldLabel(l10n.text('payment_reminder')),
                DropdownButtonFormField<int>(
                  initialValue: _reminderDays,
                  decoration: _inputDecoration(l10n.text('payment_reminder')),
                  items: [0, 1, 3, 7]
                      .map(
                        (days) => DropdownMenuItem(
                          value: days,
                          child: Text(
                            days == 0
                                ? l10n.text('same_day')
                                : l10n
                                      .text('days_before')
                                      .replaceAll('{count}', '$days'),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _reminderDays = value);
                  },
                ),
                const SizedBox(height: 15),
                _fieldLabel(l10n.text('notes_optional')),
                TextFormField(
                  controller: _notes,
                  minLines: 2,
                  maxLines: 4,
                  decoration: _inputDecoration(l10n.text('notes_optional')),
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0C2340),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(l10n.text('save')),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _fieldLabel(String value) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      value,
      style: const TextStyle(
        color: Color(0xFF334155),
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: Color(0xFFD7E0EA)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: Color(0xFFD7E0EA)),
    ),
  );
}

String _typeLabel(MovaLocalizations l10n, ScheduledPaymentType type) =>
    switch (type) {
      ScheduledPaymentType.recurring => l10n.text('payment_type_recurring'),
      ScheduledPaymentType.oneTime => l10n.text('payment_type_one_time'),
      ScheduledPaymentType.cardPayment => l10n.text('payment_type_card'),
    };

String _frequencyLabel(
  SubscriptionFrequency frequency,
  MovaLocalizations l10n,
) => l10n.text('frequency_${frequency.name}');

String _formatMoney(num amount, String currency) {
  final definition = movaCurrencies.firstWhere(
    (item) => item.code == currency,
    orElse: () => movaCurrencies.first,
  );
  return '${definition.symbol}${amount.toStringAsFixed(2)} $currency';
}

String _currencyTotals(Map<String, double> totals) => totals.isEmpty
    ? '—'
    : totals.entries
          .map((entry) => _formatMoney(entry.value, entry.key))
          .join(' · ');

String _decimal(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();
