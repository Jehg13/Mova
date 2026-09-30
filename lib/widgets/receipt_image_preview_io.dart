import 'dart:io';

import 'package:flutter/material.dart';

class ReceiptImagePreview extends StatelessWidget {
  const ReceiptImagePreview({required this.path, this.height = 180, super.key});

  final String path;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(path),
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.white70),
      ),
    );
  }
}
