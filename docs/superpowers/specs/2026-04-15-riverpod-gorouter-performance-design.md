# Plutus Flutter Refactor: GoRouter + Riverpod + Mobile Performance

**Date:** 2026-04-15
**Scope:** Big-bang migration — all changes land together in one pass
**Primary pain points addressed:** Laggy dashboard (blank states + scroll jank) on mobile

---

## 1. Architecture Overview

Three pillars executed simultaneously:

| Pillar | What changes | Why |
|---|---|---|
| **GoRouter** | Replace `MaterialApp.routes` + string navigation with typed `GoRouter` | Type safety, deep linking, auth redirects as first-class concept |
| **Riverpod** | Replace all 10 `ChangeNotifier` providers with `AsyncNotifier`/`Notifier` | Parallel data loading, fine-grained subscriptions, eliminates full-tree rebuilds |
| **Performance** | Fix `ListView` shrinkWrap, add `RepaintBoundary`, enforce `const`, move heavy work off UI thread | Fixes jank and blank dashboard states |

**Entry point change:** `main.dart` wraps the app in `ProviderScope` (Riverpod root) instead of `MultiProvider`. `MaterialApp` becomes `MaterialApp.router` fed by the GoRouter instance. All `ChangeNotifierProvider` registrations are removed.

**GetIt stays** as the DI container for services. Riverpod providers read from `sl<IService>()` rather than instantiating services directly. This fixes the duplicate-instance bug without touching the service layer.

---

## 2. GoRouter — Routing Design

### Route Tree

```
GoRouter
├── / (redirect → /login or /dashboard based on auth state)
├── /user-selection
├── /login
└── /dashboard (ShellRoute — MainNavigationPage shell)
    ├── /dashboard/home
    ├── /dashboard/history
    ├── /dashboard/import
    ├── /dashboard/investments
    ├── /dashboard/insights
    ├── /dashboard/settings
    ├── /dashboard/backup-history
    ├── /dashboard/report-config
    └── /dashboard/report-preview
```

### Key Decisions

- **`ShellRoute`** wraps `/dashboard/*` — the sidebar/bottom nav renders once and persists across sub-pages, eliminating the current full rebuild on navigation.
- **Auth redirect** lives in `GoRouter.redirect` — checks `authNotifierProvider` state and redirects unauthenticated users to `/login`, removing auth logic currently scattered across `MainPage.build()`.
- **Typed route classes** — one `GoRoute` subclass per route (e.g. `DashboardRoute`, `HistoryRoute`). Navigation becomes `HistoryRoute().push(context)` instead of `Navigator.pushNamed(context, '/history')`. Raw strings eliminated at all call sites.
- **`refreshListenable`** — the router re-evaluates `redirect` whenever auth state changes. Logout automatically navigates to `/login` without any manual `Navigator` calls.

### File

`lib/router/app_router.dart` — single source of truth for all routes and redirect logic.

---

## 3. Riverpod — State Management Design

### Provider Mapping

| Current (`ChangeNotifier`) | Riverpod replacement | Riverpod type |
|---|---|---|
| `AuthProvider` | `authNotifierProvider` | `NotifierProvider<AuthNotifier, AuthState>` |
| `SettingsProvider` | `settingsNotifierProvider` | `NotifierProvider<SettingsNotifier, SettingsState>` |
| `DashboardProvider` | `dashboardNotifierProvider` | `NotifierProvider<DashboardNotifier, DashboardState>` |
| `WidgetVisibilityProvider` | `widgetVisibilityNotifierProvider` | `NotifierProvider<WidgetVisibilityNotifier, WidgetVisibilityState>` |
| `BudgetProvider` | `budgetNotifierProvider` | `AsyncNotifierProvider<BudgetNotifier, BudgetState>` |
| `InsightsProvider` | `insightsNotifierProvider` | `AsyncNotifierProvider<InsightsNotifier, InsightsState>` |
| `BackupProvider` | `backupNotifierProvider` | `AsyncNotifierProvider<BackupNotifier, BackupState>` |
| `ReportProvider` | `reportNotifierProvider` | `AsyncNotifierProvider<ReportNotifier, ReportState>` |
| `ProfileProvider` | `profileNotifierProvider` | `AsyncNotifierProvider<ProfileNotifier, ProfileState>` |
| `ThemeProvider` (deprecated) | merged into `settingsNotifierProvider` | — |

**Synchronous (`Notifier`):** auth, settings, dashboard layout, widget visibility — always available from local storage on first read, no async needed.

**Async (`AsyncNotifier`):** budget, insights, backup, report, profile — require database or network I/O; expose `AsyncValue<T>` (loading / data / error) automatically.

### Parallel Dashboard Loading

Currently each dashboard widget loads its own data independently in `initState`, sequentially. A single `dashboardDataProvider` fires all fetches simultaneously:

```dart
@riverpod
Future<DashboardData> dashboardData(Ref ref) async {
  final results = await Future.wait([
    ref.watch(budgetNotifierProvider.future),
    ref.watch(investmentsProvider.future),
    ref.watch(billsProvider.future),
    ref.watch(recentTransactionsProvider.future),
  ]);
  return DashboardData.fromResults(results);
}
```

