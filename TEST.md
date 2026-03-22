# TEST.md — Plutus FE Test Suite

Run all tests with:
```bash
flutter test
```

---

## Test Infrastructure (`test/helpers/`)

| File | Purpose |
|---|---|
| `mock_services.dart` | Declares `@GenerateMocks` for all 12 service interfaces. Source file for `build_runner` — do not add logic here. |
| `mock_services.mocks.dart` | Auto-generated mock classes (e.g. `MockIDatabaseService`, `MockIInvestmentService`). Regenerate with `dart run build_runner build`. |
| `test_fixtures.dart` | Factory functions that create test objects with sensible defaults: `createTestUser()`, `createTestTransaction()`, `createTestBill()`, `createTestProfile()`, `createTestInvestment()`, `createTestVersionEntry()`, and `createTestUserMap()` (raw DB row). Use these instead of constructing objects manually in tests. |

---

## Model Tests (`test/models/`)

These tests verify pure data logic — no network, no DB, no Flutter widgets. They run fast and have no side effects.

### `user_model_test.dart`
Tests the `User` model used for both local and OAuth accounts.
- **`fromMap`** — parses all fields from a SQLite row map, handles null optional fields (email, oauthProvider, oauthId), correctly maps `is_guest` int to bool, parses timestamps from milliseconds.
- **`toMap`** — serializes booleans as integers (SQLite convention), converts DateTime to millisecondsSinceEpoch.
- **Round-trip** — `fromMap(toMap())` produces an equal object; null optional fields survive the cycle.
- **`copyWith`** — preserves unchanged fields, can override any subset.
- **Equatable** — two `User` objects with identical fields are `==` and share the same `hashCode`; differing id or email breaks equality.
- **`hasOAuth`** — returns true only when both `oauthProvider` and `oauthId` are non-null.

### `transaction_model_test.dart`
Tests `Posting` (a single account entry) and `Transaction` (a full double-entry record).

**Posting:**
- **`fromJson`** — parses numeric, string, and integer amounts; defaults to 0.0 on invalid string; defaults account/commodity to empty string on null.
- **`toJson`** — serializes all three fields.
- **`formattedAmount`** — prefixes positive amounts with `+`, negative with `-`, two decimal places.
- **Equatable** — structural equality on all three fields.

**Transaction:**
- **`fromJson`** — parses full transactions including nested posting list; handles null id; defaults payee/description to `''`; defaults postings to `[]`.
- **`toJson`** / **Round-trip** — full serialization cycle including nested postings.
- **`dateTime`** — converts unix seconds to `DateTime`.
- **`label`** — returns `"payee - description"`, falls back to payee-only, description-only, first posting account, or `"Transaction"` when everything is empty.
- **`isExpense`** — detects expense by checking for negative Asset postings or positive Expense postings (handles both `Assets:` and `Asset:` prefixes).
- **`totalAmount`** — absolute value of the first posting; 0.0 for empty postings.
- **`currency`** — commodity of the first posting.
- **Equatable** — id-based equality.

### `bill_model_test.dart`
Tests the `Bill` model for recurring and one-time payment tracking.
- **`fromJson`** — parses all fields; handles `is_paid` as both int (`0`/`1`) and bool; defaults currency to `'VND'`; handles null optional fields (id, category, notes); defaults to `oneTime` for unknown recurrence strings; round-trips all `BillRecurrence` enum values.
- **`toJson`** — correct field names and types; serializes `isPaid` as bool.
- **Round-trip** — all fields survive serialization.
- **`copyWith`** — targeted field updates.
- **Equatable** — equality by all fields.
- **`formattedDueDate`** — formats as `dd/MM/yyyy`.
- **`isOverdue`** — true only when unpaid and due date is in the past.
- **`isUpcoming`** — true only when unpaid and due within the next 7 days (exclusive of overdue).

### `profile_model_test.dart`
Tests the `Profile` model that stores a user's public display preferences.
- **`fromMap`** — parses all fields including five boolean visibility flags (stored as integers in SQLite), timestamps, and nullable strings.
- **`toMap`** — serializes booleans as 0/1, timestamps as milliseconds.
- **Round-trip** — all fields and null optionals survive.
- **`copyWith`** — partial updates.
- **Equatable** — equality across userId, visibility flags, and optional text fields.
- **Default values** — `showName` and `showEmail` default to `true`; all others default to `false`.

### `investment_model_test.dart`
Tests `PriceHistoryPoint` and `InvestmentModel` for the portfolio tracker.

**PriceHistoryPoint:**
- **`fromJson`** — parses unix-second timestamp to DateTime and price as double or string.
- **`toJson`** — serializes back to unix seconds.
- **Equatable** — equality on date and price.

