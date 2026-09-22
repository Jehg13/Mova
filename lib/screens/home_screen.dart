import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color primaryTeal = Color(0xFF3398B1);
  static const Color darkNavy = Color(0xFF0C2340);
  static const Color subtitleGrey = Color(0xFF64748B);
  static const Color backgroundColor = Color(0xFFF1F5F9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              HeaderSection(),
              SizedBox(height: 20),
              BalanceCard(),
              SizedBox(height: 16),
              QuickSummarySection(),
              SizedBox(height: 24),
              RecentTransactionsSection(),
              SizedBox(height: 24),
              GoalSection(),
              SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 1. ENCABEZADO ---
class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Hola, Jesús 👋",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: HomeScreen.darkNavy,
              ),
            ),
            SizedBox(height: 2),
            Text(
              "Este es tu resumen financiero",
              style: TextStyle(
                fontSize: 13,
                color: HomeScreen.subtitleGrey,
              ),
            ),
          ],
        ),
        Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFCBD5E1),
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
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
                )
              ],
            )
          ],
        )
      ],
    );
  }
}

// --- 2. TARJETA PRINCIPAL ---
class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key});

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
            color: const Color(0xFF0C2340).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Dinero disponible",
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            "\$4,250.00",
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "USD",
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          )
        ],
      ),
    );
  }
}

// --- 3. RESUMEN RÁPIDO ---
class QuickSummarySection extends StatelessWidget {
  const QuickSummarySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: SummaryItem(
            title: "Ingresos",
            amount: "\$8,400",
            icon: Icons.arrow_outward_rounded,
            color: Color(0xFF10B981),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: SummaryItem(
            title: "Gastos",
            amount: "-\$3,250",
            icon: Icons.south_west_rounded,
            color: Color(0xFFEF4444),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: SummaryItem(
            title: "Ahorro",
            amount: "\$1,200",
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: HomeScreen.subtitleGrey),
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
  const RecentTransactionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Movimientos recientes",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: HomeScreen.darkNavy,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                "Ver todos",
                style: TextStyle(
                  color: HomeScreen.primaryTeal,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: const [
              TransactionItem(
                title: "Comida",
                amount: "-\$150.00",
                icon: Icons.restaurant,
                iconColor: Color(0xFFF59E0B),
                isExpense: true,
              ),
              Divider(height: 1, color: Color(0xFFF1F5F9)),
              TransactionItem(
                title: "Gasolina",
                amount: "-\$500.00",
                icon: Icons.local_gas_station,
                iconColor: Color(0xFFEF4444),
                isExpense: true,
              ),
              Divider(height: 1, color: Color(0xFFF1F5F9)),
              TransactionItem(
                title: "Salario",
                amount: "+\$8,400.00",
                icon: Icons.account_balance_wallet,
                iconColor: Color(0xFF10B981),
                isExpense: false,
              ),
              Divider(height: 1, color: Color(0xFFF1F5F9)),
              TransactionItem(
                title: "Entretenimiento",
                amount: "-\$200.00",
                icon: Icons.movie_outlined,
                iconColor: Color(0xFF8B5CF6),
                isExpense: true,
              ),
            ],
          ),
        ),
      ],
    );
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
              color: iconColor.withOpacity(0.12),
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
              color: isExpense ? const Color(0xFFEF4444) : const Color(0xFF10B981),
            ),
          )
        ],
      ),
    );
  }
}

// --- 5. META ACTUAL ---
class GoalSection extends StatelessWidget {
  const GoalSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Meta actual",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: HomeScreen.subtitleGrey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: HomeScreen.primaryTeal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_car_outlined,
                  color: HomeScreen.primaryTeal,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Comprar carro",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: HomeScreen.darkNavy,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "\$25,000 / \$80,000",
                    style: TextStyle(
                      fontSize: 12,
                      color: HomeScreen.subtitleGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 25000 / 80000,
              minHeight: 8,
              backgroundColor: Color(0xFFF1F5F9),
              color: HomeScreen.primaryTeal,
            ),
          )
        ],
      ),
    );
  }
}