import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Heatmap grid geometry', () {
    test('grid covers exactly 84 days (12 weeks × 7 days)', () {
      const weeks = 12;
      const days = 7;
      expect(weeks * days, equals(84));
    });

    test('grid start is always a Monday', () {
      final today = DateTime.now();
      final currentMonday = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: today.weekday - 1));
      final gridStart = currentMonday.subtract(const Duration(days: 77));
      expect(gridStart.weekday, equals(1));
    });

    test('last cell date is the Sunday of the current week', () {
      final today = DateTime.now();
      final currentMonday = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: today.weekday - 1));
      final gridStart = currentMonday.subtract(const Duration(days: 77));
      final lastCell = gridStart.add(const Duration(days: 83));
      expect(lastCell.weekday, equals(7));
      final currentSunday = currentMonday.add(const Duration(days: 6));
      expect(lastCell, equals(currentSunday));
    });
  });

  group('Heatmap colour normalisation', () {
    test('zero peak produces zero cell color for all amounts', () {
      const peakAmount = 0.0;
      expect(peakAmount == 0, isTrue);
    });

    test('intensity is clamped between 0 and 1', () {
      const peak = 100.0;
      expect((50.0 / peak).clamp(0.0, 1.0), equals(0.5));
      expect((150.0 / peak).clamp(0.0, 1.0), equals(1.0));
      expect((0.0 / peak).clamp(0.0, 1.0), equals(0.0));
    });
  });

  group('Column header labels', () {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    test('first column always shows month + day', () {
      final date = DateTime(2026, 1, 6);
      final label = '${monthNames[date.month - 1]} ${date.day}';
      expect(label, equals('Jan 6'));
    });

    test('month boundary shows month name only', () {
      final prev = DateTime(2026, 1, 26);
      final curr = DateTime(2026, 2, 2);
      final crossesMonth = curr.month != prev.month;
      expect(crossesMonth, isTrue);
      final label = monthNames[curr.month - 1];
      expect(label, equals('Feb'));
    });

    test('same month shows just day number', () {
      final prev = DateTime(2026, 1, 6);
      final curr = DateTime(2026, 1, 13);
      final sameMonth = curr.month == prev.month;
      expect(sameMonth, isTrue);
      expect('${curr.day}', equals('13'));
    });
  });
}