**InvestmentModel:**
- **`fromJson`** — parses all required fields; optional `currentPrice` and `priceHistory`; validates all `AssetType` and `Currency` enum values; throws `ArgumentError` on missing required fields, invalid asset type, or unsupported currency (e.g. GBP); parses quantity/purchaseValue from strings.
- **`toJson`** — omits `current_price` and `price_history` when null; includes them when set.
- **Round-trip** — with and without optional fields, including price history list.
- **`getCurrentValue`** — `quantity × currentPrice`; falls back to `purchaseValue` when price is null.
- **`getGainLoss`** — `currentValue - purchaseValue` (signed).
- **`getGainLossPercent`** — percentage gain/loss relative to purchaseValue; returns 0.0 when purchaseValue is 0.
- **`isPositiveReturn`** — true when gain/loss ≥ 0.
- **`getFormattedGainLoss`** — formatted as `+50.00%` / `-25.00%`.
- **`getCurrencySymbol`** — returns `₫` for VND, `$` for USD, `€` for EUR.
- **Equatable** — id and quantity-based inequality checks.

### `backup_models_test.dart`
Tests the models used by the S3 backup system.
- **`VersionEntry`** — construction with required fields, Equatable equality across all four fields (s3ObjectKey, timestamp, fileSizeBytes, checksum), `props` list length and contents.
- **`ConflictResult`** — enum has exactly 5 values (match, mismatch, noRemote, offline, error) with distinct indices.
- **`ConflictChoice`** — enum has exactly 3 values (overrideLocal, keepLocal, cancel) with distinct indices.
- **`BackupException`** — creates with message-only or message+code; implements `Exception`; can be thrown and caught; preserves message and code on catch.

---

## Service Tests (`test/services/`)

Services are tested with mocked dependencies injected via constructors. No real database or network calls occur.

### `user_service_test.dart`
Tests `UserService` which manages user account creation and lookup.
- **`createLocalUser`** — creates a user when username doesn't exist; throws when username already exists; supports guest flag; throws when DB returns null after insert.
- **`createOAuthUser`** — returns existing user when OAuth provider+id already exists (skips insert); creates new user when OAuth user is new.
- **`getUserById`** — returns parsed `User` when found; returns null when not found; returns null on DB error (graceful degradation).
- **`getUserByUsername`** — found and not-found cases.
- **`getUserByOAuth`** — found and not-found cases.
- **`getAllUsers`** — returns list of parsed users; empty list on no data; empty list on error.
- **`updateLastLogin`** — delegates to `db.updateUserLastLogin`.
- **`linkOAuthToUser`** — delegates to DB; rethrows on error.
- **`clearUserData`** — delegates to DB; rethrows on error.

### `settings_service_test.dart`
Tests `SettingsService`, a typed key-value store on top of the DB settings table.
- **`setString / getString`** — round-trip; returns `defaultValue` when key missing; returns `defaultValue` on DB error; `setString` rethrows on write error.
- **`setInt / getInt`** — round-trip (stored as string, parsed back); returns default for missing key or non-numeric string.
- **`setBool / getBool`** — round-trip for both true and false; returns default when missing.
- **`setDouble / getDouble`** — round-trip; returns default for non-numeric string.
- **`setMap / getMap`** — round-trip via JSON encoding; returns null for corrupted JSON; returns null when key missing.
- **`setList / getList`** — round-trip; returns null for corrupted JSON.
- **`getAllSettings`** — returns settings map; returns empty map on DB error.
- **`deleteSetting`** — delegates to DB; rethrows on error.
- **Convenience methods** — `getThemeMode` defaults to `'system'`; `getDefaultCurrency` defaults to `'VND'`; `getNotificationsEnabled` defaults to `true`; `getAutoBackupEnabled` defaults to `false`; `setLastSyncTime`/`getLastSyncTime` round-trip; returns null for missing or invalid date strings.

### `bill_service_test.dart`
Tests `BillService` which manages upcoming bills and recurring payment schedules.
- **`getBills`** — returns empty list when no user is set (guard); returns empty list when DB is empty; returns parsed bills; returns empty list on DB error.
- **`addBill`** — inserts bill and calls notify; throws when no user logged in.
- **`updateBill`** — calls `db.updateBill` with correct id; throws when bill has no id; throws when no user.
- **`deleteBill`** — delegates delete to DB by id.
- **`markBillAsPaid`** — marks one-time bills as paid without creating a next occurrence; marks recurring bills as paid AND inserts a new bill for the next period; throws when no user.
- **`getTotalDueAmount`** — returns 0.0 with no bills; sums only unpaid bills in the correct currency within the days window (excludes: paid, wrong currency, out-of-range, overdue); returns 0.0 when no user.
- **`billStream`** — emits an updated list when `notifyBillUpdate()` is called.

