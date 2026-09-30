Future<String> persistReceiptImage(String sourcePath) {
  throw UnsupportedError(
    'El almacenamiento local de comprobantes no está disponible en web.',
  );
}

Future<void> deleteReceiptImage(String imagePath) async {}

Future<String> exportReceiptImageAsBase64(String imagePath) {
  throw UnsupportedError(
    'El almacenamiento local de comprobantes no está disponible en web.',
  );
}

Future<String> persistReceiptImageBytes(List<int> bytes) {
  throw UnsupportedError(
    'El almacenamiento local de comprobantes no está disponible en web.',
  );
}
