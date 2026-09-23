import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mova/database/database_helper.dart';
import 'package:mova/services/currency_controller.dart';
import 'package:mova/widgets/user_avatar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const Color primaryTeal = Color(0xFF0C2340);
  static const Color darkNavy = Color(0xFF0C2340);
  static const Color subtitleGrey = Color(0xFF64748B);
  static const Color backgroundColor = Color(0xFFF1F5F9);

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  late Future<_HomeData> _homeData;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
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
        ]).then(
          (results) => _HomeData(
            transactions: results[0] as List<Map<String, dynamic>>,
            summary: results[1] as Map<String, double>,
            goals: results[2] as List<Map<String, dynamic>>,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeScreen.backgroundColor,
      body: SafeArea(
        child: FutureBuilder<_HomeData>(
          future: _homeData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('No se pudo cargar el resumen: ${snapshot.error}'),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HeaderSection(),
                    const SizedBox(height: 18),
                    BalanceCard(balance: data.balance),
                    const SizedBox(height: 14),
                    QuickSummarySection(
                      income: data.income,
                      expenses: data.expenses,
                      savings: data.savings,
                    ),
                    const SizedBox(height: 24),
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

  const _HomeData({
    required this.transactions,
    required this.summary,
    required this.goals,
  });

  double get income => summary['income']!;
  double get expenses => summary['expenses']!;
  double get savings => summary['savings']!;
  double get balance => income - expenses - savings;
}

// --- 1. ENCABEZADO ---
class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: profileChanged,
      builder: (context, _, _) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: DatabaseHelper().getCurrentUser(),
          builder: (context, snapshot) {
            final name = (snapshot.data?['name'] as String?) ?? 'Hola';
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, $name 👋',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: HomeScreen.darkNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Este es tu resumen financiero',
                        style: TextStyle(
                          fontSize: 13,
                          color: HomeScreen.subtitleGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const UserAvatar(radius: 18),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (_) => const _HomeNotificationsDialog(),
                      ),
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Color(0xFFE2E8F0)),
                            ),
                            child: const Icon(
                              Icons.notifications_none_outlined,
                              size: 20,
                              color: HomeScreen.darkNavy,
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.notifications_active_outlined, color: HomeScreen.darkNavy),
          SizedBox(width: 10),
          Text('Notificaciones'),
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
                  const Text(
                    'Elige qué avisos quieres recibir en MOVA.',
                    style: TextStyle(color: HomeScreen.subtitleGrey),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Notificaciones activas'),
                    value: _enabled,
                    onChanged: (value) => _set('notifications_enabled', value),
                  ),
                  const Divider(),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Presupuesto'),
                    value: _budget,
                    onChanged: !_enabled
                        ? null
                        : (value) => _set('notification_budget', value),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Metas de ahorro'),
                    value: _goals,
                    onChanged: !_enabled
                        ? null
                        : (value) => _set('notification_goals', value),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Listas de compras'),
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
          child: const Text('Cerrar'),
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C2340), Color(0xFF1E3A5F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C2340).withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Color(0xFFB9D7F0),
                  size: 17,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "Dinero disponible",
                style: TextStyle(
                  color: Color(0xFFB9C9DB),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            appCurrencyController.format(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: .1)),
            ),
            child: Text(
              appCurrencyController.code,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
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
    return Row(
      children: [
        Expanded(
          child: SummaryItem(
            title: "Ingresos",
            amount: appCurrencyController.format(income),
            icon: Icons.arrow_outward_rounded,
            color: Color(0xFF0C2340),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: SummaryItem(
            title: "Gastos",
            amount: '-${appCurrencyController.format(expenses)}',
            icon: Icons.south_west_rounded,
            color: Color(0xFFEF4444),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: SummaryItem(
            title: "Ahorro",
            amount: appCurrencyController.format(savings),
            icon: Icons.savings_outlined,
            color: HomeScreen.primaryTeal,
          ),
        ),
      ],
    );
  }
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0C2340),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: HomeScreen.subtitleGrey,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            child: Text(
              amount,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
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
                    color: const Color(0xFFE8EEF5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    size: 17,
                    color: HomeScreen.primaryTeal,
                  ),
                ),
                const SizedBox(width: 9),
                const Text(
                  "Movimientos recientes",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: HomeScreen.darkNavy,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.arrow_forward_rounded, size: 15),
              label: const Text("Ver todos"),
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
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x090C2340),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: transactions.isEmpty
                ? const [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 22),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 32,
                            color: Color(0xFF94A3B8),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Aún no tienes movimientos registrados',
                            style: TextStyle(
                              fontSize: 13,
                              color: HomeScreen.subtitleGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]
                : transactions.take(5).toList().asMap().entries.map((entry) {
                    final transaction = entry.value;
                    final isExpense = transaction['is_income'] == 0;
                    final amount = (transaction['amount'] as num).toDouble();
                    return Column(
                      children: [
                        TransactionItem(
                          title: transaction['description'] as String,
                          amount:
                              '${isExpense ? '-' : '+'}${appCurrencyController.format(amount)}',
                          icon: _iconForCategory(
                            transaction['category'] as String,
                          ),
                          iconColor: isExpense
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF10B981),
                          isExpense: isExpense,
                        ),
                        if (entry.key < transactions.take(5).length - 1)
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      ],
                    );
                  }).toList(),
          ),
        ),
      ],
    );
  }

  static IconData _iconForCategory(String category) {
    switch (category) {
      case 'Comida':
        return Icons.restaurant;
      case 'Transporte':
        return Icons.local_gas_station;
      case 'Compras':
        return Icons.shopping_bag_outlined;
      case 'Hogar':
        return Icons.home_outlined;
      case 'Entretenimiento':
        return Icons.movie_outlined;
      case 'Sueldo':
        return Icons.account_balance_wallet;
      case 'Inversión':
        return Icons.trending_up;
      default:
        return Icons.receipt_long_outlined;
    }
  }
}

class TransactionItem extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color iconColor;
  final bool isExpense;

  const TransactionItem({
    super.key,
    required this.title,
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: HomeScreen.darkNavy,
              ),
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isExpense
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x090C2340),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEF5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  size: 17,
                  color: HomeScreen.primaryTeal,
                ),
              ),
              const SizedBox(width: 9),
              const Text(
                "Meta actual",
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
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    color: HomeScreen.subtitleGrey,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Aún no tienes metas. Crea una para empezar a ahorrar con un objetivo.",
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
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: const Color(0xFFF1F5F9),
                  color: HomeScreen.primaryTeal,
                ),
              ),
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
      color: Color(0xFFE8EEF5),
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
