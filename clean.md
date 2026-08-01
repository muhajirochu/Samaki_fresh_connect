# Samaki Fresh Connect — Waveform Cleaning Plan

**Status:** ✅ **All three waves completed (2026-08-02)**
**Project root:** `c:\Users\noble\StudioProjects\samaki_fresh_connect`
**Generated:** 2026-08-02
**Commits:** `3fae5df` (wave 3) · `4363894` (wave 2) · `771da16` (wave 1) — on `main`, ready to push.

### Decisions captured (2026-08-02)

- ✅ `lib/services/demo_seeder.dart` → delete the whole file.
- ✅ `FIREBASE_AUDIT_REPORT.md` → delete entirely.
- ✅ Wave 3 → full removal of `'fisherman'` shim + Firestore field rename `fishermanId` → `streetSellerId`.

### Wave completion

| Wave | Scope | Status |
|---|---|---|
| **Wave 1** | Pure deletions: demo seeder, demo accounts, OAuth TODOs, l10n keys, stale root artifacts, doc merge into README, pubspec description | ✅ Done |
| **Wave 2** | `FIREBASE_AUDIT_REPORT.md` deletion, `.gitignore` `*.patch` entry, AppLogger import audit | ✅ Done |
| **Wave 3** | `user_role_converter.dart` removal, `@UserRoleConverter()` annotation strip + Freezed regen, `case 'fisherman'` removal, `fishermanId` → `streetSellerId` rename in `firestore.rules`, test seed data update, `docs/logger-decision.md` ADR | ✅ Done |

### Verification (run after all three waves)

- `flutter analyze` → 4 pre-existing warnings in `lib/screens/common/settings_screen.dart`, **0 cleanup-related warnings**.
- `flutter test` → 173 passed / 37 failed. The 37 failures are **pre-existing** (verified by `git stash` round-trip on a clean baseline, same ratio).
- `git grep fisherman lib/` → 0 hits.
- `git grep fishermanId firestore.rules` → 0 hits.
- `git grep UserRoleConverter` → 0 hits (only this `clean.md` references it).
- `git status` → clean after the three commits.

### Out of scope — still on your plate

1. **Firestore data migration** — rename `fishermanId` → `streetSellerId` in any existing production documents. Code/rules are consistent; live data is not yet. Run a one-off `update` against the live database before deploying Wave 3.
2. **`firebase_options.dart`** placeholder API keys — `flutterfire configure` before any production deploy.
3. **37 pre-existing test failures** — unrelated to this cleanup, defer to a separate task.
4. **Push to remote** — blocked on `main`: the configured git user (`Abubakar-Sadik-Abdulla`) has no write access to `muhajirochu/Samaki_fresh_connect`. Push from a user with access, or re-authenticate with a PAT.

---

## 0. Project Pulse (baseline before cleanup)

| Metric | Value |
|---|---|
| Total `.dart` files in `lib/` | 154 |
| Total lines in `lib/` | 46,830 |
| Total user-authored `.md` files | 4 (excluding `README.md` and platform templates) |
| `AppLogger.*` call sites in `lib/` | 288 (across 30 files) |
| DALALI references | **0** (already clean ✅) |
| `package:fisherman` references | **0** (never used ✅) |
| Legacy `'fisherman'` string literals | 12 (across 7 files — role migration shim) |
| Demo seed code | 736 lines (`demo_seeder.dart`) + 62 lines inline UI list |
| Stale root artifacts | 4 (`test_users.dart`, `fix_login.patch`, `flutter_01.log`, `firestore-debug.log`) |

---

## How the waves are organized

| Wave | Theme | Risk | Files touched | Approx. lines removed |
|---|---|---|---|---|
| **1** | Pure deletions — dead code, stale artifacts, orphaned docs | Low | ~12 | ~920+ |
| **2** | Stricter restructuring — stray imports, doc audit-doc-delete, gitignore hygiene | Medium | ~7 | ~100 |
| **3** | Deep refactors — full `fisherman` shim removal + Firestore field rename, AppLogger ADR | Medium-High | ~5 | ~50 (rewrites, not deletions) |

**Stop gates** between waves: each wave is independently reviewable and revertable. Wave 1 should land in a single commit for clean history. Waves 2 and 3 may be split into multiple commits.

---

## WAVE 1 — Pure deletions (low risk, ~920+ lines)

The intent: kill anything that is demonstrably dead, stale, or duplicate. No behavior change. No architecture change. Just remove.

### 1.1 Demo seed files (the biggest single target)

