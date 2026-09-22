import 'dart:typed_data';

import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:image_picker_for_web/image_picker_for_web.dart';

Future<Uint8List?> pickGoalImageImpl() async {
  final file = await ImagePickerPlugin().getImageFromSource(
    source: ImageSource.gallery,
    options: const ImagePickerOptions(imageQuality: 85, maxWidth: 1200),
  );
  return file == null ? null : file.readAsBytes();
}
