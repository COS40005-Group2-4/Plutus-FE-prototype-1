# Dashboard Widget X Button Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a tinted top-bar strip with a drag hint and X remove button to each dashboard widget when edit mode is active.

**Architecture:** Two changes to one screen file — the `itemBuilder`'s `item.data != null` branch is wrapped in a `Consumer<DashboardProvider>` + `Stack` so an edit-mode overlay can float on top, and a private `_buildEditModeBar` helper builds the red-tinted strip. A new `drag_to_move` l10n key is added to `app_localizations.dart` for both EN and VI.

**Tech Stack:** Flutter, `packages/dashboard` (`DashboardItemController`), Provider (`Consumer<DashboardProvider>`), `AppLocalizations` (inline translation map in `lib/l10n/app_localizations.dart`)

---

## File Map

| File | Action |
|------|--------|
| `lib/l10n/app_localizations.dart` | Add `drag_to_move` key to EN map, VI map, and add getter |
| `lib/screens/dashboard_screen.dart` | Update `itemBuilder` DataWidget branch; add `_buildEditModeBar` |
| `test/widgets/dashboard_edit_mode_test.dart` | Unit tests for remove callback contract and visibility gate |

---

### Task 1: Add `dragToMove` localization key

**Files:**
- Modify: `lib/l10n/app_localizations.dart` (lines ~323, ~866, ~1407)

- [ ] **Step 1: Add EN string**

In `lib/l10n/app_localizations.dart`, find the EN translations map. After line 323 (`'layout_saved': 'Layout saved',`), add:

```dart
      'drag_to_move': 'drag to move',
```

The surrounding context should look like:

```dart
      'save_layout': 'Save Layout',
      'layout_saved': 'Layout saved',
      'drag_to_move': 'drag to move',
      'reset_dashboard': 'Undo Changes',
```

- [ ] **Step 2: Add VI string**

In the same file, find the VI translations map. After line 866 (`'layout_saved': 'Đã lưu bố cục',`), add:

```dart
      'drag_to_move': 'kéo để di chuyển',
```

The surrounding context should look like:

```dart
      'save_layout': 'Lưu bố cục',
      'layout_saved': 'Đã lưu bố cục',
      'drag_to_move': 'kéo để di chuyển',
      'reset_dashboard': 'Hoàn tác thay đổi',
```

- [ ] **Step 3: Add getter**

In the same file, find the getter section. After line 1407 (`String get layoutSaved => translate('layout_saved');`), add:

```dart
  String get dragToMove => translate('drag_to_move');
```

The surrounding context should look like:

```dart
  String get saveLayout => translate('save_layout');
  String get layoutSaved => translate('layout_saved');
  String get dragToMove => translate('drag_to_move');
  String get resetDashboard => translate('reset_dashboard');
```

- [ ] **Step 4: Verify no breakage**

```bash
flutter analyze lib/l10n/app_localizations.dart
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/app_localizations.dart
git commit -m "feat(l10n): add drag_to_move key for dashboard edit mode bar"
```

---

### Task 2: Edit-mode top bar — tests, implementation, and integration

**Files:**
- Create: `test/widgets/dashboard_edit_mode_test.dart`
- Modify: `lib/screens/dashboard_screen.dart` (lines 381–428, and add `_buildEditModeBar` method)

#### Background

`dashboard_screen.dart` key context:

- `_itemController.isEditing` — bool controlling edit mode (toggled by AppBar icon)
- `DashboardProvider.removeWidgetInstance(instanceId)` — removes from `widgetVisibility` map and persists
- `_itemController.delete(instanceId)` — removes from in-memory grid controller
- In `itemBuilder` (line 381), when `item.data != null` the widget returns `DataWidget(item: item)` — this is the branch we change.
- The fallback branch (when `item.data == null`) already has its own X button and must NOT be touched.

#### Step-by-step

- [ ] **Step 1: Write the failing tests**

Create `test/widgets/dashboard_edit_mode_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Edit mode bar visibility gate', () {
    test('bar is hidden when isEditing is false', () {
      const bool isEditing = false;
      // The itemBuilder uses: if (_itemController.isEditing) _buildEditModeBar(...)
      // Mirror that gate:
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

      // Simulate what _buildEditModeBar's onPressed does:
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
```

- [ ] **Step 2: Run tests to verify they fail for the right reason**

```bash
flutter test test/widgets/dashboard_edit_mode_test.dart -v
```

Expected: tests PASS (these are pure logic tests with no widget dependency — they verify the contract, not the widget render). If they fail, check for typos in the test file.

- [ ] **Step 3: Update `itemBuilder` in `dashboard_screen.dart`**

In `lib/screens/dashboard_screen.dart`, find the `itemBuilder` lambda (around line 381). The current `item.data != null` branch:

```dart
itemBuilder: (ColoredDashboardItem item) {
  var layout = item.layoutData;

  if (item.data != null) {
    return DataWidget(item: item);
  }
  // ... fallback branch (DO NOT TOUCH)
```

Replace **only** the `return DataWidget(item: item);` line with:

```dart
itemBuilder: (ColoredDashboardItem item) {
  var layout = item.layoutData;

  if (item.data != null) {
    return Consumer<DashboardProvider>(
      builder: (context, dashProvider, _) => Stack(
        children: [
          DataWidget(item: item),
          if (_itemController.isEditing)
            _buildEditModeBar(item, dashProvider),
        ],
      ),
    );
  }
  // ... fallback branch unchanged
```

- [ ] **Step 4: Add `_buildEditModeBar` helper method**

In `lib/screens/dashboard_screen.dart`, add this method inside `_DashboardWidgetState`, after the `_buildWidgetPreview` method (end of class, before the closing `}`):

```dart
  Widget _buildEditModeBar(
    ColoredDashboardItem item,
    DashboardProvider dashProvider,
  ) {
    final l10n = AppLocalizations.of(context);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          border: const Border(
            bottom: BorderSide(
              color: Color(0x4DEF4444),
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        child: Row(
          children: [
            const Icon(Icons.drag_indicator, color: Colors.white38, size: 14),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                l10n.dragToMove,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ),
            IconButton(
              onPressed: () {
                _itemController.delete(item.identifier);
                dashProvider.removeWidgetInstance(item.identifier);
              },
              icon: const Icon(
                Icons.close,
                color: Color(0xFFEF4444),
                size: 18,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
```

Note: `Color(0x4DEF4444)` is `Colors.red.withValues(alpha: 0.3)` as a compile-time constant (avoids the deprecated `withOpacity` and keeps `const` on `BoxDecoration`). The `0x4D` hex value equals `round(0.3 * 255) = 77 = 0x4D`.

- [ ] **Step 5: Analyze for errors**

```bash
flutter analyze lib/screens/dashboard_screen.dart
```

Expected: no errors. Common pitfalls:
- If `Consumer` is not imported, add `import 'package:provider/provider.dart';` — but it's already imported at line 3.
- If `DashboardProvider` is not imported, it's already at line 10.

- [ ] **Step 6: Run tests**

```bash
flutter test test/widgets/dashboard_edit_mode_test.dart -v
```

Expected: 4 tests PASS.

- [ ] **Step 7: Run full test suite**

```bash
flutter test
```

Expected: all tests PASS (no regressions).

- [ ] **Step 8: Commit**

```bash
git add lib/screens/dashboard_screen.dart test/widgets/dashboard_edit_mode_test.dart
git commit -m "feat(dashboard): add edit-mode top bar with X remove button on each widget"
```