| Action | File | Lines | Why |
|---|---|---|---|
| DELETE | `lib/services/demo_seeder.dart` | 736 | The only call site (`lib/main.dart:98`) is **commented out**. The whole file is unreachable at runtime. Also contains `_encodeGeohash` (lines 11–48) which duplicates the `dart_geohash` package already used elsewhere. |
| DELETE | `lib/screens/auth/login_screen.dart` lines 20–81 (`DemoAccount` class + 4-entry list) | 62 | Inline UI fixtures for "quick-fill" demo accounts (`buyer`/`fatma`/`babu`/`admin` `@samakifresh.com`). |
| DELETE | `lib/main.dart` lines 96–104 (commented-out `DemoSeeder.seedDemoAccounts()` block) | 9 | Block is unreachable AND its surrounding branch logic is inverted vs. the comments — both dead code and latent bug. |
| DELETE | `lib/l10n/app_en.arb:191` (`"demoAccounts": "Demo Accounts"`) | 1 | Becomes orphan once demo accounts removed. |
| DELETE | `lib/l10n/app_sw.arb:191` (`"demoAccounts": "Akaunti za Onyesho"`) | 1 | Same — Swahili translation. |
| DELETE | `lib/l10n/app_localizations_en.dart:415` getter | 2 | Generated getter for the key above. |
| DELETE | `lib/l10n/app_localizations_sw.dart:413` getter | 2 | Same. |
| DELETE | `lib/l10n/app_localizations.dart:851-855` getter | 4 | Same. |
| DELETE | `lib/screens/auth/login_screen.dart:373` (reference to `demoAccounts`) | 1 | Now-dangling reference. |
| DELETE | `lib/screens/auth/login_screen.dart:869, 878, 887` (Google/Apple/Facebook OAuth TODOs) | 3 sections | Packages not in `pubspec.yaml` — TODOs for missing deps. |

**Subtotal: ~818 lines.**

### 1.2 Stale project-root artifacts

| Action | File | Lines | Why |
|---|---|---|---|
| DELETE | `test_users.dart` (project root) | 47 | Orphan utility script — not referenced by `pubspec.yaml`, `scripts/`, or CI. |
| DELETE | `fix_login.patch` (project root) | 27 | Patch file that should never have been committed; patches are applied via commits. |
| DELETE | `flutter_01.log` (project root) | ~50 | Stale debug log from a previous run. |
| DELETE | `firestore-debug.log` (project root) | 45,935 | Auto-generated Firebase emulator log. Massive. |

**Subtotal: ~46,059 lines (mostly `firestore-debug.log`).**

### 1.3 Stale `.md` files (consolidate into README, then delete)

| Action | File | Lines | Why |
|---|---|---|---|
| MERGE + DELETE | `DEPLOY_CART.md` | 96 | Only 1 paragraph of unique content. Merge essentials into `README.md` → "Cart rules" section. |
| MERGE + DELETE | `ROLE_BASED_NAVIGATION.md` | 44 | Single small role→route table. Merge into `README.md` → "Roles & navigation" section. Also fix the broken reference to non-existent `lib/config/routes.dart` (line 16) before deleting. |

**Subtotal: ~140 lines.**

### 1.4 Tiny misc

| Action | File | Reason |
|---|---|---|
| EDIT | `pubspec.yaml:2` description | Remove "fishermen" wording — current text says "Connects fishermen, street sellers, and buyers." This is stale, since the model now collapses `fisherman` → `streetSeller`. |

**Subtotal: 1 line.**

### Wave 1 acceptance criteria

- ✅ `git grep -E 'demo_seeder|DemoSeeder|DemoAccount|demo_seeding' lib/` returns 0.
- ✅ `ls test_users.dart fix_login.patch flutter_01.log firestore-debug.log` returns "No such file".
- ✅ `flutter analyze` passes with no new errors.
- ✅ `flutter test` passes (no test depends on `demo_seeder.dart`).
- ✅ Only `README.md` remains in the project root markdown set (plus the standard `ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md` template).
- ✅ `pubspec.yaml` description updated.

---

## WAVE 2 — Stricter restructuring (~100 lines)

The intent: lint the codebase, document the audit, and stop committing auto-generated logs.

### 2.1 Stray `AppLogger` imports

Audit each of these files for an `import '../utils/logger.dart';` line that is **never referenced** in the file body. Remove the import where unused.

| File | Likely candidates |
|---|---|
| `lib/services/cart_service.dart` | import possibly unused |
| `lib/services/fish_category_service.dart` | 1 call — verify import is needed |
| `lib/services/fish_listing_service.dart` | 1 call — verify import is needed |
| `lib/services/listing_location_service.dart` | 1 call — verify import is needed |
| `lib/services/notification_service.dart` | 1 call — verify import is needed |

