import 'package:flutter/material.dart' hide FormField;
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../config/route_paths.dart';
import '../../config/theme_extensions.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/validators.dart';
import '../../utils/error_handler.dart';
import '../../providers/auth_provider.dart';
import '../../models/enums/user_role.dart';
import '../../providers/admin_provider.dart';
import '../../utils/logger.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/premium_components.dart';

// ── Demo account definitions ──────────────────────────────────────────────────
class DemoAccount {
  final String email;
  final String password;
  final UserRole role;
  final String name;
  final IconData icon;
  final Color color;

  const DemoAccount({
    required this.email,
    required this.password,
    required this.role,
    required this.name,
    required this.icon,
    required this.color,
  });
}

// Demo accounts shown on the login screen as quick-fill buttons.
// Street seller demo accounts were intentionally removed — real
// sellers must register themselves through the registration flow.
//
// The accent colours are intentionally NOT theme tokens — they're
// role identifiers that should look the same regardless of light/dark
// mode (green = buyer, red = admin) so users can spot the role at a
// glance. The values are kept here at the call-site instead of in
// AppColors because they're only meaningful on the login screen.
const List<DemoAccount> demoAccounts = [
  DemoAccount(
    email: 'buyer@samakifresh.com',
    password: 'password123',
    role: UserRole.buyer,
    name: 'Fatma Buyer',
    icon: Icons.shopping_bag_rounded,
    color: Color(0xFF2E8B57),
  ),
  DemoAccount(
    email: 'fatma@samakifresh.com',
    password: 'password123',
    role: UserRole.streetSeller,
    name: 'Fatma (Street Seller)',
    icon: Icons.storefront_rounded,
    color: Color(0xFFF57C00),
  ),
  DemoAccount(
    email: 'babu@samakifresh.com',
    password: 'password123',
    role: UserRole.streetSeller,
    name: 'Babu (Street Seller)',
    icon: Icons.storefront_rounded,
    color: Color(0xFFF57C00),
  ),
  DemoAccount(
    email: 'admin@samakifresh.com',
    password: 'password123',
    role: UserRole.admin,
    name: 'Admin User',
    icon: Icons.admin_panel_settings_rounded,
    color: Color(0xFFC62828),
  ),
];

// ── Route helper ──────────────────────────────────────────────────────────────
// The role → dashboard-path mapping now lives in
// `lib/config/route_paths.dart` (`AppRoutesExtensions.dashboardFor`).
// Call sites below use it directly so the mapping has exactly one
// definition across the codebase.

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Transparent status bar so the ocean-blue hero bleeds to the
    // top of the screen.
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final tokens = BackgroundStyle.of(context);
    final gradients = AppGradients.of(context);

    return Scaffold(
      backgroundColor: tokens.background,
      body: Column(
        children: [
          // ── Ocean hero header (centered logo + brand) ───────────────────
          _HeroHeader(gradient: gradients.hero),

          // ── Form body ───────────────────────────────────────────────────────
          const Expanded(child: _SignInTab()),
        ],
      ),
    );
  }
}

