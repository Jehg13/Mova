import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mova/database/database_helper.dart';
import 'package:mova/models/financial_account.dart';
import 'package:mova/models/receipt_scan_draft.dart';
import 'package:mova/services/mova_localizations.dart';
import 'package:mova/services/receipt_ocr_service.dart';
import 'package:mova/services/receipt_parser.dart';
import 'package:mova/widgets/mova_feedback_dialog.dart';
import 'package:mova/widgets/receipt_image_preview.dart';

bool get isReceiptScannerSupported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

class ReceiptScannerScreen extends StatefulWidget {
  const ReceiptScannerScreen({required this.categories, super.key});

  final List<String> categories;

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  final _picker = ImagePicker();
  final _database = DatabaseHelper();
  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();
  final _itemsController = TextEditingController();
  final _referenceController = TextEditingController();
  late final Future<List<FinancialAccount>> _accounts;
  XFile? _image;
  DateTime _date = DateTime.now();
  String? _category;
  bool _categorySelectedByUser = false;
  int? _accountId;
  bool _isProcessing = false;
  bool _ocrFailed = false;

  @override
  void initState() {
    super.initState();
    _accounts = _database.getFinancialAccounts(includeInactive: false);
    _category = widget.categories.contains('Otros')
        ? 'Otros'
        : widget.categories.firstOrNull;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _itemsController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2200,
      );
      if (image == null || !mounted) return;
      setState(() {
        _image = image;
        _merchantController.clear();
        _amountController.clear();
        _itemsController.clear();
        _referenceController.clear();
        _date = DateTime.now();
        _category = widget.categories.contains('Otros')
            ? 'Otros'
            : widget.categories.firstOrNull;
        _categorySelectedByUser = false;
        _ocrFailed = false;
      });
      await _processImage(image);
    } catch (error) {
      if (!mounted) return;
      showMovaError(
        context,
        movaText('No se pudo abrir la imagen o la cámara: $error'),
      );
    }
  }

  Future<void> _processImage(XFile image) async {
    setState(() {
      _isProcessing = true;
      _ocrFailed = false;
    });
    try {
      final data = await recognizeReceipt(image.path);
      if (!mounted) return;
      final amount = data.amount;
      final suggested = suggestReceiptCategory(
        '${data.merchant} ${data.items.join(' ')}',
        widget.categories,
      );
      setState(() {
        _merchantController.text = data.merchant;
        _amountController.text = amount == null
            ? ''
            : amount.toStringAsFixed(2);
        _itemsController.text = data.items.join('\n');
        _referenceController.text = data.reference ?? '';
        _date = data.date ?? DateTime.now();
        if (suggested != null) _category = suggested;
      });
      if (amount == null) {
        showMovaError(context, context.l10n.text('receipt_total_not_found'));
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _ocrFailed = true);
      showMovaError(
        context,
        '${context.l10n.text('receipt_ocr_failed')}: $error',
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) setState(() => _date = date);
  }

  void _continue() {
    final amount = double.tryParse(
      _amountController.text.trim().replaceAll(',', '.'),
    );
    if (_image == null) {
      showMovaError(context, context.l10n.text('receipt_select_image'));
      return;
    }
    if (_merchantController.text.trim().isEmpty) {
      showMovaError(context, context.l10n.text('receipt_merchant_required'));
      return;
    }
    if (amount == null || amount <= 0) {
      showMovaError(context, context.l10n.text('receipt_amount_required'));
      return;
    }
    Navigator.pop(
      context,
      ReceiptScanDraft(
        imagePath: _image!.path,
        merchant: _merchantController.text.trim(),
        amount: amount,
        date: _date,
        category:
            _category ??
            (widget.categories.isEmpty ? 'Otros' : widget.categories.first),
        categorySelected: _categorySelectedByUser,
        items: _itemsController.text
            .split('\n')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(),
        reference: _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
        accountId: _accountId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final categories = widget.categories.isEmpty
        ? const ['Otros']
        : widget.categories;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.text('receipt_scanner_title')),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: const Color(0xFF102A43),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text(
              l10n.text('receipt_scanner_help'),
              style: const TextStyle(color: Color(0xFF727272), height: 1.4),
            ),
            const SizedBox(height: 16),
            if (_image == null)
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFF0C2340),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Icon(
                    Icons.receipt_long_rounded,
                    size: 52,
                    color: Colors.white70,
                  ),
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: ReceiptImagePreview(path: _image!.path),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(l10n.text('receipt_take_photo')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(l10n.text('receipt_choose_photo')),
                  ),
                ),
              ],
            ),
            if (_image != null) ...[
              const SizedBox(height: 8),
              if (_isProcessing)
                const LinearProgressIndicator(minHeight: 2)
              else if (_ocrFailed)
                TextButton.icon(
                  onPressed: () => _processImage(_image!),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.text('receipt_retry_ocr')),
                ),
              const SizedBox(height: 12),
              _field(
                controller: _merchantController,
                label: l10n.text('receipt_merchant'),
                icon: Icons.storefront_outlined,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _amountController,
                label: l10n.text('receipt_amount'),
                icon: Icons.attach_money_rounded,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.text('receipt_date'),
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    MaterialLocalizations.of(context).formatMediumDate(_date),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: categories.contains(_category)
                    ? _category
                    : categories.first,
                decoration: InputDecoration(
                  labelText: l10n.text('category'),
                  prefixIcon: const Icon(Icons.category_outlined),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _category = value;
                  _categorySelectedByUser = value != null;
                }),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<FinancialAccount>>(
                future: _accounts,
                builder: (context, snapshot) {
                  final accounts = snapshot.data ?? const <FinancialAccount>[];
                  final selectedId =
                      accounts.any((account) => account.id == _accountId)
                      ? _accountId
                      : null;
                  return DropdownButtonFormField<int?>(
                    initialValue: selectedId,
                    decoration: InputDecoration(
                      labelText: l10n.text('account_optional'),
                      prefixIcon: const Icon(
                        Icons.account_balance_wallet_outlined,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(l10n.text('no_account_selected')),
                      ),
                      ...accounts.map(
                        (account) => DropdownMenuItem<int?>(
                          value: account.id,
                          child: Text(
                            '${account.name} · ${account.currency}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _accountId = value),
                  );
                },
              ),
              const SizedBox(height: 12),
              _field(
                controller: _referenceController,
                label: l10n.text('receipt_reference'),
                icon: Icons.confirmation_number_outlined,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _itemsController,
                label: l10n.text('receipt_items'),
                icon: Icons.list_alt_outlined,
                maxLines: 4,
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _continue,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(l10n.text('receipt_continue_to_expense')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C2340),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