### `investment_service_test.dart`
Tests `InvestmentService` which manages portfolio data from the Go FFI backend.
- **`getTotalPortfolioValue`** — 0.0 for empty list; sums `quantity × currentPrice` for each investment; falls back to `purchaseValue` when `currentPrice` is null.
- **`getTotalGainLoss`** — 0.0 for empty list; calculates percentage gain and loss; returns 0.0 when total cost is zero (divide-by-zero guard).
- **`getInvestmentList`** — fetches from FFI backend; caches result (second call within 5 min hits FFI only once); bypasses cache when `forceRefresh: true`; throws on missing `investments` key; throws on backend exception; persists to DB when userId is set.
- **`deleteInvestment`** — deletes from both FFI backend and DB; clears cache so next fetch hits FFI again; throws `ArgumentError` on empty id; throws when backend delete fails.
- **`clearCache`** — forces next `getInvestmentList` to bypass cache and hit FFI.
- **`getInvestmentDetail`** — returns parsed investment from FFI; throws `ArgumentError` on empty commodity string.
- **`saveInvestment`** — fetches current price from price API for stock/crypto types before saving to FFI; skips price fetch for bond type; returns the new investment id.
- **`getRoiIrrData`** — formats raw `roi`/`irr` strings with `%` suffix; returns null on error.

---

## Provider Tests (`test/providers/`)

Providers are Flutter `ChangeNotifier`s. These tests verify state transitions and that the correct service methods are called.

### `settings_provider_test.dart`
Tests `SettingsProvider` which persists theme, language, currency, and format preferences to `SharedPreferences`.
- **Defaults** — `ThemeMode.system`, English, VND, dd/MM/yyyy, 24h.
- **`isDarkMode`** — false by default.
- **`locale`** — `Locale('en')` by default.
- **`setThemeMode`** — updates in-memory state, persists to SharedPreferences, notifies listeners; `isDarkMode` becomes true for dark mode.
- **`toggleTheme`** — flips between dark and light.
- **`setLanguage`** — updates language and locale; persists `'vi'` code.
- **`setCurrency`** — updates and persists currency code.
- **`setDateFormat`** / **`setTimeFormat`** — update and persist format codes.
- **Persistence on load** — pre-populated SharedPreferences values are read back correctly on construction.
- **`AppLanguage.fromCode`** — correct enum from code string; defaults to English for unknown.
- **`AppCurrency.fromCode`** — correct enum; defaults to VND for unknown; `original.isOriginal` is true, others are false.
- **`DateFormatType.fromString`** / **`TimeFormatType.fromString`** — correct enum; defaults for unknown.

### `widget_visibility_provider_test.dart`
Tests `WidgetVisibilityProvider` which controls which of the 12 dashboard widgets are shown.
- **Defaults** — all 12 widgets visible, no hidden widgets, `getVisibleWidgets()` returns 12 ids.
- **`isWidgetVisible`** — true for known widget ids; true for unknown ids (permissive default).
- **`hideWidget`** — hides widget, decrements count, adds to `hiddenWidgetIds`, notifies listeners; no-op for unknown widget id.
- **`showWidget`** — shows a previously hidden widget.
- **`toggleWidget`** — hides when visible, shows when hidden.
- **`reset`** — restores all 12 widgets to visible.
- **`getVisibleWidgets`** — returns only visible ids, filtered list has correct length.
- **Persistence** — hidden widgets are persisted to SharedPreferences and loaded by a new provider instance.
- **`isInitialized`** — becomes true after async setup completes.

### `profile_provider_test.dart`
Tests `ProfileProvider` which manages a user's editable profile (display name, position, visibility toggles).
- **Initial state** — `profile` is null, state is `initial`, `isEditing` is false, `errorMessage` is empty.
- **`loadProfile`** — loads existing profile from service and transitions to `loaded` state; creates a default profile when none exists (calls `createProfile` with `showName: true, showEmail: true`); transitions to `error` state and sets `errorMessage` on exception.
- **`updateProfile`** — updates specified fields via service, sets `isEditing` to false; no-op when `profile` is null.
- **`toggleFieldVisibility`** — flips the named visibility field (e.g. `'name'` → `showName`); no-op for unknown field name.
- **`setEditing`** — toggles `isEditing` flag.
- **`resetState`** — clears error state back to `loaded`; no-op when not in error state.
