import 'dart:convert';
import 'dart:math';

class SharedGoalPayload {
  static const type = 'mova.shared_goal';
  static const version = 1;

  final String id;
  final String name;
  final double targetAmount;
  final String icon;

  const SharedGoalPayload({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.icon,
  });

  String encode() => jsonEncode({
    'type': type,
    'v': version,
    'id': id,
    'name': name,
    'target': targetAmount,
    'icon': icon,
  });

  static SharedGoalPayload parse(String input) {
    final value = _decode(input);
    if (value['type'] != type || value['v'] != version) {
      throw const FormatException('QR de meta no compatible');
    }
    final id = value['id'];
    final name = value['name'];
    final target = value['target'];
    if (id is! String || !_isId(id) || name is! String || name.trim().isEmpty) {
      throw const FormatException('Datos de meta inválidos');
    }
    final amount = target is num ? target.toDouble() : double.nan;
    if (!amount.isFinite || amount <= 0) {
      throw const FormatException('Monto objetivo inválido');
    }
    return SharedGoalPayload(
      id: id,
      name: name.trim(),
      targetAmount: amount,
      icon: value['icon'] is String ? value['icon'] as String : 'flag',
    );
  }

  static Map<String, dynamic> _decode(String input) {
    try {
      final decoded = jsonDecode(input.trim());
      if (decoded is! Map) throw const FormatException();
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      throw const FormatException('QR inválido');
    }
  }

  static bool _isId(String value) => RegExp(
    r'^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$',
  ).hasMatch(value);
}

class ContributionPayload {
  static const type = 'mova.contribution';
  static const version = 1;

  final String contributionId;
  final String goalId;
  final String contributor;
  final double amount;

  const ContributionPayload({
    required this.contributionId,
    required this.goalId,
    required this.contributor,
    required this.amount,
  });

  String encode() => jsonEncode({
    'type': type,
    'v': version,
    'id': contributionId,
    'goal': goalId,
    'by': contributor,
    'amount': amount,
  });

  static ContributionPayload parse(String input) {
    final value = jsonDecode(input.trim());
    if (value is! Map || value['type'] != type || value['v'] != version) {
      throw const FormatException('QR de aporte no compatible');
    }
    final id = value['id'];
    final goal = value['goal'];
    final by = value['by'];
    final amount = value['amount'];
    if (id is! String ||
        goal is! String ||
        !_isId(id) ||
        !_isId(goal) ||
        by is! String ||
        by.trim().isEmpty ||
        amount is! num ||
        !amount.toDouble().isFinite ||
        amount <= 0) {
      throw const FormatException('Datos de aporte inválidos');
    }
    return ContributionPayload(
      contributionId: id,
      goalId: goal,
      contributor: by.trim(),
      amount: amount.toDouble(),
    );
  }

  static bool _isId(String value) => RegExp(
    r'^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$',
  ).hasMatch(value);
}

String newSharedId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
