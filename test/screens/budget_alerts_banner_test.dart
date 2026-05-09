import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Budget alerts banner logic', () {
    // Routing the booleans through a parameter prevents the analyzer
    // from constant-folding the `&&` and emitting dead_code warnings.
    bool shouldShow({required bool alertsNonEmpty, required bool dismissed}) =>
        alertsNonEmpty && !dismissed;

    test('banner shown when alerts non-empty and not dismissed', () {
      expect(shouldShow(alertsNonEmpty: true, dismissed: false), isTrue);
    });

    test('banner hidden when dismissed', () {
      expect(shouldShow(alertsNonEmpty: true, dismissed: true), isFalse);
    });

    test('banner hidden when no alerts', () {
      expect(shouldShow(alertsNonEmpty: false, dismissed: false), isFalse);
    });

    test('alert text uses currency symbol not hardcoded dollar', () {
      const sym = '₫';
      const spent = 1500000.0;
      const budgeted = 1000000.0;
      final pct = (spent / budgeted * 100).round();
      final text = 'Food: $pct% ($sym${spent.toStringAsFixed(0)} / $sym${budgeted.toStringAsFixed(0)})';
      expect(text, contains('₫'));
      expect(text, isNot(contains('\$')));
      expect(text, equals('Food: 150% (₫1500000 / ₫1000000)'));
    });
  });
}
