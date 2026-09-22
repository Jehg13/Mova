import 'package:flutter/material.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  // 1. TÍTULO Y SUBTÍTULO
                  Text(
                    "Mis metas",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Convierte tus planes en objetivos",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  SizedBox(height: 20),

                  // 2. TARJETA RESUMEN (Summary)
                  SummaryGoalsCard(),
                  SizedBox(height: 20),

                  // 3. LISTA DE METAS
                  GoalCard(
                    title: "Comprar carro",
                    emoji: "🚗",
                    targetAmount: 80000,
                    savedAmount: 25000,
                    targetDate: "Diciembre 2026",
                  ),
                  SizedBox(height: 16),
                  GoalCard(
                    title: "Viaje",
                    emoji: "✈️",
                    targetAmount: 20000,
                    savedAmount: 12500,
                    targetDate: "Marzo 2027",
                  ),
                  SizedBox(height: 16),
                  GoalCard(
                    title: "Laptop",
                    emoji: "💻",
                    targetAmount: 30000,
                    savedAmount: 18000,
                    targetDate: "Octubre 2026",
                  ),
                  SizedBox(height: 80), // Espacio para que el botón no tape la última tarjeta
                ],
              ),
            ),

            // 4. BOTÓN FLOTANTE ("+ Nueva meta")
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton.extended(
                onPressed: () {},
                backgroundColor: const Color(0xFF1E293B), // Oscuro elegante
                elevation: 4,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  "Nueva meta",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- COMPONENTES DE LA PANTALLA ---

class SummaryGoalsCard extends StatelessWidget {
  const SummaryGoalsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE2F1ED), Color(0xFFE0E7FF)], // Degradado verde pastel a azul
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Summary",
                style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 4),
              Text(
                "Ahorro total",
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
              SizedBox(height: 4),
              Text(
                "\$29,500",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              SizedBox(height: 4),
              Text(
                "3 metas activas",
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFF4A8B82).withOpacity(0.2),
            child: const Icon(
              Icons.attach_money,
              size: 36,
              color: Color(0xFF4A8B82),
            ),
          )
        ],
      ),
    );
  }
}

class GoalCard extends StatelessWidget {
  final String title;
  final String emoji;
  final double targetAmount;
  final double savedAmount;
  final String targetDate;

  const GoalCard({
    super.key,
    required this.title,
    required this.emoji,
    required this.targetAmount,
    required this.savedAmount,
    required this.targetDate,
  });

  @override
  Widget build(BuildContext context) {
    final double remainingAmount = targetAmount - savedAmount;
    final double percentage = (savedAmount / targetAmount).clamp(0.0, 1.0);
    final int percentageText = (percentage * 100).round();

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
          // Ícono y Título
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Meta vs Ahorrado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Meta: \$${targetAmount.toStringAsFixed(0)}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                "Ahorrado: \$${savedAmount.toStringAsFixed(0)}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Barra de progreso y Porcentaje
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percentage,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "$percentageText%",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Te faltan vs Objetivo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Te faltan \$${remainingAmount.toStringAsFixed(0)}",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              Text(
                "Objetivo: $targetDate",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}