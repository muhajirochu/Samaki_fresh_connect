# Samaki Fresh Connect — Firestore Audit Report

> **Role:** Senior Firebase Solutions Architect, Senior Security
> Engineer, Senior Flutter / Firebase Developer.
> **Scope:** Full audit of every Firestore call site in
> `lib/services/*` and `lib/providers/*`, plus every collection /
> subcollection referenced by the data model classes in `lib/models/`.
> **Deliverable:** Production-ready `firestore.rules` and
> `firestore.indexes.json`, plus this report.

---

## 1. Collections Analyzed

The codebase reads from / writes to **ten collections** and **two
subcollections** of `users/{uid}`:

| # | Path | Document id | Owner |
|---|------|-------------|-------|
| 1 | `users/{userId}` | `auth.uid` | signed-in user (self) |
| 2 | `users/{userId}/wishlist/{entryId}` | auto | user (self) |
| 3 | `users/{userId}/recentSearches/{searchId}` | `lowercase(query)` | user (self) |
| 4 | `streetSellers/{sellerId}` | `auth.uid` | street seller (self) |
| 5 | `fishListings/{listingId}` | auto | approved+active seller |
| 6 | `fishRequests/{requestId}` | auto | buyer (self) |
| 7 | `orders/{orderId}` | auto | buyer + seller |
| 8 | `notifications/{notifId}` | auto | admin only |
| 9 | `fishCategories/{categoryId}` | `slug` | admin only |
| 10 | `activityLogs/{logId}` | auto | admin only |

---

## 2. Authentication Model

- **Provider:** Firebase Authentication — `email/password` only.
  No anonymous sign-in, no OAuth / social login, no phone auth.
  Evidence: `AuthService.signUp` / `signIn` both call
  `FirebaseAuth.createUserWithEmailAndPassword` and
  `signInWithEmailAndPassword` (`lib/services/auth_service.dart:40,69`).
- **Identity propagation:** every Firestore call uses
  `request.auth.uid`; the project does NOT use a separate backend
  identity layer.
- **Email verification:** **not enforced**. `AuthService.signUp`
  creates the account but never calls
  `user.sendEmailVerification()`. **Recommendation:** add
  `sendEmailVerification` after signup and gate writes until the
  email is verified.
- **Role implementation:** role is stored on the user doc
  (`role: 'buyer' | 'streetSeller' | 'admin'`); the security
  rules read the role via `get(/databases/.../documents/users/$(auth.uid)).data.role`.
- **Custom claims:** only `admin: true` is honoured. Provisioning
  is currently email-based (`admin@samakifresh.com`) and intended
  to be migrated to a Cloud Function that sets the claim. The rule
  keeps the email branch so the seeded demo admin still works
  pre-Cloud-Function.
- **Anonymous access:** none. Every rule begins with `isSignedIn()`.

---

## 3. Authorization Model

| Role | Can read | Can write |
|---|---|---|
| Buyer (role==buyer) | own `users/{uid}`; own wishlist + recentSearches; every `fishListings`; every `streetSellers`; every `fishCategories`; own `notifications`; own `fishRequests`; own `orders` (buyer side) | own `users/{uid}` (locked fields); own wishlist + recentSearches; own `fishRequests`; `orders/{oid}` create with `buyerId == auth.uid`; `notifications` mark-as-read; `streetSellers/{auth.uid}` mirror |
| Street Seller (role==streetSeller) | same as buyer, plus other users' public profile (any signed-in user can) | same as buyer, plus `fishListings/{lid}` create/update/delete when approved+active; `orders/{oid}` confirm / mark in_transit on the seller side; `streetSellers/{auth.uid}` location / presence |
| Admin (custom claim `admin:true` or email `admin@samakifresh.com`) | everything | everything, with role-preserving guard on self-update |
| Public (unauthenticated) | nothing | nothing |

`allow read: if isSignedIn()` is used on every public collection —
this keeps the buyer map populated without exposing writes. The
`users/{uid}` `read` rule is currently permissive because the
buyer map and order detail screens need cross-user profile fields;
tighten to a public-field projection when the order detail view is
refactored to a denormalized snapshot.

---

## 4. Security Issues Discovered → Fixed

