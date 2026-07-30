# Gold/Navy Redesign — PR4: Web Shell, Shim Deletion & Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the gold/navy migration — delete the deprecated `AppColors`/`GlassContainer`/`GlassBackground`/`AppElevation`/`AppGradients` layer (extracting the kept `AppMotion`), brand the web splash shell per spec §6, land PR3's final-review follow-up bundle (onStatus ink token, insights chip idiom, chart dot threshold, residual l10n, dead param), and write the spec-mandated before/after summary doc.

**Architecture:** Spec §10 row 4 (`feat/web-shell-brand-cleanup`) + §2.3 migration safety net + §6 branding + §11 deliverables (docs/superpowers/specs/2026-07-29-gold-navy-redesign-design.md). PR3 (#37, merged e1d6bc7) left zero live consumers of the shims — deletion is file removal + doc-comment tidy, NOT migration. `AppMotion` (spec §2: "kept") currently cohabits `app_elevation.dart` and moves to its own file. The follow-up bundle items come verbatim from PR3's final whole-branch review.

**Tech Stack:** Flutter (Dart ^3.9.2), Material 3, plain HTML/CSS (web/index.html), flutter_test.

## Global Constraints

- Branch `feat/web-shell-brand-cleanup` (exists, tracks main at e1d6bc7). Working directory is the worktree: D:\Backup\Work\Uni\COS40005\Plutus\Plutus-FE-prototype-1\.claude\worktrees\web-shell-brand-cleanup — every shell command cd-prefixed there; file tools use absolute paths under it; `git branch --show-current` must print `feat/web-shell-brand-cleanup` immediately before every commit.
- Baseline at e1d6bc7: full `flutter test` = 605 app tests passing (+2 packages/dashboard tests; its `todo_test.dart` placeholder failure is pre-existing); `flutter analyze lib` = 0; full `flutter analyze` = 9 issues (4 packages/dashboard(+example), 4 avatar-test `scale` deprecations, 1 example invalid_override) — gate on no NEW issues. Task 1 deletes `test/theme/on_accent_contrast_test.dart`, so the app test count DROPS; record the new count in the Task 1 report and gate later tasks on that number.
- Every NEW user-facing string: key+value in BOTH `'en'` and `'vi'` maps of lib/l10n/app_localizations.dart plus a getter (`String get x => translate('x');`) — snake_case map keys, camelCase getters, real Vietnamese. Prefer existing keys.
- One-accent policy (spec §3/§5): gold ≤1×/view for decorative accents; theme-driven active-state affordances are system-level (PR3 ruling, PR #37 body).
- Report document files (lib/widgets/report/) keep fixed `PlutusTokens.dark` inks — Task 3's ink sweep NEVER touches them, nor the avatar-editor painter literals.
- No new pub dependencies. Conventional commits. Stage exact paths only — never `git add -A`. Never run whole-file `dart format`. `docs/` is gitignored — the Task 7 doc needs `git add -f`.
- **THE PR4 EXIT CRITERION:** `grep -rn "AppColors\|GlassContainer\|GlassBackground\|AppElevation\|AppGradients" lib/ test/ --include="*.dart"` returns ZERO hits (code, imports, and comments alike).

## Locked judgment calls (decided at plan time — cite, don't re-litigate)

1. **Web/wide top-bar navigation (spec §5) is EXCLUDED from PR4.** PR2 made the documented call to keep the retokenized floating bottom bar at all widths; that call shipped in two merged PRs (#36, #37) whose bodies flagged it without owner override. The PR4 body flags it one final time as the standing open item. Do NOT build it.
2. **`AppMotion` extraction:** spec §2 keeps AppMotion; `app_elevation.dart` (its current host) dies. AppMotion moves VERBATIM to new `lib/theme/app_motion.dart`. Survey-verified: 6 importers, all using only AppMotion members; `AppElevation.low/medium/high` have ZERO callers; `AppGradients.*` has ZERO callers.
3. **`onStatus` token** formalizes PR2/PR3's blessed "white content ink on `.dot` status fills" precedent as a computed getter. The Sell FAB is NOT a status fill (brandNavy) — it takes the brightness-aware ink idiom Task 13 of PR3 established for the insights FABs, not onStatus.
4. **Chart dot threshold flips to `< 30`** (dots on sparse series, none on dense). PR3's final review identified the plan wording "no dots below ~30 points" as a slip implemented faithfully; standard charting practice governs.
5. **Web shell scope = `web/index.html` only.** `manifest.json` already carries navy `#0B0E2A` for `background_color`/`theme_color` (verified), and `web/favicon.png` + `web/icons/` exist from the brand PR — Task 2 verifies these and edits only index.html (splash colors + gold hairline + `theme-color` meta).
6. **The before/after summary doc is spec-mandated** (§11: "Before/after summary per screen (written in PR4)") — it overrides the repo's default "no summary files" rule by explicit spec deliverable.

---

### Task 1: Delete the deprecated theme/glass layer, extract AppMotion

**Files:**
- Create: `lib/theme/app_motion.dart`
- Modify: `lib/router/app_router.dart` (:18 import, :58 comment), `lib/screens/dashboard_screen.dart` (:22 import), `lib/screens/main_navigation_page.dart` (:8 import), `lib/widgets/animated_theme_scope.dart` (:4 import, :20 + :150 comments), `lib/widgets/core/app_skeleton.dart` (:2 import), `lib/widgets/core/entrance_reveal.dart` (:2 import), `lib/widgets/core/app_canvas.dart` (:6 comment)
- Delete: `lib/theme/app_colors.dart`, `lib/theme/app_elevation.dart`, `lib/theme/app_gradients.dart`, `lib/widgets/glass_container.dart`, `lib/widgets/glass_background.dart`, `test/theme/on_accent_contrast_test.dart`

**Interfaces:**
- Produces: `lib/theme/app_motion.dart` exporting `class AppMotion` with the EXACT existing members (`static const Duration fast/medium/slow`; `static const Curve standard/emphasized`) — copied verbatim from app_elevation.dart:127-135 including its doc comment.

- [ ] **Step 1: Deletion guards (STOP on any hit).** From the worktree root run each; every one must return ONLY the file itself / nothing:
  - `grep -rln "app_colors" lib/ test/ --include="*.dart"` → only `lib/theme/app_colors.dart`, `lib/widgets/glass_container.dart`, `lib/widgets/glass_background.dart`, `test/theme/on_accent_contrast_test.dart` (all on the delete list)
  - `grep -rln "glass_container\|glass_background" lib/ test/ --include="*.dart"` → only the two shim files themselves
  - `grep -rn "AppElevation\.\|AppGradients\." lib/ test/ --include="*.dart"` → only `lib/widgets/glass_container.dart:93` (on the delete list) and the doc comment in app_colors.dart:155 (dies too)
  - `grep -rln "AppMotion" test/ --include="*.dart"` → nothing (no test pins AppMotion)
  If ANY other file appears, STOP and report BLOCKED with the hit.
- [ ] **Step 2: Create `lib/theme/app_motion.dart`** — new file containing exactly: the `AppMotion` class block from `lib/theme/app_elevation.dart` (lines ~127-135: the class doc comment, `fast`=150ms, `medium`=250ms, `slow`=400ms, `standard`=Curves.easeInOutCubic, `emphasized`=Curves.easeOutCubic) plus the single `import 'package:flutter/animation.dart';` (or `material.dart` if the class body needs it — match what the members actually require; `Curves`/`Duration` need only `animation.dart`... verify with analyze). Add file-level doc: `/// Motion constants for the gold/navy design system (spec §2: fast 150 / medium 250 / slow 400, easeOutCubic emphasis).`
- [ ] **Step 3: Repoint the 6 importers** — in app_router.dart:18, dashboard_screen.dart:22, main_navigation_page.dart:8, animated_theme_scope.dart:4, app_skeleton.dart:2, entrance_reveal.dart:2 replace the `.../theme/app_elevation.dart` import with the same-depth `.../theme/app_motion.dart`. No other changes to these lines.
- [ ] **Step 4: Delete the five lib/test files** — `git rm lib/theme/app_colors.dart lib/theme/app_elevation.dart lib/theme/app_gradients.dart lib/widgets/glass_container.dart lib/widgets/glass_background.dart test/theme/on_accent_contrast_test.dart`
- [ ] **Step 5: Tidy the four stale doc comments** (they reference deleted types; the exit grep catches comment mentions too):
  - app_router.dart:58 — rewrite the sentence so it references `AppCanvas` instead of `GlassBackground` (keep its meaning: route transitions read as one continuous surface).
  - animated_theme_scope.dart:20 and :150 — replace the `GlassBackground` example references with `AppCanvas`.
  - app_canvas.dart:6 — change ``Replaces the legacy [GlassBackground].`` to `Replaces the legacy glass background surface.` (square-bracket dartdoc ref would dangle).
- [ ] **Step 6: Verify** — exit grep from Global Constraints → ZERO hits; `grep -rln "AppMotion" lib/` → `lib/theme/app_motion.dart` + the 6 consumers; `flutter analyze lib` → 0; full `flutter test` → all green (count drops vs 605 by the deleted contrast test's cases — RECORD the new count in your report); `flutter test test/theme/` green (remaining theme tests untouched).
- [ ] **Step 7: Commit**

```powershell
git add lib/theme/app_motion.dart lib/router/app_router.dart lib/screens/dashboard_screen.dart lib/screens/main_navigation_page.dart lib/widgets/animated_theme_scope.dart lib/widgets/core/app_skeleton.dart lib/widgets/core/entrance_reveal.dart lib/widgets/core/app_canvas.dart
git rm lib/theme/app_colors.dart lib/theme/app_elevation.dart lib/theme/app_gradients.dart lib/widgets/glass_container.dart lib/widgets/glass_background.dart test/theme/on_accent_contrast_test.dart
git commit -m "refactor(theme)!: delete AppColors/glass/elevation/gradients shims, extract AppMotion"
```

---

### Task 2: Web splash shell branding (spec §6)

**Files:**
- Modify: `web/index.html`

- [ ] **Step 1: Verify the untouched pieces** (report evidence, change nothing): `web/manifest.json` has `"background_color": "#0B0E2A"` and `"theme_color": "#0B0E2A"`; `web/favicon.png` and `web/icons/` exist. If manifest values differ, fix them to `#0B0E2A` and note it.
- [ ] **Step 2: Splash palette** — in index.html's `#plutus-splash` CSS (lines ~39-62): the spec (§6) mandates a FIXED navy-950 splash. Set `background: #0B0E2A;` unconditionally and DELETE the `prefers-color-scheme: dark` override block (the light-mode `#fdf2f8` legacy pink dies).
- [ ] **Step 3: Gold progress hairline** — under the centered logo img, add a thin indeterminate gold hairline per spec ("thin gold progress hairline"). Inside `#plutus-splash`, after the `<img>`, add:

```html
<div id="plutus-splash-bar"><div></div></div>
```

and CSS (inside the existing `<style>` block):

```css
#plutus-splash-bar {
  width: 160px;
  height: 2px;
  margin-top: 24px;
  background: rgba(201, 151, 15, 0.25);
  overflow: hidden;
  border-radius: 1px;
}
#plutus-splash-bar > div {
  width: 40%;
  height: 100%;
  background: #C9970F;
  border-radius: 1px;
  animation: plutus-splash-sweep 1.2s ease-in-out infinite;
}
@keyframes plutus-splash-sweep {
  0% { transform: translateX(-100%); }
  100% { transform: translateX(350%); }
}
```

Make `#plutus-splash` a column flexbox (`display: flex; flex-direction: column; align-items: center; justify-content: center;`) if it isn't already, so logo + bar center as a stack. Preserve the existing fade-out script behavior (the whole `#plutus-splash` div still fades and is removed on first frame).
- [ ] **Step 4: theme-color meta** — in `<head>`, add `<meta name="theme-color" content="#0B0E2A" />` (index.html currently has none).
- [ ] **Step 5: Verify** — `flutter build web --release --no-tree-shake-icons --source-maps --dart-define=FLUTTER_WEB_AUTO_DETECT=true --dart-define-from-file=app.env` succeeds (app.env exists in the worktree root). Visual splash check happens in Task 8's controller smoke.
- [ ] **Step 6: Commit** — `git add web/index.html && git commit -m "feat(web): navy splash shell with gold progress hairline and theme-color"` (include web/manifest.json only if Step 1 changed it).

---

### Task 3: `onStatus` ink token + status-fill ink consolidation

**Files:**
- Modify: `lib/theme/plutus_tokens.dart`, `lib/widgets/import/import_feedback.dart`, `lib/screens/insights_screen.dart` (:77), `lib/screens/report_preview_screen.dart` (2 snackbars incl. the SnackBarAction), `lib/widgets/export_dialog.dart` (1 snackbar), `lib/widgets/export_preview_dialog.dart` (2 snackbars), `lib/screens/investment_detail_screen.dart` (:289-290 Sell FAB), plus any additional `Colors.white`-ink-on-`.dot`-fill sites the Step 2 grep surfaces (list each in the report)

**Interfaces:**
- Produces: `Color get onStatus => const Color(0xFFFFFFFF);` as a GETTER on `PlutusTokens` (computed, both themes, excluded from copyWith/lerp exactly like `goldSelectedFill`), doc comment: `/// Fixed white ink for content on saturated status fills (.dot arms): snackbars, count badges. Pairs with .dot the way onGold pairs with gold.`

- [ ] **Step 1: Add the getter** to `PlutusTokens` next to `goldSelectedFill` (it is the precedent: a computed getter, no constructor field, no lerp change). Run `flutter test test/theme/` — must stay green (if `plutus_tokens_test.dart` pins a member count and fails, update that expectation minimally and record it).
- [ ] **Step 2: Find every consolidation site** — `grep -rn "Colors.white" lib/ --include="*.dart"` and keep ONLY hits where the white is content ink sitting on a `.dot`-filled SnackBar/badge/container. KNOWN sites: import_feedback.dart (helper content ink), insights_screen.dart:77 (unread badge on `t.error.dot`), report_preview_screen.dart (success + failure snackbars: content ink AND the success `SnackBarAction(textColor: Colors.white)`), export_dialog.dart (error snackbar ink), export_preview_dialog.dart (warning + error snackbar inks), investment_list_screen.dart + transaction_history_page.dart snackbars IF they carry explicit white ink on `.dot` fills. EXCLUDED (do not touch): lib/widgets/report/ (fixed doc palette), avatar_editor painter literals (:~422/:~440, brightness-independent by design, commented), main_navigation_page/investment_detail FAB inks (Step 3 handles the Sell FAB; others are on brand fills, not status fills), any white that is a fill rather than ink.
- [ ] **Step 3: Swap ink at each site** — `const TextStyle(color: Colors.white...)` → `TextStyle(color: t.onStatus...)` (drop `const` where needed; each file already has a `t` local or add `final PlutusTokens t = context.tokens;`). import_feedback.dart keeps its public signature; its doc comment gains "ink: t.onStatus". The Sell FAB (investment_detail_screen.dart:289-290) instead takes the brightness-aware idiom from insights_screen.dart:46: `final Color sellInk = Theme.of(context).brightness == Brightness.dark ? t.onGold : Colors.white;` applied to both the icon color and label style (brandNavy is pale in dark theme — white ink fails there; this mirrors the insights FAB fix PR3 shipped).
- [ ] **Step 4: Verify** — `grep -n "Colors.white" <each modified file>` → remaining hits only where Step 2 excluded them (justify each in the report); `flutter analyze lib` → 0; full `flutter test` → green at the Task 1-recorded count.
- [ ] **Step 5: Commit** — `git add lib/theme/plutus_tokens.dart lib/widgets/import/import_feedback.dart lib/screens/insights_screen.dart lib/screens/report_preview_screen.dart lib/widgets/export_dialog.dart lib/widgets/export_preview_dialog.dart lib/screens/investment_detail_screen.dart` (+ any Step 2 extras actually modified) `&& git commit -m "feat(theme): onStatus ink token, brightness-aware Sell FAB ink"`

---

### Task 4: Chart dot threshold + insights chip idiom (final-review polish)

**Files:**
- Modify: `lib/screens/investment_detail_screen.dart` (:600), `lib/screens/insights_screen.dart` (:188-231, the two ChoiceChips)

- [ ] **Step 1: Flip the dot threshold** — investment_detail_screen.dart:600: `show: spots.length >= 30,` → `show: spots.length < 30,` and update any adjacent comment to say "dots only on sparse series (<30 points); dense lines stay clean" (Locked call #4).
- [ ] **Step 2: Align the two insights period ChoiceChips to the selected-chip idiom** (history/transaction chips are the reference: selected = goldSelectedFill fill + gold hairline + goldText label; unselected = surfaceSubtle + textSecondary). For BOTH ChoiceChips (preset ~:193 and custom-range ~:211), keeping all existing behavior/props:

```dart
selectedColor: t.goldSelectedFill,
backgroundColor: t.surfaceSubtle,
side: BorderSide(color: selected ? t.gold : t.border),
labelStyle: TextStyle(
  color: selected ? t.goldText : t.textSecondary,
  fontSize: 12,
  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
),
```

For the custom chip use its own selected expression (`provider.hasCustomDateRange`) in place of `selected`. NOTE the one-accent check: only ONE chip in the row is ever selected at a time (period presets and custom range are mutually exclusive by provider state) — the gold ring stays singular; state this verification in your report after reading the provider's setter logic (`setSelectedPeriod` clears the custom range — confirm in lib/providers, one focused read).
- [ ] **Step 3: Verify** — `flutter analyze lib` → 0; full `flutter test` green at the recorded count.
- [ ] **Step 4: Commit** — `git add lib/screens/investment_detail_screen.dart lib/screens/insights_screen.dart && git commit -m "fix(polish): sparse-series chart dots, gold-ring insights period chips"`

---

### Task 5: Residual l10n sweep (pre-existing EN literals in redesigned files)

**Files:**
- Modify: `lib/widgets/import/file_preview_table.dart`, `lib/widgets/import/ai_category_field.dart` (:38), `lib/screens/investment_list_screen.dart` (:301), `lib/l10n/app_localizations.dart`
- Tests: `test/widgets/import/file_preview_table_test.dart`, `test/widgets/import/ai_category_field_test.dart` (update expectations MINIMALLY if they pin the literals; record exactly what/why)

- [ ] **Step 1: Check the maps first** — the import screens already localize `date`/`payee`/`amount`/`category` style labels (PR3 Task 8 batch). `grep -n "'date'\|'payee'\|'amount'\|'category'\|'select'" lib/l10n/app_localizations.dart` and reuse every existing key. Add only what's missing, EN + VI + getter each:
  - `categorizing` EN `'Categorizing...'` / VI `'Đang phân loại...'` (compose the count: `'${l10n.categorizing} $aiProgress/$aiTotal'`)
  - `transactionsFoundSelected` — file_preview_table.dart:62 interpolates two counts mid-sentence; `translate` has no placeholders, so split: `transactionsFound` EN `'transactions found,'` / VI `'giao dịch được tìm thấy,'` and `selectedCount` EN `'selected'` / VI `'đã chọn'`, composed as `'${transactions.length} ${l10n.transactionsFound} ${selectedIndices.length} ${l10n.selectedCount}'`
  - `select` EN `'Select'` / VI `'Chọn'` (dropdown hint :205) — reuse if present
  - `unitsSuffix` EN `'units'` / VI `'đơn vị'` (investment_list_screen.dart:301, composed after the quantity)
- [ ] **Step 2: Wire the literals** — file_preview_table.dart: :62 (compose), :75 (categorizing), :159-163 DataColumn labels → existing `date`/`payee`/`amount`/`category` keys (the empty first column stays `Text('')`), :205 hint → select key; ai_category_field.dart:38 `labelText: 'Category'` → the existing category key; investment_list_screen.dart:301 `'... ${investment.quantity} units'` → `'... ${investment.quantity} ${l10n.unitsSuffix}'`. NOTE: file_preview_table's widgets receive l10n how the file already does (check for an existing `AppLocalizations.of(context)` — add the standard lookup if absent).
- [ ] **Step 3: Verify** — `flutter test test/widgets/import/` green (record any minimal expectation updates); `flutter analyze lib` → 0; full `flutter test` green at the recorded count.
- [ ] **Step 4: Commit** — `git add lib/widgets/import/file_preview_table.dart lib/widgets/import/ai_category_field.dart lib/screens/investment_list_screen.dart lib/l10n/app_localizations.dart test/widgets/import/ && git commit -m "fix(l10n): localize residual import-table and investment strings"` (include only test files actually modified).

---

### Task 6: Dead `profile` parameter removal

**Files:**
- Modify: `lib/widgets/profile_widget.dart` (:72, :445, :659)

- [ ] **Step 1: Guard** — `grep -n "_showAvatarPicker" lib/widgets/profile_widget.dart` → exactly the definition (:72) + two call sites (:445, :659); confirm the `profile` param is unread inside the method body (PR3's Task 10 review verified this; re-verify).
- [ ] **Step 2: Remove** — `void _showAvatarPicker(Profile profile)` → `void _showAvatarPicker()`; call sites `onTap: () => _showAvatarPicker(profile)` → `onTap: _showAvatarPicker` (tear-off; keep the closure form `() => _showAvatarPicker()` if the surrounding code style demands it — match the file).
- [ ] **Step 3: Verify** — `flutter analyze lib` → 0; full `flutter test` green at the recorded count.
- [ ] **Step 4: Commit** — `git add lib/widgets/profile_widget.dart && git commit -m "refactor(widgets): drop dead profile param from avatar picker"`

---

### Task 7: Before/after summary doc (spec §11 deliverable)

**Files:**
- Create: `docs/superpowers/redesign-before-after.md`

- [ ] **Step 1: Write the doc** — one markdown table over every redesigned surface, sourced from spec §7's per-screen table (read `docs/superpowers/specs/2026-07-29-gold-navy-redesign-design.md` §7) and the merged PR descriptions (`gh pr view 35 --json body -q .body`, same for 36 and 37). Columns: **Surface | Before (legacy idiom) | After (gold/navy idiom) | PR**. Rows: nav chrome, dashboard grid + each widget family (budget, bills, tax, investments, trends, breakdown, heatmap, history card, profile), login/user-selection, settings, backup + dialogs, import tabs, transaction history page + detail dialog, budget sheet + avatar editor, investment list/detail + dialogs, insights + widgets, report document (cover/sections/config/preview/export), web shell (this PR). Keep each cell to one phrase (e.g. "dark glass card, white ink" → "AppCard, token ink, hairline border"). Header note: palette + principles in two lines (navy structure / gold ≤1 accent / status quartets / fixed navy report document). ~60-90 lines total — a summary, not a spec copy.
- [ ] **Step 2: Commit (force-add — docs/ is gitignored)**

```powershell
git add -f docs/superpowers/plans/2026-07-31-gold-navy-pr4-web-shell-cleanup.md docs/superpowers/redesign-before-after.md
git commit --only docs/superpowers/redesign-before-after.md -m "docs(redesign): before/after summary per screen"
```

(The plan file is already committed at branch start; the `git add -f` line is safe if it shows as unchanged.)

---

### Task 8: Verification sweep

**Files:** none (verification only)

- [ ] **Step 1: THE PR4 EXIT CRITERION** — `grep -rn "AppColors\|GlassContainer\|GlassBackground\|AppElevation\|AppGradients" lib/ test/ --include="*.dart"` → ZERO hits. `grep -rln "AppMotion" lib/` → app_motion.dart + 6 consumers. Record both outputs.
- [ ] **Step 2:** Full `flutter analyze` → no issues beyond the 9-issue baseline (all pre-existing, none in lib/). Full `flutter test` → green at the Task 1-recorded count. `cd packages/dashboard && flutter test` → green except the pre-existing todo_test placeholder.
- [ ] **Step 3:** `flutter build web --release --no-tree-shake-icons --source-maps --dart-define=FLUTTER_WEB_AUTO_DETECT=true --dart-define-from-file=app.env` → succeeds.
- [ ] **Step 4: Visual smoke** (controller-run: serve build/web statically, Playwright, light + dark, 1280 + 390, guest profile):
  - Web splash: navy #0B0E2A both themes, centered logo, animated gold hairline, fades on first frame.
  - Browser tab/PWA chrome shows navy theme-color.
  - Insights period chips: gold ring + goldText on the single selected chip; neutral others.
  - Investment detail (seed one investment + 2 valuations): sparse series now SHOWS dots; Sell FAB ink legible in both themes.
  - Insights unread badge + one snackbar (e.g. failed export): white ink on dot fill unchanged visually.
  - App still renders everywhere post-shim-deletion (dashboard, history, import, settings, report preview) — no missing-symbol crashes, both themes, no overflow at 390.
- [ ] **Step 5:** Fix anything broken; re-run affected tests; commit fixes with `fix(...)` messages.

---

### Task 9: Push + open PR

- [ ] **Step 1:** `git push -u origin feat/web-shell-brand-cleanup`
- [ ] **Step 2:** `gh pr create --base main` — title `feat(web): navy splash shell and final shim deletion (redesign PR4)`; body per repo convention (Summary / Verification / Next) flagging: the exit-criterion grep outputs; AppMotion extraction; onStatus token; the web/wide top-bar nav as the LAST standing open spec item (owner: build later or close as accepted); "Next: redesign rollout complete — no PR5 planned".
- [ ] **Step 3:** Report the PR URL.

---

## Plan self-review record

- **Spec coverage:** §10 row 4 contents = web splash/favicon/manifest (T2: index.html; favicon+manifest verified already-branded), delete shims + glass widgets (T1, incl. §5's "glows are deleted with the shims" via AppElevation and §2.3's glass widgets), before/after summary doc (T7). §2 "AppMotion kept" (T1 extraction). §6 splash detail (navy-950 bg, centered logo, thin gold hairline, manifest+theme-color navy) = T2. PR3 final-review follow-up bundle = T3 (onStatus + Sell FAB), T4 (dots + chips), T5 (l10n), T6 (dead param). Exit criterion + smoke = T8; PR = T9. §5 web top-bar nav deliberately excluded (Locked call #1). §6 settings About-row icon stays non-applicable (no version source — verified in PR3).
- **Placeholder scan:** all steps carry exact code/values/paths; grep guards specify expected outputs; no TBDs. The T7 doc's content is enumerated (columns, rows, sources, length bound) rather than "write a summary".
- **Type consistency:** `AppMotion` members copied verbatim (fast/medium/slow/standard/emphasized — names verified against app_elevation.dart:127-135); `onStatus` getter mirrors the shipped `goldSelectedFill` getter pattern (computed, no field, no lerp); chip idiom fields match ChoiceChip's actual API (`selectedColor`, `backgroundColor`, `side`, `labelStyle`); T5 composes around `translate()`'s no-placeholder limitation exactly as PR3 did.
- **Known risks:** deleting on_accent_contrast_test changes the headline test count (handled: T1 records, later tasks gate on it); `plutus_tokens_test` may pin member behavior (T3 Step 1 runs it focused); file_preview_table tests may pin literals (T5 allows minimal recorded updates).
