import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/shared_goal.dart';

void main() {
  test('shared goal payload round trips and rejects malformed data', () {
    final payload = SharedGoalPayload(
      id: '12345678-1234-4234-9234-123456789abc',
      name: 'Viaje',
      targetAmount: 1200,
      icon: 'travel',
    );
    expect(SharedGoalPayload.parse(payload.encode()).name, 'Viaje');
    expect(() => SharedGoalPayload.parse('{}'), throwsFormatException);
    expect(
      () => SharedGoalPayload.parse(
        '{"type":"mova.shared_goal","v":1,"id":"bad","name":"x","target":1}',
      ),
      throwsFormatException,
    );
  });

  test('contribution payload validates positive amounts and ids', () {
    final payload = ContributionPayload(
      contributionId: '12345678-1234-4234-9234-123456789abc',
      goalId: 'abcdefab-cdef-4abc-8def-abcdefabcdef',
      contributor: 'Ana',
      amount: 25,
    );
    expect(ContributionPayload.parse(payload.encode()).amount, 25);
    expect(
      () => ContributionPayload.parse(
        '{"type":"mova.contribution","v":1,"id":"${payload.contributionId}",'
        '"goal":"${payload.goalId}","by":"Ana","amount":0}',
      ),
      throwsFormatException,
    );
  });
}