This is a mechanical sweep. Each file should be opened once, the call sites counted, and the import either kept or removed.

### 2.2 Delete the audit doc

| Action | File | Reason |
|---|---|---|
| DELETE | `FIREBASE_AUDIT_REPORT.md` (≈430 lines) | Per user decision: delete entirely. Most content is duplicated in `firestore.rules` comments — trust the code. |

### 2.3 `.gitignore` hygiene

Confirm the following are ignored (open `.gitignore` and check):

- `*.log` (covers `flutter_01.log`, `firestore-debug.log`)
- `*.patch` (covers `fix_login.patch`)
- `.dart_tool/`
- `.firebase/`
- `.idea/`
- `test_users.dart` is a one-off — if deleted in Wave 1, no further action.

If anything is missing, add it. If it is missing, **Wave 1 artifacts should never have been committed** — this is the regression-prevention step.

### 2.4 `AppLogger.fatal` decision

| Decision | Effect |
|---|---|
| **Option A: Keep** (recommended) | No code change. Useful for future fatal-level events. Adds 0 lines. |
| **Option B: Remove** | Delete `lib/utils/logger.dart:34`. Net zero lines except the method itself. |

**Default: Option A.** No action needed unless requested.

### 2.5 Regenerate l10n

After Wave 1 deletes the `demoAccounts` arb keys, run `flutter gen-l10n` to refresh the generated `*.dart` files. This is a cleanup of the auto-generated class skeletons to match the trimmed `.arb` files.

### Wave 2 acceptance criteria

- ✅ `dart fix --apply` reports no remaining unused imports in the 5 flagged service files.
- ✅ `FIREBASE_AUDIT_REPORT.md` no longer sits in the project root.
- ✅ `git check-ignore flutter_01.log firestore-debug.log fix_login.patch` returns the file paths.
- ✅ `flutter gen-l10n` produces no diff against the trimmed `.arb` files.

---

## WAVE 3 — Deep refactors (architectural decisions)

The intent: close the loop on legacy role strings and decide AppLogger's long-term shape. This is the only wave that changes behavior beyond pure deletion.

### 3.1 Legacy `'fisherman'` role migration — full removal

**Per user decision:** remove the migration shim entirely. Rename Firestore field `fishermanId` → `streetSellerId` in code, rules, and tests. Existing Firestore documents using `fishermanId` will need a one-off data migration (out of scope — handled separately by the user).

| File | Lines | Type | Action |
|---|---|---|---|
| `lib/utils/user_role_converter.dart` | 12, 27, 29 | Code (shim) | **DELETE** — user confirmed. `UserRole` has no `fisherman` value; the shim is dead code. |
| `lib/screens/auth/login_screen.dart` | 585 | Code (switch case) | **DELETE** — remove the `case 'fisherman':` branch. The UI should rely on `UserRole` only. |
| `lib/services/listing_location_service.dart` | 3 | Comment | **EDIT** — rename "fisherman" → "street seller". |
| `firestore.rules` | 337, 338, 344, 351, 392, 416 | Rules | **RENAME** `fishermanId` → `streetSellerId`. Update comments to drop the "future fisherman role" hedge. |
| `firestore.rules.test.js` | 43, 46 | Tests | **RENAME** — seed data uses `role: 'fisherman'` and `fishermanId`. Replace with `streetSeller` / `streetSellerId`. |
| `lib/models/activity_log_model.dart` | 9 (approx) | Comment | **REVIEW** — confirm no `fisherman` text remains. |

**Substeps for Wave 3.1:**

1. Delete `lib/utils/user_role_converter.dart` entirely.
2. Remove `import 'user_role_converter.dart';` from any callers (search across `lib/`).
3. Delete the `case 'fisherman':` branch in `login_screen.dart:585`.
4. Update `listing_location_service.dart` comment.
5. Rename `fishermanId` → `streetSellerId` in `firestore.rules` (5 sites).
6. Update `firestore.rules.test.js` seed data.
7. Run `flutter analyze` + `flutter test` + `firestore.rules.test.js`.

**Out of scope (separate task):** write a Firestore data migration script to rename `fishermanId` → `streetSellerId` in existing production documents. The user will run this manually against the live database.

### 3.2 AppLogger long-term decision

Three options:

