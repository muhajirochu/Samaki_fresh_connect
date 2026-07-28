# Samaki Fresh Connect

Mobile marketplace for Zanzibar's fish supply chain ecosystem. Connects
street sellers and buyers with a real-time, location-aware directory of
fresh fish listings.

## Stack

- **Flutter** (Dart 3) — Android, iOS, web, desktop
- **State** — [Riverpod](https://riverpod.dev/) (`hooks_riverpod` +
  `flutter_hooks`)
- **Routing** — `go_router`
- **Backend** — Firebase (Auth + Cloud Firestore), Cloudinary (image
  uploads), OSRM (routing), OSM (map tiles via `flutter_map`)
- **Local** — `shared_preferences` for prefs, `flutter_local_notifications`
  for buyer push notifications
- **Localisation** — `flutter_localizations` + ARB files (`lib/l10n/*.arb`)

## Roles

| Role          | Dashboard path              | What they do                                       |
|---------------|-----------------------------|----------------------------------------------------|
| `buyer`       | `/dashboard/buyer`          | Browse listings, search by fish type, place orders |
| `streetSeller`| `/dashboard/street_seller`  | Create / edit listings, track sales, see buyers    |
| `admin`       | `/dashboard/admin`          | Approve sellers, suspend users, manage categories  |

(`UserRole` lives in `lib/models/enums/user_role.dart`.)

## Project layout

```
lib/
├── config/          # Theme + GoRouter wiring
├── constants/       # AppColors, AppSizes, AppStrings
├── l10n/            # Generated AppLocalizations + .arb sources
├── models/          # Domain models (Freezed) + enums + Result<T,F>
├── providers/       # Riverpod providers (auth, listing, order, ...)
├── screens/         # Role-scoped screens (admin/auth/buyer/common/street_seller)
├── services/        # Firestore / Cloudinary / OSRM / geohash wrappers
├── utils/           # logger, validators, formatters, helpers
└── widgets/         # Shared UI components (cards, common, map, ...)
```

## Running

```sh
flutter pub get
flutter run                     # debug
flutter test                    # full test suite
flutter analyze                 # lints
dart run build_runner build     # regenerate Freezed / json_serializable
```

## Useful scripts

- `scripts/disable-http2.cjs` — required workaround for
  `firebase-tools` 15.x HTTP/2 regression when deploying Firestore
  indexes (`NODE_OPTIONS="--require ./scripts/disable-http2.cjs"`).
- `scripts/test_firestore_rules.sh` — runs `firestore.rules.test.js`
  against the local emulator.

## Operational docs

- [`FIREBASE_AUDIT_REPORT.md`](FIREBASE_AUDIT_REPORT.md) — Firestore
  rules / indexes audit (current).
- [`ROLE_BASED_NAVIGATION.md`](ROLE_BASED_NAVIGATION.md) — how each
  role is routed after login.

## Environment

Copy `.env.example` → `.env` and fill in the Firebase / Cloudinary
credentials. `.env` is gitignored.