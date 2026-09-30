import 'dart:io';
import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

Future<String> persistReceiptImage(String sourcePath) async {
  final documents = await getApplicationDocumentsDirectory();
  final directory = Directory(path.join(documents.path, 'mova_receipts'));
  await directory.create(recursive: true);
  final extension = path.extension(sourcePath).toLowerCase();
  final safeExtension = RegExp(r'^\.(jpg|jpeg|png|webp)$').hasMatch(extension)
      ? extension
      : '.jpg';
  final destination = File(
    path.join(
      directory.path,
      'receipt_${DateTime.now().microsecondsSinceEpoch}$safeExtension',
    ),
  );
  await File(sourcePath).copy(destination.path);
  return destination.path;
}

Future<void> deleteReceiptImage(String imagePath) async {
  final file = File(imagePath);
  if (await file.exists()) await file.delete();
}

Future<String> exportReceiptImageAsBase64(String imagePath) async {
  final file = File(imagePath);
  if (!await file.exists()) {
    throw StateError('No se encontró el archivo del comprobante: $imagePath');
  }
  return base64Encode(await file.readAsBytes());
}

Future<String> persistReceiptImageBytes(List<int> bytes) async {
  final documents = await getApplicationDocumentsDirectory();
  final directory = Directory(path.join(documents.path, 'mova_receipts'));
  await directory.create(recursive: true);
  final destination = File(
    path.join(
      directory.path,
      'receipt_${DateTime.now().microsecondsSinceEpoch}.jpg',
    ),
  );
  await destination.writeAsBytes(bytes, flush: true);
  return destination.path;
}
