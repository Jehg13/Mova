import 'package:flutter/material.dart';

class ReceiptImagePreview extends StatelessWidget {
  const ReceiptImagePreview({required this.path, this.height = 180, super.key});

  final String path;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(
        child: Icon(Icons.receipt_long_outlined, color: Colors.white70),
      ),
    );
  }
}
