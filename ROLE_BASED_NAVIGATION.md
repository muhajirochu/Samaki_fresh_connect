# Role-Based Navigation

After a successful sign-in, `lib/config/routes.dart:49-92` redirects
the user to the dashboard for their role. Roles are read from the
`UserRole` enum (`lib/models/enums/user_role.dart`) and the
`userRole` field on the signed-in user's Firestore doc.

## Current roles

| Role          | Dashboard route        | Notes                                          |
|---------------|------------------------|------------------------------------------------|
| `buyer`       | `/dashboard/buyer`     | Default for unknown / missing roles.           |
| `streetSeller`| `/dashboard/street_seller` | Sellers list fish, manage stock.           |
| `admin`       | `/dashboard/admin`     | Full admin shell with manage screens.          |

The legacy roles `fisherman` and `dalali` (broker) referenced in
earlier revisions of this doc were collapsed into `streetSeller` once
the data model settled. Create-listing / broker-approval flows now
live under `streetSeller`.

## Auth-route guard

`lib/config/routes.dart:49` uses an inline redirect that:

1. Bounces an unauthenticated user away from any protected path to
   `/login` (paths under `/splash`, `/login`, `/register` are the only
   exceptions).
2. Enforces an admin-only guard on `/admin/*` paths — non-admin users
   are sent to `/dashboard/street_seller` (sellers) or
   `/dashboard/buyer` (buyers).
3. If a logged-in user lands on an auth route, sends them to their
   role-specific dashboard.

## Demo accounts

`lib/services/demo_seeder.dart` seeds two demo accounts on cold start
so the role-switching UX is testable without Firebase sign-in:

- `buyer@samakifresh.com` / `password123`  → `buyer`
- `admin@samakifresh.com` / `password123`  → `admin`

The login screen surfaces these as quick-fill buttons
(`demoAccounts` in `lib/screens/auth/login_screen.dart`).