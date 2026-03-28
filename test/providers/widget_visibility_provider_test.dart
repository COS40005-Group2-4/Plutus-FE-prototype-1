import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plutus_fe_prototype/providers/widget_visibility_provider.dart';

void main() {
  group('WidgetVisibilityProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('all widgets visible by default', () async {
      final provider = WidgetVisibilityProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.visibleWidgetsCount, 19);
      expect(provider.getVisibleWidgets().length, 19);
      expect(provider.hiddenWidgetIds, isEmpty);
    });

    test('isWidgetVisible returns true for known widgets', () async {
      final provider = WidgetVisibilityProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.isWidgetVisible('profile'), true);
      expect(provider.isWidgetVisible('budget'), true);
      expect(provider.isWidgetVisible('investment'), true);
    });

    test('isWidgetVisible returns true for unknown widget', () async {
      final provider = WidgetVisibilityProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.isWidgetVisible('nonexistent'), true);
    });

    test('hideWidget hides a widget and notifies', () async {
      final provider = WidgetVisibilityProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      bool notified = false;
      provider.addListener(() => notified = true);

      await provider.hideWidget('profile');

      expect(provider.isWidgetVisible('profile'), false);
      expect(provider.visibleWidgetsCount, 18);
      expect(provider.hiddenWidgetIds, contains('profile'));
      expect(notified, true);
    });

    test('showWidget shows a hidden widget', () async {
      final provider = WidgetVisibilityProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.hideWidget('budget');
      expect(provider.isWidgetVisible('budget'), false);

      await provider.showWidget('budget');
      expect(provider.isWidgetVisible('budget'), true);
    });

    test('toggleWidget flips visibility', () async {
      final provider = WidgetVisibilityProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.toggleWidget('roi');
      expect(provider.isWidgetVisible('roi'), false);

      await provider.toggleWidget('roi');
      expect(provider.isWidgetVisible('roi'), true);
    });

    test('hideWidget is no-op for unknown widget', () async {
      final provider = WidgetVisibilityProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.hideWidget('nonexistent');
      expect(provider.visibleWidgetsCount, 19);
    });

    test('reset makes all widgets visible', () async {
      final provider = WidgetVisibilityProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.hideWidget('profile');
      await provider.hideWidget('budget');
      await provider.hideWidget('history');
      expect(provider.visibleWidgetsCount, 16);

      provider.reset();
      expect(provider.visibleWidgetsCount, 19);
    });

    test('getVisibleWidgets returns only visible ones', () async {
      final provider = WidgetVisibilityProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.hideWidget('roi');
      await provider.hideWidget('irr');

      final visible = provider.getVisibleWidgets();
      expect(visible, isNot(contains('roi')));
      expect(visible, isNot(contains('irr')));
      expect(visible.length, 17);
    });

    test('persistence: saves and loads visibility', () async {
      // First instance: hide some widgets
      final provider1 = WidgetVisibilityProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      await provider1.hideWidget('profile');
      await provider1.hideWidget('tax');

      // Second instance should load saved state
      final provider2 = WidgetVisibilityProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider2.isWidgetVisible('profile'), false);
      expect(provider2.isWidgetVisible('tax'), false);
      expect(provider2.isWidgetVisible('budget'), true);
    });

    test('isInitialized becomes true after setup', () async {
      final provider = WidgetVisibilityProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.isInitialized, true);
    });
  });
}
