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

After a successful sign-in, the auth redirect in `lib/config/`
sends the user to the dashboard for their role. The route table
lives in `lib/config/route_paths.dart` (`AppRoutesExtensions.dashboardFor`).
The auth-route guard:

1. Bounces an unauthenticated user away from any protected path to
   `/login` (paths under `/splash`, `/login`, `/register` are the only
   exceptions).
2. Enforces an admin-only guard on `/admin/*` paths — non-admin users
   are sent to `/dashboard/street_seller` (sellers) or
   `/dashboard/buyer` (buyers).
3. If a logged-in user lands on an auth route, sends them to their
   role-specific dashboard.

## Cart Firestore rules

The cart is a private subcollection at
`users/{buyerId}/cart/{listingId}`, gated by a single Firestore
Security Rules entry. The rules live in `firestore.rules`:

```rules
match /cart/{listingId} {
  // The cart is private to the buyer. Not even an admin reads
  // it — nothing in the admin console surfaces cart contents...
  allow read, write: if isSelf(userId);
}
```

This block is part of the `match /users/{userId}` block, so `isSelf`
already has the right context.

### Deploying to a real Firebase project

The Firebase project that hosts the demo data is
`samaki-fresh-connect-dev`. The CLI's currently active project
(`firebase use` shows it) is the one to push to. If you are
authenticated under a different account than the one that owns
`samaki-fresh-connect-dev`, run `firebase login:use <email>` first.

To deploy the rules (and the composite indexes, if changed):

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:rules,firestore:indexes
```

The full project ID is in `lib/firebase_options.dart`. The `authDomain`
and `storageBucket` in that file are the values to verify in the
Firebase console after the deploy.

> `lib/firebase_options.dart` ships with demo API keys
> (`AIzaSyDemoAndroidApiKey`, etc.) which are placeholders, not real
> credentials. Run `flutterfire configure` before any production
> deploy.

### Emulator verification

`firebase emulators:start --only firestore,auth` reads the on-disk
`firestore.rules`. `flutter run` against the emulator binds via
`FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8080)`.
The cart tab renders "Your cart is empty" against a real Firestore
document stream — no `PERMISSION_DENIED` in the logs.

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

## Environment

Copy `.env.example` → `.env` and fill in the Firebase / Cloudinary
credentials. `.env` is gitignored.