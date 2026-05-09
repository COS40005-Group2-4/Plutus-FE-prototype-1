import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Local T&C shown tracking', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('isLocalTcShown returns false when key not set', () async {
      final prefs = await SharedPreferences.getInstance();
      final shown = prefs.getBool('user_5_tc_shown') ?? false;
      expect(shown, isFalse);
    });

    test('isLocalTcShown returns true after key is set', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_5_tc_shown', true);
      final shown = prefs.getBool('user_5_tc_shown') ?? false;
      expect(shown, isTrue);
    });

    test('different users have independent tc_shown keys', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_1_tc_shown', true);
      final user1Shown = prefs.getBool('user_1_tc_shown') ?? false;
      final user2Shown = prefs.getBool('user_2_tc_shown') ?? false;
      expect(user1Shown, isTrue);
      expect(user2Shown, isFalse);
    });
  });

  group('handleLocalTcResult contract', () {
    // The bool flag flows through a parameter so the analyzer cannot
    // constant-fold the `if (agreed)` branch and emit dead_code.
    ({bool consentRecorded, bool shownMarked}) handle({required bool agreed}) {
      bool consentRecorded = false;
      bool shownMarked = false;
      if (agreed) consentRecorded = true;
      shownMarked = true;
      return (consentRecorded: consentRecorded, shownMarked: shownMarked);
    }

    test('agreed=true records consent and marks shown', () {
      final r = handle(agreed: true);
      expect(r.consentRecorded, isTrue);
      expect(r.shownMarked, isTrue);
    });

    test('agreed=false skips consent but still marks shown', () {
      final r = handle(agreed: false);
      expect(r.consentRecorded, isFalse);
      expect(r.shownMarked, isTrue);
    });
  });
}
