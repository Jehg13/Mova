import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mova/database/database_helper.dart';
import 'package:mova/models/financial_account.dart';
import 'package:mova/models/receipt_scan_draft.dart';
import 'package:mova/models/transaction_category_catalog.dart';
import 'package:mova/screens/nivo_screen.dart';
import 'package:mova/services/currency_controller.dart';
import 'package:mova/services/receipt_storage.dart';
import 'package:mova/screens/receipt_scanner_screen.dart';
import 'package:mova/widgets/mova_feedback_dialog.dart';
import 'package:mova/widgets/receipt_image_preview.dart';
import 'package:mova/widgets/mova_design_system.dart';
import 'package:mova/services/mova_localizations.dart';

enum _DuplicateReceiptAction { cancel, attach, create }

class _DuplicateReceiptDecision {
  const _DuplicateReceiptDecision(this.action, {this.transactionId});

  final _DuplicateReceiptAction action;
  final int? transactionId;
}

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
  late Future<List<FinancialAccount>> _accounts;
  FinancialAccount? _selectedAccount;
  List<FinancialAccount> _loadedAccounts = [];
  bool _accountChoiceMade = false;
  ReceiptScanDraft? _receiptDraft;
  bool _receiptCategoryConfirmed = false;

  @override
  void initState() {
    super.initState();
    _loadCustomCategories();
    _loadAccounts();
  }

  void _loadAccounts() {
    _accounts = _loadActiveAccounts();
  }

  Future<List<FinancialAccount>> _loadActiveAccounts() async {
    final accounts = await _databaseHelper.getFinancialAccounts(
      includeInactive: false,
    );
    _loadedAccounts = accounts;
    if (isIncome && !_accountChoiceMade && _selectedAccount == null) {
      final cashAccounts = accounts
          .where((account) => account.type == FinancialAccountType.cash)
          .toList();
      _selectedAccount = _defaultCashAccount(cashAccounts);
    }
    return accounts;
  }

  FinancialAccount? _defaultCashAccount(List<FinancialAccount> accounts) {
    if (accounts.length == 1) return accounts.single;
    for (final account in accounts) {
      if (account.name.trim().toLowerCase() == 'efectivo') return account;
    }
    return null;
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
    setState(_loadAccounts);
  }

  final List<Map<String, String>> incomeCategories = TransactionCategoryCatalog
      .income
      .map((category) => Map<String, String>.of(category))
      .toList();

  final List<Map<String, String>> expenseCategories = TransactionCategoryCatalog
      .expense
      .map((category) => Map<String, String>.of(category))
      .toList();

  final Color primaryColor = MovaDesign.navy;

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
    if (_isSaving) return;
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

    final receipt = _receiptDraft;
    final transactionDate = selectedDate;
    final transactionIsIncome = isIncome;
    final transactionCategory = selectedCategory;
    final transactionAccount = _selectedAccount;
    final transactionNote = _noteController.text.trim();
    setState(() => _isSaving = true);
    if (receipt != null) {
      List<Map<String, dynamic>> duplicates;
      try {
        duplicates = await _databaseHelper.findPossibleDuplicateReceipts(
          amount: amount,
          date: transactionDate,
          merchant: description,
          reference: receipt.reference,
        );
      } catch (error) {
        if (mounted) {
          setState(() => _isSaving = false);
          _showMessage(
            movaText('No se pudieron revisar posibles duplicados: $error'),
          );
        }
        return;
      }
      if (!mounted) return;
      if (duplicates.isNotEmpty) {
        final decision = await showDialog<_DuplicateReceiptDecision>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(dialogContext.l10n.text('receipt_duplicate_title')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dialogContext.l10n.text('receipt_duplicate_message')),
                  const SizedBox(height: 12),
                  ...duplicates.take(3).map((duplicate) {
                    final id = duplicate['id'] as int;
                    final date = DateTime.tryParse(
                      duplicate['date'] as String? ?? '',
                    );
                    final hasReceipt =
                        (duplicate['receipt_image_path'] as String?)
                            ?.isNotEmpty ==
                        true;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: OutlinedButton.icon(
                        onPressed: hasReceipt
                            ? null
                            : () => Navigator.pop(
                                dialogContext,
                                _DuplicateReceiptDecision(
                                  _DuplicateReceiptAction.attach,
                                  transactionId: id,
                                ),
                              ),
                        icon: Icon(
                          hasReceipt
                              ? Icons.check_circle_outline
                              : Icons.attach_file_rounded,
                        ),
                        label: Text(
                          '${duplicate['description']} · '
                          '${appCurrencyController.format((duplicate['amount'] as num).toDouble())} · '
                          '${date == null ? '' : MaterialLocalizations.of(dialogContext).formatMediumDate(date)}'
                          '${hasReceipt ? '\n${dialogContext.l10n.text('receipt_has_attachment')}' : '\n${dialogContext.l10n.text('receipt_attach_existing')}'}',
                          textAlign: TextAlign.left,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(
                  dialogContext,
                  const _DuplicateReceiptDecision(
                    _DuplicateReceiptAction.cancel,
                  ),
                ),
                child: Text(dialogContext.l10n.text('cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(
                  dialogContext,
                  const _DuplicateReceiptDecision(
                    _DuplicateReceiptAction.create,
                  ),
                ),
                child: Text(dialogContext.l10n.text('receipt_save_duplicate')),
              ),
            ],
          ),
        );
        if (decision == null ||
            decision.action == _DuplicateReceiptAction.cancel) {
          if (mounted) setState(() => _isSaving = false);
          return;
        }
        if (decision.action == _DuplicateReceiptAction.attach) {
          String? imagePath;
          try {
            imagePath = await persistReceiptImage(receipt.imagePath);
            await _databaseHelper.attachReceiptToTransaction(
              transactionId: decision.transactionId!,
              amount: amount,
              date: transactionDate,
              imagePath: imagePath,
              items: jsonEncode(receipt.items),
              reference: receipt.reference,
            );
            if (!mounted) return;
            _amountController.clear();
            _descriptionController.clear();
            _noteController.clear();
            setState(() {
              _receiptDraft = null;
              selectedDate = DateTime.now();
              _isSaving = false;
            });
            _showSuccess(context.l10n.text('receipt_attached_existing'));
            return;
          } catch (error) {
            if (imagePath != null) {
              try {
                await deleteReceiptImage(imagePath);
              } catch (cleanupError) {
                debugPrint(
                  'No se pudo limpiar el comprobante temporal: $cleanupError',
                );
              }
            }
            if (!mounted) return;
            setState(() => _isSaving = false);
            _showMessage(movaText('No se pudo asociar el comprobante: $error'));
            return;
          }
        }
      }
    }

    String? persistedReceiptPath;
    try {
      if (receipt != null) {
        persistedReceiptPath = await persistReceiptImage(receipt.imagePath);
      }
      await _databaseHelper.insertTransaction(
        amount: amount,
        isIncome: transactionIsIncome,
        category: transactionCategory,
        description: description,
        date: transactionDate,
        note: transactionNote,
        accountId: transactionAccount?.id,
        currency: transactionAccount?.currency ?? appCurrencyController.code,
        receiptImagePath: persistedReceiptPath,
        receiptItems: receipt == null ? null : jsonEncode(receipt.items),
        receiptReference: receipt?.reference,
      );

      if (!mounted) return;
      _showSuccess(
        transactionIsIncome
            ? movaText('Ingreso guardado correctamente')
            : movaText('Gasto guardado correctamente'),
      );
      _amountController.clear();
      _descriptionController.clear();
      _noteController.clear();
      _receiptDraft = null;
      setState(() {
        selectedDate = DateTime.now();
        _isSaving = false;
      });
    } catch (error) {
      if (persistedReceiptPath != null) {
        try {
          await deleteReceiptImage(persistedReceiptPath);
        } catch (cleanupError) {
          debugPrint(
            'No se pudo limpiar el comprobante temporal: $cleanupError',
          );
        }
      }
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

  Future<void> _scanReceipt() async {
    final draft = await Navigator.push<ReceiptScanDraft>(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptScannerScreen(
          categories: expenseCategories
              .where(
                (category) =>
                    category['name'] != 'Ahorro' &&
                    category['name'] != 'Ahorro sin meta',
              )
              .map((category) => category['name']!)
              .toList(),
        ),
      ),
    );
    if (draft == null || !mounted) return;
    final accounts = await _accounts;
    if (!mounted) return;
    setState(() {
      isIncome = false;
      _receiptDraft = draft;
      _receiptCategoryConfirmed = draft.categorySelected;
      _amountController.text = draft.amount.toStringAsFixed(2);
      _descriptionController.text = draft.merchant;
      selectedDate = draft.date;
      selectedCategory = draft.category;
      _selectedAccount = accounts
          .where((account) => account.id == draft.accountId)
          .firstOrNull;
      _accountChoiceMade = draft.accountId != null;
    });
    _showSuccess(context.l10n.text('receipt_draft_attached'));
  }

  Future<void> _prepareReceiptWithNivo() async {
    final draft = _receiptDraft;
    if (draft == null || _isSaving) return;
    final categoryConfirmed =
        _receiptCategoryConfirmed || draft.categorySelected;
    final proposalDraft = ReceiptScanDraft(
      imagePath: draft.imagePath,
      merchant: draft.merchant,
      amount: draft.amount,
      date: draft.date,
      category: categoryConfirmed ? selectedCategory : '',
      categorySelected: categoryConfirmed,
      items: draft.items,
      reference: draft.reference,
      accountId: _selectedAccount?.id,
    );
    final registered = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => NivoScreen(initialReceiptDraft: proposalDraft),
      ),
    );
    if (!mounted || registered != true) return;
    setState(() {
      _receiptDraft = null;
      _receiptCategoryConfirmed = false;
      _amountController.clear();
      _descriptionController.clear();
      _noteController.clear();
      _selectedAccount = null;
      _accountChoiceMade = false;
      selectedDate = DateTime.now();
    });
    _showSuccess('Gasto registrado correctamente desde Nivo');
  }

  void _removeReceipt() {
    setState(() {
      _receiptDraft = null;
      _receiptCategoryConfirmed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentCategories = isIncome ? incomeCategories : expenseCategories;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                        colors: [Color(0xFF0C2340), Color(0xFF535353)],
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
                            color: Color(0xFF727272),
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
                  color: const Color(0xFFECECEC),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _isSaving
                            ? null
                            : () {
                                setState(() {
                                  isIncome = false;
                                  selectedCategory = "Comida";
                                });
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: !isIncome ? Colors.white : null,
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: !isIncome
                                ? const [
                                    BoxShadow(
                                      color: Color(0x120C2340),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_downward_rounded,
                                  size: 17,
                                  color: !isIncome
                                      ? MovaDesign.negative
                                      : MovaDesign.muted,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  l10n.text('expense'),
                                  style: TextStyle(
                                    color: MovaDesign.ink,
                                    fontWeight: FontWeight.w700,
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
                        onTap: _isSaving
                            ? null
                            : () {
                                setState(() {
                                  isIncome = true;
                                  selectedCategory = "Sueldo";
                                  _receiptDraft = null;
                                  if (_selectedAccount?.type ==
                                      FinancialAccountType.creditCard) {
                                    _selectedAccount = null;
                                    _accountChoiceMade = false;
                                  }
                                  if (_selectedAccount == null &&
                                      !_accountChoiceMade) {
                                    final cashAccounts = _loadedAccounts
                                        .where(
                                          (account) =>
                                              account.type ==
                                              FinancialAccountType.cash,
                                        )
                                        .toList();
                                    _selectedAccount = _defaultCashAccount(
                                      cashAccounts,
                                    );
                                  }
                                });
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: isIncome ? Colors.white : null,
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: isIncome
                                ? const [
                                    BoxShadow(
                                      color: Color(0x120C2340),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_upward_rounded,
                                  size: 17,
                                  color: isIncome
                                      ? MovaDesign.positive
                                      : MovaDesign.muted,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  l10n.text('income_singular'),
                                  style: TextStyle(
                                    color: MovaDesign.ink,
                                    fontWeight: FontWeight.w700,
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

              if (!isIncome && isReceiptScannerSupported) ...[
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : _scanReceipt,
                  icon: const Icon(Icons.document_scanner_outlined),
                  label: Text(l10n.text('receipt_scan')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    minimumSize: const Size.fromHeight(46),
                    side: BorderSide(
                      color: primaryColor.withValues(alpha: .35),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
                if (_receiptDraft != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: ReceiptImagePreview(
                              path: _receiptDraft!.imagePath,
                              height: 48,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.text('receipt_draft_attached'),
                            style: const TextStyle(
                              color: Color(0xFF102A43),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.text('receipt_remove'),
                          onPressed: _isSaving ? null : _removeReceipt,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : _prepareReceiptWithNivo,
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: Text(movaText('Revisar propuesta con Nivo')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
              ],

              // 3. CAMPO DE MONTO DINÁMICO
              Container(
                clipBehavior: Clip.antiAlias,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  gradient: MovaDesign.primaryGradient,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0x268CE1E8)),
                  boxShadow: MovaDesign.cardShadow,
                ),
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: MovaRadialHighlight(color: Color(0xFF9E9E9E)),
                    ),
                    Column(
                      children: [
                        Text(
                          isIncome
                              ? l10n.text('how_much_received')
                              : l10n.text('how_much'),
                          style: const TextStyle(
                            color: Color(0xFFD3D3D3),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 9),
                        TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textAlign: TextAlign.center,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                          decoration: InputDecoration(
                            prefixText: '\$ ',
                            prefixStyle: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFCFCFCF),
                            ),
                            hintText: movaText('0.00'),
                            hintStyle: TextStyle(
                              color: Color(0xFF8D8D8D),
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            filled: false,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 18,
                    color: primaryColor,
                  ),
                  SizedBox(width: 7),
                  Text(
                    l10n.text('account_optional'),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF102A43),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              FutureBuilder<List<FinancialAccount>>(
                future: _accounts,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(l10n.text('accounts_load_error'));
                  }
                  final accounts = (snapshot.data ?? [])
                      .where(
                        (account) =>
                            !isIncome ||
                            account.type != FinancialAccountType.creditCard,
                      )
                      .toList();
                  final selectedId =
                      accounts.any(
                        (account) => account.id == _selectedAccount?.id,
                      )
                      ? _selectedAccount!.id
                      : null;
                  return DropdownButtonFormField<int?>(
                    initialValue: selectedId,
                    decoration: InputDecoration(
                      hintText: l10n.text('no_account_selected'),
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
                    onChanged: (id) {
                      setState(() {
                        _selectedAccount = id == null
                            ? null
                            : accounts.firstWhere(
                                (account) => account.id == id,
                              );
                        _accountChoiceMade = true;
                      });
                    },
                  );
                },
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
                        if (_receiptDraft != null) {
                          _receiptCategoryConfirmed = true;
                        }
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
                                : Color(0xFFE7E7E7),
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
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
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
