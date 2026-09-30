class ReceiptScanDraft {
  const ReceiptScanDraft({
    required this.imagePath,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
    required this.items,
    required this.reference,
    required this.accountId,
    this.categorySelected = false,
  });

  final String imagePath;
  final String merchant;
  final double amount;
  final DateTime date;
  final String category;
  final bool categorySelected;
  final List<String> items;
  final String? reference;
  final int? accountId;
}

class ReceiptOcrData {
  const ReceiptOcrData({
    required this.merchant,
    required this.amount,
    required this.date,
    required this.items,
    required this.reference,
  });

  final String merchant;
  final double? amount;
  final DateTime? date;
  final List<String> items;
  final String? reference;
}
