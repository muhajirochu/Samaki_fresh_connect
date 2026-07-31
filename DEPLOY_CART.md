# Deploying the cart Firestore rules

The cart is a private subcollection at
`users/{buyerId}/cart/{listingId}`, gated by a single Firestore
Security Rules entry. The rules live in `firestore.rules` and look
like this:

```rules
match /cart/{listingId} {
  // The cart is private to the buyer. Not even an admin reads
  // it — nothing in the admin console surfaces cart contents...
  allow read, write: if isSelf(userId);
}
```

This block is part of the `match /users/{userId}` block, so `isSelf`
already has the right context.

## Deploying to a real Firebase project

The Firebase project that hosts the demo data is
`samaki-fresh-connect-dev`. The CLI's currently active project
(`firebase use` shows it) is the one to push to. If you are
authenticated under a different account than the one that owns
`samaki-fresh-connect-dev`, run `firebase login:use <email>` first.

To deploy ONLY the rules (no other Firebase resources touched):

```bash
firebase deploy --only firestore:rules
```

To deploy the rules AND the composite indexes at the same time:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

The full project ID is in `lib/firebase_options.dart`. The `authDomain`
and `storageBucket` in that file are the values to verify in the
Firebase console after the deploy.

## Why this needs its own deploy

`lib/firebase_options.dart` ships with demo API keys
(`AIzaSyDemoAndroidApiKey`, etc.) which are placeholders, not real
credentials. The Android debug build points at the local Firebase
emulator via `useFirestoreEmulator` in `lib/main.dart`, so the app on
a developer's machine talks to the emulator, not production. The
emulator reads the same `firestore.rules` file from disk, so any rule
change is picked up by the next `flutter run` against a freshly
restarted emulator.

A real-device build (release flavor) uses the production Firebase
project — that is the build where `firebase deploy` matters. The rules
file in source is the single source of truth, so a deploy promotes
the dev rules to production.

## What I verified on the emulator (Aug 2026)

1. `firebase emulators:start --only firestore,auth` reads the
   on-disk `firestore.rules` and the cart block above.
2. `flutter run` against the emulator binds via
   `FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8080)`.
3. The cart tab renders "Your cart is empty" against a real Firestore
   document stream — no `PERMISSION_DENIED` in the logs. Before this
   wiring, the same screen logged
   `users/{uid}/cart ... PERMISSION_DENIED` because the app was
   silently talking to production Firebase with the demo API key.

## If `firebase deploy` reports "Invalid project selection"

Your CLI session is not on the right project. Run:

```bash
firebase login:list          # see what you are signed in as
firebase login               # re-authenticate, if needed
firebase use --add samaki-fresh-connect-dev
```

`--add` registers the project as an alias so subsequent
`firebase use samaki-fresh-connect-dev` is enough. If the alias
already exists, `firebase use` will switch to it.

## If `firebase deploy` reports "Unable to verify project access"

The Firebase account you are signed into with the CLI does not own
the project. Either:

- Ask the project owner to add you under
  `Project settings → Users and permissions`, or
- Sign into an account that does own it via `firebase login:use`.

Do NOT paste a service-account JSON or API key into a chat window.
The correct path is to grant the right identity to your CLI
session.