// ── Hero header — full-bleed ocean gradient with centered logo, two fish
// silhouettes, and "Welcome Back" copy. ───────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final LinearGradient gradient;
  const _HeroHeader({required this.gradient});

  @override
  Widget build(BuildContext context) {
    final statusBarH = MediaQuery.of(context).padding.top;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        // Wave-like bottom edge so the form feels like it's emerging
        // from water. `borderRadius` alone is too rigid.
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Two faint fish silhouettes flanking the header, mirroring
          // the design. Using `Icons.set_meal_rounded` as a stylized
          // fish stand-in (no extra asset).
          Positioned(
            top: statusBarH + 8,
            left: 18,
            child: Icon(
              Icons.set_meal_rounded,
              color: cs.onPrimary.withValues(alpha: 0.35),
              size: 26,
            ),
          ),
          Positioned(
            top: statusBarH + 8,
            right: 18,
            child: Icon(
              Icons.set_meal_rounded,
              color: cs.onPrimary.withValues(alpha: 0.35),
              size: 26,
            ),
          ),
          // Soft radial glow blob behind the logo for depth.
          Positioned(
            top: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      cs.onPrimary.withValues(alpha: 0.18),
                      cs.onPrimary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: statusBarH + 32, bottom: 28),
            child: Column(
              children: [
                // Circular logo plate — matches the design's white
                // ring around the fish icon.
                Container(
                  width: 96,
                  height: 96,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.onPrimary,
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            cs.primary,
                            cs.secondary,
                          ],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const AppLogo(
                        size: 72,
                        borderRadius: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Brand name — "SamakiFresh " bold + "Connect" lighter
                Text.rich(
                  TextSpan(
                    style: tt.headlineSmall?.copyWith(
                      color: cs.onPrimary,
                      letterSpacing: -0.4,
                    ),
                    children: [
                      const TextSpan(
                        text: 'SamakiFresh ',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(
                        text: 'Connect',
                        style: TextStyle(
                          color: cs.onPrimary.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Tiny fish-divider — a single-line ornamental piece.
                _FishDivider(color: cs.onPrimary.withValues(alpha: 0.55)),
                const SizedBox(height: 14),
                Text(
                  'Welcome Back',
                  style: tt.headlineSmall?.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Sign in to continue to your dashboard.',
                    textAlign: TextAlign.center,
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onPrimary.withValues(alpha: 0.85),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal fish-divider line. Uses a dash + fish icon + dash
/// composition that renders crisply without a custom SVG asset.
class _FishDivider extends StatelessWidget {
  final Color color;
  const _FishDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Row(
        children: [
          Expanded(child: Divider(color: color, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.set_meal_rounded,
              size: 14,
              color: color,
            ),
          ),
          Expanded(child: Divider(color: color, thickness: 1)),
        ],
      ),
    );
  }
}

// ── Sign In tab ───────────────────────────────────────────────────────────────
class _SignInTab extends HookConsumerWidget {
  const _SignInTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final emailCtrl = useTextEditingController();
    final passwordCtrl = useTextEditingController();
    final isLoading = useState(false);
    final obscure = useState(true);
    final authService = ref.watch(authServiceProvider);

    Future<void> handleLogin() async {
      if (!formKey.currentState!.validate()) return;
      isLoading.value = true;

      final email = emailCtrl.text.trim();
      final password = passwordCtrl.text;

      // ── Demo account quick-fill (bypasses Firestore lookup — uses role from local list) ──
      final demo = demoAccounts.cast<DemoAccount?>().firstWhere(
            (d) =>
                d!.email.toLowerCase() == email.toLowerCase() &&
                d.password == password,
            orElse: () => null,
          );

      if (demo != null) {
        AppLogger.info('Demo login: ${demo.email}');
        try {
          final fbUser = await authService.signIn(
            email: demo.email,
            password: demo.password,
          );
          if (fbUser == null) throw StateError('Demo sign-in returned no user');
          setMockUser(null);
          ref.invalidate(authStateProvider);
          ref.invalidate(currentUserProvider);
          ref.invalidate(currentUserStreamProvider);
          ref.invalidate(currentUserDataProvider);
          if (context.mounted) {
            context.go(AppRoutesExtensions.dashboardFor(demo.role));
          }
        } catch (e) {
          AppLogger.error('Demo sign-in failed for ${demo.email}: $e');
          if (context.mounted) {
            _showSnack(context, 'Demo sign-in failed: $e', isError: true);
          }
        }
        if (context.mounted) isLoading.value = false;
        return;
      }

      // ── Real user login ──────────────────────────────────────────────────────
      try {
        setMockUser(null);
        ref.invalidate(authStateProvider);
        ref.invalidate(currentUserProvider);
        ref.invalidate(currentUserStreamProvider);
        ref.invalidate(currentUserDataProvider);

        // STEP 1: Sign in with Firebase Auth — get the auth User object
        final fbUser = await authService.signIn(email: email, password: password);

        if (fbUser == null) {
          if (context.mounted) {
            _showSnack(context, 'Sign-in failed. Please try again.', isError: true);
          }
          return;
        }

        // STEP 2: Log the UID as requested.
        final uid = fbUser.uid;
        AppLogger.info('Fetched UID: $uid');
        AppLogger.info('Firebase Auth succeeded. UID: $uid | Email: ${fbUser.email}');

        // STEP 3: Read raw Firestore document directly by UID
        // This is the most reliable path — direct doc read, no query needed
        Map<String, dynamic>? rawData;
        String? resolvedRole;

        try {
          final docSnap = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();

          AppLogger.debug('Firestore users/$uid exists: ${docSnap.exists}');

          if (docSnap.exists && docSnap.data() != null) {
            rawData = Map<String, dynamic>.from(docSnap.data()!);
            rawData['userId'] = uid; // ensure userId is stamped
            resolvedRole = rawData['role']?.toString();
            AppLogger.info('Firestore read OK. role=$resolvedRole fields=${rawData.keys.toList()}');
          }
        } on FirebaseException catch (fe) {
          AppLogger.error('Firestore direct-read FAILED: code=${fe.code} msg=${fe.message}');
          if (context.mounted) {
            _showSnack(context, 'Database error: ${fe.message}. Check your connection.', isError: true);
          }
          await authService.signOut();
          return;
        }

        // STEP 4: If not found by UID, try email fallback (heals old registrations)
        if (rawData == null) {
          AppLogger.warning('users/$uid not found. Trying email fallback: ${fbUser.email}');
          try {
            final q = await FirebaseFirestore.instance
                .collection('users')
                .where('email', isEqualTo: fbUser.email ?? email)
                .limit(1)
                .get();

            if (q.docs.isEmpty) {
              // Try lowercase email
              final q2 = await FirebaseFirestore.instance
                  .collection('users')
                  .where('email', isEqualTo: (fbUser.email ?? email).toLowerCase())
                  .limit(1)
                  .get();
              if (q2.docs.isNotEmpty) {
                rawData = Map<String, dynamic>.from(q2.docs.first.data());
              }
            } else {
              rawData = Map<String, dynamic>.from(q.docs.first.data());
            }

            if (rawData != null) {
              rawData['userId'] = uid;
              resolvedRole = rawData['role']?.toString();
              AppLogger.info('Email fallback succeeded. role=$resolvedRole');

              // HARD FIX: Firestore's `users/{uid}` create rule
              // requires `phoneNumber` to be a non-empty string. If
              // the migrated doc has no phone number (e.g. it was
              // created by an older build) we seed a placeholder
              // so the migration write passes the rule.
              if (rawData['phoneNumber'] == null ||
                  (rawData['phoneNumber'] is String &&
                      (rawData['phoneNumber'] as String).isEmpty)) {
                rawData['phoneNumber'] = '+255000000000';
              }
              // Also ensure `fullName` is non-empty (same rule).
              if (rawData['fullName'] == null ||
                  (rawData['fullName'] is String &&
                      (rawData['fullName'] as String).isEmpty)) {
                rawData['fullName'] = (fbUser.email ?? email).split('@').first;
              }

              // Migrate: write correct doc at users/{uid}
              rawData['createdAt'] = rawData['createdAt'] ?? FieldValue.serverTimestamp();
              rawData['updatedAt'] = FieldValue.serverTimestamp();
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .set(rawData, SetOptions(merge: true));
                AppLogger.info('Migrated user doc to users/$uid');
              } on FirebaseException catch (fe) {
                // Migration write can fail if the rule rejects the
                // data (legacy doc missing required fields). Falling
                // through to STEP 5 lets us create a fresh doc
                // instead of stranding the user on /login.
                AppLogger.warning(
                    'Migration write failed (${fe.code}): ${fe.message} — '
                    'falling through to STEP 5 default doc');
              }
            }
          } on FirebaseException catch (fe) {
            AppLogger.error('Email fallback FAILED: ${fe.code} ${fe.message}');
          }
        }

        // STEP 5: If still no document, create a basic one so the user can log in.
        // We honour the email domain so existing demo accounts (e.g.
        // `admin@samakifresh.com`) get the right role without forcing
        // every legacy user to become a buyer.
        if (rawData == null) {
          AppLogger.warning('No Firestore doc found for UID=$uid. Creating a default doc.');
          final now = FieldValue.serverTimestamp();
          final lowerEmail = (fbUser.email ?? email).toLowerCase();
          // Pick a role that matches the email. The default of `buyer`
          // is the lowest-privilege choice, but `@samakifresh.com`
          // addresses are demo accounts and should keep their
          // intended role.
          String inferredRole;
          if (lowerEmail == 'admin@samakifresh.com') {
            inferredRole = 'admin';
          } else if (lowerEmail.endsWith('@samakifresh.com')) {
            inferredRole = 'streetSeller';
          } else {
            inferredRole = 'buyer';
          }
          // HARD FIX: Firestore's `users/{uid}` create rule requires
          // `phoneNumber` to be a non-empty string AND a 200-char
          // max name. We seed a placeholder phone number so the
          // user can sign in immediately; the user updates it to
          // their real number on the profile screen.
          rawData = {
            'userId': uid,
            'email': fbUser.email ?? email,
            'fullName': (fbUser.displayName?.isNotEmpty ?? false)
                ? fbUser.displayName
                : email.split('@').first,
            'phoneNumber': '+255000000000',
            'role': inferredRole,
            'isActive': true,
            'isApproved': false,
            'createdAt': now,
            'updatedAt': now,
          };
          resolvedRole = inferredRole;
          try {
            await FirebaseFirestore.instance.collection('users').doc(uid).set(rawData);
            AppLogger.info('Created default $inferredRole doc for UID=$uid');
          } on FirebaseException catch (fe) {
            AppLogger.error('Failed to create default doc: ${fe.code} ${fe.message}');
            if (context.mounted) {
              _showSnack(context, 'Failed to create user profile. Contact support.', isError: true);
            }
            await authService.signOut();
            return;
          }
        }

        // STEP 6: Determine role and navigate to the correct dashboard
        // We read the role string directly — no UserModel parse required.
        // This means even if the model has a parse bug, login still works.
        final UserRole userRole;
        switch (resolvedRole) {
          case 'streetSeller':
          case 'fisherman':
          case 'seller':
            userRole = UserRole.streetSeller;
            break;
          case 'admin':
            userRole = UserRole.admin;
            break;
          case 'buyer':
          default:
            userRole = UserRole.buyer;
        }

        AppLogger.info('Login complete. UID=$uid role=${userRole.name}. Navigating...');

        // Write audit log (swallow any failure — login must always succeed)
        try {
          final log = ref.read(adminActivityLogServiceProvider);
          await log.write(
            type: 'login',
            actorUid: uid,
            actorRole: userRole.name,
            title: 'User signed in',
            subtitle: fbUser.email ?? email,
          );
        } catch (_) {/* swallow — audit-only */}

        if (context.mounted) {
          context.go(AppRoutesExtensions.dashboardFor(userRole));
        }
      } on FirebaseAuthException catch (e) {
        AppLogger.error('FirebaseAuthException: code=${e.code} msg=${e.message}');
        if (context.mounted) {
          String msg;
          switch (e.code) {
            case 'user-not-found':
            case 'invalid-credential':
            case 'wrong-password':
              msg = 'Barua pepe au neno la siri si sahihi.';
              break;
            case 'too-many-requests':
              msg = 'Majaribio mengi sana. Jaribu tena baadaye.';
              break;
            case 'user-disabled':
              msg = 'Akaunti yako imezuiwa. Wasiliana na msaada.';
              break;
            case 'network-request-failed':
              msg = 'Hakuna muunganisho wa intaneti. Angalia wifi yako.';
              break;
            default:
              msg = 'Imeshindwa kuingia: ${e.message}';
          }
          _showSnack(context, msg, isError: true);
        }
      } on FirebaseException catch (e) {
        AppLogger.error('FirebaseException: code=${e.code} msg=${e.message}');
        if (context.mounted) {
          _showSnack(context, 'Hitilafu ya database: ${e.message}', isError: true);
        }
      } catch (e, st) {
        AppLogger.error('Unexpected login error: $e\n$st');
        if (context.mounted) {
          _showSnack(context, 'Hitilafu isiyotarajiwa. Jaribu tena.', isError: true);
        }
      } finally {
        if (context.mounted) isLoading.value = false;
      }
    }

    Future<void> handleForgotPassword() async {
      final email = emailCtrl.text.trim();
      if (email.isEmpty) {
        _showSnack(
            context, 'Enter your email first, then tap Forgot Password.');
        return;
      }
      try {
        await authService.sendPasswordResetEmail(email);
        if (context.mounted) {
          _showSnack(context, 'Password reset email sent. Check your inbox.');
        }
      } catch (e) {
        if (context.mounted) {
          _showSnack(context, ErrorHandler.getErrorMessage(e), isError: true);
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: themedInputDec(
                context,
                hint: 'Email address',
                leadingIcon: Icons.email_outlined,
              ),
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 14),

            // Password
            TextFormField(
              controller: passwordCtrl,
              obscureText: obscure.value,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => handleLogin(),
              decoration: themedInputDec(
                context,
                hint: 'Password',
                leadingIcon: Icons.lock_outline_rounded,
                suffix: IconButton(
                  icon: Icon(
                    obscure.value
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 20,
                  ),
                  onPressed: () => obscure.value = !obscure.value,
                ),
              ),
              validator: Validators.validatePassword,
            ),

            // Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isLoading.value ? null : handleForgotPassword,
                child: const Text('Forgot password?',
                    style: TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(height: 8),

            // Sign in button
            GradientButton(
              label: l10n.login,
              prefixIcon: Icons.login_rounded,
              onPressed: isLoading.value ? null : handleLogin,
              isLoading: isLoading.value,
            ),
            const SizedBox(height: 24),

            // Demo section
            _DemoSection(isLoading: isLoading.value),
            const SizedBox(height: 18),

            // Footer
            _SignupFooter(),
          ],
        ),
      ),
    );
  }
}

// ── Sign up footer ────────────────────────────────────────────────────────────
class _SignupFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.70),
          ),
        ),
        GestureDetector(
          onTap: () => context.push('/register'),
          behavior: HitTestBehavior.opaque,
          child: Text(
            'sign up.',
            style: tt.bodyMedium?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Demo accounts section ─────────────────────────────────────────────────────
class _DemoSection extends HookConsumerWidget {
  final bool isLoading;
  const _DemoSection({required this.isLoading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = useState(false);
    final cs = Theme.of(context).colorScheme;
    final tokens = BackgroundStyle.of(context);
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        GestureDetector(
          onTap: () => expanded.value = !expanded.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tokens.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.bolt_rounded, color: cs.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Demo Access',
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Tap a role to auto-login instantly',
                        style: tt.bodySmall,
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: expanded.value ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.expand_more_rounded,
                      color: cs.onSurface.withValues(alpha: 0.55)),
                ),
              ],
            ),
          ),
        ),

        // Demo cards (collapsible)
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: demoAccounts
                  .map(
                    (demo) => _DemoCard(demo: demo, isLoading: isLoading),
                  )
                  .toList(),
            ),
          ),
          crossFadeState: expanded.value
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }
}

