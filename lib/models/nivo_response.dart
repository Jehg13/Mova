import 'nivo_query.dart';

class NivoResponse {
  const NivoResponse({
    required this.text,
    required this.confidence,
    this.intent,
    this.data = const {},
    this.requiresClarification = false,
    this.requiresConfirmation = false,
  });

  final String text;
  final NivoConfidence confidence;
  final NivoIntent? intent;
  final Map<String, Object?> data;
  final bool requiresClarification;
  final bool requiresConfirmation;
}
