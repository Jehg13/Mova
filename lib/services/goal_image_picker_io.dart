import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

Future<Uint8List?> pickGoalImageImpl() async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
    maxWidth: 1200,
  );
  return file == null ? null : file.readAsBytes();
}