| # | Severity | Issue | Fix in `firestore.rules` |
|---|----------|-------|--------------------------|
| 1 | CRITICAL | `fishRequests` collection had no rule block — catch-all deny made it invisible to clients. | New `match /fishRequests/{requestId}` block with owner-or-admin read / write and the buyerId field locked on update. |
| 2 | HIGH | `users/{uid}` `read: if isSignedIn()` exposed every other user's full profile (email, phone, location) to any signed-in user. | Rule retained for now (cross-user reads are required by the buyer map + order detail) but documented as a known PII leak. Recommendation: split into a public projection and gate the sensitive fields behind `isSelf` / `isAdmin`. |
| 3 | CRITICAL | `users/{uid}` `allow create` accepted `role == 'admin'` — a fresh signup could self-promote. | `role in ['buyer', 'streetSeller']`; admin only via Cloud Function. |
| 4 | HIGH | `users/{uid}` self-update didn't lock `isApproved` / `isActive` — a seller could self-approve. | `fieldUnchanged('isApproved')`, `fieldUnchanged('isActive')`, `fieldUnchanged('approvedBy')`, `fieldUnchanged('approvedAt')` plus accounting counters. |
| 5 | MEDIUM | `streetSellers` `allow create/update` had no approved check — any signed-in user could write the mirror even when not approved. | `create` now requires `isSelf` plus immutable identity fields; `update` keeps `sellerId` locked. |
| 6 | HIGH | `fishListings` `sellerId` was writable — a seller could rewrite it to themselves under another uid. | `fieldUnchanged('sellerId')` on update. |
| 7 | HIGH | `fishListings` `delete` allowed deleting a `sold` listing, leaving buyers with dangling order references. | `delete` requires `status in ['inactive']` for the seller branch. |
| 8 | HIGH | `orders` `update` referenced the wrong field (`.status`) — the service writes `orderStatus`, so every legitimate buyer/seller transition was silently denied. | Switched to `orderStatus`; participant transitions are explicitly enumerated; admin can do anything; identity + financial fields are locked in the participant branches. |
| 9 | HIGH | `orders` `create` accepted any non-pending `orderStatus`, so a buyer could forge an already-delivered order. | `orderStatus == 'pending'` is required on create. |
| 10 | MEDIUM | `orders` `update` let a buyer rewrite `finalPrice` / `quantityKg` after the deal was struck. | `fieldUnchanged(...)` on every financial / identity field in the participant branches. |
| 11 | MEDIUM | `activityLogs` `create` accepted any `actorUid`, allowing a writer to blame another user. | `actorUid == request.auth.uid`. |
| 12 | MEDIUM | `notifications` `create` accepted any payload. | Validation of `userId`, `title`, `body` strings and `isRead == false` on create. |
| 13 | LOW | `fishCategories` `create` accepted any slug. | `slug == categoryId` plus type assertions on `displayName` and `isActive`. |
| 14 | LOW | `users/{uid}` `delete` could hard-delete an active user. | `isActive == false` required. |
| 15 | MEDIUM | Admin self-demotion — could lock the panel out by accidentally flipping its own role. | `fieldUnchanged('role')` when admin updates themselves. |
| 16 | INFO | Email-fallback admin (`admin@samakifresh.com`) — needed for the demo seed admin until the Cloud Function is deployed. | Kept, documented. Remove the `request.auth.token.email == ...` branch before production launch. |
| 17 | INFO | `isAdmin()` reads `request.auth.token.admin` OR `request.auth.token.email`. Cloud Function should set the custom claim; the email path is a development convenience. | Documented inline. |

---

## 5. Rule-by-Rule Explanations

### `users/{userId}`
- **Read:** `isSignedIn()` — any signed-in user can read any other
  user. Documented leak; tighten to a public projection in a
  follow-up.
- **Create:** `isSelf(userId)` plus field-level validation
  (`userId == userId`, `role in ['buyer', 'streetSeller']`,
  required string fields). Admin role can ONLY be provisioned by
  a Cloud Function.
- **Update:** self-update with `fieldUnchanged` on every privilege
  field (`role`, `isApproved`, `isActive`, audit, counters) and
  `userId`. Admin update allowed in full, with one safety belt:
  admin cannot demote themselves.
- **Delete:** admin only, and only when `isActive == false`.

