import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mova/models/receipt_scan_draft.dart';
import 'package:mova/services/receipt_parser.dart';

Future<ReceiptOcrData> recognizeReceipt(String imagePath) async {
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final result = await recognizer.processImage(
      InputImage.fromFilePath(imagePath),
    );
    return parseReceiptText(result.text);
  } finally {
    await recognizer.close();
  }
}
