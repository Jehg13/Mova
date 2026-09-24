import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mova/database/database_helper.dart';
import 'package:mova/widgets/mova_feedback_dialog.dart';
import 'package:mova/services/mova_localizations.dart';

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
  final Color primaryColor = Color(0xFF0C2340);

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
      _showMessage(movaText('Ingresa un monto válido mayor que cero'));
      return;
    }
    if (description.isEmpty) {
      _showMessage(movaText('Escribe una descripción'));
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
      _showSuccess(
        isIncome
            ? movaText('Ingreso guardado correctamente')
            : movaText('Gasto guardado correctamente'),
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
      _showMessage(movaText('No se pudo guardar el movimiento: $error'));
    }
  }

  void _showMessage(String message) {
    showMovaError(context, message);
  }

  void _showSuccess(String message) {
    showMovaSuccess(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentCategories = isIncome ? incomeCategories : expenseCategories;

    return Scaffold(
      backgroundColor: Color(0xFFF1F5F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0C2340), Color(0xFF36577D)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      isIncome
                          ? Icons.trending_up_rounded
                          : Icons.receipt_long_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isIncome
                              ? l10n.text('add_income')
                              : l10n.text('add_expense'),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF102A43),
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          isIncome
                              ? l10n.text('income_help')
                              : l10n.text('expense_help'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // 2. TOGGLE (GASTO / INGRESO)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Color(0xFFD5DEE9)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0C0C2340),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(4),
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
                          padding: EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            gradient: !isIncome
                                ? LinearGradient(
                                    colors: [
                                      Color(0xFF0C2340),
                                      Color(0xFF1E3A5F),
                                    ],
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_downward_rounded,
                                  size: 17,
                                  color: !isIncome
                                      ? Colors.white
                                      : Color(0xFF64748B),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  l10n.text('expense'),
                                  style: TextStyle(
                                    color: !isIncome
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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
                          padding: EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            gradient: isIncome
                                ? LinearGradient(
                                    colors: [
                                      Color(0xFF0C2340),
                                      Color(0xFF1E3A5F),
                                    ],
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_upward_rounded,
                                  size: 17,
                                  color: isIncome
                                      ? Colors.white
                                      : Color(0xFF64748B),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  l10n.text('income_singular'),
                                  style: TextStyle(
                                    color: isIncome
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // 3. CAMPO DE MONTO DINÁMICO
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: isIncome
                      ? LinearGradient(
                          colors: [Color(0xFF0C2340), Color(0xFF1E3A5F)],
                        )
                      : null,
                  color: isIncome ? null : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: .16),
                      blurRadius: 18,
                      offset: Offset(0, 7),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      isIncome
                          ? l10n.text('how_much_received')
                          : l10n.text('how_much'),
                      style: TextStyle(
                        color: isIncome ? Colors.white70 : Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 6),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.numberWithOptions(
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
                        hintText: movaText('0.00'),
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
              SizedBox(height: 20),

              // 4. SELECTOR DE CATEGORÍA
              Row(
                children: [
                  Icon(
                    isIncome
                        ? Icons.account_balance_wallet_outlined
                        : Icons.category_outlined,
                    size: 18,
                    color: primaryColor,
                  ),
                  SizedBox(width: 7),
                  Text(
                    isIncome
                        ? l10n.text('income_source')
                        : l10n.text('category'),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF102A43),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),

              // Creador desplegable
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x080C2340),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          currentCategories.firstWhere(
                            (item) => item["name"] == selectedCategory,
                            orElse: () => currentCategories.first,
                          )["emoji"]!,
                          style: TextStyle(fontSize: 20),
                        ),
                        SizedBox(width: 10),
                        Text(
                          movaText(selectedCategory),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF102A43),
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.check_circle_rounded, color: Color(0xFF0C2340)),
                  ],
                ),
              ),
              SizedBox(height: 12),

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
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: selectedCategory == item["name"]
                              ? primaryColor.withValues(alpha: 0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selectedCategory == item["name"]
                                ? primaryColor
                                : Color(0xFFE2E8F0),
                          ),
                          boxShadow: selectedCategory == item["name"]
                              ? [
                                  BoxShadow(
                                    color: Color(0x180C2340),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 5,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item["emoji"]!,
                                style: TextStyle(fontSize: 14),
                              ),
                              SizedBox(width: 4),
                              Text(
                                movaText(item["name"]!),
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
              SizedBox(height: 20),

              // 5. DESCRIPCIÓN
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 18,
                      color: primaryColor,
                    ),
                    SizedBox(width: 7),
                    Text(
                      movaText("Descripción"),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF102A43),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.edit_note_rounded),
                  hintText: isIncome
                      ? movaText("¿De dónde provino este ingreso?")
                      : l10n.text('what_spent'),
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  contentPadding: EdgeInsets.all(16),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFFD8E1EB)),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // 6. FECHA
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: primaryColor,
                  ),
                  SizedBox(width: 7),
                  Text(
                    movaText("Fecha"),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF102A43),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x080C2340),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        MaterialLocalizations.of(context)
                            .formatFullDate(selectedDate),
                      ),
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),

              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.notes_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  hintText: l10n.text('optional_note'),
                  hintStyle: TextStyle(color: Colors.grey),
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
              SizedBox(height: 10),

              // 7. BOTÓN PRINCIPAL
              if (isIncome)
                Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    movaText("El ingreso se agregará a tu saldo."),
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                    elevation: 5,
                    shadowColor: primaryColor.withValues(alpha: .28),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isIncome
                              ? l10n.text('save_income')
                              : l10n.text('save_movement'),
                          style: TextStyle(
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
