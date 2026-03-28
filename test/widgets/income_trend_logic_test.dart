import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Income trend MoM calculation', () {
    test('positive income growth', () {
      const prev = 4000.0;
      const current = 4500.0;
      final momChange = ((current - prev) / prev) * 100;
      expect(momChange, closeTo(12.5, 0.01));
    });

    test('negative income decline', () {
      const prev = 5000.0;
      const current = 4200.0;
      final momChange = ((current - prev) / prev) * 100;
      expect(momChange, closeTo(-16.0, 0.01));
    });

    test('zero previous income avoids division by zero', () {
      const prev = 0.0;
      double momChange = 0;
      if (prev > 0) {
        momChange = ((4000.0 - prev) / prev) * 100;
      }
      expect(momChange, equals(0.0));
    });

    test('identical months yields 0% change', () {
      const prev = 3000.0;
      const current = 3000.0;
      final momChange = ((current - prev) / prev) * 100;
      expect(momChange, equals(0.0));
    });
  });

  group('Net cash flow', () {
    test('surplus when income exceeds expenses', () {
      const income = 5000.0;
      const expense = 3500.0;
      expect(income - expense, equals(1500.0));
      expect(income - expense > 0, isTrue);
    });

    test('deficit when expenses exceed income', () {
      const income = 2000.0;
      const expense = 3200.0;
      expect(income - expense, equals(-1200.0));
      expect(income - expense < 0, isTrue);
    });
  });

  group('Rolling 12-month window', () {
    test('more than 12 months keeps only the last 12', () {
      final allKeys = List.generate(
          15, (i) => '2024-${(i + 1).toString().padLeft(2, '0')}');
      final displayKeys = allKeys.length > 12
          ? allKeys.sublist(allKeys.length - 12)
          : allKeys;
      expect(displayKeys.length, equals(12));
      expect(displayKeys.first, equals('2024-04'));
    });

    test('fewer than 12 months shows all', () {
      final allKeys = ['2025-01', '2025-02', '2025-03'];
      final displayKeys = allKeys.length > 12
          ? allKeys.sublist(allKeys.length - 12)
          : allKeys;
      expect(displayKeys.length, equals(3));
    });
  });
}
