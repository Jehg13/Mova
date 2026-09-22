import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TÍTULO Y SELECTOR DE PERIODO
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Análisis",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    value: "Este mes",
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.black87),
                    items: const [
                      DropdownMenuItem(
                        value: "Este mes",
                        child: Text("Este mes", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: "Mes anterior",
                        child: Text("Mes anterior", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ],
                    onChanged: (value) {},
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. RESUMEN (Summary)
              const AnalyticsSummaryCard(),
              const SizedBox(height: 16),

              // 3. GRÁFICO (Main Graph)
              const MainGraphCard(),
              const SizedBox(height: 20),

              // 4. GASTOS POR CATEGORÍA
              const CategoryExpensesSection(),
              const SizedBox(height: 20),

              // 5. CUADRO DE RESUMEN
              const InsightCard(),
            ],
          ),
        ),
      ),
    );
  }
}

// --- COMPONENTES ---

class AnalyticsSummaryCard extends StatelessWidget {
  const AnalyticsSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Summary",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SummaryStatItem(title: "Ingresos", amount: "\$8,400.00", color: Color(0xFF4A8B82)),
              SummaryStatItem(title: "Gastos", amount: "\$3,250.00", color: Color(0xFF3B82F6)),
              SummaryStatItem(title: "Ahorro", amount: "\$5,150.00", color: Color(0xFFD97706)),
            ],
          )
        ],
      ),
    );
  }
}

class SummaryStatItem extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;

  const SummaryStatItem({
    super.key,
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

class MainGraphCard extends StatelessWidget {
  const MainGraphCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Main Graph",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Row(
                children: const [
                  LegendDot(color: Color(0xFF4A8B82), label: "Ingresos"),
                  SizedBox(width: 12),
                  LegendDot(color: Color(0xFF3B82F6), label: "Gastos"),
                ],
              )
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: LineChartPainter(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Lun", style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text("Mar", style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text("Mié", style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text("Jue", style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text("Vie", style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text("Sáb", style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text("Dom", style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text("Lun", style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text("Mié", style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text("Jue", style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text("Vie", style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text("Sáb", style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text("Dom", style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }
}

class LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const LegendDot({super.key, required this.color, required this.label});

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
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

class CategoryExpensesSection extends StatelessWidget {
  const CategoryExpensesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Gastos por categoría",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          CategoryProgressItem(
            emoji: "🍔",
            title: "Comida",
            amount: "\$1,200.00",
            percentage: 37,
            color: Color(0xFF4A8B82),
          ),
          SizedBox(height: 12),
          CategoryProgressItem(
            emoji: "⛽",
            title: "Transporte",
            amount: "\$800.00",
            percentage: 25,
            color: Color(0xFF3B82F6),
          ),
          SizedBox(height: 12),
          CategoryProgressItem(
            emoji: "🎮",
            title: "Entretenimiento",
            amount: "\$450.00",
            percentage: 14,
            color: Color(0xFF8B5CF6),
          ),
          SizedBox(height: 12),
          CategoryProgressItem(
            emoji: "🛍️",
            title: "Compras",
            amount: "\$500.00",
            percentage: 15,
            color: Color(0xFFEC4899),
          ),
          SizedBox(height: 12),
          CategoryProgressItem(
            emoji: "📦",
            title: "Otros",
            amount: "\$300.00",
            percentage: 9,
            color: Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }
}

class CategoryProgressItem extends StatelessWidget {
  final String emoji;
  final String title;
  final String amount;
  final int percentage;
  final Color color;

  const CategoryProgressItem({
    super.key,
    required this.emoji,
    required this.title,
    required this.amount,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              "$amount - $percentage%",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 6,
            backgroundColor: Colors.grey.shade100,
            color: color,
          ),
        ),
      ],
    );
  }
}

class InsightCard extends StatelessWidget {
  const InsightCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Resumen",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            "Este mes tus gastos de comida representan la mayor parte de tus gastos.",
            style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// --- PAINTER PARA EL GRÁFICO DE LÍNEAS ---
class LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final greenPaint = Paint()
      ..color = const Color(0xFF4A8B82)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final bluePaint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final greenPath = Path();
    greenPath.moveTo(0, size.height * 0.7);
    greenPath.quadraticBezierTo(size.width * 0.15, size.height * 0.2, size.width * 0.3, size.height * 0.6);
    greenPath.quadraticBezierTo(size.width * 0.45, size.height * 0.1, size.width * 0.6, size.height * 0.5);
    greenPath.quadraticBezierTo(size.width * 0.75, size.height * 0.2, size.width * 0.9, size.height * 0.4);
    greenPath.lineTo(size.width, size.height * 0.1);

    final bluePath = Path();
    bluePath.moveTo(0, size.height * 0.9);
    bluePath.quadraticBezierTo(size.width * 0.2, size.height * 0.6, size.width * 0.35, size.height * 0.8);
    bluePath.quadraticBezierTo(size.width * 0.5, size.height * 0.4, size.width * 0.7, size.height * 0.7);
    bluePath.quadraticBezierTo(size.width * 0.85, size.height * 0.5, size.width, size.height * 0.3);

    canvas.drawPath(greenPath, greenPaint);
    canvas.drawPath(bluePath, bluePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}