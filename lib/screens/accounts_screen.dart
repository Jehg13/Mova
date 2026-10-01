import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mova/database/database_helper.dart';
import 'package:mova/models/financial_account.dart';
import 'package:mova/services/currency_controller.dart';
import 'package:mova/services/mova_localizations.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final _database = DatabaseHelper();
  late Future<List<FinancialAccount>> _accounts;
  late Future<Map<String, Map<String, double>>> _overview;
  late Future<Map<int?, double>> _savingsByAccount;

  @override
  void initState() {
    super.initState();
    DatabaseHelper.financialDataVersion.addListener(_onFinancialDataChanged);
    _load();
  }

  @override
  void dispose() {
    DatabaseHelper.financialDataVersion.removeListener(_onFinancialDataChanged);
    super.dispose();
  }

  void _onFinancialDataChanged() {
    if (mounted) setState(_load);
  }

  void _load() {
    _accounts = _database.getFinancialAccounts();
    _overview = _database.getFinancialOverview(
      homeCurrency: appCurrencyController.code,
    );
    _savingsByAccount = _database.getUnassignedSavingsByAccount();
  }

  Future<void> _refresh() async {
    setState(_load);
    await Future.wait([_accounts, _overview, _savingsByAccount]);
  }

  Future<void> _openForm([FinancialAccount? account]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FinancialAccountFormScreen(account: account),
      ),
    );
    if (saved == true && mounted) await _refresh();
  }

  Future<void> _openDetail(FinancialAccount account) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FinancialAccountDetailsScreen(account: account),
      ),
    );
    if (changed == true && mounted) await _refresh();
  }

  Future<void> _openTransfer(List<FinancialAccount> accounts) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TransferScreen(accounts: accounts)),
    );
    if (saved == true && mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.text('my_accounts')),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          IconButton(
            tooltip: l10n.text('new_account'),
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<FinancialAccount>>(
        future: _accounts,
        builder: (context, accountSnapshot) {
          if (accountSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (accountSnapshot.hasError) {
            return Center(child: Text(l10n.text('accounts_load_error')));
          }
          final accounts = accountSnapshot.data ?? const <FinancialAccount>[];
          return FutureBuilder<Map<String, Map<String, double>>>(
            future: _overview,
            builder: (context, overviewSnapshot) {
              if (overviewSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (overviewSnapshot.hasError) {
                return Center(child: Text(l10n.text('accounts_load_error')));
              }
              final overview =
                  overviewSnapshot.data ??
                  const <String, Map<String, double>>{};
              final active = accounts.where((item) => item.isActive).toList();
              final assets = overview['assets'] ?? const <String, double>{};
              final debts = _totalsByCurrency(
                active.where(
                  (item) => item.type == FinancialAccountType.creditCard,
                ),
              );
              return FutureBuilder<Map<int?, double>>(
                future: _savingsByAccount,
                builder: (context, savingsSnapshot) {
                  if (savingsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (savingsSnapshot.hasError) {
                    return Center(
                      child: Text(l10n.text('accounts_load_error')),
                    );
                  }
                  final savingsByAccount =
                      savingsSnapshot.data ?? const <int?, double>{};
                  final eligibleForLegacySavings = active
                      .where(
                        (account) =>
                            account.type != FinancialAccountType.creditCard &&
                            account.currency == appCurrencyController.code,
                      )
                      .toList();
                  final unassignedSavings = savingsByAccount[null] ?? 0;
                  final inferSingleAccountSavings =
                      eligibleForLegacySavings.length == 1;
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                      children: [
                        _OverviewCard(
                          title: l10n.text('available_to_spend'),
                          values:
                              overview['available'] ?? const <String, double>{},
                          icon: Icons.account_balance_wallet_outlined,
                          accent: const Color(0xFF0C2340),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _OverviewCard(
                                title: l10n.text('money_in_accounts'),
                                values: assets,
                                icon: Icons.account_balance_outlined,
                                accent: const Color(0xFF606060),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _OverviewCard(
                                title: l10n.text('credit_debt'),
                                values: debts,
                                icon: Icons.credit_card_outlined,
                                accent: const Color(0xFF4D4D4D),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _OverviewCard(
                          title: l10n.text('allocated_savings_and_goals'),
                          values: overview['allocated_savings'] ?? const {},
                          icon: Icons.savings_outlined,
                          accent: const Color(0xFF646464),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.text('my_accounts'),
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: !_canTransfer(active)
                                  ? null
                                  : () => _openTransfer(active),
                              icon: const Icon(
                                Icons.swap_horiz_rounded,
                                size: 18,
                              ),
                              label: Text(l10n.text('transfer')),
                            ),
                          ],
                        ),
                        if (accounts.isEmpty)
                          _EmptyAccountsCard(onCreate: () => _openForm())
                        else
                          ...accounts.map((account) {
                            final linkedSavings =
                                savingsByAccount[account.id] ?? 0;
                            final inferredSavings =
                                inferSingleAccountSavings &&
                                    account.id ==
                                        eligibleForLegacySavings.single.id
                                ? unassignedSavings
                                : 0.0;
                            final allocatedSavings =
                                linkedSavings + inferredSavings;
                            return _AccountCard(
                              account: account,
                              realBalance:
                                  account.balance +
                                  (linkedSavings > 0 ? linkedSavings : 0),
                              allocatedSavings: allocatedSavings,
                              availableBalance:
                                  account.balance - inferredSavings,
                              onTap: () => _openDetail(account),
                            );
                          }),
                        if (unassignedSavings > 0 && !inferSingleAccountSavings)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 12),
                            child: Text(
                              '${l10n.text('unassigned_savings_account_label')}: '
                              '${_money(unassignedSavings, appCurrencyController.code)}',
                              style: const TextStyle(
                                color: Color(0xFF727272),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: () => _openForm(),
                          icon: const Icon(Icons.add),
                          label: Text(l10n.text('new_account')),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0C2340),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.title,
    required this.values,
    required this.icon,
    required this.accent,
  });
  final String title;
  final Map<String, double> values;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE7E7E7)),
    ),
    child: Row(
      children: [
        Icon(icon, color: accent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Color(0xFF727272)),
              ),
              const SizedBox(height: 4),
              if (values.isEmpty)
                const Text('—', style: TextStyle(fontWeight: FontWeight.w800))
              else
                ...values.entries.map(
                  (entry) => Text(
                    _money(entry.value, entry.key),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.realBalance,
    required this.allocatedSavings,
    required this.availableBalance,
    required this.onTap,
  });
  final FinancialAccount account;
  final double realBalance;
  final double allocatedSavings;
  final double availableBalance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final credit = account.type == FinancialAccountType.creditCard;
    final color = account.isActive
        ? const Color(0xFF0C2340)
        : const Color(0xFFA1A1A1);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE7E7E7)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                child: Icon(_accountIcon(account.type), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${context.l10n.text('account_type_${account.type.name}')}'
                      '${account.institution.isEmpty ? '' : ' · ${account.institution}'}',
                      style: const TextStyle(
                        color: Color(0xFF727272),
                        fontSize: 12,
                      ),
                    ),
                    if (!account.isActive)
                      Text(
                        context.l10n.text('inactive'),
                        style: const TextStyle(
                          color: Color(0xFF626262),
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
                  if (!credit && account.isActive && allocatedSavings > 0)
                    Text(
                      context.l10n.text('account_real_balance_label'),
                      style: const TextStyle(
                        color: Color(0xFF727272),
                        fontSize: 10,
                      ),
                    ),
                  Text(
                    _money(realBalance, account.currency),
                    style: TextStyle(
                      color: credit ? const Color(0xFF414141) : color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (!credit && account.isActive && allocatedSavings > 0)
                    Text(
                      '${context.l10n.text('account_available_label')}: '
                      '${_money(availableBalance, account.currency)}',
                      style: const TextStyle(
                        color: Color(0xFF0C2340),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (!credit && account.isActive && allocatedSavings > 0)
                    Text(
                      '${context.l10n.text('account_allocated_label')}: '
                      '${_money(allocatedSavings, account.currency)}',
                      style: const TextStyle(
                        color: Color(0xFF727272),
                        fontSize: 10,
                      ),
                    ),
                  if (credit)
                    Text(
                      '${context.l10n.text('credit_available')}: ${_money(account.availableCredit, account.currency)}',
                      style: const TextStyle(
                        color: Color(0xFF727272),
                        fontSize: 10,
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

class _EmptyAccountsCard extends StatelessWidget {
  const _EmptyAccountsCard({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE7E7E7)),
    ),
    child: Column(
      children: [
        const Icon(Icons.account_balance_wallet_outlined, size: 34),
        const SizedBox(height: 8),
        Text(context.l10n.text('accounts_empty')),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onCreate,
          child: Text(context.l10n.text('new_account')),
        ),
      ],
    ),
  );
}

class FinancialAccountFormScreen extends StatefulWidget {
  const FinancialAccountFormScreen({super.key, this.account});
  final FinancialAccount? account;

  @override
  State<FinancialAccountFormScreen> createState() =>
      _FinancialAccountFormScreenState();
}

class _FinancialAccountFormScreenState
    extends State<FinancialAccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _database = DatabaseHelper();
  late final TextEditingController _name;
  late final TextEditingController _institution;
  late final TextEditingController _lastFour;
  late final TextEditingController _initialBalance;
  late FinancialAccountType _type;
  late String _currency;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    _name = TextEditingController(text: account?.name ?? '');
    _institution = TextEditingController(text: account?.institution ?? '');
    _lastFour = TextEditingController(text: account?.lastFour ?? '');
    _initialBalance = TextEditingController(
      text: account == null ? '0' : _decimal(account.initialBalance),
    );
    _type = account?.type ?? FinancialAccountType.bank;
    _currency = account?.currency ?? appCurrencyController.code;
  }

  @override
  void dispose() {
    _name.dispose();
    _institution.dispose();
    _lastFour.dispose();
    _initialBalance.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final amount = double.parse(
        _initialBalance.text.trim().replaceAll(',', '.'),
      );
      final old = widget.account;
      final account = FinancialAccount(
        id: old?.id ?? 0,
        name: _name.text.trim(),
        type: _type,
        currency: _currency,
        initialBalance: amount,
        institution: _institution.text.trim(),
        lastFour: _lastFour.text.trim(),
        icon: _accountIconName(_type),
        isActive: old?.isActive ?? true,
        creditLimit: _type == FinancialAccountType.creditCard
            ? old?.creditLimit
            : null,
        createdAt: old?.createdAt ?? DateTime.now(),
      );
      if (old == null) {
        await _database.createFinancialAccount(account);
      } else {
        await _database.updateFinancialAccount(account);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.l10n.text('save_error')}: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final credit = _type == FinancialAccountType.creditCard;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.text(widget.account == null ? 'new_account' : 'edit_account'),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          children: [
            _label(l10n.text('account_name')),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: _decoration(l10n.text('account_name_hint')),
              validator: (value) => value == null || value.trim().isEmpty
                  ? l10n.text('required_field')
                  : null,
            ),
            const SizedBox(height: 15),
            _label(l10n.text('account_type')),
            if (_type == FinancialAccountType.cash)
              InputDecorator(
                decoration: _decoration(l10n.text('account_type')),
                child: Text(l10n.text('account_type_cash')),
              )
            else
              DropdownButtonFormField<FinancialAccountType>(
                initialValue: _type,
                decoration: _decoration(l10n.text('account_type')),
                items: FinancialAccountType.values
                    .where((type) => type != FinancialAccountType.cash)
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(l10n.text('account_type_${type.name}')),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _type = value);
                },
              ),
            const SizedBox(height: 15),
            _label(l10n.text('currency')),
            DropdownButtonFormField<String>(
              initialValue: _currency,
              decoration: _decoration(l10n.text('currency')),
              items: movaCurrencies
                  .map(
                    (currency) => DropdownMenuItem(
                      value: currency.code,
                      child: Text('${currency.code} · ${currency.name}'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _currency = value);
              },
            ),
            const SizedBox(height: 15),
            if (!credit) ...[
              _label(l10n.text('initial_balance')),
              TextFormField(
                controller: _initialBalance,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: _decoration('0.00'),
                validator: (value) {
                  final number = double.tryParse(
                    (value ?? '').replaceAll(',', '.'),
                  );
                  if (number == null || number < 0) {
                    return l10n.text('invalid_initial_balance');
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 15),
            _label(l10n.text('institution_optional')),
            TextFormField(
              controller: _institution,
              decoration: _decoration(l10n.text('institution_hint')),
            ),
            const SizedBox(height: 15),
            _label(l10n.text('last_four_optional')),
            TextFormField(
              controller: _lastFour,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _decoration('4582'),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0C2340),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(l10n.text('save_account')),
            ),
          ],
        ),
      ),
    );
  }
}

class FinancialAccountDetailsScreen extends StatefulWidget {
  const FinancialAccountDetailsScreen({super.key, required this.account});
  final FinancialAccount account;

  @override
  State<FinancialAccountDetailsScreen> createState() =>
      _FinancialAccountDetailsScreenState();
}

class _FinancialAccountDetailsScreenState
    extends State<FinancialAccountDetailsScreen> {
  final _database = DatabaseHelper();
  late Future<FinancialAccount?> _account;
  late Future<List<Map<String, Object?>>> _activity;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _account = _database.getFinancialAccount(widget.account.id);
    _activity = _database.getFinancialAccountActivity(widget.account.id);
  }

  Future<void> _refresh() async {
    setState(_load);
    await Future.wait([_account, _activity]);
  }

  Future<void> _edit() async {
    final account = await _account;
    if (!mounted || account == null) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FinancialAccountFormScreen(account: account),
      ),
    );
    if (saved == true && mounted) {
      await _refresh();
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  Future<void> _toggleActive(FinancialAccount account) async {
    try {
      await _database.setFinancialAccountActive(account.id, !account.isActive);
      if (mounted) {
        await _refresh();
        if (!mounted) return;
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.l10n.text('save_error')}: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.account.name),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          IconButton(
            tooltip: l10n.text('edit_account'),
            onPressed: _edit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: FutureBuilder<FinancialAccount?>(
        future: _account,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final account = snapshot.data;
          if (account == null) {
            return Center(child: Text(l10n.text('account_not_found')));
          }
          final credit = account.type == FinancialAccountType.creditCard;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE7E7E7)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.text('account_type_${account.type.name}'),
                        style: const TextStyle(color: Color(0xFF727272)),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _money(account.balance, account.currency),
                        style: TextStyle(
                          color: credit
                              ? const Color(0xFF414141)
                              : const Color(0xFF0C2340),
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (credit) ...[
                        const SizedBox(height: 5),
                        Text(
                          '${l10n.text('credit_available')}: ${_money(account.availableCredit, account.currency)} / ${_money(account.creditLimit ?? 0, account.currency)}',
                          style: const TextStyle(color: Color(0xFF727272)),
                        ),
                      ],
                      const Divider(height: 24),
                      if (account.institution.isNotEmpty)
                        _detail(l10n.text('institution'), account.institution),
                      if (account.lastFour.isNotEmpty)
                        _detail(
                          l10n.text('last_four'),
                          '•••• ${account.lastFour}',
                        ),
                      _detail(l10n.text('currency'), account.currency),
                      _detail(
                        l10n.text('status'),
                        l10n.text(account.isActive ? 'active' : 'inactive'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _toggleActive(account),
                  icon: Icon(
                    account.isActive
                        ? Icons.pause_circle_outline
                        : Icons.check_circle_outline,
                  ),
                  label: Text(
                    l10n.text(
                      account.isActive ? 'deactivate_account' : 'reactivate',
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.text('account_activity'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<Map<String, Object?>>>(
                  future: _activity,
                  builder: (context, activitySnapshot) {
                    if (activitySnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (activitySnapshot.hasError) {
                      return Text(l10n.text('activity_load_error'));
                    }
                    final items =
                        activitySnapshot.data ?? const <Map<String, Object?>>[];
                    if (items.isEmpty) {
                      return Text(l10n.text('no_account_activity'));
                    }
                    return Column(
                      children: items.map((item) {
                        final transfer = item['activity_type'] == 'transfer';
                        final isOutflow = transfer
                            ? item['from_account_id'] == account.id
                            : item['is_income'] != 1;
                        final title = transfer
                            ? '${l10n.text('transfer')}: ${item['from_name']} → ${item['to_name']}'
                            : item['description'] as String;
                        return Card(
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: Color(0xFFE7E7E7)),
                          ),
                          child: ListTile(
                            leading: Icon(
                              transfer
                                  ? Icons.swap_horiz_rounded
                                  : isOutflow
                                  ? Icons.south_west_rounded
                                  : Icons.arrow_outward_rounded,
                              color: isOutflow
                                  ? const Color(0xFF4D4D4D)
                                  : const Color(0xFF646464),
                            ),
                            title: Text(title),
                            subtitle: Text(
                              _dateLabel(item['date'] as String? ?? ''),
                            ),
                            trailing: Text(
                              '${isOutflow ? '−' : '+'}${_money(item['amount'] as num, account.currency)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
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
        },
      ),
    );
  }
}

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key, required this.accounts});
  final List<FinancialAccount> accounts;

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _database = DatabaseHelper();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  late FinancialAccount _from;
  FinancialAccount? _to;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final sources = widget.accounts
        .where((account) => account.type != FinancialAccountType.creditCard)
        .toList();
    _from = sources.first;
    _to = widget.accounts.cast<FinancialAccount?>().firstWhere(
      (account) =>
          account!.id != _from.id && account.currency == _from.currency,
      orElse: () => null,
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final destination = _to;
    if (destination == null) return;
    setState(() => _saving = true);
    try {
      await _database.transferBetweenAccounts(
        fromAccountId: _from.id,
        toAccountId: destination.id,
        amount: double.parse(_amount.text.replaceAll(',', '.')),
        date: _date,
        description: _description.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.l10n.text('save_error')}: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sourceAccounts = widget.accounts
        .where((account) => account.type != FinancialAccountType.creditCard)
        .toList();
    final destinations = widget.accounts
        .where(
          (account) =>
              account.id != _from.id && account.currency == _from.currency,
        )
        .toList();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.text('transfer_money')),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _label(l10n.text('source_account')),
            DropdownButtonFormField<FinancialAccount>(
              initialValue: _from,
              decoration: _decoration(l10n.text('source_account')),
              items: sourceAccounts
                  .map(
                    (account) => DropdownMenuItem(
                      value: account,
                      child: Text(
                        '${account.name} · ${_money(account.balance, account.currency)}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _from = value;
                  if (_to?.id == value.id || _to?.currency != value.currency) {
                    _to = null;
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            _label(l10n.text('destination_account')),
            DropdownButtonFormField<FinancialAccount>(
              initialValue: destinations.contains(_to) ? _to : null,
              decoration: _decoration(l10n.text('destination_account')),
              items: destinations
                  .map(
                    (account) => DropdownMenuItem(
                      value: account,
                      child: Text(
                        '${account.name} · ${l10n.text('account_type_${account.type.name}')}',
                      ),
                    ),
                  )
                  .toList(),
              validator: (value) =>
                  value == null ? l10n.text('required_field') : null,
              onChanged: (value) => setState(() => _to = value),
            ),
            const SizedBox(height: 16),
            _label(l10n.text('amount')),
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: _decoration(_from.currency),
              validator: (value) {
                final amount = double.tryParse(
                  (value ?? '').replaceAll(',', '.'),
                );
                return amount == null || amount <= 0
                    ? l10n.text('amount_must_be_positive')
                    : null;
              },
            ),
            const SizedBox(height: 16),
            _label(l10n.text('date')),
            OutlinedButton.icon(
              onPressed: () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (selected != null) setState(() => _date = selected);
              },
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(_dateLabel(_date.toIso8601String())),
            ),
            const SizedBox(height: 16),
            _label(l10n.text('description_optional')),
            TextFormField(
              controller: _description,
              decoration: _decoration(l10n.text('description_optional')),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0C2340),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(l10n.text('transfer_money')),
            ),
          ],
        ),
      ),
    );
  }
}

Map<String, double> _totalsByCurrency(Iterable<FinancialAccount> accounts) {
  final totals = <String, double>{};
  for (final account in accounts) {
    totals.update(
      account.currency,
      (value) => value + account.balance,
      ifAbsent: () => account.balance,
    );
  }
  return totals;
}

bool _canTransfer(List<FinancialAccount> accounts) {
  return accounts.any(
    (source) =>
        source.type != FinancialAccountType.creditCard &&
        accounts.any(
          (destination) =>
              destination.id != source.id &&
              destination.currency == source.currency,
        ),
  );
}

IconData _accountIcon(FinancialAccountType type) => switch (type) {
  FinancialAccountType.cash => Icons.payments_outlined,
  FinancialAccountType.bank => Icons.account_balance_outlined,
  FinancialAccountType.debitCard => Icons.credit_card_outlined,
  FinancialAccountType.creditCard => Icons.credit_card_rounded,
  FinancialAccountType.savings => Icons.savings_outlined,
};

String _accountIconName(FinancialAccountType type) => switch (type) {
  FinancialAccountType.cash => 'payments',
  FinancialAccountType.bank => 'account_balance',
  FinancialAccountType.debitCard => 'credit_card',
  FinancialAccountType.creditCard => 'credit_card',
  FinancialAccountType.savings => 'savings',
};

String _money(num amount, String currency) {
  final definition = movaCurrencies.firstWhere(
    (item) => item.code == currency,
    orElse: () => movaCurrencies.first,
  );
  return '${definition.symbol}${amount.toStringAsFixed(2)} ${definition.code}';
}

String _decimal(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();

String _dateLabel(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  return '${date.day}/${date.month}/${date.year}';
}

Widget _label(String value) => Padding(
  padding: const EdgeInsets.only(bottom: 7),
  child: Text(
    value,
    style: const TextStyle(
      color: Color(0xFF3F3F3F),
      fontSize: 13,
      fontWeight: FontWeight.w700,
    ),
  ),
);

InputDecoration _decoration(String hint) => InputDecoration(
  hintText: hint,
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFE7E7E7)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFE7E7E7)),
  ),
);

Widget _detail(String label, String value) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Row(
    children: [
      Expanded(
        child: Text(label, style: const TextStyle(color: Color(0xFF727272))),
      ),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    ],
  ),
);