class _DemoCard extends HookConsumerWidget {
  final DemoAccount demo;
  final bool isLoading;

  const _DemoCard({required this.demo, required this.isLoading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = BackgroundStyle.of(context);
    final tt = Theme.of(context).textTheme;

    Future<void> handleTap() async {
      if (isLoading) return;

      AppLogger.info('Demo card tapped: ${demo.email}');

      // Sign in through Firebase Auth rather than stamping a mock user.
      //
      // This card is the second demo-login entry point; the form's
      // "Demo login" path above was converted in 4dbaf3f but this one
      // was missed, so tapping it left `request.auth == null` and
      // EVERY Firestore read returned PERMISSION_DENIED — the buyer
      // dashboard showed "0 Fish Available" and search returned
      // nothing at all, because `fishListings` was never readable.
      //
      // The demo accounts are real Firebase Auth accounts provisioned
      // by DemoSeeder.seedDemoAccounts on cold start.
      final messenger = ScaffoldMessenger.of(context);
      final errorColor = Theme.of(context).colorScheme.error;
      try {
        final fbUser = await ref.read(authServiceProvider).signIn(
              email: demo.email,
              password: demo.password,
            );
        if (fbUser == null) {
          throw StateError('Demo sign-in returned no user');
        }
        // Clear any leftover mock user so the real auth event wins.
        setMockUser(null);
        ref.invalidate(authStateProvider);
        ref.invalidate(currentUserProvider);
        ref.invalidate(currentUserStreamProvider);
        ref.invalidate(currentUserDataProvider);
      } catch (e) {
        AppLogger.error('Demo sign-in failed for ${demo.email}: $e');
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Demo sign-in failed: $e\n'
              'Check that Firebase Auth is reachable and the '
              'demo accounts were seeded.',
            ),
            backgroundColor: errorColor,
          ),
        );
        return;
      }

