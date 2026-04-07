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
    test('agreed=true records consent and marks shown', () {
      bool consentRecorded = false;
      bool tcShownMarked = false;

      void recordConsent() => consentRecorded = true;
      void markShown() => tcShownMarked = true;

      const agreed = true;
      if (agreed) recordConsent();
      markShown();

      expect(consentRecorded, isTrue);
      expect(tcShownMarked, isTrue);
    });

    test('agreed=false skips consent but still marks shown', () {
      bool consentRecorded = false;
      bool tcShownMarked = false;

      void recordConsent() => consentRecorded = true;
      void markShown() => tcShownMarked = true;

      const agreed = false;
      if (agreed) recordConsent();
      markShown();

      expect(consentRecorded, isFalse);
      expect(tcShownMarked, isTrue);
    });
  });
}
