import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mova/database/database_helper.dart';
import 'package:mova/models/subscription.dart';
import 'package:mova/models/financial_account.dart';
import 'package:mova/services/currency_controller.dart';
import 'package:mova/services/mova_localizations.dart';
import 'package:mova/services/subscription_reminder_service.dart';
import 'package:mova/widgets/mova_design_system.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final _database = DatabaseHelper();
  late Future<List<Subscription>> _subscriptions;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _subscriptions = _database.getSubscriptions();
  }

  Future<void> _refresh() async {
    setState(_load);
    await _subscriptions;
  }

  Future<void> _openForm([Subscription? subscription]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SubscriptionFormScreen(subscription: subscription),
      ),
    );
    if (saved == true && mounted) await _refresh();
  }

  Future<void> _openDetails(Subscription subscription) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SubscriptionDetailsScreen(subscription: subscription),
      ),
    );
    if (changed == true && mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: MovaDesign.canvas,
      appBar: AppBar(
        title: Text(l10n.text('my_subscriptions')),
        backgroundColor: MovaDesign.canvas,
        actions: [
          IconButton(
            tooltip: l10n.text('new_subscription'),
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<Subscription>>(
        future: _subscriptions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.text('subscriptions_load_error'),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final subscriptions = snapshot.data ?? const <Subscription>[];
          final active = subscriptions
              .where((item) => item.status == SubscriptionStatus.active)
              .toList();
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final end = today.add(const Duration(days: 30));
          final upcoming =
              active.where((item) {
                  final due = DateTime(
                    item.nextChargeDate.year,
                    item.nextChargeDate.month,
                    item.nextChargeDate.day,
                  );
                  return !due.isBefore(today) && due.isBefore(end);
                }).toList()
                ..sort((a, b) => a.nextChargeDate.compareTo(b.nextChargeDate));
          final monthlyByCurrency = _monthlyByCurrency(active);
          final upcomingByCurrency = _monthlyByCurrency(
            upcoming,
            monthly: false,
          );
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _SummaryCard(
                  title: l10n.text('active_subscriptions'),
                  value: '${active.length}',
                  icon: Icons.autorenew_rounded,
                  accent: const Color(0xFF0C2340),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = (constraints.maxWidth - 12) / 2;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _SummaryCard(
                          width: itemWidth,
                          title: l10n.text('estimated_monthly_spend'),
                          amounts: monthlyByCurrency,
                          icon: Icons.calendar_month_outlined,
                          accent: const Color(0xFF2563EB),
                        ),
                        _SummaryCard(
                          width: itemWidth,
                          title: l10n.text('estimated_annual_spend'),
                          amounts: {
                            for (final entry in monthlyByCurrency.entries)
                              entry.key: entry.value * 12,
                          },
                          icon: Icons.date_range_rounded,
                          accent: const Color(0xFF7C3AED),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                _SectionHeading(
                  title: l10n.text('upcoming_charges'),
                  trailing: upcomingByCurrency.isEmpty
                      ? null
                      : Text(
                          _currencyTotals(upcomingByCurrency),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                ),
                if (upcoming.isEmpty)
                  _EmptyCard(
                    text: l10n.text('no_upcoming_charges'),
                    icon: Icons.event_available_outlined,
                  )
                else
                  ...upcoming.map(
                    (subscription) => _UpcomingCard(
                      subscription: subscription,
                      onTap: () => _openDetails(subscription),
                    ),
                  ),
                const SizedBox(height: 20),
                _SectionHeading(
                  title: l10n.text('all_subscriptions'),
                  trailing: TextButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.text('add')),
                  ),
                ),
                if (subscriptions.isEmpty)
                  _EmptyCard(
                    text: l10n.text('subscriptions_empty'),
                    icon: Icons.subscriptions_outlined,
                    action: FilledButton.icon(
                      onPressed: () => _openForm(),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.text('new_subscription')),
                    ),
                  )
                else
                  ...subscriptions.map(
                    (subscription) => _SubscriptionCard(
                      subscription: subscription,
                      onTap: () => _openDetails(subscription),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.icon,
    required this.accent,
    this.value,
    this.amounts,
    this.width,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final String? value;
  final Map<String, double>? amounts;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            const SizedBox(height: 5),
            if (value != null)
              Text(
                value!,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              )
            else
              _currencyTotalsWidget(amounts ?? const {}),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text, required this.icon, this.action});
  final String text;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      children: [
        Icon(icon, size: 32, color: const Color(0xFF64748B)),
        const SizedBox(height: 10),
        Text(text, textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: 14), action!],
      ],
    ),
  );
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.subscription, required this.onTap});
  final Subscription subscription;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final days = _daysUntil(subscription.nextChargeDate);
    final relative = days == 0
        ? context.l10n.text('today')
        : context.l10n.text('days_count').replaceAll('{count}', '$days');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFEFF6FF),
          child: Icon(
            Icons.notifications_active_outlined,
            color: Color(0xFF2563EB),
          ),
        ),
        title: Text(
          subscription.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${_dateLabel(context, subscription.nextChargeDate)} · $relative',
        ),
        trailing: Text(
          _money(subscription.amount, subscription.currency),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.subscription, required this.onTap});
  final Subscription subscription;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = subscription.status;
    final statusColor = switch (status) {
      SubscriptionStatus.active => const Color(0xFF15803D),
      SubscriptionStatus.paused => const Color(0xFFB45309),
      SubscriptionStatus.cancelled => const Color(0xFF64748B),
    };
    final statusLabel = switch (status) {
      SubscriptionStatus.active => context.l10n.text('active'),
      SubscriptionStatus.paused => context.l10n.text('paused'),
      SubscriptionStatus.cancelled => context.l10n.text('cancelled'),
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: const Color(0xFFF1F5F9),
                child: Icon(
                  _categoryIcon(subscription.category),
                  color: const Color(0xFF0C2340),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_money(subscription.amount, subscription.currency)} / ${_frequencyLabel(context, subscription.frequency)}',
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${context.l10n.text('next_charge')}: ${_dateLabel(context, subscription.nextChargeDate)}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                    if (subscription.accountLabel.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '💳 ${subscription.accountLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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

class SubscriptionFormScreen extends StatefulWidget {
  const SubscriptionFormScreen({super.key, this.subscription});
  final Subscription? subscription;

  @override
  State<SubscriptionFormScreen> createState() => _SubscriptionFormScreenState();
}

class _SubscriptionFormScreenState extends State<SubscriptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _database = DatabaseHelper();
  final _reminders = SubscriptionReminderService();
  late Future<List<FinancialAccount>> _accounts;
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _amount;
  late final TextEditingController _account;
  late final TextEditingController _notes;
  late DateTime _nextChargeDate;
  late SubscriptionFrequency _frequency;
  late int _reminderDays;
  late String _currency;
  late String _category;
  int? _accountId;
  List<FinancialAccount> _accountsValue = const [];
  List<String> _categories = _defaultExpenseCategories;
  bool _saving = false;

  static const _defaultExpenseCategories = [
    'Comida',
    'Transporte',
    'Compras',
    'Hogar',
    'Entretenimiento',
    'Suscripciones',
    'Servicios',
    'Salud',
    'Ahorro',
    'Otros',
  ];

  @override
  void initState() {
    super.initState();
    final subscription = widget.subscription;
    _name = TextEditingController(text: subscription?.name ?? '');
    _description = TextEditingController(text: subscription?.description ?? '');
    _amount = TextEditingController(
      text: subscription == null ? '' : _decimal(subscription.amount),
    );
    _account = TextEditingController(text: subscription?.accountLabel ?? '');
    _notes = TextEditingController(text: subscription?.notes ?? '');
    _nextChargeDate = subscription?.nextChargeDate ?? DateTime.now();
    _frequency = subscription?.frequency ?? SubscriptionFrequency.monthly;
    _reminderDays = subscription?.reminderDays ?? 1;
    _currency = subscription?.currency ?? appCurrencyController.code;
    _category = subscription?.category ?? 'Entretenimiento';
    _accountId = subscription?.accountId;
    _accounts = _database.getFinancialAccounts();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final stored = await _database.getCustomCategories();
    if (!mounted) return;
    final names = stored
        .where((item) => item['type'] == 'expense')
        .map((item) => item['name'] as String)
        .toSet();
    setState(() {
      _categories = {..._defaultExpenseCategories, ...names}.toList()..sort();
      if (!_categories.contains(_category)) _categories.add(_category);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _amount.dispose();
    _account.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _nextChargeDate.isBefore(DateTime(2000))
          ? DateTime.now()
          : _nextChargeDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null) setState(() => _nextChargeDate = selected);
  }

  String _selectedAccountLabel() {
    if (_accountId == null) return _account.text.trim();
    return _accountsValue
            .where((account) => account.id == _accountId)
            .map(
              (account) => account.lastFour.isEmpty
                  ? account.name
                  : '${account.name} •••• ${account.lastFour}',
            )
            .firstOrNull ??
        _account.text.trim();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      _accountsValue = await _accounts;
      if (_accountId != null &&
          !_accountsValue.any(
            (account) =>
                account.id == _accountId &&
                account.isActive &&
                account.currency == _currency,
          )) {
        throw StateError(
          'La cuenta asociada debe estar activa y usar la moneda seleccionada.',
        );
      }
      final amount = double.parse(_amount.text.trim().replaceAll(',', '.'));
      final previous = widget.subscription;
      final subscription = Subscription(
        id: previous?.id ?? 0,
        name: _name.text.trim(),
        description: _description.text.trim(),
        amount: amount,
        currency: _currency,
        category: _category,
        frequency: _frequency,
        nextChargeDate: _nextChargeDate,
        billingDay:
            previous != null && _nextChargeDate == previous.nextChargeDate
            ? previous.billingDay
            : _nextChargeDate.day,
        accountId: _accountId,
        accountLabel: _selectedAccountLabel(),
        status: previous?.status ?? SubscriptionStatus.active,
        reminderDays: _reminderDays,
        createdAt: previous?.createdAt ?? DateTime.now(),
        notes: _notes.text.trim(),
      );
      final id = previous == null
          ? await _database.createSubscription(subscription)
          : previous.id;
      if (previous != null) await _database.updateSubscription(subscription);
      String? reminderError;
      try {
        await _refreshReminder(id);
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
        SnackBar(content: Text('${context.l10n.text('save_error')}: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _refreshReminder(int id) async {
    final subscription = await _database.getSubscription(id);
    if (subscription == null) return;
    await _reminders.schedule(subscription);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: MovaDesign.canvas,
      appBar: AppBar(
        title: Text(
          l10n.text(
            widget.subscription == null
                ? 'new_subscription'
                : 'edit_subscription',
          ),
        ),
        backgroundColor: MovaDesign.canvas,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          children: [
            _fieldLabel(l10n.text('subscription_name')),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration(l10n.text('subscription_name_hint')),
              validator: (value) => value == null || value.trim().isEmpty
                  ? l10n.text('required_field')
                  : null,
            ),
            const SizedBox(height: 16),
            _fieldLabel(l10n.text('description_optional')),
            TextFormField(
              controller: _description,
              decoration: _inputDecoration(l10n.text('description_optional')),
            ),
            const SizedBox(height: 16),
            _fieldLabel(l10n.text('amount_and_currency')),
            Row(
              children: [
                Expanded(
                  flex: 2,
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
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _currency,
                    decoration: _inputDecoration(l10n.text('currency')),
                    items: movaCurrencies
                        .map(
                          (currency) => DropdownMenuItem(
                            value: currency.code,
                            child: Text(currency.code),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _currency = value;
                          if (_accountsValue.any(
                            (account) =>
                                account.id == _accountId &&
                                account.currency != value,
                          )) {
                            _accountId = null;
                            _account.clear();
                          }
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _fieldLabel(l10n.text('category')),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: _inputDecoration(l10n.text('category')),
              items: _categories
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 16),
            _fieldLabel(l10n.text('frequency')),
            DropdownButtonFormField<SubscriptionFrequency>(
              initialValue: _frequency,
              decoration: _inputDecoration(l10n.text('frequency')),
              items: SubscriptionFrequency.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(_frequencyLabel(context, value)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _frequency = value);
              },
            ),
            const SizedBox(height: 16),
            _fieldLabel(l10n.text('next_charge')),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(_dateLabel(context, _nextChargeDate)),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _fieldLabel(l10n.text('account_or_card')),
            FutureBuilder<List<FinancialAccount>>(
              future: _accounts,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(l10n.text('accounts_load_error'));
                }
                _accountsValue = snapshot.data ?? const [];
                final options = _accountsValue
                    .where(
                      (account) =>
                          account.currency == _currency &&
                          (account.isActive || account.id == _accountId) &&
                          (account.type != FinancialAccountType.cash ||
                              account.id == _accountId),
                    )
                    .toList();
                return DropdownButtonFormField<int?>(
                  initialValue: options.any((item) => item.id == _accountId)
                      ? _accountId
                      : null,
                  decoration: _inputDecoration(
                    l10n.text('no_account_selected'),
                  ),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(l10n.text('no_account_selected')),
                    ),
                    ...options.map(
                      (account) => DropdownMenuItem<int?>(
                        value: account.id,
                        enabled: account.type != FinancialAccountType.cash,
                        child: Text(
                          '${account.name} · ${l10n.text('account_type_${account.type.name}')}${account.isActive ? '' : ' · ${l10n.text('inactive')}'}',
                        ),
                      ),
                    ),
                  ],
                  onChanged: (id) {
                    setState(() {
                      _accountId = id;
                      if (id == null) _account.clear();
                      if (id != null) {
                        final account = options.firstWhere(
                          (item) => item.id == id,
                        );
                        _account.text = account.lastFour.isEmpty
                            ? account.name
                            : '${account.name} •••• ${account.lastFour}';
                      }
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _account,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration(l10n.text('account_hint')),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            _fieldLabel(l10n.text('notes_optional')),
            TextFormField(
              controller: _notes,
              minLines: 2,
              maxLines: 4,
              decoration: _inputDecoration(l10n.text('notes_optional')),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0C2340),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.text('save_subscription')),
            ),
          ],
        ),
      ),
    );
  }
}

class SubscriptionDetailsScreen extends StatefulWidget {
  const SubscriptionDetailsScreen({super.key, required this.subscription});
  final Subscription subscription;

  @override
  State<SubscriptionDetailsScreen> createState() =>
      _SubscriptionDetailsScreenState();
}

class _SubscriptionDetailsScreenState extends State<SubscriptionDetailsScreen> {
  final _database = DatabaseHelper();
  final _reminders = SubscriptionReminderService();
  late Subscription _subscription;
  late Future<List<Map<String, Object?>>> _history;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _subscription = widget.subscription;
    _loadHistory();
  }

  void _loadHistory() {
    _history = _database.getSubscriptionHistory(_subscription.id);
  }

  Future<void> _refresh() async {
    final refreshed = await _database.getSubscription(_subscription.id);
    if (!mounted) return;
    if (refreshed == null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _subscription = refreshed;
      _loadHistory();
    });
  }

  Future<void> _edit() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SubscriptionFormScreen(subscription: _subscription),
      ),
    );
    if (saved == true) await _refresh();
  }

  Future<void> _changeStatus(SubscriptionStatus status) async {
    try {
      await _database.setSubscriptionStatus(_subscription.id, status);
      String? reminderError;
      try {
        if (status == SubscriptionStatus.active) {
          final updated = await _database.getSubscription(_subscription.id);
          if (updated != null) await _reminders.schedule(updated);
        } else {
          await _reminders.cancel(_subscription.id);
        }
      } catch (error) {
        reminderError = '$error';
      }
      await _refresh();
      if (reminderError != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${context.l10n.text('reminder_schedule_error')}: $reminderError',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.l10n.text('save_error')}: $error')),
      );
    }
  }

  Future<void> _markPaid() async {
    if (_busy || _subscription.status != SubscriptionStatus.active) return;
    final duplicate = await _database.findPotentialDuplicateSubscriptionExpense(
      _subscription.id,
    );
    int? existingTransactionId;
    if (duplicate != null && mounted) {
      final decision = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.text('possible_duplicate')),
          content: Text(context.l10n.text('possible_duplicate_body')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: Text(context.l10n.text('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'existing'),
              child: Text(context.l10n.text('link_existing_movement')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'new'),
              child: Text(context.l10n.text('create_expense_anyway')),
            ),
          ],
        ),
      );
      if (decision == null || decision == 'cancel') return;
      if (decision == 'existing') existingTransactionId = duplicate;
    }
    setState(() => _busy = true);
    try {
      await _database.recordSubscriptionPayment(
        _subscription.id,
        expectedChargeDate: _subscription.nextChargeDate,
        existingTransactionId: existingTransactionId,
      );
      final updated = (await _database.getSubscription(_subscription.id))!;
      String? reminderError;
      try {
        await _reminders.schedule(updated);
      } catch (error) {
        reminderError = '$error';
      }
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reminderError == null
                ? context.l10n.text('subscription_payment_saved')
                : '${context.l10n.text('reminder_schedule_error')}: $reminderError',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.l10n.text('save_error')}: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.text('delete_subscription')),
        content: Text(context.l10n.text('delete_subscription_confirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.text('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _reminders.cancel(_subscription.id);
      await _database.deleteSubscription(_subscription.id);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.l10n.text('save_error')}: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscription = _subscription;
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: MovaDesign.canvas,
      appBar: AppBar(
        title: Text(subscription.name),
        backgroundColor: MovaDesign.canvas,
        actions: [
          IconButton(
            tooltip: l10n.text('edit_subscription'),
            onPressed: _edit,
            icon: const Icon(Icons.edit_outlined),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') _delete();
              if (value == 'pause') _changeStatus(SubscriptionStatus.paused);
              if (value == 'activate') _changeStatus(SubscriptionStatus.active);
              if (value == 'cancel') {
                _changeStatus(SubscriptionStatus.cancelled);
              }
            },
            itemBuilder: (_) => [
              if (subscription.status == SubscriptionStatus.active)
                PopupMenuItem(value: 'pause', child: Text(l10n.text('pause'))),
              if (subscription.status == SubscriptionStatus.paused)
                PopupMenuItem(
                  value: 'activate',
                  child: Text(l10n.text('reactivate')),
                ),
              if (subscription.status != SubscriptionStatus.cancelled)
                PopupMenuItem(
                  value: 'cancel',
                  child: Text(l10n.text('cancel_subscription')),
                ),
              PopupMenuItem(value: 'delete', child: Text(l10n.text('delete'))),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _money(subscription.amount, subscription.currency),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0C2340),
                  ),
                ),
                Text(
                  '${l10n.text('every')} ${_frequencyLabel(context, subscription.frequency)} · ${subscription.category}',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                const Divider(height: 28),
                _detailLine(
                  Icons.event_outlined,
                  l10n.text('next_charge'),
                  _dateLabel(context, subscription.nextChargeDate),
                ),
                if (subscription.accountLabel.isNotEmpty)
                  _detailLine(
                    Icons.credit_card_outlined,
                    l10n.text('account_or_card'),
                    subscription.accountLabel,
                  ),
                _detailLine(
                  Icons.notifications_none_rounded,
                  l10n.text('payment_reminder'),
                  subscription.reminderDays == 0
                      ? l10n.text('same_day')
                      : l10n
                            .text('days_before')
                            .replaceAll(
                              '{count}',
                              '${subscription.reminderDays}',
                            ),
                ),
                if (subscription.description.isNotEmpty)
                  _detailLine(
                    Icons.notes_rounded,
                    l10n.text('description'),
                    subscription.description,
                  ),
                if (subscription.notes.isNotEmpty)
                  _detailLine(
                    Icons.sticky_note_2_outlined,
                    l10n.text('notes'),
                    subscription.notes,
                  ),
              ],
            ),
          ),
          if (subscription.status == SubscriptionStatus.active) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _markPaid,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(l10n.text('mark_as_paid')),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0C2340),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            l10n.text('payment_history'),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<Map<String, Object?>>>(
            future: _history,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text(l10n.text('history_load_error'));
              }
              final history = snapshot.data ?? const [];
              if (history.isEmpty) {
                return _EmptyCard(
                  text: l10n.text('no_subscription_payments'),
                  icon: Icons.receipt_long_outlined,
                );
              }
              return Column(
                children: history.map((payment) {
                  final paidAt = DateTime.parse(payment['paid_at'] as String);
                  final account = payment['account_label'] as String? ?? '';
                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF15803D),
                      ),
                      title: Text(_dateLabel(context, paidAt)),
                      subtitle: Text(
                        account.isEmpty
                            ? l10n.text('paid')
                            : '${l10n.text('paid')} · $account',
                      ),
                      trailing: Text(
                        _money(
                          payment['amount'] as num,
                          payment['currency'] as String,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

Map<String, double> _monthlyByCurrency(
  List<Subscription> subscriptions, {
  bool monthly = true,
}) {
  final totals = <String, double>{};
  for (final subscription in subscriptions) {
    final monthAmount = switch (subscription.frequency) {
      SubscriptionFrequency.weekly => subscription.amount * 52 / 12,
      SubscriptionFrequency.biweekly => subscription.amount * 26 / 12,
      SubscriptionFrequency.monthly => subscription.amount,
      SubscriptionFrequency.bimonthly => subscription.amount / 2,
      SubscriptionFrequency.quarterly => subscription.amount / 3,
      SubscriptionFrequency.semiannual => subscription.amount / 6,
      SubscriptionFrequency.annual => subscription.amount / 12,
    };
    final amount = monthly ? monthAmount : subscription.amount;
    totals.update(
      subscription.currency,
      (value) => value + amount,
      ifAbsent: () => amount,
    );
  }
  return totals;
}

Widget _currencyTotalsWidget(Map<String, double> totals) {
  if (totals.isEmpty) {
    return const Text('—', style: TextStyle(fontSize: 22));
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: totals.entries
        .map(
          (entry) => Text(
            _money(entry.value, entry.key),
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        )
        .toList(),
  );
}

String _currencyTotals(Map<String, double> totals) =>
    totals.entries.map((entry) => _money(entry.value, entry.key)).join(' · ');

String _money(num value, String currency) {
  final definition = movaCurrencies.firstWhere(
    (item) => item.code == currency,
    orElse: () => movaCurrencies.first,
  );
  return '${definition.symbol}${value.toStringAsFixed(2)}';
}

String _decimal(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();

String _frequencyLabel(BuildContext context, SubscriptionFrequency frequency) =>
    context.l10n.text('frequency_${frequency.name}');

String _dateLabel(BuildContext context, DateTime date) {
  final months = [
    context.l10n.text('month_jan'),
    context.l10n.text('month_feb'),
    context.l10n.text('month_mar'),
    context.l10n.text('month_apr'),
    context.l10n.text('month_may'),
    context.l10n.text('month_jun'),
    context.l10n.text('month_jul'),
    context.l10n.text('month_aug'),
    context.l10n.text('month_sep'),
    context.l10n.text('month_oct'),
    context.l10n.text('month_nov'),
    context.l10n.text('month_dec'),
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

int _daysUntil(DateTime date) {
  final today = DateTime.now();
  return DateTime(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime(today.year, today.month, today.day)).inDays;
}

IconData _categoryIcon(String category) {
  final normalized = category.toLowerCase();
  if (normalized.contains('entreten') || normalized.contains('stream')) {
    return Icons.movie_outlined;
  }
  if (normalized.contains('servicio') || normalized.contains('internet')) {
    return Icons.wifi_rounded;
  }
  if (normalized.contains('salud') || normalized.contains('gimnas')) {
    return Icons.fitness_center_rounded;
  }
  return Icons.autorenew_rounded;
}

Widget _fieldLabel(String label) => Padding(
  padding: const EdgeInsets.only(bottom: 7),
  child: Text(
    label,
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
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
  ),
);

Widget _detailLine(IconData icon, String label, String value) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 19, color: const Color(0xFF64748B)),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            const SizedBox(height: 3),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ],
  ),
);
