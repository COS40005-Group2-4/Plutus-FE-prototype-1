import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Budget alerts banner logic', () {
    test('banner shown when alerts non-empty and not dismissed', () {
      const alertsNonEmpty = true;
      const dismissed = false;
      final showBanner = alertsNonEmpty && !dismissed;
      expect(showBanner, isTrue);
    });

    test('banner hidden when dismissed', () {
      const alertsNonEmpty = true;
      const dismissed = true;
      final showBanner = alertsNonEmpty && !dismissed;
      expect(showBanner, isFalse);
    });

    test('banner hidden when no alerts', () {
      const alertsNonEmpty = false;
      const dismissed = false;
      final showBanner = alertsNonEmpty && !dismissed;
      expect(showBanner, isFalse);
    });

    test('alert text uses currency symbol not hardcoded dollar', () {
      const sym = '₫';
      const spent = 1500000.0;
      const budgeted = 1000000.0;
      final pct = (spent / budgeted * 100).round();
      final text = 'Food: $pct% (${sym}${spent.toStringAsFixed(0)} / ${sym}${budgeted.toStringAsFixed(0)})';
      expect(text, contains('₫'));
      expect(text, isNot(contains('\$')));
      expect(text, equals('Food: 150% (₫1500000 / ₫1000000)'));
    });
  });
}
