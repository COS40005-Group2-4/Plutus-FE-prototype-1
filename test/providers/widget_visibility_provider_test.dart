import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plutus_fe_prototype/providers/widget_visibility_notifier.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('WidgetVisibilityNotifier', () {
    test('all widgets visible by default', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(widgetVisibilityNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(widgetVisibilityNotifierProvider);
      expect(state.visibleCount, 23);
      expect(state.visibleWidgets.length, 23);
      expect(state.hiddenWidgetIds, isEmpty);
    });

    test('isWidgetVisible returns true for known widgets', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(widgetVisibilityNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(widgetVisibilityNotifierProvider);
      expect(state.isWidgetVisible('profile'), true);
      expect(state.isWidgetVisible('budget'), true);
      expect(state.isWidgetVisible('investment'), true);
    });

    test('isWidgetVisible returns true for unknown widget', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(widgetVisibilityNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(widgetVisibilityNotifierProvider);
      expect(state.isWidgetVisible('nonexistent'), true);
    });

    test('hideWidget hides a widget and notifies', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(widgetVisibilityNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      bool notified = false;
      container.listen(widgetVisibilityNotifierProvider, (_, _) {
        notified = true;
      });

      final notifier = container.read(widgetVisibilityNotifierProvider.notifier);
      await notifier.hideWidget('profile');

      final state = container.read(widgetVisibilityNotifierProvider);
      expect(state.isWidgetVisible('profile'), false);
      expect(state.visibleCount, 22);
      expect(state.hiddenWidgetIds, contains('profile'));
      expect(notified, true);
    });

    test('showWidget shows a hidden widget', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(widgetVisibilityNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(widgetVisibilityNotifierProvider.notifier);
      await notifier.hideWidget('budget');
      expect(
          container.read(widgetVisibilityNotifierProvider).isWidgetVisible('budget'),
          false);

      await notifier.showWidget('budget');
      expect(
          container.read(widgetVisibilityNotifierProvider).isWidgetVisible('budget'),
          true);
    });

    test('toggleWidget flips visibility', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(widgetVisibilityNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(widgetVisibilityNotifierProvider.notifier);
      await notifier.toggleWidget('roi');
      expect(
          container.read(widgetVisibilityNotifierProvider).isWidgetVisible('roi'),
          false);

      await notifier.toggleWidget('roi');
      expect(
          container.read(widgetVisibilityNotifierProvider).isWidgetVisible('roi'),
          true);
    });

    test('hideWidget is no-op for unknown widget', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(widgetVisibilityNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(widgetVisibilityNotifierProvider.notifier);
      await notifier.hideWidget('nonexistent');

      final state = container.read(widgetVisibilityNotifierProvider);
      expect(state.visibleCount, 23);
    });

    test('reset makes all widgets visible', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(widgetVisibilityNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(widgetVisibilityNotifierProvider.notifier);
      await notifier.hideWidget('profile');
      await notifier.hideWidget('budget');
      await notifier.hideWidget('history');
      expect(container.read(widgetVisibilityNotifierProvider).visibleCount, 20);

      await notifier.reset();
      expect(container.read(widgetVisibilityNotifierProvider).visibleCount, 23);
    });

    test('getVisibleWidgets returns only visible ones', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(widgetVisibilityNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(widgetVisibilityNotifierProvider.notifier);
      await notifier.hideWidget('roi');
      await notifier.hideWidget('irr');

      final state = container.read(widgetVisibilityNotifierProvider);
      expect(state.visibleWidgets, isNot(contains('roi')));
      expect(state.visibleWidgets, isNot(contains('irr')));
      expect(state.visibleWidgets.length, 21);
    });

    test('persistence: saves and loads visibility', () async {
      // First container: hide some widgets
      final container1 = ProviderContainer();
      addTearDown(container1.dispose);

      container1.read(widgetVisibilityNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier1 =
          container1.read(widgetVisibilityNotifierProvider.notifier);
      await notifier1.hideWidget('profile');
      await notifier1.hideWidget('tax');

      // Second container should load saved state
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      container2.read(widgetVisibilityNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final state2 = container2.read(widgetVisibilityNotifierProvider);
      expect(state2.isWidgetVisible('profile'), false);
      expect(state2.isWidgetVisible('tax'), false);
      expect(state2.isWidgetVisible('budget'), true);
    });

    test('isInitialized becomes true after setup', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(widgetVisibilityNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(widgetVisibilityNotifierProvider);
      expect(state.isInitialized, true);
    });
  });
}
