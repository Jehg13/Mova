import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mova/models/financial_account.dart';
import 'package:mova/services/currency_controller.dart';
import 'package:mova/database/database_helper.dart';
import 'package:mova/screens/accounts_screen.dart';
import 'package:mova/services/goal_image_picker.dart';
import 'package:mova/models/shared_goal.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mova/widgets/mova_feedback_dialog.dart';
import 'package:mova/services/mova_localizations.dart';
import 'package:mova/widgets/mova_design_system.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _database = DatabaseHelper();
  late Future<List<Map<String, dynamic>>> _goals;

  @override
  void initState() {
    super.initState();
    DatabaseHelper.financialDataVersion.addListener(_refreshGoals);
    _loadGoals();
  }

  @override
  void dispose() {
    DatabaseHelper.financialDataVersion.removeListener(_refreshGoals);
    super.dispose();
  }

  void _refreshGoals() {
    if (mounted) setState(_loadGoals);
  }

  void _loadGoals() {
    _goals = _database.getGoals();
  }

  Future<void> _newGoal() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const _CreateGoalDialog(),
    );
    if (created == true && mounted) setState(_loadGoals);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _goals,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  movaText(
                    'No se pudieron cargar las metas: ${snapshot.error}',
                  ),
                ),
              );
            }
            final goals = snapshot.data ?? <Map<String, dynamic>>[];
            final saved = goals.fold<double>(
              0,
              (sum, goal) => sum + (goal['saved_amount'] as num).toDouble(),
            );
            final target = goals.fold<double>(
              0,
              (sum, goal) => sum + (goal['target_amount'] as num).toDouble(),
            );
            return RefreshIndicator(
              onRefresh: () async {
                setState(_loadGoals);
                await _goals;
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
                children: [
                  Text(
                    l10n.text('my_goals'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.text('goals_subtitle'),
                    style: TextStyle(fontSize: 14, color: Color(0xFF727272)),
                  ),
                  const SizedBox(height: 20),
                  _SummaryCard(
                    saved: saved,
                    target: target,
                    count: goals.length,
                  ),
                  const SizedBox(height: 20),
                  const _GoalAccountsCard(),
                  const SizedBox(height: 20),
                  _UnassignedSavingsCard(onChanged: () => setState(_loadGoals)),
                  const SizedBox(height: 20),
                  if (goals.isEmpty)
                    const _NoGoalsCard()
                  else
                    ...goals.map(
                      (goal) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _GoalCard(
                          goal: goal,
                          onChanged: () => setState(_loadGoals),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newGoal,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          l10n.text('new_goal'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _GoalAccountsCard extends StatefulWidget {
  const _GoalAccountsCard();

  @override
  State<_GoalAccountsCard> createState() => _GoalAccountsCardState();
}

class _GoalAccountsCardState extends State<_GoalAccountsCard> {
  final _database = DatabaseHelper();
  late Future<List<FinancialAccount>> _accounts;
  late Future<Map<int?, double>> _savingsByAccount;

  @override
  void initState() {
    super.initState();
    DatabaseHelper.financialDataVersion.addListener(_refreshAccounts);
    _loadAccounts();
  }

  @override
  void dispose() {
    DatabaseHelper.financialDataVersion.removeListener(_refreshAccounts);
    super.dispose();
  }

  void _loadAccounts() {
    _accounts = _database.getFinancialAccounts(includeInactive: false);
    _savingsByAccount = _database.getUnassignedSavingsByAccount();
  }

  void _refreshAccounts() {
    if (mounted) setState(_loadAccounts);
  }

  Future<void> _transfer(List<FinancialAccount> accounts) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TransferScreen(accounts: accounts)),
    );
    if (changed == true && mounted) setState(_loadAccounts);
  }

  Future<void> _openAccounts() async {
    await Navigator.of(context)
        .push<void>(MaterialPageRoute(builder: (_) => const AccountsScreen()));
    if (mounted) setState(_loadAccounts);
  }

  String _money(double amount, String currency) {
    final definition = movaCurrencies.firstWhere(
      (item) => item.code == currency,
      orElse: () => movaCurrencies.first,
    );
    return '${definition.symbol}${amount.toStringAsFixed(2)} ${definition.code}';
  }

  bool _canTransfer(List<FinancialAccount> accounts) => accounts.any(
    (source) =>
        source.type != FinancialAccountType.creditCard &&
        accounts.any(
          (destination) =>
              destination.id != source.id &&
              destination.currency == source.currency,
        ),
  );

  IconData _icon(FinancialAccountType type) => switch (type) {
    FinancialAccountType.cash => Icons.payments_outlined,
    FinancialAccountType.bank => Icons.account_balance_outlined,
    FinancialAccountType.debitCard => Icons.credit_card_outlined,
    FinancialAccountType.creditCard => Icons.credit_card_rounded,
    FinancialAccountType.savings => Icons.savings_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<List<FinancialAccount>>(
      future: _accounts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.text('accounts_load_error')),
            ),
          );
        }

        final accounts = snapshot.data ?? const <FinancialAccount>[];
        return FutureBuilder<Map<int?, double>>(
          future: _savingsByAccount,
          builder: (context, savingsSnapshot) {
            if (savingsSnapshot.connectionState == ConnectionState.waiting) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              );
            }
            if (savingsSnapshot.hasError) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.text('accounts_load_error')),
                ),
              );
            }
            final savingsByAccount =
                savingsSnapshot.data ?? const <int?, double>{};
            final eligibleForLegacySavings = accounts
                .where(
                  (account) =>
                      account.type != FinancialAccountType.creditCard &&
                      account.currency == appCurrencyController.code,
                )
                .toList();
            final unassignedSavings = savingsByAccount[null] ?? 0;
            final inferSingleAccountSavings =
                eligibleForLegacySavings.length == 1;
            return Card(
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF0F7),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Color(0xFF0C2340),
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.text('money_by_account'),
                                style: const TextStyle(
                                  color: Color(0xFF0C2340),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.text('money_by_account_hint'),
                                style: const TextStyle(
                                  color: Color(0xFF667085),
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (accounts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(
                          l10n.text('accounts_empty'),
                          style: const TextStyle(
                            color: Color(0xFF667085),
                            fontSize: 13,
                          ),
                        ),
                      )
                    else
                      ...accounts.map(
                        (account) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color:
                                      account.type ==
                                          FinancialAccountType.creditCard
                                      ? const Color(0xFFF1F3F6)
                                      : const Color(0xFFF5F8FB),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Icon(
                                  _icon(account.type),
                                  color: const Color(0xFF0C2340),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      account.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF182230),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      l10n.text(
                                        'account_type_${account.type.name}',
                                      ),
                                      style: const TextStyle(
                                        color: Color(0xFF667085),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Builder(
                                builder: (context) {
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
                                  final realBalance =
                                      account.balance +
                                      (linkedSavings > 0 ? linkedSavings : 0);
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (allocatedSavings > 0 &&
                                          account.type !=
                                              FinancialAccountType.creditCard)
                                        Text(
                                          l10n.text(
                                            'account_real_balance_label',
                                          ),
                                          style: const TextStyle(
                                            color: Color(0xFF667085),
                                            fontSize: 9,
                                          ),
                                        ),
                                      Text(
                                        _money(realBalance, account.currency),
                                        textAlign: TextAlign.end,
                                        style: TextStyle(
                                          color:
                                              account.type ==
                                                  FinancialAccountType
                                                      .creditCard
                                              ? const Color(0xFF667085)
                                              : const Color(0xFF0C2340),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      if (allocatedSavings > 0 &&
                                          account.type !=
                                              FinancialAccountType
                                                  .creditCard) ...[
                                        Text(
                                          '${l10n.text('account_available_label')}: '
                                          '${_money(account.balance - inferredSavings, account.currency)}',
                                          style: const TextStyle(
                                            color: Color(0xFF0C2340),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          '${l10n.text('account_allocated_label')}: '
                                          '${_money(allocatedSavings, account.currency)}',
                                          style: const TextStyle(
                                            color: Color(0xFF667085),
                                            fontSize: 9,
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (accounts.any(
                      (account) =>
                          account.type == FinancialAccountType.creditCard,
                    ))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          l10n.text('credit_card_transfer_note'),
                          style: const TextStyle(
                            color: Color(0xFF667085),
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ),
                    if (unassignedSavings > 0 && !inferSingleAccountSavings)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          '${l10n.text('unassigned_savings_account_label')}: '
                          '${_money(unassignedSavings, appCurrencyController.code)}',
                          style: const TextStyle(
                            color: Color(0xFF667085),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _canTransfer(accounts)
                            ? () => _transfer(accounts)
                            : _openAccounts,
                        icon: Icon(
                          _canTransfer(accounts)
                              ? Icons.swap_horiz_rounded
                              : Icons.add_card_outlined,
                          size: 19,
                        ),
                        label: Text(
                          _canTransfer(accounts)
                              ? l10n.text('transfer_money')
                              : l10n.text('manage_accounts'),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0C2340),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _UnassignedSavingsCard extends StatefulWidget {
  final VoidCallback onChanged;

  const _UnassignedSavingsCard({required this.onChanged});

  @override
  State<_UnassignedSavingsCard> createState() => _UnassignedSavingsCardState();
}

class _UnassignedSavingsCardState extends State<_UnassignedSavingsCard> {
  final _database = DatabaseHelper();
  late Future<double> _balance;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _balance = _database.getUnassignedSavings();
  }

  Future<void> _openAmountDialog({required bool withdraw}) async {
    if (_saving) return;
    final result = await showDialog<({double amount, int accountId})>(
      context: context,
      builder: (_) =>
          _SavingsAmountDialog(withdraw: withdraw, currentSavings: _balance),
    );
    if (result == null || !mounted) return;
    setState(() => _saving = true);
    try {
      if (withdraw) {
        await _database.withdrawUnassignedSavings(
          result.amount,
          accountId: result.accountId,
        );
      } else {
        await _database.moveToUnassignedSavings(
          result.amount,
          accountId: result.accountId,
        );
      }
      if (!mounted) return;
      final updatedBalance = await _database.getUnassignedSavings();
      if (!mounted) return;
      setState(() {
        _balance = Future.value(updatedBalance);
        _saving = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onChanged();
      });
      await showMovaSuccess(
        context,
        withdraw
            ? movaText('Ahorro retirado correctamente.')
            : movaText('Ahorro agregado correctamente.'),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      await showMovaError(
        context,
        error.toString().replaceFirst('Bad state: ', ''),
        title: movaText('No se pudo actualizar el ahorro'),
      );
    } finally {
      if (mounted && _saving) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: _balance,
      builder: (context, snapshot) {
        final balance = snapshot.data ?? 0;
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1F3A), Color(0xFF172B45)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: .12)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B1F3A).withValues(alpha: .16),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned(
                  right: -52,
                  top: -78,
                  child: IgnorePointer(
                    child: Container(
                      width: 210,
                      height: 210,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: .11),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .14),
                              ),
                            ),
                            child: const Icon(
                              Icons.savings_outlined,
                              color: Colors.white,
                              size: 23,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  movaText('Ahorro libre'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  movaText(
                                    'Ahorra sin tener una meta específica',
                                  ),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: .68),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 21),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Text(
                          appCurrencyController.format(balance),
                          key: ValueKey(balance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 31,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.7,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _saving
                                  ? null
                                  : () => _openAmountDialog(withdraw: false),
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: MovaDesign.navy,
                                      ),
                                    )
                                  : const Icon(Icons.add_rounded, size: 19),
                              label: Text(movaText('Agregar')),
                              style: FilledButton.styleFrom(
                                foregroundColor: MovaDesign.navy,
                                backgroundColor: Colors.white,
                                disabledForegroundColor: MovaDesign.navy
                                    .withValues(alpha: .55),
                                disabledBackgroundColor: Colors.white
                                    .withValues(alpha: .75),
                                minimumSize: const Size(0, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: !_saving && balance > 0
                                  ? () => _openAmountDialog(withdraw: true)
                                  : null,
                              icon: const Icon(
                                Icons.south_west_rounded,
                                size: 18,
                              ),
                              label: Text(movaText('Retirar')),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                disabledForegroundColor: Colors.white
                                    .withValues(alpha: .42),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: .42),
                                ),
                                minimumSize: const Size(0, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SavingsAmountDialog extends StatefulWidget {
  final bool withdraw;
  final Future<double> currentSavings;

  const _SavingsAmountDialog({
    required this.withdraw,
    required this.currentSavings,
  });

  @override
  State<_SavingsAmountDialog> createState() => _SavingsAmountDialogState();
}

class _SavingsAmountDialogState extends State<_SavingsAmountDialog> {
  final _controller = TextEditingController();
  final _database = DatabaseHelper();
  String? _error;
  late Future<List<FinancialAccount>> _accounts;
  int? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    _accounts = _database.getFinancialAccounts(includeInactive: false).then((
      accounts,
    ) {
      final eligibleAccounts = accounts
          .where(
            (account) =>
                account.type != FinancialAccountType.creditCard &&
                account.currency == appCurrencyController.code,
          )
          .toList();
      if (eligibleAccounts.isNotEmpty) {
        _selectedAccountId = eligibleAccounts.first.id;
      }
      return eligibleAccounts;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = double.tryParse(_controller.text.trim().replaceAll(',', '.'));
    if (value == null || value <= 0) {
      setState(() => _error = movaText('Escribe una cantidad mayor a cero.'));
      return;
    }
    final accountId = _selectedAccountId;
    if (accountId == null) {
      setState(() => _error = movaText('Selecciona una cuenta.'));
      return;
    }
    Navigator.of(context).pop((amount: value, accountId: accountId));
  }

  @override
  Widget build(BuildContext context) {
    final symbol = appCurrencyController.definition.symbol;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDEDED),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      widget.withdraw
                          ? Icons.remove_rounded
                          : Icons.savings_outlined,
                      color: const Color(0xFF0C2340),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.withdraw
                          ? movaText('Retirar ahorro libre')
                          : movaText('Agregar ahorro libre'),
                      style: const TextStyle(
                        color: Color(0xFF102A43),
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.withdraw
                    ? movaText(
                        'Elige cuánto deseas retirar y a qué cuenta devolverlo.',
                      )
                    : movaText(
                        'Elige de qué cuenta apartar el dinero, sin asociarlo a una meta.',
                      ),
                style: const TextStyle(color: Color(0xFF727272), height: 1.35),
              ),
              const SizedBox(height: 16),
              FutureBuilder<double>(
                future: widget.currentSavings,
                builder: (context, snapshot) {
                  final savings = snapshot.data ?? 0;
                  return FutureBuilder<List<FinancialAccount>>(
                    future: _accounts,
                    builder: (context, accountsSnapshot) {
                      final accounts = accountsSnapshot.data ?? const [];
                      FinancialAccount? selectedAccount;
                      for (final account in accounts) {
                        if (account.id == _selectedAccountId) {
                          selectedAccount = account;
                          break;
                        }
                      }
                      return Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F4F4),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _SavingsInfo(
                                    label: movaText('Ahorrado'),
                                    value: appCurrencyController.format(
                                      savings,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: _SavingsInfo(
                                    label: widget.withdraw
                                        ? movaText('saving_destination_label')
                                        : movaText('saving_source_label'),
                                    value: appCurrencyController.format(
                                      selectedAccount?.balance ?? 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (accountsSnapshot.connectionState ==
                              ConnectionState.waiting)
                            const LinearProgressIndicator()
                          else if (accounts.isEmpty)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                movaText(
                                  'No hay cuentas activas en la moneda principal.',
                                ),
                                style: const TextStyle(
                                  color: Color(0xFFB42318),
                                ),
                              ),
                            )
                          else
                            DropdownButtonFormField<int>(
                              initialValue: selectedAccount?.id,
                              decoration: InputDecoration(
                                labelText: movaText(
                                  widget.withdraw
                                      ? 'saving_destination_label'
                                      : 'saving_source_label',
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              items: accounts
                                  .map(
                                    (account) => DropdownMenuItem(
                                      value: account.id,
                                      child: Text(account.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _selectedAccountId = value),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: movaText('Cantidad'),
                  prefixText: '$symbol ',
                  hintText: movaText('0.00'),
                  errorText: _error,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFDFDFDF)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFDFDFDF)),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(movaText('Cancelar')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      child: Text(
                        widget.withdraw
                            ? movaText('Retirar')
                            : movaText('Guardar'),
                      ),
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

class _SavingsInfo extends StatelessWidget {
  final String label;
  final String value;

  const _SavingsInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          movaText(label),
          style: const TextStyle(color: Color(0xFF727272), fontSize: 12),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF102A43),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CreateGoalDialog extends StatefulWidget {
  const _CreateGoalDialog();

  @override
  State<_CreateGoalDialog> createState() => _CreateGoalDialogState();
}

class _CreateGoalDialogState extends State<_CreateGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _target = TextEditingController();
  final _initialSaved = TextEditingController();
  final _database = DatabaseHelper();
  Uint8List? _image;
  String _icon = 'flag';
  bool _saving = false;

  static const icons = <String, IconData>{
    'flag': Icons.flag_outlined,
    'none': Icons.not_interested_outlined,
    'home': Icons.home_outlined,
    'car': Icons.directions_car_outlined,
    'travel': Icons.flight_takeoff_outlined,
    'laptop': Icons.laptop_outlined,
    'education': Icons.school_outlined,
    'health': Icons.favorite_border,
    'gift': Icons.card_giftcard_outlined,
    'savings': Icons.savings_outlined,
  };

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _initialSaved.dispose();
    super.dispose();
  }

  Future<void> _selectImage() async {
    try {
      final bytes = await pickGoalImage();
      if (mounted && bytes != null) setState(() => _image = bytes);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            movaText('No se pudo abrir el selector de imágenes: $error'),
          ),
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final target = _number(_target.text);
    final saved = _number(_initialSaved.text);
    if (saved > target) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(movaText('El ahorro inicial no puede superar la meta')),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _database.insertGoal(
        name: _name.text.trim(),
        targetAmount: target,
        savedAmount: saved,
        icon: _icon,
        image: _image,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(movaText('No se pudo crear la meta: $error'))),
      );
    }
  }

  double _number(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    return normalized.isEmpty ? 0 : double.parse(normalized);
  }

  String? _validateAmount(String? value, {bool optional = false}) {
    if (optional && (value == null || value.trim().isEmpty)) return null;
    final number = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    return number == null || number <= 0
        ? movaText('Ingresa un monto mayor que cero')
        : null;
  }

  InputDecoration _decoration(
    String label,
    String hint,
    IconData icon, {
    String? prefix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefix,
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFFA1A1A1)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFE7E7E7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFE7E7E7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF0C2340), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 22),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.flag_outlined,
                        color: Color(0xFF0C2340),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movaText('Crear nueva meta'),
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF102A43),
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            movaText('Dale un propósito a tu ahorro'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF727272),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      color: const Color(0xFF727272),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _imagePicker(),
                const SizedBox(height: 21),
                Text(
                  movaText('Información de la meta'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  decoration: _decoration(
                    'Nombre de la meta',
                    'Ej. Viaje, laptop o fondo de emergencia',
                    Icons.edit_outlined,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Escribe un nombre'
                      : null,
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _target,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _decoration(
                          movaText('Monto objetivo'),
                          '0.00',
                          Icons.track_changes_outlined,
                          prefix: '\$ ',
                        ),
                        validator: _validateAmount,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _initialSaved,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _decoration(
                          movaText('Ahorro inicial'),
                          'Opcional',
                          Icons.savings_outlined,
                          prefix: '\$ ',
                        ),
                        validator: (value) =>
                            _validateAmount(value, optional: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  movaText('Elige un icono'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: icons.entries.map((entry) {
                    final selected = entry.key == _icon;
                    return InkWell(
                      onTap: () => setState(() => _icon = entry.key),
                      borderRadius: BorderRadius.circular(13),
                      child: Tooltip(
                        message: entry.key == 'none' ? 'Sin icono' : entry.key,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF0C2340)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF0C2340)
                                  : const Color(0xFFE7E7E7),
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Icon(
                            entry.value,
                            size: 21,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF727272),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
                Semantics(
                  button: true,
                  label: movaText('Sin icono'),
                  selected: _icon == 'none',
                  child: InkWell(
                    onTap: () => setState(() => _icon = 'none'),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 5,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _icon == 'none'
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 18,
                            color: _icon == 'none'
                                ? const Color(0xFF0C2340)
                                : const Color(0xFF727272),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            movaText('Sin icono'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _icon == 'none'
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: _icon == 'none'
                                  ? const Color(0xFF0C2340)
                                  : const Color(0xFF535353),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          side: const BorderSide(color: Color(0xFFDDDDDD)),
                        ),
                        child: Text(
                          movaText('Cancelar'),
                          style: TextStyle(color: Color(0xFF535353)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0C2340),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                movaText('Crear meta'),
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePicker() {
    return InkWell(
      onTap: _selectImage,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        height: 142,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD6D6D6), width: 1.2),
        ),
        child: _image == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    color: Color(0xFF0C2340),
                    size: 38,
                  ),
                  SizedBox(height: 8),
                  Text(
                    movaText('Agregar imagen'),
                    style: TextStyle(
                      color: Color(0xFF0C2340),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    movaText('Opcional · JPG, PNG o WebP'),
                    style: TextStyle(fontSize: 11, color: Color(0xFF727272)),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(19),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(_image!, fit: BoxFit.cover),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: IconButton.filled(
                        onPressed: () => setState(() => _image = null),
                        icon: const Icon(Icons.close, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF3F3F3F),
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

class _SummaryCard extends StatelessWidget {
  final double saved;
  final double target;
  final int count;

  const _SummaryCard({
    required this.saved,
    required this.target,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target <= 0 ? 0.0 : (saved / target).clamp(0.0, 1.0);
    return MovaSurface(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      elevation: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movaText('RESUMEN DE AHORRO'),
                      style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 1,
                        color: MovaDesign.muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      movaText('Tu avance acumulado'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: MovaDesign.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: MovaDesign.navy,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: MovaDesign.navy.withValues(alpha: .18),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.savings_rounded,
                  size: 21,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            appCurrencyController.format(saved),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -.7,
              color: MovaDesign.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${movaText('de')} ${appCurrencyController.format(target)} ${movaText('establecidos')}',
            style: const TextStyle(fontSize: 12, color: MovaDesign.muted),
          ),
          const SizedBox(height: 14),
          MovaProgressBar(value: progress, height: 8),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: MovaDesign.softBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(progress * 100).round()}% ${movaText('completado')}',
                  style: const TextStyle(
                    color: MovaDesign.navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                movaText(
                  '$count ${count == 1 ? 'meta activa' : 'metas activas'}',
                ),
                style: const TextStyle(fontSize: 12, color: MovaDesign.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditGoalSavingsDialog extends StatefulWidget {
  final Map<String, dynamic> goal;

  const _EditGoalSavingsDialog({required this.goal});

  @override
  State<_EditGoalSavingsDialog> createState() => _EditGoalSavingsDialogState();
}

class _EditGoalSavingsDialogState extends State<_EditGoalSavingsDialog> {
  final _database = DatabaseHelper();
  late final TextEditingController _amount;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: (widget.goal['saved_amount'] as num).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = double.tryParse(_amount.text.trim().replaceAll(',', '.'));
    final target = (widget.goal['target_amount'] as num).toDouble();
    if (value == null || value < 0 || value > target) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            movaText(
              'Ingresa un valor entre ${appCurrencyController.format(0)} y ${appCurrencyController.format(target)}',
            ),
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _database.updateGoalSavedAmount(widget.goal['id'] as int, value);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(movaText('No se pudo actualizar el ahorro: $error')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(movaText('Modificar ahorro')),
      content: TextField(
        controller: _amount,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: movaText('Cantidad ahorrada'),
          prefixText: '\$ ',
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(movaText('Cancelar')),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(movaText('Guardar')),
        ),
      ],
    );
  }
}

class _NoGoalsCard extends StatelessWidget {
  const _NoGoalsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7E7E7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0C2340),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.flag_outlined, size: 42, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            context.l10n.text('no_goals_yet'),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            context.l10n.text('create_goal_savings'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _WithdrawGoalDialog extends StatefulWidget {
  final Map<String, dynamic> goal;

  const _WithdrawGoalDialog({required this.goal});

  @override
  State<_WithdrawGoalDialog> createState() => _WithdrawGoalDialogState();
}

class _WithdrawGoalDialogState extends State<_WithdrawGoalDialog> {
  final _database = DatabaseHelper();
  final _amount = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _withdraw() async {
    final current = (widget.goal['saved_amount'] as num).toDouble();
    final amount = double.tryParse(_amount.text.trim().replaceAll(',', '.'));
    if (amount == null || amount <= 0 || amount > current) {
      setState(
        () => _error =
            'Ingresa un monto entre ${appCurrencyController.format(0.01)} y ${appCurrencyController.format(current)}.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _database.updateGoalSavedAmount(
        widget.goal['id'] as int,
        current - amount,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      setState(
        () => _error = 'No se pudo retirar el dinero. Intenta nuevamente.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = (widget.goal['saved_amount'] as num).toDouble();
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 18, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.south_west_rounded,
              color: Color(0xFF414141),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              movaText('Retirar de la meta'),
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              movaText(
                'Devuelve una parte de lo ahorrado a tu dinero disponible.',
              ),
              style: TextStyle(color: Color(0xFF727272), height: 1.35),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE7E7E7)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Color(0xFF6A6A6A),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      movaText('Disponible en la meta'),
                      style: TextStyle(color: Color(0xFF727272), fontSize: 12),
                    ),
                  ),
                  Text(
                    appCurrencyController.format(current),
                    style: const TextStyle(
                      color: Color(0xFF102A43),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _withdraw(),
              decoration: InputDecoration(
                labelText: movaText('Monto a retirar'),
                prefixText: '${appCurrencyController.definition.symbol} ',
                hintText: movaText('0.00'),
                errorText: _error,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFDFDFDF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFDFDFDF)),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(movaText('Cancelar')),
        ),
        FilledButton(
          onPressed: _saving ? null : _withdraw,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF414141),
          ),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(movaText('Retirar')),
        ),
      ],
    );
  }
}

class _GoalHistoryDialog extends StatelessWidget {
  final int goalId;

  const _GoalHistoryDialog({required this.goalId});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(movaText('Historial de la meta')),
      content: SizedBox(
        width: 360,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: DatabaseHelper().getGoalMovements(goalId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Text(
                movaText('No se pudo cargar el historial: ${snapshot.error}'),
              );
            }
            final movements = snapshot.data ?? [];
            if (movements.isEmpty) {
              return Text(movaText('Todavía no hay movimientos en esta meta.'));
            }
            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: movements.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final movement = movements[index];
                  final withdrawal = movement['type'] == 'withdrawal';
                  final amount = (movement['amount'] as num).toDouble();
                  final date = DateTime.tryParse(
                    movement['created_at'] as String,
                  );
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      withdrawal
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: withdrawal
                          ? const Color(0xFF414141)
                          : const Color(0xFF0C2340),
                    ),
                    title: Text(
                      withdrawal
                          ? movaText('Retiro')
                          : movaText('Ahorro agregado'),
                    ),
                    subtitle: Text(
                      date == null
                          ? ''
                          : MaterialLocalizations.of(context)
                                .formatMediumDate(date),
                    ),
                    trailing: Text(
                      '${withdrawal ? '-' : '+'}${appCurrencyController.format(amount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: withdrawal
                            ? const Color(0xFF414141)
                            : const Color(0xFF0C2340),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(movaText('Cerrar')),
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Map<String, dynamic> goal;
  final VoidCallback onChanged;

  const _GoalCard({required this.goal, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 390;
    final target = (goal['target_amount'] as num).toDouble();
    final saved = (goal['saved_amount'] as num).toDouble();
    final progress = (saved / target).clamp(0.0, 1.0);
    final rawImage = goal['image'];
    final image = rawImage is Uint8List
        ? rawImage
        : rawImage is List
        ? Uint8List.fromList(rawImage.cast<int>())
        : null;
    final icon =
        _CreateGoalDialogState.icons[goal['icon']] ?? Icons.flag_outlined;
    return MovaSurface(
      padding: const EdgeInsets.all(16),
      radius: MovaDesign.radiusLarge,
      elevation: progress >= .9,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: SizedBox(
              width: narrow ? 60 : 68,
              height: narrow ? 60 : 68,
              child: image != null && image.isNotEmpty
                  ? Image.memory(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _goalIconFallback(icon),
                    )
                  : goal['icon'] == 'none'
                  ? Container(
                      color: MovaDesign.softBlue,
                      child: const Icon(
                        Icons.flag_outlined,
                        color: MovaDesign.muted,
                      ),
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF2F2F2), Color(0xFFE9E9E9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: MovaDesign.navy,
                        size: narrow ? 27 : 31,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        goal['name'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: MovaDesign.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: movaText('Modificar ahorro'),
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      onPressed: () async {
                        final updated = await showDialog<bool>(
                          context: context,
                          builder: (_) => _EditGoalSavingsDialog(goal: goal),
                        );
                        if (updated == true) onChanged();
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      color: const Color(0xFF727272),
                    ),
                    IconButton(
                      tooltip: movaText('Eliminar meta'),
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => _DeleteGoalDialog(goal: goal),
                        );
                        if (confirmed != true) return;
                        await DatabaseHelper().deleteGoal(goal['id'] as int);
                        onChanged();
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: const Color(0xFF414141),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movaText('PROGRESO DE LA META'),
                            style: TextStyle(
                              color: Color(0xFFA1A1A1),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${appCurrencyController.format(saved)} de ${appCurrencyController.format(target)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF727272),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 39,
                            height: 39,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 3.5,
                              strokeCap: StrokeCap.round,
                              backgroundColor: MovaDesign.softBlue,
                              color: progress >= .9
                                  ? MovaDesign.positive
                                  : MovaDesign.accent,
                            ),
                          ),
                          Text(
                            '${(progress * 100).round()}%',
                            style: const TextStyle(
                              color: MovaDesign.navy,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                MovaProgressBar(
                  value: progress,
                  height: 7,
                  color: progress >= .9
                      ? MovaDesign.positive
                      : MovaDesign.accent,
                ),
                if (progress >= .9 && progress < 1) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 13,
                        color: MovaDesign.warning,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        context.l10n.text('goal_almost_complete'),
                        style: const TextStyle(
                          color: MovaDesign.warning,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 13),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(7, 5, 7, 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 5,
                    runSpacing: 3,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          final updated = await showDialog<bool>(
                            context: context,
                            builder: (_) => _WithdrawGoalDialog(goal: goal),
                          );
                          if (updated == true) onChanged();
                        },
                        icon: const Icon(
                          Icons.arrow_downward_rounded,
                          size: 17,
                        ),
                        label: Text(movaText('Retirar')),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF414141),
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          minimumSize: const Size(0, 34),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) =>
                              _GoalHistoryDialog(goalId: goal['id'] as int),
                        ),
                        icon: const Icon(Icons.history_rounded, size: 17),
                        label: Text(movaText('Historial')),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF0C2340),
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          minimumSize: const Size(0, 34),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final id = await DatabaseHelper().ensureGoalShared(
                            goal['id'] as int,
                          );
                          if (context.mounted && id != null) {
                            await showDialog<void>(
                              context: context,
                              builder: (_) => _QrDialog(
                                title: movaText('Compartir meta'),
                                data: SharedGoalPayload(
                                  id: id,
                                  name: goal['name'] as String,
                                  targetAmount: target,
                                  icon: goal['icon'] as String? ?? 'flag',
                                ).encode(),
                              ),
                            );
                            onChanged();
                          }
                        },
                        icon: const Icon(Icons.qr_code_2_rounded, size: 17),
                        label: Text(movaText('Compartir')),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF0C2340),
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          minimumSize: const Size(0, 34),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final amount = await showDialog<double>(
                            context: context,
                            builder: (_) => const _ContributionAmountDialog(),
                          );
                          if (amount == null || !context.mounted) return;
                          final id = await DatabaseHelper().ensureGoalShared(
                            goal['id'] as int,
                          );
                          if (!context.mounted || id == null) return;
                          await showDialog<void>(
                            context: context,
                            builder: (_) => _QrDialog(
                              title: movaText('QR de aporte'),
                              data: ContributionPayload(
                                contributionId: newSharedId(),
                                goalId: id,
                                contributor: 'Invitado',
                                amount: amount,
                              ).encode(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.volunteer_activism_outlined,
                          size: 17,
                        ),
                        label: Text(movaText('Aporte')),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF0C2340),
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          minimumSize: const Size(0, 34),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _goalIconFallback(IconData icon) {
    return Container(
      color: const Color(0xFFF2F2F2),
      child: Icon(icon, color: const Color(0xFF0C2340), size: 31),
    );
  }
}

class _ContributionAmountDialog extends StatefulWidget {
  const _ContributionAmountDialog();

  @override
  State<_ContributionAmountDialog> createState() =>
      _ContributionAmountDialogState();
}

class _ContributionAmountDialogState extends State<_ContributionAmountDialog> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(movaText('Monto del aporte')),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          prefixText: '\$ ',
          hintText: movaText('0.00'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(movaText('Cancelar')),
        ),
        FilledButton(
          onPressed: () {
            final amount = double.tryParse(
              controller.text.trim().replaceAll(',', '.'),
            );
            if (amount != null && amount > 0) Navigator.pop(context, amount);
          },
          child: Text(movaText('Crear QR')),
        ),
      ],
    );
  }
}

class _QrDialog extends StatelessWidget {
  final String title;
  final String data;

  const _QrDialog({required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SizedBox(
        width: 320,
        height: 380,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF102A43),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(width: 230, height: 230, child: QrImageView(data: data)),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(movaText('Cerrar')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteGoalDialog extends StatelessWidget {
  final Map<String, dynamic> goal;

  const _DeleteGoalDialog({required this.goal});

  @override
  Widget build(BuildContext context) {
    final saved = (goal['saved_amount'] as num).toDouble();
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(movaText('Eliminar meta')),
      content: Text(
        saved > 0
            ? 'Se eliminará esta meta y se devolverán ${appCurrencyController.format(saved)} a tu saldo. Esta acción no se puede deshacer.'
            : movaText(
                '¿Quieres eliminar esta meta? Esta acción no se puede deshacer.',
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(movaText('Cancelar')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF414141),
          ),
          child: Text(movaText('Eliminar')),
        ),
      ],
    );
  }
}