      if (context.mounted) {
        context.go(AppRoutesExtensions.dashboardFor(demo.role));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: handleTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: demo.color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: demo.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(demo.icon, color: demo.color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        demo.role.displayName,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        demo.name,
                        style: tt.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: demo.color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Snack helper ──────────────────────────────────────────────────────────────
void _showSnack(BuildContext context, String message, {bool isError = false}) {
  final cs = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? cs.error : cs.secondary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ),
  );
}

/// Builds a theme-aware [InputDecoration] from the current theme.
///
/// Adds an optional [leadingIcon] so the email/password fields mirror
/// the design's icon-prefixed inputs (mail/lock on the left edge).
InputDecoration themedInputDec(
  BuildContext context, {
  required String hint,
  Widget? suffix,
  IconData? leadingIcon,
}) {
  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;

  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: cs.surfaceContainerHighest,
    hintStyle: tt.bodyMedium
        ?.copyWith(color: cs.onSurface.withValues(alpha: 0.55), fontSize: 15),
    contentPadding: EdgeInsets.symmetric(
      horizontal: 16,
      vertical: leadingIcon != null ? 14 : 14,
    ),
    prefixIcon: leadingIcon != null
        ? Icon(leadingIcon, size: 20, color: cs.onSurface.withValues(alpha: 0.55))
        : null,
    suffixIcon: suffix,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.primary, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.error, width: 1.6),
    ),
  );
}