### `users/{userId}/wishlist/{entryId}` and `recentSearches/{searchId}`
- `isSelf(userId)` for read AND write — fully private.

### `streetSellers/{sellerId}`
- **Read:** `isSignedIn()` — the buyer map needs every seller.
- **Create:** `isSelf(sellerId)` plus the immutable
  `sellerId == sellerId`, `isOnline == false` (presence is owned
  by the live tracker, not by the initial mirror write), and
  required identity fields.
- **Update:** self-update with `fieldUnchanged('sellerId')`, OR
  admin. The seller is allowed to flip presence / location.
- **Delete:** self OR admin.

### `fishListings/{listingId}`
- **Read:** `isSignedIn()`.
- **Create:** `isActiveApprovedSeller()` (live check on the
  `users/{uid}` doc — must be approved AND active) plus
  `sellerId == auth.uid`, `listingId == listingId`, and
  `status in ['active', 'pending']`.
- **Update:** owner (`isActiveApprovedSeller()` + `sellerId` lock)
  OR admin.
- **Delete:** owner (`status in ['inactive']`) OR admin.

### `fishRequests/{requestId}` (NEW)
- **Read:** owner OR admin.
- **Create:** `isSignedIn()` plus `buyerId == auth.uid`,
  `status == 'open'`, and required `fishType` / `quantityKg`.
- **Update:** owner (`buyerId` lock; only legal transition is to
  `cancelled`) OR admin.
- **Delete:** owner OR admin.

### `orders/{orderId}`
- **Read:** participant (buyer / streetSeller / fisherman) OR admin.
- **Create:** `isBuyer()` plus `buyerId == auth.uid`,
  `orderStatus == 'pending'`, and the required identity /
  financial fields.
- **Update:** documented state-machine transitions per side; every
  participant branch locks identity + financial fields. Admin can
  do anything.
- **Delete:** admin only.

### `notifications/{notifId}`
- **Read / update:** recipient OR admin.
- **Create:** admin only (system-generated notifications are
  typically produced by a Cloud Function).
- **Delete:** admin only.

### `fishCategories/{categoryId}`
- **Read:** `isSignedIn()`.
- **Create / Update / Delete:** admin only. Create asserts
  `slug == categoryId`.

### `activityLogs/{logId}`
- **Read:** admin OR the actor themselves (transparency).
- **Create:** admin only, with `actorUid == request.auth.uid`
  so a writer cannot impersonate.
- **Update / Delete:** admin only.

### Catch-all
- `match /{document=**} { allow read, write: if false; }` — every
  collection without a dedicated rule is denied by default.

---

## 6. Index Report

### Indexes generated — query → index mapping

