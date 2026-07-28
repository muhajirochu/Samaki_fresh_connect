/// Pure auth redirect resolver.
///
/// Extracted from `lib/config/routes.dart` so it has zero Riverpod
/// or widget dependencies and can be unit-tested without a router
/// or `ProviderContainer`. The router wraps it in a closure that
/// supplies the live user / auth state.
///
/// The rules below are ordered — earlier rules short-circuit. The
/// splash route is intentionally exempt from redirect in *both*
/// directions: `SplashScreen` holds a 1.6s brand moment and
/// navigates itself; auto-redirecting away would kill that.
library;

import '../models/enums/user_role.dart';
import '../models/user_model.dart';
import 'route_paths.dart';

/// Resolve the redirect target for a navigation event.
///
/// * [user] — the current signed-in user, or `null` when the stream
///   has not yet produced a value (or the user just signed out).
///   Equivalent to `mockUser ?? currentUserStream.valueOrNull`.
/// * [hasAuthUser] — `true` when either the auth state has a user
///   OR [user] is non-null. Lets the redirect distinguish
///   "auth says signed-in but the user doc hasn't loaded yet"
///   from "signed out".
/// * [location] — `state.matchedLocation`, i.e. the URL the user is
///   trying to visit.
///
/// Returns `null` to mean "no redirect — keep going to [location]".
String? resolveAuthRedirect({
  required UserModel? user,
  required bool hasAuthUser,
  required String location,
}) {
  // 1. Splash is exempt. The splash holds a brand moment and
  //    navigates itself once the brand animation finishes.
  if (location == AppRoutes.splash) return null;

  final isAuthRoute =
      location == AppRoutes.login || location == AppRoutes.register;

  // 2. Signed out. Bounce any non-auth route to /login. Auth routes
  //    stay put so the user can actually see the login screen.
  //    This single rule covers every protected prefix (/admin,
  //    /buyer, /dashboard, /listings, /orders, /profile,
  //    /settings, …) — no prefix list to maintain.
  if (!hasAuthUser) {
    return isAuthRoute ? null : AppRoutes.login;
  }

  // 3. Auth says signed-in but the user doc hasn't loaded yet
  //    (e.g. the brief register window between signUp() and
  //    saveUser()). Stay put until the doc lands — the
  //    AuthRefreshNotifier will fire and re-run the redirect.
  if (user == null) return null;

  // 4. Non-admin on /admin/* → bounce to their own dashboard.
  //    (Admins stay on whatever /admin/* path they targeted.)
  if (location.startsWith('/admin') && user.role != UserRole.admin) {
    return AppRoutesExtensions.dashboardFor(user.role);
  }

  // 5. Logged-in user landing on an auth route → their dashboard.
  if (isAuthRoute) {
    return AppRoutesExtensions.dashboardFor(user.role);
  }

  return null;
}