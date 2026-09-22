import 'dart:typed_data';

import 'goal_image_picker_io.dart'
    if (dart.library.js_interop) 'goal_image_picker_web.dart';

Future<Uint8List?> pickGoalImage() => pickGoalImageImpl();
