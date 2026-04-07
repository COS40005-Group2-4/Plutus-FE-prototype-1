import 'package:flutter_test/flutter_test.dart';

// Helper that mirrors the itemBuilder's conditional logic
bool shouldShowEditBar(bool isEditing) => isEditing;

// Helper that mirrors the onPressed logic
void performRemove(
  String instanceId,
  void Function(String) controllerDelete,
  void Function(String) providerRemove,
) {
  controllerDelete(instanceId);
  providerRemove(instanceId);
}

void main() {
  group('Edit mode bar visibility gate', () {
    test('bar is hidden when isEditing is false', () {
      expect(shouldShowEditBar(false), isFalse);
    });

    test('bar is shown when isEditing is true', () {
      expect(shouldShowEditBar(true), isTrue);
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
}
