import 'package:flutter/material.dart';

Future<void> showMovaFeedback(
  BuildContext context, {
  required String title,
  required String message,
  bool success = false,
}) {
  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color:
                    (success
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF0C2340))
                        .withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                success ? Icons.check_rounded : Icons.info_outline_rounded,
                color: success
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF0C2340),
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF102A43),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (Navigator.of(
                    dialogContext,
                    rootNavigator: true,
                  ).canPop()) {
                    Navigator.of(dialogContext, rootNavigator: true).pop();
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0C2340),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Entendido'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showMovaError(
  BuildContext context,
  String message, {
  String title = 'Algo salió mal',
}) {
  return showMovaFeedback(context, title: title, message: message);
}

Future<void> showMovaSuccess(
  BuildContext context,
  String message, {
  String title = 'Listo',
}) {
  return showMovaFeedback(
    context,
    title: title,
    message: message,
    success: true,
  );
}
