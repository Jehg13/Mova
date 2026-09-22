import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mova/services/currency_controller.dart';
import 'package:mova/database/database_helper.dart';
import 'package:mova/services/goal_image_picker.dart';
import 'package:mova/models/shared_goal.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
    _loadGoals();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _goals,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'No se pudieron cargar las metas: ${snapshot.error}',
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
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Mis metas',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF102A43),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Importar QR',
                        onPressed: () => _importQr(context),
                        icon: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Color(0xFF0C2340),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Convierte tus planes en objetivos',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 20),
                  _SummaryCard(
                    saved: saved,
                    target: target,
                    count: goals.length,
                  ),
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
        backgroundColor: const Color(0xFF1E293B),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nueva meta',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _importQr(BuildContext context) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importar QR'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Pega aquí el texto del QR',
            helperText:
                'La cámara estará disponible en futuras versiones móviles.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Validar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.trim().isEmpty || !mounted) return;
    try {
      try {
        final contribution = ContributionPayload.parse(text);
        await _database.addContribution(contribution);
        if (!context.mounted) {
          return;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aporte importado correctamente')),
          );
        }
      } on FormatException {
        final payload = SharedGoalPayload.parse(text);
        await _database.importSharedGoal(payload);
        if (!context.mounted) {
          return;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Meta compartida importada')),
          );
        }
      }
      if (mounted) setState(_loadGoals);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('QR inválido: $error')));
      }
    }
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _balance = _database.getUnassignedSavings();

  Future<void> _openAmountDialog({required bool withdraw}) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(withdraw ? 'Retirar ahorro libre' : 'Agregar ahorro libre'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Cantidad',
            prefixText: '${appCurrencyController.definition.symbol} ',
            hintText: '0.00',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(
                controller.text.trim().replaceAll(',', '.'),
              );
              if (value == null || value <= 0) return;
              Navigator.pop(context, value);
            },
            child: Text(withdraw ? 'Retirar' : 'Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount == null || !mounted) return;
    try {
      if (withdraw) {
        await _database.withdrawUnassignedSavings(amount);
      } else {
        await _database.addUnassignedSavings(amount);
      }
      if (!mounted) return;
      setState(_load);
      widget.onChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            withdraw
                ? 'Ahorro retirado correctamente'
                : 'Ahorro agregado correctamente',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: _balance,
      builder: (context, snapshot) {
        final balance = snapshot.data ?? 0;
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEAF0F7), Color(0xFFDCE7F2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFC3D2E1)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120C2340),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.savings_outlined,
                      color: Color(0xFF0C2340),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ahorro libre',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Ahorra sin tener una meta específica',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF526D8D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                appCurrencyController.format(balance),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF102A43),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openAmountDialog(withdraw: false),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Agregar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: balance > 0
                          ? () => _openAmountDialog(withdraw: true)
                          : null,
                      icon: const Icon(Icons.remove_rounded, size: 18),
                      label: const Text('Retirar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
          content: Text('No se pudo abrir el selector de imágenes: $error'),
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
        const SnackBar(
          content: Text('El ahorro inicial no puede superar la meta'),
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
        SnackBar(content: Text('No se pudo crear la meta: $error')),
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
        ? 'Ingresa un monto mayor que cero'
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
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
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
                        color: const Color(0xFFDDF3EE),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.flag_outlined,
                        color: Color(0xFF0C2340),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Crear nueva meta',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF102A43),
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Dale un propósito a tu ahorro',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      color: const Color(0xFF64748B),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _imagePicker(),
                const SizedBox(height: 21),
                const Text(
                  'Información de la meta',
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
                          'Monto objetivo',
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
                          'Ahorro inicial',
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
                const Text(
                  'Elige un icono',
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
                                  : const Color(0xFFE2E8F0),
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Icon(
                            entry.value,
                            size: 21,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      onTap: () => setState(() => _icon = entry.key),
                      borderRadius: BorderRadius.circular(13),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
                Semantics(
                  button: true,
                  label: 'Sin icono',
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
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Sin icono',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _icon == 'none'
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: _icon == 'none'
                                  ? const Color(0xFF0C2340)
                                  : const Color(0xFF475569),
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
                          side: const BorderSide(color: Color(0xFFD6DEE8)),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: Color(0xFF475569)),
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
                            : const Text(
                                'Crear meta',
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
          color: const Color(0xFFEAF5F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFB9DED6), width: 1.2),
        ),
        child: _image == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    color: Color(0xFF0C2340),
                    size: 38,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Agregar imagen',
                    style: TextStyle(
                      color: Color(0xFF0C2340),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Opcional · JPG, PNG o WebP',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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
                          foregroundColor: const Color(0xFF334155),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 19, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C2340), Color(0xFF1E3A5F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220C2340),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RESUMEN DE AHORRO',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        color: Color(0xFFB9C9DB),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Tu avance acumulado',
                      style: TextStyle(fontSize: 13, color: Color(0xFFE2E8F0)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.savings_rounded,
                  size: 28,
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
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'de ${appCurrencyController.format(target)} establecidos',
            style: const TextStyle(fontSize: 12, color: Color(0xFFB9C9DB)),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(.18),
              color: const Color(0xFFB9D7F0),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).round()}% completado',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$count ${count == 1 ? 'meta activa' : 'metas activas'}',
                style: const TextStyle(fontSize: 12, color: Color(0xFFB9C9DB)),
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
            'Ingresa un valor entre ${appCurrencyController.format(0)} y ${appCurrencyController.format(target)}',
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
        SnackBar(content: Text('No se pudo actualizar el ahorro: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text('Modificar ahorro'),
      content: TextField(
        controller: _amount,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Cantidad ahorrada',
          prefixText: '\$ ',
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
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
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0C2340),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(Icons.flag_outlined, size: 42, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            'Aún no tienes metas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            'Crea una meta para darle un objetivo a tus ahorros.',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ingresa un retiro entre ${appCurrencyController.format(0.01)} y ${appCurrencyController.format(current)}',
          ),
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo retirar el dinero: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = (widget.goal['saved_amount'] as num).toDouble();
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text('Retirar de la meta'),
      content: TextField(
        controller: _amount,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Monto a retirar',
          prefixText: '\$ ',
          helperText: 'Disponible: ${appCurrencyController.format(current)}',
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _withdraw,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFB42318),
          ),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Retirar'),
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
      title: const Text('Historial de la meta'),
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
              return Text('No se pudo cargar el historial: ${snapshot.error}');
            }
            final movements = snapshot.data ?? [];
            if (movements.isEmpty) {
              return const Text('Todavía no hay movimientos en esta meta.');
            }
            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: movements.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
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
                          ? const Color(0xFFB42318)
                          : const Color(0xFF0C2340),
                    ),
                    title: Text(withdrawal ? 'Retiro' : 'Ahorro agregado'),
                    subtitle: Text(
                      date == null
                          ? ''
                          : '${date.day}/${date.month}/${date.year}',
                    ),
                    trailing: Text(
                      '${withdrawal ? '-' : '+'}${appCurrencyController.format(amount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: withdrawal
                            ? const Color(0xFFB42318)
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
          child: const Text('Cerrar'),
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
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: SizedBox(
              width: 72,
              height: 72,
              child: image != null && image.isNotEmpty
                  ? Image.memory(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _goalIconFallback(icon),
                    )
                  : goal['icon'] == 'none'
                  ? Container(color: const Color(0xFFF8FAFC))
                  : Container(
                      color: const Color(0xFFEAF5F2),
                      child: Icon(
                        icon,
                        color: const Color(0xFF0C2340),
                        size: 31,
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF102A43),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Modificar ahorro',
                      onPressed: () async {
                        final updated = await showDialog<bool>(
                          context: context,
                          builder: (_) => _EditGoalSavingsDialog(goal: goal),
                        );
                        if (updated == true) onChanged();
                      },
                      icon: const Icon(Icons.edit_outlined, size: 19),
                      color: const Color(0xFF64748B),
                    ),
                    IconButton(
                      tooltip: 'Eliminar meta',
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => _DeleteGoalDialog(goal: goal),
                        );
                        if (confirmed != true) return;
                        await DatabaseHelper().deleteGoal(goal['id'] as int);
                        onChanged();
                      },
                      icon: const Icon(Icons.delete_outline, size: 19),
                      color: const Color(0xFFB42318),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '${appCurrencyController.format(saved)} de ${appCurrencyController.format(target)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 7,
                          backgroundColor: const Color(0xFFE2E8F0),
                          color: const Color(0xFF0C2340),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        final updated = await showDialog<bool>(
                          context: context,
                          builder: (_) => _WithdrawGoalDialog(goal: goal),
                        );
                        if (updated == true) onChanged();
                      },
                      icon: const Icon(Icons.arrow_downward_rounded, size: 17),
                      label: const Text('Retirar'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFB42318),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(width: 14),
                    TextButton.icon(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) =>
                            _GoalHistoryDialog(goalId: goal['id'] as int),
                      ),
                      icon: const Icon(Icons.history_rounded, size: 17),
                      label: const Text('Historial'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF0C2340),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Compartir meta',
                      onPressed: () async {
                        final id = await DatabaseHelper().ensureGoalShared(
                          goal['id'] as int,
                        );
                        if (context.mounted && id != null) {
                          await showDialog<void>(
                            context: context,
                            builder: (_) => _QrDialog(
                              title: 'Compartir meta',
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
                      icon: const Icon(
                        Icons.qr_code_2_rounded,
                        size: 20,
                        color: Color(0xFF0C2340),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Crear QR de aporte',
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
                            title: 'QR de aporte',
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
                        size: 20,
                        color: Color(0xFF0C2340),
                      ),
                    ),
                  ],
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
      color: const Color(0xFFEAF3FA),
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
      title: const Text('Monto del aporte'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(prefixText: '\$ ', hintText: '0.00'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final amount = double.tryParse(
              controller.text.trim().replaceAll(',', '.'),
            );
            if (amount != null && amount > 0) Navigator.pop(context, amount);
          },
          child: const Text('Crear QR'),
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
                  child: const Text('Cerrar'),
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
      title: const Text('Eliminar meta'),
      content: Text(
        saved > 0
            ? 'Se eliminará esta meta y se devolverán ${appCurrencyController.format(saved)} a tu saldo. Esta acción no se puede deshacer.'
            : '¿Quieres eliminar esta meta? Esta acción no se puede deshacer.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFB42318),
          ),
          child: const Text('Eliminar'),
        ),
      ],
    );
  }
}