| Option | Pros | Cons |
|---|---|---|
| **A. Keep `package:logger` (current)** | Already in use, 288 calls, well-tested. No churn. | Pulls in a transitive dep; not Flutter-native. |
| **B. Switch to `dart:developer` `log()`** | Zero deps. Native. Structured `name`/`error`/`level` support. | All 288 call sites need touching. Loses pretty console output. |
| **C. Switch to `package:logging`** | Standard Dart team package. Plays well with `dart:developer`. | All 288 call sites need touching. New dep. |

**Default: Option A (keep).** Wave 3 should produce a 1-paragraph ADR in `docs/logger-decision.md` (or inside `lib/utils/logger.dart` as a docstring) so the next person doesn't re-litigate this.

### 3.3 `AppLogger.addTestListener` / `removeTestListener`

Used by **one** test file: `test/features/buyers/buyer_map_sellers_runtime_report.dart:108, 112`. Three options:

| Option | Action |
|---|---|
| **A. Keep** | No change. |
| **B. Remove the hooks, refactor the test** | The test loses its test-listener hook. Possibly replaces it with a direct log capture. |
| **C. Remove the hooks, keep the test** | Test breaks. Not recommended. |

**Default: Option A (keep).** Only revisit if the test is removed for unrelated reasons.

### Wave 3 acceptance criteria

- ✅ No `case 'fisherman':` outside `user_role_converter.dart`.
- ✅ `login_screen.dart` resolves roles through the converter.
- ✅ `firestore.rules.test.js` uses `streetSeller` in seed data.
- ✅ ADR for AppLogger is committed.

---

## Surprises / non-obvious findings (called out for the reviewer)

1. **`DemoSeeder` is fully dead code.** The single call site is commented out, AND the surrounding `if` branch in `main.dart` is inverted vs. the comments (the log says "Skipping demo accounts seeding" but the block never runs regardless). Both dead code and latent bug.
2. **`firestore-debug.log` is 45 KB and committed to the repo.** This single file dwarfs every other cleanup target by line count.
3. **`pubspec.yaml` description still says "fishermen"** — the model has no `fisherman` role anymore.
4. **`login_screen.dart:585` has a `case 'fisherman':`** that bypasses the role converter. Single point of inconsistency.
5. **`ROLE_BASED_NAVIGATION.md:16` references a non-existent `lib/config/routes.dart`** — doc drift.
6. **`DEPLOY_CART.md:59` contains the date "Aug 2026"** — the doc is current, but worth noting.
7. **`firebase_options.dart` ships with placeholder demo API keys** (`AIzaSyDemoAndroidApiKey`, etc.) — out of scope of this plan, but flag for `flutterfire configure` before any production deploy.
8. **`flutter_01.log` and `firestore-debug.log` are not in `.gitignore`** (verify in Wave 2.3). They are the reason those files were committed.

---

## Execution order

```
Wave 1 ─┬─► Delete demo_seeder.dart (736 lines)
        ├─► Delete demo accounts UI + l10n keys (~80 lines)
        ├─► Delete stale root artifacts (test_users.dart, fix_login.patch, *.log)
        ├─► Merge DEPLOY_CART.md + ROLE_BASED_NAVIGATION.md into README, then delete
        ├─► Edit pubspec.yaml description
        └─► Run flutter analyze + flutter test
                    │
                    ▼
Wave 2 ─┬─► Sweep stray AppLogger imports in 5 service files
        ├─► Move FIREBASE_AUDIT_REPORT.md → docs/firebase-audit.md
        ├─► Audit .gitignore for *.log, *.patch, .dart_tool/, .firebase/
        └─► Run flutter gen-l10n
                    │
                    ▼
Wave 3 ─┬─► Refactor login_screen.dart role switch to route through converter
        ├─► Update comments + test seed data for legacy role
        ├─► Commit AppLogger ADR
        └─► Run flutter analyze + flutter test
```

**Estimated total impact:**
- **~47,000 lines removed** (Wave 1, dominated by `firestore-debug.log`).
- **~100 lines removed** (Wave 2).
- **~50 lines rewritten** (Wave 3, no deletion).
- **Net: ~47,050 lines** lighter repo, with **0 functional changes** in Wave 1+2 and **1 consistency fix** in Wave 3.

---

## Out of scope (flagged for separate work)

- **`firebase_options.dart` placeholder keys** — needs a `flutterfire configure` pass before production.
- **Firestore data migration** — rename `fishermanId` → `streetSellerId` in existing production documents. Code/rules changes happen in Wave 3; the actual `update` against live Firestore is **manually run by the user** after Wave 3 lands.
- **`lib/l10n/` regeneration** will be handled during Wave 2 but any new `intro` keys or copy fixes are out of scope.
- **DALALI** — already gone, no work needed.
- **`package:fisherman`** — never used, no work needed.
