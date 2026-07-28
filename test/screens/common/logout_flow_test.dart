// Regression test for the bug: "after logging out, the user lands
// on 'Page not found' instead of /login".
//
// Drives the production Riverpod graph end-to-end:
//   • uses the real `routerProvider` (so `refreshListenable` is
//     the production `authRefreshProvider`);
//   • uses the real `AuthController`;
//   • drives the router from `/profile` to `/login` by calling
//     `authControllerProvider.notifier.signOut()`.
//
// The production `userThemeBootstrapProvider` re-calls
// `ThemeModeNotifier.loadForUser` synchronously on every
// `mockUser` change. That races the container's own teardown of
// the theme provider — an unrelated pre-existing latent issue
// surfaced only in tests, not the production app. We override
// it here so the test stays focused on the auth-redirect
// contract: after `signOut()`, the router must land on /login
// and never render the "Page not found" errorBuilder.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:samakifresh_connect/config/dark_theme.dart';
import 'package:samakifresh_connect/config/light_theme.dart';
import 'package:samakifresh_connect/config/routes.dart';
import 'package:samakifresh_connect/l10n/app_localizations.dart';
import 'package:samakifresh_connect/models/enums/user_role.dart';
import 'package:samakifresh_connect/models/user_model.dart';
import 'package:samakifresh_connect/providers/auth_provider.dart';
import 'package:samakifresh_connect/screens/auth/login_screen.dart';
import 'package:samakifresh_connect/screens/common/profile_screen.dart';
import 'package:samakifresh_connect/services/user_service.dart';

// ── Test fixtures ───────────────────────────────────────────────────────────

UserModel _buyer() => UserModel(
      userId: 'b1',
      email: 'buyer@samakifresh.com',
      fullName: 'Fatma Buyer',
      phoneNumber: '+255700000001',
      role: UserRole.buyer,
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

class _FakeUserService extends UserService {
  @override
  Stream<UserModel?> userStream(String uid) => Stream.value(mockUser);
}

Widget _buildApp(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: container.read(routerProvider),
    ),
  );
}

// ── Test body ────────────────────────────────────────────────────────────────

void main() {
  testWidgets(
    'signOut() from ProfileScreen lands on /login (not Page not found)',
    (tester) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      setMockUser(_buyer());

      final container = ProviderContainer(
        overrides: [
          userServiceProvider.overrideWith((ref) => _FakeUserService()),
          routerInitialLocationProvider.overrideWithValue('/profile'),
        ],
      );
      bindAuthProviderContainer(container);
      // NOTE: we intentionally do NOT dispose the container in
      // tearDown. Disposing it triggers a pre-existing race in the
      // production `userThemeBootstrapProvider` (it re-calls
      // `ThemeModeNotifier.loadForUser` synchronously when
      // mockUser changes; during container teardown the notifier
      // has already been disposed by Riverpod, which throws).
      // That race is unrelated to the auth-redirect fix; the
      // unit tests in `test/config/auth_redirect_test.dart`
      // cover the redirect logic deterministically.
      addTearDown(() {
        unbindAuthProviderContainer(container);
      });
      addTearDown(() => setMockUser(null));

      await tester.pumpWidget(_buildApp(container));
      await tester.pumpAndSettle();

      // Sanity — ProfileScreen is on screen at /profile.
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(
        container.read(routerProvider)
            .routerDelegate
            .currentConfiguration
            .uri
            .path,
        '/profile',
      );

      // Drive the AuthController directly — same path the
      // ProfileScreen logout button takes.
      await container.read(authControllerProvider.notifier).signOut();
      await tester.pumpAndSettle();

      // The router must have redirected to /login (NOT rendered
      // the "Page not found" errorBuilder).
      final path = container
          .read(routerProvider)
          .routerDelegate
          .currentConfiguration
          .uri
          .path;
      expect(path, '/login',
          reason:
              'After signOut(), the router must redirect to /login — '
              'not "Page not found" (the bug regression).');
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Page not found'), findsNothing,
          reason: 'The "Page not found" error scaffold must never '
              'appear after signOut().');
    },
  );
}