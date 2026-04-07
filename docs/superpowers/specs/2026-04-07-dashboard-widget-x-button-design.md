# Dashboard Widget X Button Design

**Date:** 2026-04-07
**Scope:** `lib/screens/dashboard_screen.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`

---

## Problem

Dashboard widgets have no remove button on the widget itself. Users must open the sidebar menu to remove a widget. In edit mode there is no in-place affordance.

The fallback placeholder path (when `item.data == null`) already has an X overlay, but the real `DataWidget` path does not.

---

## Design

### What changes

Three files:

| File | Change |
|------|--------|
| `lib/screens/dashboard_screen.dart` | Wrap `DataWidget` in `Stack` with edit-mode top bar overlay; add `_buildEditModeBar` helper |
| `lib/l10n/app_en.arb` | Add `dragToMove` key |
| `lib/l10n/app_vi.arb` | Add `dragToMove` key |

### Edit mode top bar (Style B)

When `_itemController.isEditing` is true, a tinted strip appears at the top of each real widget:

```
┌──────────────────────────────────────┐  ← red tint strip, bottom border
│  ✥ drag to move            [×]       │
└──────────────────────────────────────┘
│                                      │
│        widget content                │
│                                      │
└──────────────────────────────────────┘
```

Visual spec:
- `Positioned(top: 0, left: 0, right: 0)` inside a `Stack`
- Background: `Colors.red.withValues(alpha: 0.15)`
- Bottom border: `Colors.red.withValues(alpha: 0.3)`, width 1
- Padding: `EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4)`
- Left side: `Icons.drag_indicator` (size 14, `Colors.white38`) + `Text(l10n.dragToMove)` (size 11, `Colors.white38`), wrapped in `Expanded` to push X right
- Right side: `IconButton` with `Icons.close` (size 18, `Color(0xFFEF4444)`), no padding, constraints removed

### Remove action

Tap X:
1. `_itemController.delete(item.identifier)` — removes widget from in-memory grid controller
2. `dashProvider.removeWidgetInstance(item.identifier)` — removes from `widgetVisibility` map and persists to storage

No confirmation dialog. Removal is immediate.

### itemBuilder change

```dart
// Before:
if (item.data != null) {
  return DataWidget(item: item);
}

// After:
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
```

### `_buildEditModeBar` helper

Private method on `_DashboardWidgetState`. Returns a `Positioned` widget:

```dart
Widget _buildEditModeBar(ColoredDashboardItem item, DashboardProvider dashProvider) {
  final l10n = AppLocalizations.of(context);
  return Positioned(
    top: 0,
    left: 0,
    right: 0,
    child: Container(
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.15),
        border: Border(
          bottom: BorderSide(
            color: Colors.red.withValues(alpha: 0.3),
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
            icon: const Icon(Icons.close, color: Color(0xFFEF4444), size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    ),
  );
}
```

### Localization

`app_en.arb`:
```json
"dragToMove": "drag to move"
```

`app_vi.arb`:
```json
"dragToMove": "kéo để di chuyển"
```

---

## Out of Scope

- Confirmation dialog before removal
- Undo/restore after removal
- X button shown outside edit mode
- Changes to the fallback placeholder path (already has its own X)
- Drag handle gesture wiring (the icon is visual hint only — dragging is handled by the `dashboard` package)
