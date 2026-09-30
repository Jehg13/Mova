import 'package:flutter_test/flutter_test.dart';
import 'package:mova/services/receipt_parser.dart';

void main() {
  group('parseReceiptText', () {
    test('extracts merchant, explicit total, local date and reference', () {
      final receipt = parseReceiptText('''
CAFETERIA LUNA
Fecha: 15/09/2026
Folio: AB12345
Cafe americano 45.00
Subtotal 45.00
IVA 7.20
TOTAL A PAGAR: \$ 1,234.56
''');

      expect(receipt.merchant, 'CAFETERIA LUNA');
      expect(receipt.amount, 1234.56);
      expect(receipt.date, DateTime(2026, 9, 15));
      expect(receipt.reference, 'AB12345');
      expect(receipt.items, contains('Cafe americano 45.00'));
      expect(receipt.items, isNot(contains('Fecha: 15/09/2026')));
      expect(receipt.items, isNot(contains('Subtotal 45.00')));
      expect(receipt.items, isNot(contains('IVA 7.20')));
    });

    test('does not treat subtotal, tax or change as the total', () {
      final receipt = parseReceiptText('''
TIENDA
Subtotal 450.00
IVA 72.00
Cambio 100.00
''');

      expect(receipt.amount, isNull);
    });

    test('supports comma decimal totals and validates dates', () {
      final receipt = parseReceiptText('''
SERVICIO
Fecha 2026-10-02
TOTAL: \$ 219,50
''');

      expect(receipt.amount, 219.5);
      expect(receipt.date, DateTime(2026, 10, 2));
    });

    test('suggests only a category that exists in MOVA', () {
      expect(
        suggestReceiptCategory('Netflix monthly charge', [
          'Comida',
          'Entretenimiento',
          'Otros',
        ]),
        'Entretenimiento',
      );
      expect(suggestReceiptCategory('pharmacy', ['Comida', 'Otros']), 'Otros');
    });
  });
}
