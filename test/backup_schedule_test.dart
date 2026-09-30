import 'package:flutter_test/flutter_test.dart';
import 'package:mova/services/backup_schedule.dart';

void main() {
  test('calculates daily and weekly automatic backup times', () {
    final last = DateTime(2026, 9, 30, 10, 35);

    expect(BackupSchedule.next(last, 'daily'), DateTime(2026, 10, 1, 10, 35));
    expect(BackupSchedule.next(last, 'weekly'), DateTime(2026, 10, 7, 10, 35));
  });

  test('monthly schedule clamps at month end and respects due time', () {
    final last = DateTime(2026, 1, 31, 10, 35);

    expect(BackupSchedule.next(last, 'monthly'), DateTime(2026, 2, 28, 10, 35));
    expect(
      BackupSchedule.isDue(
        last: last,
        frequency: 'monthly',
        now: DateTime(2026, 2, 28, 10, 34),
      ),
      isFalse,
    );
    expect(
      BackupSchedule.isDue(
        last: last,
        frequency: 'monthly',
        now: DateTime(2026, 2, 28, 10, 35),
      ),
      isTrue,
    );
  });
}
