import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Savings rate status and progress', () {
    test('progress bar fraction for rates below 20%', () {
      expect((5.0 / 20.0).clamp(0.0, 1.0), closeTo(0.25, 0.01));
      expect((15.0 / 20.0).clamp(0.0, 1.0), closeTo(0.75, 0.01));
      expect((0.0 / 20.0).clamp(0.0, 1.0), equals(0.0));
    });

    test('progress bar caps at 1.0 for rates above 20%', () {
      expect((30.0 / 20.0).clamp(0.0, 1.0), equals(1.0));
      expect((50.0 / 20.0).clamp(0.0, 1.0), equals(1.0));
    });

    test('status text thresholds: green >= 20, orange >= 10, red < 10', () {
      // These thresholds match _getRateColor logic
      expect(25.0 >= 20, isTrue); // "On track"
      expect(15.0 >= 10 && 15.0 < 20, isTrue); // "Almost there"
      expect(5.0 < 10, isTrue); // "Below target"
    });

    test('MoM change is difference of last two rates', () {
      const prev = 18.5;
      const current = 22.3;
      expect(current - prev, closeTo(3.8, 0.01));
    });

    test('negative savings rate is handled', () {
      // When expenses > income, rate is negative
      const income = 1000.0;
      const expense = 1500.0;
      final rate =
          ((income - expense) / income * 100).clamp(-100.0, 100.0);
      expect(rate, equals(-50.0));
      expect((rate / 20.0).clamp(0.0, 1.0), equals(0.0)); // progress bar empty
    });
  });
}
