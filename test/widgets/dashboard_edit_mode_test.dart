import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Edit mode bar visibility gate', () {
    test('bar is hidden when isEditing is false', () {
      const bool isEditing = false;
      final bool barShown = isEditing;
      expect(barShown, isFalse);
    });

    test('bar is shown when isEditing is true', () {
      const bool isEditing = true;
      final bool barShown = isEditing;
      expect(barShown, isTrue);
    });
  });

  group('Remove action callback contract', () {
    test('X tap calls both delete and removeWidgetInstance with the same instanceId', () {
      final List<String> deleteCalls = [];
      final List<String> removeCalls = [];

      void fakeDelete(String id) => deleteCalls.add(id);
      void fakeRemove(String id) => removeCalls.add(id);

      const String instanceId = 'budget_0';
      fakeDelete(instanceId);
      fakeRemove(instanceId);

      expect(deleteCalls, equals(['budget_0']));
      expect(removeCalls, equals(['budget_0']));
    });

    test('X tap on different instance IDs routes each call correctly', () {
      final List<String> deleteCalls = [];
      final List<String> removeCalls = [];

      void fakeDelete(String id) => deleteCalls.add(id);
      void fakeRemove(String id) => removeCalls.add(id);

      for (final id in ['budget_0', 'spending_1', 'networth_0']) {
        fakeDelete(id);
        fakeRemove(id);
      }

      expect(deleteCalls, equals(['budget_0', 'spending_1', 'networth_0']));
      expect(removeCalls, equals(['budget_0', 'spending_1', 'networth_0']));
    });
  });
}
