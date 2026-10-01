import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mova/database/database_helper.dart';
import 'package:mova/services/currency_controller.dart';
import 'package:mova/services/mova_localizations.dart';
import 'package:mova/models/subscription.dart';
import 'package:mova/models/financial_account.dart';
import 'package:mova/models/scheduled_payment.dart';
import 'package:mova/widgets/user_avatar.dart';
import 'package:mova/widgets/mova_notifications_dialog.dart';
import 'package:mova/widgets/mova_design_system.dart';

import 'login_screen.dart';
import 'movements_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onOpenSettings,
    this.onOpenSubscriptions,
    this.onOpenAccounts,
    this.onOpenPayments,
  });

  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenSubscriptions;
  final VoidCallback? onOpenAccounts;
  final VoidCallback? onOpenPayments;

  static const Color primaryTeal = MovaDesign.accent;
  static const Color darkNavy = Color(0xFF0C2340);
  static const Color subtitleGrey = Color(0xFF727272);
  static const Color backgroundColor = MovaDesign.canvas;

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  late Future<_HomeData> _homeData;

  @override
  void initState() {
    super.initState();
    DatabaseHelper.financialDataVersion.addListener(refresh);
    _loadHomeData();
  }

  @override
  void dispose() {
    DatabaseHelper.financialDataVersion.removeListener(refresh);
    super.dispose();
  }

  void refresh() {
    if (mounted) {
      setState(_loadHomeData);
    }
  }

  void _loadHomeData() {
    _homeData =
        Future.wait([
          _databaseHelper.getTransactions(),
          _databaseHelper.getTransactionSummary(),
          _databaseHelper.getGoals(),
          _databaseHelper.getSubscriptions(),
          _databaseHelper.getFinancialAccounts(includeInactive: false),
          _databaseHelper.getScheduledPayments(),
          _databaseHelper.getFinancialOverview(
            homeCurrency: appCurrencyController.code,
          ),
        ]).then(
          (results) => _HomeData(
            transactions: results[0] as List<Map<String, dynamic>>,
            summary: results[1] as Map<String, double>,
            goals: results[2] as List<Map<String, dynamic>>,
            subscriptions: results[3] as List<Subscription>,
            accounts: results[4] as List<FinancialAccount>,
            scheduledPayments: results[5] as List<ScheduledPayment>,
            accountOverview: results[6] as Map<String, Map<String, double>>,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: FutureBuilder<_HomeData>(
          future: _homeData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  movaText('No se pudo cargar el resumen: ${snapshot.error}'),
                ),
              );
            }
            final data = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async {
                setState(_loadHomeData);
                await _homeData;
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HeaderSection(onOpenSettings: widget.onOpenSettings),
                    const SizedBox(height: 22),
                    BalanceCard(balance: data.balance),
                    const SizedBox(height: 14),
                    QuickSummarySection(
                      income: data.income,
                      expenses: data.expenses,
                      savings: data.savings,
                    ),
                    if (data.accounts.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      AccountsOverviewSection(
                        accounts: data.accounts,
                        overview: data.accountOverview,
                        onTap: widget.onOpenAccounts,
                      ),
                    ],
                    if (data.upcomingPaymentItems.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      UpcomingPaymentsOverviewSection(
                        payments: data.upcomingPaymentItems,
                        onTap: widget.onOpenPayments,
                      ),
                    ],
                    const SizedBox(height: 27),
                    RecentTransactionsSection(transactions: data.transactions),
                    const SizedBox(height: 24),
                    GoalSection(goals: data.goals),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HomeData {
  final List<Map<String, dynamic>> transactions;
  final Map<String, double> summary;
  final List<Map<String, dynamic>> goals;
  final List<Subscription> subscriptions;
  final List<FinancialAccount> accounts;
  final List<ScheduledPayment> scheduledPayments;
  final Map<String, Map<String, double>> accountOverview;

  const _HomeData({
    required this.transactions,
    required this.summary,
    required this.goals,
    required this.subscriptions,
    required this.accounts,
    required this.scheduledPayments,
    required this.accountOverview,
  });

  List<Subscription> get activeSubscriptions =>
      subscriptions
          .where(
            (subscription) => subscription.status == SubscriptionStatus.active,
          )
          .toList()
        ..sort((a, b) => a.nextChargeDate.compareTo(b.nextChargeDate));

  List<UpcomingPayment> get upcomingPaymentItems {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = today.add(const Duration(days: 30));
    final items = [
      ...activeSubscriptions.map(UpcomingPayment.fromSubscription),
      ...scheduledPayments.map((payment) {
        final accountId = payment.targetAccountId ?? payment.accountId;
        final account = accountId == null
            ? null
            : accounts.where((item) => item.id == accountId).firstOrNull;
        final label = account == null
            ? ''
            : account.lastFour.isEmpty
            ? account.name
            : '${account.name} •••• ${account.lastFour}';
        return UpcomingPayment.fromScheduled(payment, accountLabel: label);
      }),
    ];
    items.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return items.where((item) {
      final due = DateTime(
        item.dueDate.year,
        item.dueDate.month,
        item.dueDate.day,
      );
      return !due.isBefore(today) && due.isBefore(end);
    }).toList();
  }

  double get income => summary['income']!;
  double get expenses => summary['expenses']!;
  double get savings => summary['savings']!;
  double get balance {
    if (accounts.isEmpty) return income - expenses - savings;
    return accountOverview['available']?[appCurrencyController.code] ?? 0;
  }
}

class AccountsOverviewSection extends StatelessWidget {
  const AccountsOverviewSection({
    super.key,
    required this.accounts,
    required this.overview,
    this.onTap,
  });
  final List<FinancialAccount> accounts;
  final Map<String, Map<String, double>> overview;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final byType = <String, Map<String, double>>{};
    for (final account in accounts) {
      if (account.type == FinancialAccountType.creditCard) continue;
      final key = account.type == FinancialAccountType.cash ? 'cash' : 'bank';
      byType
          .putIfAbsent(key, () => {})
          .update(
            account.currency,
            (value) => value + account.balance,
            ifAbsent: () => account.balance,
          );
    }
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE7E7E7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.text('my_accounts'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    '${accounts.length}',
                    style: const TextStyle(color: Color(0xFF727272)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final type in ['cash', 'bank'])
                if ((byType[type] ?? {}).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(l10n.text('${type}_accounts'))),
                        Text(
                          _accountTotals(byType[type]!),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
              ..._overviewRows(
                l10n.text('general_savings'),
                overview['general_savings'] ?? const {},
              ),
              ..._overviewRows(
                l10n.text('goals'),
                overview['goal_allocations'] ?? const {},
              ),
              ..._overviewRows(
                l10n.text('credit_debt'),
                overview['credit_debt'] ?? const {},
                debt: true,
              ),
              const Divider(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.text('available_to_spend'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    _accountTotals(overview['available'] ?? const {}),
                    style: const TextStyle(
                      color: HomeScreen.darkNavy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<Widget> _overviewRows(
  String title,
  Map<String, double> values, {
  bool debt = false,
}) {
  if (values.isEmpty) return const [];
  return [
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          Text(
            '${debt ? '−' : ''}${_accountTotals(values)}',
            style: TextStyle(
              color: debt ? const Color(0xFF414141) : null,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  ];
}

String _accountTotals(Map<String, double> values) => values.entries
    .map((entry) {
      final definition = movaCurrencies.firstWhere(
        (item) => item.code == entry.key,
        orElse: () => movaCurrencies.first,
      );
      return '${definition.symbol}${entry.value.toStringAsFixed(2)} ${entry.key}';
    })
    .join(' · ');

class UpcomingPaymentsOverviewSection extends StatelessWidget {
  const UpcomingPaymentsOverviewSection({
    super.key,
    required this.payments,
    this.onTap,
  });

  final List<UpcomingPayment> payments;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = today.add(const Duration(days: 30));
    final dueWithinMonth = payments.where((item) {
      final due = DateTime(
        item.dueDate.year,
        item.dueDate.month,
        item.dueDate.day,
      );
      return due.isBefore(end);
    }).toList();
    final shown = dueWithinMonth.take(3).toList();
    final totals = <String, double>{};
    for (final payment in dueWithinMonth) {
      totals.update(
        payment.currency,
        (value) => value + payment.amount,
        ifAbsent: () => payment.amount,
      );
    }
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE7E7E7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.event_note_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.text('upcoming_payments'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    context.l10n.text('view_all'),
                    style: const TextStyle(
                      color: Color(0xFF606060),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              if (shown.isEmpty)
                Text(context.l10n.text('no_scheduled_payments'))
              else
                ...shown.map(
                  (payment) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            payment.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${_subscriptionMoney(payment.amount, payment.currency)} · ${_daysUntilCharge(context, payment.dueDate)}${payment.accountLabel.isEmpty ? '' : ' · ${payment.accountLabel}'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF535353),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (totals.isNotEmpty) ...[
                const Divider(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.text('payments_next_30_days'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      totals.entries
                          .map(
                            (entry) =>
                                _subscriptionMoney(entry.value, entry.key),
                          )
                          .join(' · '),
                      style: const TextStyle(
                        color: HomeScreen.darkNavy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class UpcomingSubscriptionsSection extends StatelessWidget {
  const UpcomingSubscriptionsSection({
    super.key,
    required this.subscriptions,
    this.onTap,
  });

  final List<Subscription> subscriptions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = today.add(const Duration(days: 30));
    final upcomingWithinMonth = subscriptions.where((item) {
      final due = DateTime(
        item.nextChargeDate.year,
        item.nextChargeDate.month,
        item.nextChargeDate.day,
      );
      return !due.isBefore(today) && due.isBefore(end);
    }).toList();
    final upcoming = upcomingWithinMonth.take(3).toList();
    final totals = <String, double>{};
    for (final subscription in upcomingWithinMonth) {
      totals.update(
        subscription.currency,
        (value) => value + subscription.amount,
        ifAbsent: () => subscription.amount,
      );
    }
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE7E7E7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.autorenew_rounded,
                    color: HomeScreen.darkNavy,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.text('upcoming_payments'),
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    '${subscriptions.length} ${context.l10n.text('active')}',
                    style: const TextStyle(
                      color: Color(0xFF727272),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (upcoming.isEmpty)
                Text(context.l10n.text('no_upcoming_charges'))
              else
                ...upcoming.map(
                  (subscription) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            subscription.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${_subscriptionMoney(subscription.amount, subscription.currency)} · ${_daysUntilCharge(context, subscription.nextChargeDate)}',
                          style: const TextStyle(
                            color: Color(0xFF535353),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (totals.isNotEmpty) ...[
                const Divider(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.text('upcoming_payments_total'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      totals.entries
                          .map(
                            (entry) =>
                                _subscriptionMoney(entry.value, entry.key),
                          )
                          .join(' · '),
                      style: const TextStyle(
                        color: HomeScreen.darkNavy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _subscriptionMoney(num value, String currency) {
  final definition = movaCurrencies.firstWhere(
    (item) => item.code == currency,
    orElse: () => movaCurrencies.first,
  );
  return '${definition.symbol}${value.toStringAsFixed(2)}';
}

String _daysUntilCharge(BuildContext context, DateTime date) {
  final now = DateTime.now();
  final days = DateTime(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime(now.year, now.month, now.day)).inDays;
  if (days < 0) return context.l10n.text('payment_status_overdue');
  return days == 0
      ? context.l10n.text('today')
      : context.l10n.text('days_count').replaceAll('{count}', '$days');
}

// --- 1. ENCABEZADO ---
class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key, this.onOpenSettings});

  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: profileChanged,
      builder: (context, _, _) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: DatabaseHelper().getCurrentUser(),
          builder: (context, snapshot) {
            final name = (snapshot.data?['name'] as String?) ?? 'Hola';
            final l10n = context.l10n;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 27,
                            height: 27,
                            decoration: BoxDecoration(
                              gradient: MovaDesign.accentGradient,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: [
                                BoxShadow(
                                  color: MovaDesign.accent.withValues(
                                    alpha: .2,
                                  ),
                                  blurRadius: 9,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.show_chart_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'MOVA',
                            style: TextStyle(
                              color: HomeScreen.darkNavy,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.8,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: MovaDesign.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            MaterialLocalizations.of(context)
                                .formatMediumDate(DateTime.now()),
                            style: const TextStyle(
                              color: HomeScreen.subtitleGrey,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 13),
                      Text(
                        '${l10n.text('hello')}, $name',
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: HomeScreen.darkNavy,
                          letterSpacing: -.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.text('home_summary'),
                        style: const TextStyle(
                          fontSize: 13,
                          color: HomeScreen.subtitleGrey,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: l10n.text('account_options'),
                      onPressed: () => _showProfileMenu(context),
                      padding: EdgeInsets.all(5),
                      constraints: const BoxConstraints.tightFor(
                        width: 46,
                        height: 46,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: MovaDesign.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: UserAvatar(radius: 16),
                    ),
                    const SizedBox(width: 5),
                    IconButton(
                      tooltip: l10n.text('notifications'),
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => MovaNotificationsDialog(),
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: MovaDesign.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        size: 22,
                        color: HomeScreen.darkNavy,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showProfileMenu(BuildContext context) async {
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.text('account_options'),
                style: TextStyle(
                  color: Color(0xFF102A43),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: Text(l10n.text('settings')),
                subtitle: Text(l10n.text('preferences')),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onOpenSettings?.call();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFF414141),
                ),
                title: Text(l10n.text('logout')),
                subtitle: Text(l10n.text('exit_device')),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await DatabaseHelper().logout();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeNotificationsDialog extends StatefulWidget {
  const _HomeNotificationsDialog();

  @override
  State<_HomeNotificationsDialog> createState() =>
      _HomeNotificationsDialogState();
}

class _HomeNotificationsDialogState extends State<_HomeNotificationsDialog> {
  final _database = DatabaseHelper();
  bool _loading = true;
  bool _enabled = true;
  bool _budget = true;
  bool _goals = true;
  bool _shopping = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final values = await Future.wait([
      _database.getNotificationsEnabled(),
      _database.getNotificationOption('notification_budget'),
      _database.getNotificationOption('notification_goals'),
      _database.getNotificationOption('notification_shopping'),
    ]);
    if (!mounted) return;
    setState(() {
      _enabled = values[0];
      _budget = values[1];
      _goals = values[2];
      _shopping = values[3];
      _loading = false;
    });
  }

  Future<void> _set(String key, bool value) async {
    await _database.setNotificationOption(key, value);
    if (!mounted) return;
    setState(() {
      if (key == 'notifications_enabled') {
        _enabled = value;
      } else if (key == 'notification_budget') {
        _budget = value;
      } else if (key == 'notification_goals') {
        _goals = value;
      } else if (key == 'notification_shopping') {
        _shopping = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Icon(Icons.notifications_active_outlined, color: HomeScreen.darkNavy),
          SizedBox(width: 10),
          Text(l10n.text('notifications')),
        ],
      ),
      content: _loading
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.text('choose_notifications'),
                    style: TextStyle(color: HomeScreen.subtitleGrey),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.text('notifications_active')),
                    value: _enabled,
                    onChanged: (value) => _set('notifications_enabled', value),
                  ),
                  const Divider(),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.text('personal_budget')),
                    value: _budget,
                    onChanged: !_enabled
                        ? null
                        : (value) => _set('notification_budget', value),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.text('savings_goals')),
                    value: _goals,
                    onChanged: !_enabled
                        ? null
                        : (value) => _set('notification_goals', value),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.text('shopping_lists')),
                    value: _shopping,
                    onChanged: !_enabled
                        ? null
                        : (value) => _set('notification_shopping', value),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.text('close')),
        ),
      ],
    );
  }
}

// --- 2. TARJETA PRINCIPAL ---
class BalanceCard extends StatelessWidget {
  final double balance;

  const BalanceCard({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: MovaDesign.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: MovaDesign.cardShadow,
        border: Border.all(color: const Color(0x338CE1E8)),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: MovaRadialHighlight(color: Color(0xFF9E9E9E)),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: .075),
                  width: 1,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Color(0xFFCFCFCF),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    movaText('Dinero disponible'),
                    style: const TextStyle(
                      color: Color(0xFFD3D3D3),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(end: balance),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                builder: (context, animatedBalance, _) => FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    appCurrencyController.format(animatedBalance),
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.4,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 13,
                          color: Color(0xFFCFCFCF),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${movaText('balance')} · ${appCurrencyController.code}',
                          style: const TextStyle(
                            color: Color(0xFFDFDFDF),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFFCFCFCF),
                    size: 15,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- 3. RESUMEN RÁPIDO ---
class QuickSummarySection extends StatelessWidget {
  final double income;
  final double expenses;
  final double savings;

  const QuickSummarySection({
    super.key,
    required this.income,
    required this.expenses,
    required this.savings,
  });

  @override
  Widget build(BuildContext context) {
    return MovaSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: SummaryItem(
              title: movaText("Ingresos"),
              amount: appCurrencyController.format(income),
              icon: Icons.arrow_outward_rounded,
              color: MovaDesign.positive,
            ),
          ),
          _summaryDivider(),
          Expanded(
            child: SummaryItem(
              title: movaText("Gastos"),
              amount: '-${appCurrencyController.format(expenses)}',
              icon: Icons.south_west_rounded,
              color: MovaDesign.negative,
            ),
          ),
          _summaryDivider(),
          Expanded(
            child: SummaryItem(
              title: movaText("Ahorro"),
              amount: appCurrencyController.format(savings),
              icon: Icons.savings_outlined,
              color: MovaDesign.navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryDivider() => Container(
    width: 1,
    height: 36,
    color: MovaDesign.border,
    margin: const EdgeInsets.symmetric(horizontal: 8),
  );
}

class SummaryItem extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;

  const SummaryItem({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: HomeScreen.subtitleGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            amount,
            maxLines: 1,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -.2,
            ),
          ),
        ),
      ],
    );
  }
}

// --- 4. MOVIMIENTOS RECIENTES ---
class RecentTransactionsSection extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  const RecentTransactionsSection({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEDED),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    size: 17,
                    color: HomeScreen.primaryTeal,
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  movaText("Movimientos recientes"),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: HomeScreen.darkNavy,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MovementsScreen()),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 15),
              label: Text(movaText("Ver todos")),
              style: TextButton.styleFrom(
                foregroundColor: HomeScreen.primaryTeal,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        MovaSurface(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: transactions.isEmpty
                ? [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 22),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 32,
                            color: Color(0xFFA1A1A1),
                          ),
                          SizedBox(height: 8),
                          Text(
                            movaText('Aún no tienes movimientos registrados'),
                            style: TextStyle(
                              fontSize: 13,
                              color: HomeScreen.subtitleGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]
                : [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        '${transactions.length} movimiento${transactions.length == 1 ? '' : 's'} registrados',
                        style: const TextStyle(
                          color: Color(0xFF727272),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ...transactions.take(5).toList().asMap().entries.map((
                      entry,
                    ) {
                      final transaction = entry.value;
                      final isSavingsDeposit = DatabaseHelper.isSavingsDeposit(
                        transaction,
                      );
                      final isExpense =
                          transaction['is_income'] == 0 && !isSavingsDeposit;
                      final amount = (transaction['amount'] as num).toDouble();
                      final date = DateTime.tryParse(
                        transaction['date'] as String? ?? '',
                      );
                      final subtitle = [
                        context.l10n.translate(
                          transaction['category'] as String? ?? '',
                        ),
                        if (date != null)
                          MaterialLocalizations.of(context)
                              .formatMediumDate(date),
                      ].where((part) => part.isNotEmpty).join(' · ');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: TransactionItem(
                          title: transaction['description'] as String,
                          subtitle: subtitle,
                          amount:
                              '${isExpense ? '-' : '+'}${appCurrencyController.format(amount)}',
                          icon: _iconForCategory(
                            transaction['category'] as String,
                          ),
                          iconColor: isExpense
                              ? MovaDesign.negative
                              : MovaDesign.positive,
                          isExpense: isExpense,
                        ),
                      );
                    }),
                  ],
          ),
        ),
      ],
    );
  }

  static IconData _iconForCategory(String category) {
    switch (category) {
      case 'Comida':
        return Icons.restaurant_rounded;
      case 'Transporte':
        return Icons.directions_car_rounded;
      case 'Compras':
        return Icons.shopping_bag_rounded;
      case 'Hogar':
        return Icons.home_rounded;
      case 'Entretenimiento':
        return Icons.movie_rounded;
      case 'Sueldo':
        return Icons.account_balance_wallet_rounded;
      case 'Inversión':
        return Icons.trending_up_rounded;
      default:
        return Icons.receipt_long_outlined;
    }
  }
}

class TransactionItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;
  final Color iconColor;
  final bool isExpense;

  const TransactionItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    required this.iconColor,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: HomeScreen.darkNavy,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: MovaDesign.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: isExpense ? MovaDesign.negative : MovaDesign.positive,
            ),
          ),
        ],
      ),
    );
  }
}

// --- 5. META ACTUAL ---
class GoalSection extends StatelessWidget {
  final List<Map<String, dynamic>> goals;

  const GoalSection({super.key, required this.goals});

  @override
  Widget build(BuildContext context) {
    return MovaSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEDED),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  size: 17,
                  color: HomeScreen.primaryTeal,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                movaText("Meta actual"),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: HomeScreen.darkNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (goals.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE7E7E7)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    color: HomeScreen.subtitleGrey,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.l10n.text('no_goals_home'),
                      style: TextStyle(
                        fontSize: 13,
                        color: HomeScreen.subtitleGrey,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            _ActiveGoalSummary(goal: goals.first),
        ],
      ),
    );
  }
}

class _ActiveGoalSummary extends StatelessWidget {
  final Map<String, dynamic> goal;

  const _ActiveGoalSummary({required this.goal});

  @override
  Widget build(BuildContext context) {
    final target = (goal['target_amount'] as num).toDouble();
    final saved = (goal['saved_amount'] as num).toDouble();
    final progress = (saved / target).clamp(0.0, 1.0);
    final rawImage = goal['image'];
    final image = rawImage is Uint8List
        ? rawImage
        : rawImage is List
        ? Uint8List.fromList(rawImage.cast<int>())
        : null;

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 58,
            height: 58,
            child: image != null && image.isNotEmpty
                ? Image.memory(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _GoalFallbackIcon(),
                  )
                : const _GoalFallbackIcon(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                goal['name'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: HomeScreen.darkNavy,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${appCurrencyController.format(saved)} / ${appCurrencyController.format(target)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: HomeScreen.subtitleGrey,
                ),
              ),
              const SizedBox(height: 8),
              MovaProgressBar(value: progress, height: 7),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoalFallbackIcon extends StatelessWidget {
  const _GoalFallbackIcon();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Color(0xFFEDEDED),
      child: Center(
        child: Icon(
          Icons.flag_outlined,
          color: HomeScreen.primaryTeal,
          size: 28,
        ),
      ),
    );
  }
}
