import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mova/database/database_helper.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => AddTransactionScreenState();
}

class AddTransactionScreenState extends State<AddTransactionScreen> {
  bool isIncome = true;
  String selectedCategory = "Sueldo";
  DateTime selectedDate = DateTime.now();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCustomCategories();
  }

  Future<void> _loadCustomCategories() async {
    final categories = await _databaseHelper.getCustomCategories();
    if (!mounted) return;
    setState(() {
      for (final category in categories) {
        final item = {
          'name': category['name'] as String,
          'emoji': category['emoji'] as String,
        };
        final target = category['type'] == 'income'
            ? incomeCategories
            : expenseCategories;
        if (!target.any((existing) => existing['name'] == item['name'])) {
          target.add(item);
        }
      }
    });
  }

  void refreshCategories() {
    _loadCustomCategories();
  }

  // Listas de categorías según el tipo
  final List<Map<String, String>> incomeCategories = [
    {"name": "Sueldo", "emoji": "💼"},
    {"name": "Freelance", "emoji": "💰"},
    {"name": "Inversión", "emoji": "📈"},
    {"name": "Regalo", "emoji": "\u{1F381}"},
    {"name": "Venta", "emoji": "\u{1F3F7}\u{FE0F}"},
    {"name": "Otro", "emoji": "📦"},
  ];

  final List<Map<String, String>> expenseCategories = [
    {"name": "Comida", "emoji": "\u{1F354}"},
    {"name": "Transporte", "emoji": "⛽"},
    {"name": "Compras", "emoji": "\u{1F6CD}\u{FE0F}"},
    {"name": "Hogar", "emoji": "\u{1F3E0}"},
    {"name": "Entretenimiento", "emoji": "🎬"},
    {"name": "Ahorro", "emoji": "💰"},
    {"name": "Ahorro sin meta", "emoji": "\u{1F3E6}"},
    {"name": "Otros", "emoji": "📦"},
  ];

  // Estilo de colores (Teal/Verde militar)
  final Color primaryColor = const Color(0xFF0C2340);

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date != null && mounted) {
      setState(() => selectedDate = date);
    }
  }

  Future<void> _saveTransaction() async {
    final amountText = _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountText);
    final description = _descriptionController.text.trim();

    if (amount == null || amount <= 0) {
      _showMessage('Ingresa un monto válido mayor que cero');
      return;
    }
    if (description.isEmpty) {
      _showMessage('Escribe una descripción');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _databaseHelper.insertTransaction(
        amount: amount,
        isIncome: isIncome,
        category: selectedCategory,
        description: description,
        date: selectedDate,
        note: _noteController.text.trim(),
      );

      if (!mounted) return;
      _showMessage(
        isIncome
            ? 'Ingreso guardado correctamente'
            : 'Gasto guardado correctamente',
      );
      _amountController.clear();
      _descriptionController.clear();
      _noteController.clear();
      setState(() {
        selectedDate = DateTime.now();
        _isSaving = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('No se pudo guardar el movimiento: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime date) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

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
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isIncome
                    ? "Registra el dinero que recibiste"
                    : "Registra un ingreso o gasto",
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
                            color: !isIncome
                                ? primaryColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              "Gasto",
                              style: TextStyle(
                                color: !isIncome
                                    ? Colors.white
                                    : Colors.black87,
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
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
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
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isIncome ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        prefixText: '\$ ',
                        prefixStyle: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isIncome ? Colors.white : Colors.black,
                        ),
                        hintText: '0.00',
                        hintStyle: TextStyle(
                          color: isIncome ? Colors.white54 : Colors.black38,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        border: InputBorder.none,
                        isDense: true,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedCategory,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: selectedCategory == item["name"]
                              ? primaryColor.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selectedCategory == item["name"]
                                ? primaryColor
                                : Colors.transparent,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 5,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item["emoji"]!,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item["name"]!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: selectedCategory == item["name"]
                                      ? primaryColor
                                      : Colors.black87,
                                  fontWeight: selectedCategory == item["name"]
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // 5. DESCRIPCIÓN
              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  "Descripción",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: isIncome
                      ? "¿De dónde provino este ingreso?"
                      : "¿En qué gastaste?",
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
                child: const Text(
                  "Fecha",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDate(selectedDate)),
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Agregar nota (opcional)',
                  hintStyle: const TextStyle(color: Colors.grey),
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
              const SizedBox(height: 10),

              // 7. BOTÓN PRINCIPAL
              if (isIncome)
                Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    "El ingreso se agregará a tu saldo.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isIncome ? "Guardar ingreso" : "Guardar movimiento",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
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
