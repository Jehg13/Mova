import 'package:flutter/material.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  // Estado para controlar si es Ingreso o Gasto
  bool isIncome = true;

  // Selección de categoría
  String selectedCategory = "Sueldo";

  // Listas de categorías según el tipo
  final List<Map<String, String>> incomeCategories = [
    {"name": "Sueldo", "emoji": "💼"},
    {"name": "Freelance", "emoji": "💰"},
    {"name": "Inversión", "emoji": "📈"},
    {"name": "Regalo", "emoji": "🎁"},
    {"name": "Venta", "emoji": "🏷️"},
    {"name": "Otro", "emoji": "📦"},
  ];

  final List<Map<String, String>> expenseCategories = [
    {"name": "Comida", "emoji": "🍔"},
    {"name": "Transporte", "emoji": "⛽"},
    {"name": "Compras", "emoji": "🛍️"},
    {"name": "Hogar", "emoji": "🏠"},
    {"name": "Entretenimiento", "emoji": "🎬"},
    {"name": "Otros", "emoji": "📦"},
  ];

  // Estilo de colores (Teal/Verde militar)
  final Color primaryColor = const Color(0xFF4A8B82);

  @override
  Widget build(BuildContext context) {
    final currentCategories = isIncome ? incomeCategories : expenseCategories;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. TÍTULO DINÁMICO
              Text(
                isIncome ? "Agregar ingreso" : "Agregar movimiento",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                isIncome ? "Registra el dinero que recibiste" : "Registra un ingreso o gasto",
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // 2. TOGGLE (GASTO / INGRESO)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isIncome = false;
                            selectedCategory = "Comida";
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !isIncome ? primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              "Gasto",
                              style: TextStyle(
                                color: !isIncome ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isIncome = true;
                            selectedCategory = "Sueldo";
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isIncome ? primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              "Ingreso",
                              style: TextStyle(
                                color: isIncome ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. CAMPO DE MONTO DINÁMICO
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: isIncome ? primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryColor, width: 1.5),
                ),
                child: Column(
                  children: [
                    Text(
                      isIncome ? "¿Cuánto recibiste?" : "¿Cuánto?",
                      style: TextStyle(
                        color: isIncome ? Colors.white70 : Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isIncome ? "\$ 8,400.00" : "\$ 150.00",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isIncome ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. SELECTOR DE CATEGORÍA
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  isIncome ? "Fuente del ingreso" : "Categoría",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              
              // Creador desplegable
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(selectedCategory, style: const TextStyle(fontWeight: FontWeight.w500)),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Chips de Categorías
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: currentCategories.map((item) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedCategory = item["name"]!;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(item["emoji"]!, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            item["name"]!,
                            style: TextStyle(
                              fontSize: 12,
                              color: selectedCategory == item["name"] ? primaryColor : Colors.black87,
                              fontWeight: selectedCategory == item["name"] ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // 5. DESCRIPCIÓN
              Align(
                alignment: Alignment.centerLeft,
                child: const Text("Descripción", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: isIncome ? "¿De dónde provino este ingreso?" : "¿En qué gastaste?",
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 6. FECHA
              Align(
                alignment: Alignment.centerLeft,
                child: const Text("Fecha", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("18 de agosto de 2026"),
                    Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Text("Agregar nota", style: TextStyle(color: Colors.grey)),
                ),
              ),
              const SizedBox(height: 10),

              // 7. BOTÓN PRINCIPAL
              if (isIncome)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    "Se agregarán \$8,400.00 a tu saldo.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isIncome ? "Guardar ingreso" : "Guardar movimiento",
                    style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
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