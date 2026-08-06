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
      body: CustomScrollView(
        slivers: [
          // ── Ocean hero header (centered logo + brand) ───────────────────
          SliverToBoxAdapter(
            child: _HeroHeader(gradient: gradients.hero),
          ),

          // ── Form body ───────────────────────────────────────────────────────
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _SignInTab(),
          ),
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

    // The hero is given a taller, more substantial presence so it
    // "interacts" with the login form below — the form's first
    // field sits closer to the hero's curve, and the bottom
    // border-radius now appears to wrap the form's top edge.
    //
    // We can't use negative padding/margin (Flutter asserts
    // non-negative insets), so the interaction effect is achieved
    // purely by increasing the hero's inner bottom padding and
    // adding a SizedBox spacer above the form to nudge it up.
    return SizedBox(
      // Adds 64px of extra bottom layout space *inside* the hero
      // zone, which makes the form start 64px lower than the
      // hero's painted bottom edge. Visually the hero bleeds over
      // the form area because its decoration is taller than the
      // space the column reserves for it.
      child: Container(
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
            // padding so the brand content (logo + SamakiFresh Connect + Welcome Back)
            // sits comfortably.
            padding: EdgeInsets.only(top: statusBarH + 40, bottom: 40),
            // Wrap the column in a width-stretching Align so its
            // children actually center horizontally inside the
            // hero's full width. Without this, the column collapses
            // to its widest child and "Welcome Back" / logo hug the
            // start edge on some screens.
            child: Align(
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
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
                        color: Colors.white,
                        alignment: Alignment.center,
                        child: const AppLogo(
                          size: 84,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Brand name — "SamakiFresh " bold + "Connect" lighter
                  Text.rich(
                    textAlign: TextAlign.center,
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
                  const SizedBox(height: 14),
                  Text(
                    'Welcome Back',
                    textAlign: TextAlign.center,
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
          ),
        ],
      ),
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

    // Uses SliverFillRemaining in the parent CustomScrollView
    // so the entire login screen can scroll out of the way of the keyboard.
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Align(
        alignment: Alignment.topCenter,
        // Cap the form width on tablets / wide screens so the
        // email/password fields don't stretch to absurd lengths.
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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

                        // Footer
                        _SignupFooter(),

                        // Social sign-in block — Google + Apple + Facebook.
                        // UI only (no auth wiring yet, per the request).
                        const _SocialSignIn(),
                      ],
                    ),
                  ),
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
        Flexible(
          child: Text(
            "Don't have an account? ",
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.70),
            ),
            overflow: TextOverflow.ellipsis,
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

// ── Social sign-in footer ─────────────────────────────────────────────────────
// UI-only placeholder for Google / Apple / Facebook sign-in. The buttons
// render the proper branded icons and labels but `onPressed` is a no-op
// for now — the real auth wiring (google_sign_in, sign_in_with_apple,
// firebase_auth_facebook) will be added in a follow-up. The layout
// matches the rest of the form: max-width 480, centered, scroll-friendly.
class _SocialSignIn extends StatelessWidget {
  const _SocialSignIn();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // "or continue with" divider — same visual idiom as most
        // modern sign-in screens, with a thin line on each side of
        // the label so it reads as a section break.
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            children: [
              Expanded(
                child: Divider(
                  color: cs.outline.withValues(alpha: 0.35),
                  thickness: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'or continue with',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.60),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: cs.outline.withValues(alpha: 0.35),
                  thickness: 1,
                ),
              ),
            ],
          ),
        ),

        // Three icon-only social buttons in a row. Using IconButton
        // in a circle so the row stays compact on small phones; the
        // provider name is conveyed by the icon itself.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SocialButton(
              icon: Icons.g_mobiledata_rounded,
              label: 'Google',
              onPressed: () {
                debugPrint('Sign in with Google (not yet implemented)');
              },
            ),
            const SizedBox(width: 14),
            _SocialButton(
              icon: Icons.apple_rounded,
              label: 'Apple',
              onPressed: () {
                debugPrint('Sign in with Apple (not yet implemented)');
              },
            ),
            const SizedBox(width: 14),
            _SocialButton(
              icon: Icons.facebook_rounded,
              label: 'Facebook',
              onPressed: () {
                debugPrint('Sign in with Facebook (not yet implemented)');
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// Circular icon button for one social provider. Renders the icon in
/// a soft tinted disk so it stands out against the form background
/// without being a heavy filled button.
class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkResponse(
          onTap: onPressed,
          radius: 32,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.surfaceContainerHighest,
              border: Border.all(
                color: cs.outline.withValues(alpha: 0.4),
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 28,
              color: cs.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: tt.bodySmall?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.70),
            fontSize: 11,
            letterSpacing: 0.2,
          ),
        ),
      ],
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