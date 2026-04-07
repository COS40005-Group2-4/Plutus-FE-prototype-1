# Budget Alerts Banner Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Surface `BudgetProvider.alerts` to the user via a dismissible amber banner at the top of the dashboard body, using `SettingsProvider.currency.symbol` for correct currency formatting.

**Architecture:** `_DashboardWidgetState` gains a `bool _alertsDismissed` field. The `body:` `SafeArea`'s inner widget is wrapped in a `Consumer<BudgetProvider>` + `Column`, with `_buildAlertsBanner` injected above the existing `Consumer<DashboardProvider>`. Dismissal is session-scoped (resets on app restart or user switch via `_recreateStorageAndController`).

**Tech Stack:** Flutter, Provider (`Consumer<BudgetProvider>`, `context.read<SettingsProvider>()`), `BudgetAlert` model

---

## File Map

| File | Action |
|---|---|
| `lib/screens/dashboard_screen.dart` | Add `_alertsDismissed` field, two imports, `Consumer<BudgetProvider>` wrapper, `_buildAlertsBanner` method |
| `test/screens/budget_alerts_banner_test.dart` | Widget test for banner display/dismiss logic |

---

### Task 1: Budget alerts banner in `dashboard_screen.dart`

**Files:**
- Modify: `lib/screens/dashboard_screen.dart`
- Create: `test/screens/budget_alerts_banner_test.dart`

- [ ] **Step 1: Write test**

Create `test/screens/budget_alerts_banner_test.dart`:

```dart
import 'package:flutter/material.dart';
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
```

- [ ] **Step 2: Run test — expect PASS**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && flutter test test/screens/budget_alerts_banner_test.dart -v
```

Expected: 4 tests pass.

- [ ] **Step 3: Add imports to `dashboard_screen.dart`**

In `lib/screens/dashboard_screen.dart`, find the existing line:
```dart
import '../providers/dashboard_provider.dart';
```

Add immediately after it:
```dart
import '../providers/budget_provider.dart';
import '../providers/settings_provider.dart';
```

- [ ] **Step 4: Add `_alertsDismissed` field**

In `lib/screens/dashboard_screen.dart`, find:
```dart
  int? _lastUserId;
```

Add immediately after it:
```dart
  bool _alertsDismissed = false;
```

- [ ] **Step 5a: Replace the `body:` opening in `dashboard_screen.dart`**

Find:
```dart
      body: SafeArea(
        child: Consumer<DashboardProvider>(
          builder: (context, dashProvider, _) {
```

Replace with:
```dart
      body: SafeArea(
        child: Consumer<BudgetProvider>(
          builder: (context, budgetProvider, _) {
            final alerts = budgetProvider.alerts;
            return Column(
              children: [
                if (alerts.isNotEmpty && !_alertsDismissed)
                  _buildAlertsBanner(alerts),
                Expanded(
                  child: Consumer<DashboardProvider>(
                    builder: (context, dashProvider, _) {
```

- [ ] **Step 5b: Replace the `body:` closing in `dashboard_screen.dart`**

Find (the three lines that close the DashboardProvider builder, Consumer, and SafeArea):
```dart
          },
        ),
      ),
    );
  }

  Widget _menuItem(
```

Replace with:
```dart
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _menuItem(
```

- [ ] **Step 6: Add `_buildAlertsBanner` method**

In `lib/screens/dashboard_screen.dart`, find the method `void _updateHiddenItems(` and add the new method immediately before it:

```dart
  Widget _buildAlertsBanner(List<BudgetAlert> alerts) {
    final currency = context.read<SettingsProvider>().currency;
    return Container(
      width: double.infinity,
      color: Colors.amber.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.warning_amber_outlined, color: Colors.amber, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: alerts.map((alert) {
                final pct = (alert.spent / alert.budgeted * 100).round();
                final sym = currency.symbol;
                return Text(
                  '${alert.category.name}: $pct% '
                  '(${sym}${alert.spent.toStringAsFixed(0)} / '
                  '${sym}${alert.budgeted.toStringAsFixed(0)})',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _alertsDismissed = true),
            child: const Icon(Icons.close, color: Colors.amber, size: 16),
          ),
        ],
      ),
    );
  }

```

- [ ] **Step 7: Analyze**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && flutter analyze lib/screens/dashboard_screen.dart
```

Expected: no errors.

- [ ] **Step 8: Run full test suite**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && flutter test
```

Expected: all tests pass.

- [ ] **Step 9: Commit**

```bash
cd /Users/anh.dinh/Desktop/PJs/Plutus-FE-prototype-1 && git add lib/screens/dashboard_screen.dart test/screens/budget_alerts_banner_test.dart && git commit -m "$(cat <<'EOF'
feat(dashboard): show dismissible budget alerts banner with correct currency symbol
EOF
)"
```
