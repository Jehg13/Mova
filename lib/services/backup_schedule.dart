class BackupSchedule {
  static DateTime next(DateTime last, String frequency) {
    switch (frequency) {
      case 'daily':
        return last.add(const Duration(days: 1));
      case 'monthly':
        final nextMonth = DateTime(last.year, last.month + 1);
        final day =
            last.day < DateTime(nextMonth.year, nextMonth.month + 1, 0).day
            ? last.day
            : DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
        return DateTime(
          nextMonth.year,
          nextMonth.month,
          day,
          last.hour,
          last.minute,
          last.second,
        );
      default:
        return last.add(const Duration(days: 7));
    }
  }

  static bool isDue({
    required DateTime? last,
    required String frequency,
    required DateTime now,
  }) => last == null || !now.isBefore(next(last, frequency));
}