All service calls run in parallel. The dashboard skeleton shows once; data appears together.

### Fine-Grained Subscriptions

Each dashboard widget watches only its own provider slice. A profile update no longer causes `BudgetWidget` to rebuild. `ref.watch` replaces all `Consumer<Provider>` wrappers.

### Sealed AuthState

```dart
sealed class AuthState {
  const AuthState();
}
class AuthLoading extends AuthState { const AuthLoading(); }
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final User user;
}
class AuthUnauthenticated extends AuthState { const AuthUnauthenticated(); }
class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}
```

Replaces the boolean flag scatter currently in `AuthProvider`.

### File Layout

```
lib/providers/
├── auth_notifier.dart
├── settings_notifier.dart
├── dashboard_notifier.dart
├── budget_notifier.dart
├── insights_notifier.dart
├── backup_notifier.dart
├── report_notifier.dart
├── profile_notifier.dart
├── widget_visibility_notifier.dart
└── dashboard_data_provider.dart   ← new parallel loader
```

---

## 4. Performance — Mobile Optimisations

### Fix 1: ListView shrinkWrap → Sliver-based layout

Every dashboard widget currently uses `ListView.builder(shrinkWrap: true, physics: NeverScrollableScrollPhysics())` nested inside an outer scroll view. This forces Flutter to lay out the entire list eagerly with no lazy rendering.

**Replacement:** The outer dashboard scroll becomes a `CustomScrollView`. Each dashboard section becomes a `SliverList.builder`. Items outside the viewport are never built.

```dart
// Before
ListView.builder(shrinkWrap: true, physics: NeverScrollableScrollPhysics(), ...)

// After
SliverList.builder(itemBuilder: ..., itemCount: ...)
```

### Fix 2: `RepaintBoundary` around chart widgets

`fl_chart` widgets repaint on every animation tick. Without a boundary, repaints propagate up the ancestor subtree. Each chart widget (`CashflowWidget`, `ExpenseBreakdownChartWidget`, budget charts) is wrapped:

```dart
RepaintBoundary(child: SomeChartWidget())
```

### Fix 3: Heavy computation off the UI thread

`export_service.dart` (CSV/PDF generation) and `ocr_service.dart` (post-processing) run CPU-intensive work on the main isolate. Moved to background isolate via `compute()`:

```dart
final result = await compute(_parseTransactionsCsv, rawCsv);
```

### Fix 4: Sweep across all widgets

- `const` constructors propagated — every static widget node becomes `const`
- `AppSpacing` / `AppColors` tokens replace all magic numbers (`SizedBox(height: 4)` → `SizedBox(height: AppSpacing.xs)`, `Colors.white` → semantic token)
- All widgets use `sl<IService>()` — zero direct `Service()` instantiation remaining
- `StatefulWidget` converted to `ConsumerWidget` wherever `setState` was only serving Provider consumption

---

## 5. Testing Design

### Layer 1: Riverpod provider unit tests

Each notifier gets its own test file using `ProviderContainer` — no Flutter widgets required:

```dart
test('budgetNotifier loads budgets in parallel with transactions', () async {
  final container = ProviderContainer(overrides: [
    budgetNotifierProvider.overrideWith(() => BudgetNotifier(mockBudgetService)),
  ]);
  final state = await container.read(budgetNotifierProvider.future);
  expect(state.budgets, isNotEmpty);
});
```

### Layer 2: GoRouter navigation tests

Auth redirect logic and route resolution tested without rendering full screens:

```dart
test('unauthenticated user is redirected to /login', () async {
  final router = createTestRouter(authState: const AuthUnauthenticated());
  expect(router.routerDelegate.currentConfiguration.uri.path, '/login');
});
```

### Layer 3: Widget tests updated for `ConsumerWidget`

Existing widget tests updated to wrap in `ProviderScope` with overrides instead of `MultiProvider`. New tests cover:

- Dashboard shows skeleton while `dashboardDataProvider` is loading
- Dashboard shows data after `AsyncValue.data`
- Dashboard shows error widget on `AsyncValue.error`
- `RepaintBoundary` present in widget tree for all chart widgets

### Test File Layout

```
test/
├── providers/               ← new, one file per notifier
│   ├── auth_notifier_test.dart
│   ├── budget_notifier_test.dart
│   ├── settings_notifier_test.dart
│   ├── insights_notifier_test.dart
│   ├── backup_notifier_test.dart
│   ├── report_notifier_test.dart
│   ├── profile_notifier_test.dart
│   ├── widget_visibility_notifier_test.dart
│   └── dashboard_data_provider_test.dart
├── router/                  ← new
│   └── app_router_test.dart
├── screens/                 ← updated for ProviderScope
└── widgets/                 ← updated + new AsyncValue state tests
```

**Coverage target:** All notifiers, all GoRouter redirect paths, and all `AsyncValue` states (loading / data / error) for every dashboard widget.

---

## 6. Out of Scope

- Service layer changes (no modifications to `lib/services/`)
- Go FFI backend (`Plutus-backend-prototype-2/`)
- Lambda / Terraform infrastructure
- Database schema changes
- UI visual redesign (layout and design tokens enforced, not redesigned)