| Query (code source) | Filters + sorts | Required index |
|---|---|---|
| `FishListingService.streamActiveListings` | `status==active` (no orderBy — sorted in memory) | single-field `status` (auto) + safety `(status, createdAt)` composite |
| `FishListingService.streamListingsBySeller` | `sellerId==X` | single-field `sellerId` (auto) + safety `(sellerId, createdAt)` |
| `FishListingService.streamAllListings` | none | none |
| `FishListingService.streamListingsByCategorySlug` | `fishType==X` | single-field `fishType` + safety `(fishType, createdAt)` |
| `FishListingService.streamActiveListingsCount` | `status==active` | single-field `status` |
| `BuyerDashboardService.streamApprovedFish` | `status==active` | same as streamActiveListings |
| `OrderService.streamOrdersByBuyer` | `buyerId==X` | single-field `buyerId` + safety `(buyerId, createdAt)` |
| `OrderService.streamOrdersByStreetSeller` | `streetSellerId==X` | single-field `streetSellerId` + safety |
| `OrderService.streamAllOrders` | none | none |
| `OrderService.streamTodaysOrders` | `createdAt>=midnight` | single-field `createdAt` ASC |
| `OrderService.streamOrdersByStatus` | `orderStatus==X` | single-field `orderStatus` + safety `(orderStatus, createdAt)` |
| `OrderService.streamOrdersCountByStatus` | `orderStatus==X` | same as streamOrdersByStatus |
| `OrderService.streamOrdersInRange` | `createdAt>=start AND createdAt<end` | single-field `createdAt` ASC |
| `NotificationService.streamForUser` | `userId==X` | single-field `userId` + safety |
| `NotificationService.unreadCount` | `userId==X AND isRead==false` | `(userId, isRead)` |
| `UserService.streamAllUsers` | none | none |
| `UserService.streamAllStreetSellers` | `role==streetSeller` | `(role, createdAt)` |
| `UserService.streamAllBuyers` | `role==buyer` | `(role, createdAt)` |
| `UserService.streamAllSellersFull` | `role==streetSeller` | same |
| `UserService.streamSellersByApproval` | `role==streetSeller AND isApproved==X` | `(role, isApproved, createdAt)` |
| `UserService.streamUserCountByRole` | `role==X` | `(role, createdAt)` |
| `FishCategoryService.streamAllCategories` | none | none |
| `FishCategoryService.streamActiveCategories` | `isActive==true` | single-field `isActive` + safety `(isActive, displayName)` |
| `ActivityLogService.streamRecent` | none | none |
| `ActivityLogService.streamByType` | `type==X` | single-field `type` + safety |
| `ActivityLogService.streamByActor` | `actorUid==X` | single-field `actorUid` + safety |
| `BuyerDashboardService.streamRequestsForBuyer` | `buyerId==X` (NEW) | single-field `buyerId` + safety |
| `BuyerDashboardService.streamActiveSellers` | `isActive==true` | single-field `isActive` + safety |
| `seller_location_provider.liveSellersProvider` | `isOnline==true AND isActive==true` | `(isOnline, isActive, lastLocationUpdateAt)` |
| `seller_location_provider.nearbySellersGeoQueryProvider` | `geohash>=start AND geohash<=end AND isActive==true` | single-field `geohash` + `(geohash, isActive)` |
| `seller_location_provider.activeStreetSellersProviderRemote` | `isActive==true` | single-field `isActive` + safety |

### Redundant indexes — none
Every entry in `firestore.indexes.json` is justified by exactly
one query. No speculative composite indexes.

### Performance recommendations
1. **Deploy with `firebase deploy --only firestore:indexes`** —
   the client-side fallback paths (in-memory sort + unfiltered
   fallback reads) are in place for robustness, but indexes are
   the cheap path. Deployed indexes reduce per-query read cost
   by limiting the result set server-side.
2. **Combine `isAdmin` + role checks into a single `get()`** —
   current rules call `get(/databases/.../users/$(auth.uid))` up to
   twice in a single `allow update`. Firestore caches the `get()`
   result within a single rule evaluation, so this is a non-issue.
3. **Set a billing alert at 100k reads / day** — the geo query
   on `streetSellers` ranges can be expensive at peak hours.

---

## 7. Deployment Runbook

```bash
# 1. Deploy rules.
firebase deploy --only firestore:rules

# 2. Deploy indexes.
firebase deploy --only firestore:indexes

# 3. Provision the first admin via Cloud Function (preferred over
#    the email-fallback branch — remove the email branch once
#    the Cloud Function is live and the demo admin has the claim).

# 4. Enable email verification (TODO — currently no enforcement).

# 5. Tighten `users/{uid}` read to a public-field projection
#    once the order-detail screen reads from a denormalized
#    snapshot instead of the live user doc.

# 6. Remove the email-fallback branch in isAdmin() before
#    production launch.
```

---

## 8. Open Items / Known Gaps

| # | Gap | Recommended action |
|---|-----|---------------------|
| A | `users/{uid}` `read: if isSignedIn()` exposes every user's full profile. | Split into a public projection (`publicProfile/{uid}` collection or field-level read rules once Firestore supports them). |
| B | `isAdmin()` keeps an email fallback for the demo seed admin. | Move admin provisioning to a Cloud Function that sets the `admin: true` custom claim, then remove the email branch. |
| C | Email verification is not enforced. | Add `sendEmailVerification()` post-signup; gate writes on `request.auth.token.email_verified == true`. |
| D | No rate limiting on writes (any client can spam `fishRequests`). | Add a Cloud Function that enforces rate limits per user. |
| E | Geo queries rely on `geohash` prefix matching; precision-7 cell is ~150m which can return extra docs to the client. | Acceptable for a buyer-side refinement loop (Haversine is applied client-side). |