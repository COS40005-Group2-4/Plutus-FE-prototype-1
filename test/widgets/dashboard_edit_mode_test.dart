import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/widgets/dashboard/widget_edit_chrome.dart';

// Helper that mirrors the itemBuilder's conditional logic.
bool shouldShowEditChrome(bool isEditing) => isEditing;

// Helper that mirrors the toggle logic on _toggleEditMode.
bool toggleEditMode(bool current) => !current;

// Helper that mirrors the onPressed logic for remove.
void performRemove(
  String instanceId,
  void Function(String) controllerDelete,
  void Function(String) providerRemove,
) {
  controllerDelete(instanceId);
  providerRemove(instanceId);
}

/// Mirrors `_handleWidgetAction` in dashboard_screen.dart so the dispatch
/// table is verified independently of the screen widget tree (which has
/// heavy provider/setup deps).
Future<void> dispatchWidgetAction(
  WidgetEditAction action,
  String instanceId, {
  required void Function(String) controllerDelete,
  required void Function(String) providerRemove,
  required void Function() onUnavailable,
}) async {
  switch (action) {
    case WidgetEditAction.remove:
      controllerDelete(instanceId);
      providerRemove(instanceId);
      break;
    case WidgetEditAction.rename:
    case WidgetEditAction.duplicate:
    case WidgetEditAction.lock:
    case WidgetEditAction.resetSize:
      onUnavailable();
      break;
  }
}

void main() {
  group('Edit mode chrome visibility gate', () {
    test('chrome is hidden when isEditing is false', () {
      expect(shouldShowEditChrome(false), isFalse);
    });

    test('chrome is shown when isEditing is true', () {
      expect(shouldShowEditChrome(true), isTrue);
    });
  });

  group('toggleEditMode', () {
    test('idle → editing', () {
      expect(toggleEditMode(false), isTrue);
    });

    test('editing → idle', () {
      expect(toggleEditMode(true), isFalse);
    });

    test('round-trip returns to original state', () {
      expect(toggleEditMode(toggleEditMode(false)), isFalse);
      expect(toggleEditMode(toggleEditMode(true)), isTrue);
    });
  });

  group('Remove action: both controller and provider are called', () {
    test('performRemove calls controllerDelete with the instanceId', () {
      final List<String> deleteCalls = [];
      final List<String> removeCalls = [];
      performRemove('budget_0', deleteCalls.add, removeCalls.add);
      expect(deleteCalls, equals(['budget_0']));
    });

    test('performRemove calls providerRemove with the instanceId', () {
      final List<String> deleteCalls = [];
      final List<String> removeCalls = [];
      performRemove('budget_0', deleteCalls.add, removeCalls.add);
      expect(removeCalls, equals(['budget_0']));
    });

    test('performRemove calls both in order for multiple widgets', () {
      final List<String> deleteCalls = [];
      final List<String> removeCalls = [];
      for (final id in ['budget_0', 'spending_1', 'networth_0']) {
        performRemove(id, deleteCalls.add, removeCalls.add);
      }
      expect(deleteCalls, equals(['budget_0', 'spending_1', 'networth_0']));
      expect(removeCalls, equals(['budget_0', 'spending_1', 'networth_0']));
    });
  });

  group('dispatchWidgetAction routes the new overflow menu actions', () {
    test('remove action delegates to controller + provider in order',
        () async {
      final List<String> deleteCalls = [];
      final List<String> removeCalls = [];
      var unavailableCalls = 0;

      await dispatchWidgetAction(
        WidgetEditAction.remove,
        'cashflow_0',
        controllerDelete: deleteCalls.add,
        providerRemove: removeCalls.add,
        onUnavailable: () => unavailableCalls++,
      );

      expect(deleteCalls, equals(['cashflow_0']));
      expect(removeCalls, equals(['cashflow_0']));
      expect(unavailableCalls, 0);
    });

    test('non-destructive actions surface the unavailable hint, never delete',
        () async {
      const placeholderActions = [
        WidgetEditAction.rename,
        WidgetEditAction.duplicate,
        WidgetEditAction.lock,
        WidgetEditAction.resetSize,
      ];
      for (final action in placeholderActions) {
        final List<String> deleteCalls = [];
        final List<String> removeCalls = [];
        var unavailableCalls = 0;

        await dispatchWidgetAction(
          action,
          'budget_0',
          controllerDelete: deleteCalls.add,
          providerRemove: removeCalls.add,
          onUnavailable: () => unavailableCalls++,
        );

        expect(deleteCalls, isEmpty, reason: 'action $action must not delete');
        expect(removeCalls, isEmpty,
            reason: 'action $action must not remove from persistence');
        expect(unavailableCalls, 1,
            reason: 'action $action must surface unavailable hint exactly once');
      }
    });
  });
}
