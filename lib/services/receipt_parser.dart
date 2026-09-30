import 'package:mova/models/receipt_scan_draft.dart';

ReceiptOcrData parseReceiptText(String text) {
  final lines = text
      .split(RegExp(r'[\r\n]+'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  final totalLines = lines.where(_isTotalLine).toList();
  final totalLine = totalLines.cast<String?>().firstWhere(
    (line) =>
        line != null &&
        RegExp(
          r'total\s+a\s+pagar|amount\s+due|grand\s+total',
          caseSensitive: false,
        ).hasMatch(line),
    orElse: () => totalLines.isEmpty ? null : totalLines.last,
  );
  final amount = totalLine == null ? null : _amountFromLine(totalLine);
  final date = _dateFromText(text);
  final merchant = _merchantFromLines(lines);
  final items = _itemsFromLines(lines, merchant);
  final referenceMatch = RegExp(
    r'(?:folio|ticket|ref(?:erencia)?|transacci[oó]n)\s*[:#-]?\s*([A-Z0-9-]{3,})',
    caseSensitive: false,
  ).firstMatch(text);

  return ReceiptOcrData(
    merchant: merchant,
    amount: amount,
    date: date,
    items: items,
    reference: referenceMatch?.group(1),
  );
}

bool _isTotalLine(String line) {
  final normalized = line.toLowerCase();
  if (RegExp(r'\b(subtotal|iva|impuesto|cambio|change|propina)\b')
      .hasMatch(normalized)) {
    return false;
  }
  return RegExp(
    r'\b(total|importe\s+total|amount\s+due|grand\s+total)\b',
    caseSensitive: false,
  ).hasMatch(line);
}

double? _amountFromLine(String line) {
  final matches = RegExp(r'\d[\d.,]*').allMatches(line).toList();
  if (matches.isEmpty) return null;
  final raw = matches.last.group(0)!;
  final lastComma = raw.lastIndexOf(',');
  final lastDot = raw.lastIndexOf('.');
  String normalized;
  if (lastComma >= 0 && lastDot >= 0) {
    final decimalSeparator = lastComma > lastDot ? ',' : '.';
    normalized = raw
        .replaceAll(decimalSeparator == ',' ? '.' : ',', '')
        .replaceAll(decimalSeparator, '.');
  } else {
    final separator = lastComma >= 0
        ? ','
        : lastDot >= 0
        ? '.'
        : '';
    if (separator.isEmpty) {
      normalized = raw;
    } else {
      final decimalDigits = raw.length - raw.lastIndexOf(separator) - 1;
      normalized = decimalDigits == 2
          ? raw.replaceAll(separator, '.')
          : raw.replaceAll(separator, '');
    }
  }
  final value = double.tryParse(normalized);
  return value != null && value > 0 ? value : null;
}

DateTime? _dateFromText(String text) {
  final isoDate = RegExp(r'\b(20\d{2})[-/.](\d{1,2})[-/.](\d{1,2})\b')
      .firstMatch(text);
  if (isoDate != null) {
    return _validDate(
      int.parse(isoDate.group(1)!),
      int.parse(isoDate.group(2)!),
      int.parse(isoDate.group(3)!),
    );
  }
  final localDate = RegExp(r'\b(\d{1,2})[-/.](\d{1,2})[-/.](20\d{2}|\d{2})\b')
      .firstMatch(text);
  if (localDate != null) {
    var year = int.parse(localDate.group(3)!);
    if (year < 100) year += 2000;
    return _validDate(
      year,
      int.parse(localDate.group(2)!),
      int.parse(localDate.group(1)!),
    );
  }
  return null;
}

DateTime? _validDate(int year, int month, int day) {
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  final date = DateTime(year, month, day);
  return date.year == year && date.month == month && date.day == day
      ? date
      : null;
}

String _merchantFromLines(List<String> lines) {
  for (final line in lines.take(8)) {
    final normalized = line.toLowerCase();
    if (line.length < 3 ||
        RegExp(r'\d{2,}').hasMatch(line) ||
        RegExp(
          r'\b(ticket|recibo|factura|gracias|thank|tel|rfc|total|fecha)\b',
          caseSensitive: false,
        ).hasMatch(normalized)) {
      continue;
    }
    return line;
  }
  return '';
}

List<String> _itemsFromLines(List<String> lines, String merchant) {
  final items = <String>[];
  var afterMerchant = merchant.isEmpty;
  for (final line in lines) {
    if (!afterMerchant) {
      if (line == merchant) afterMerchant = true;
      continue;
    }
    if (_isTotalLine(line) ||
        RegExp(
          r'\b(subtotal|iva|impuesto|cambio|total)\b',
          caseSensitive: false,
        ).hasMatch(line)) {
      break;
    }
    if (RegExp(r'\d').hasMatch(line) &&
        !RegExp(r'\d{1,2}[-/.]\d{1,2}[-/.]\d{2,4}').hasMatch(line) &&
        !RegExp(
          r'\b(folio|ticket|ref(?:erencia)?)\b',
          caseSensitive: false,
        ).hasMatch(line)) {
      items.add(line);
      if (items.length == 20) break;
    }
  }
  return items;
}

String? suggestReceiptCategory(String text, List<String> categories) {
  final value = text.toLowerCase();
  final suggestions = <List<String>>[
    ['comida', 'restaurante', 'restaurant', 'cafe', 'cafeter', 'supermercado'],
    ['transporte', 'uber', 'didi', 'gasolin', 'estacionamiento'],
    ['entretenimiento', 'netflix', 'spotify', 'disney', 'cine'],
    ['hogar', 'internet', 'electricidad', 'agua', 'luz'],
    ['compras', 'tienda', 'market', 'amazon'],
  ];
  for (var i = 0; i < suggestions.length; i++) {
    if (!suggestions[i].any(value.contains)) continue;
    final match = categories.where(
      (category) => category.toLowerCase() == suggestions[i][0],
    );
    if (match.isNotEmpty) return match.first;
  }
  return categories
      .where((category) => category.toLowerCase() == 'otros')
      .firstOrNull;
}
