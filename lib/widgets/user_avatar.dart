import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mova/database/database_helper.dart';

final profileChanged = ValueNotifier<int>(0);

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, this.radius = 20});

  final double radius;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: profileChanged,
      builder: (context, _, __) => FutureBuilder<Map<String, dynamic>?>(
        future: DatabaseHelper().getCurrentUser(),
        builder: (context, snapshot) {
          final raw = snapshot.data?['profile_image'];
          final image = raw is Uint8List
              ? raw
              : raw is List
              ? Uint8List.fromList(raw.cast<int>())
              : null;
          return CircleAvatar(
            radius: radius,
            backgroundColor: const Color(0xFFCBD5E1),
            backgroundImage: image != null && image.isNotEmpty
                ? MemoryImage(image)
                : null,
            child: image == null || image.isEmpty
                ? Icon(Icons.person, color: Colors.white, size: radius)
                : null,
          );
        },
      ),
    );
  }
}
