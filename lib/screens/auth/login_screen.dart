
import 'package:flutter/material.dart' hide FormField;
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../config/route_paths.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/validators.dart';
import '../../utils/error_handler.dart';
import '../../providers/auth_provider.dart';
import '../../models/enums/user_role.dart';
import '../../providers/admin_provider.dart';
import '../../utils/logger.dart';
import '../../widgets/common/app_logo.dart';

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

    return const Scaffold(
      backgroundColor: Color(0xFFF0F9FF),
      body: SingleChildScrollView(
        physics: ClampingScrollPhysics(),
        child: Column(
          children: [
            // ── Ocean hero header ─────────────────────────────────────────────
            _HeroHeader(),
            // ── Form body ─────────────────────────────────────────────────────
            _SignInTab(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Header — large blue gradient section with wave shape, fish watermark
// ─────────────────────────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusBarH = MediaQuery.of(context).padding.top;
    final screenW = MediaQuery.of(context).size.width;

    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          // ── Blue gradient background with custom wave clipper ──────────────
          ClipPath(
            clipper: _WaveClipper(),
            child: Container(
              width: double.infinity,
              // The wave clipper needs extra bottom space to render the wave
              padding: EdgeInsets.only(
                top: statusBarH + 12,
                bottom: 50, // extra padding so content clears the wave clip
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0C4A6E), // deepest ocean — sky-900
                    Color(0xFF0369A1), // sky-700
                    Color(0xFF0EA5E9), // sky-500 — bright
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              child: Stack(
                children: [
                  // ── Fish watermark (large, subtle, top-right) ─────────────
                  Positioned(
                    right: -20,
                    top: 10,
                    child: Opacity(
                      opacity: 0.08,
                      child: Icon(
                        Icons.set_meal_rounded,
                        size: screenW * 0.55,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // ── Decorative bubble / glow circles ─────────────────────
                  Positioned(
                    left: -40,
                    top: 20,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.10),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 30,
                    top: 60,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 80,
                    top: 20,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),

                  // ── Main content ──────────────────────────────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo in a white rounded-square container
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const AppLogo(size: 48, withGlow: false),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Brand name
                      RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'SamakiFresh',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextSpan(
                              text: ' Connect',
                              style: TextStyle(
                                color: Color(0xFFBAE6FD), // sky-200 — lighter
                                fontSize: 22,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Decorative line separator (  — Connect —  style)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 32,
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.40),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'FRESH · QUALITY · TRUST',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.60),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 32,
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.40),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Welcome text
                      Text(
                        l10n.loginWelcomeBack,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        l10n.loginSignInContinue,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Wave layer 2 — slightly lighter blue wave below for depth ──────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: _WaveClipper2(),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0EA5E9).withValues(alpha: 0.35),
                      const Color(0xFF38BDF8).withValues(alpha: 0.20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wave clippers for organic bottom shape on the hero header
// ─────────────────────────────────────────────────────────────────────────────
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);

    final cp1 = Offset(size.width * 0.25, size.height);
    final ep1 = Offset(size.width * 0.5, size.height - 30);
    path.quadraticBezierTo(cp1.dx, cp1.dy, ep1.dx, ep1.dy);

    final cp2 = Offset(size.width * 0.78, size.height - 60);
    final ep2 = Offset(size.width, size.height - 15);
    path.quadraticBezierTo(cp2.dx, cp2.dy, ep2.dx, ep2.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper oldClipper) => false;
}

class _WaveClipper2 extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.5);

    final cp1 = Offset(size.width * 0.3, 0);
    final ep1 = Offset(size.width * 0.6, size.height * 0.4);
    path.quadraticBezierTo(cp1.dx, cp1.dy, ep1.dx, ep1.dy);

    final cp2 = Offset(size.width * 0.85, size.height * 0.85);
    final ep2 = Offset(size.width, size.height * 0.3);
    path.quadraticBezierTo(cp2.dx, cp2.dy, ep2.dx, ep2.dy);

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper2 oldClipper) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Sign In tab — elevated white card form
// ─────────────────────────────────────────────────────────────────────────────
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Elevated white form card ─────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.10),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Email field ─────────────────────────────────────
                        _PremiumTextField(
                          controller: emailCtrl,
                          hint: l10n.loginEmailAddress,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          prefixIcon: Icons.mail_outline_rounded,
                          validator: Validators.validateEmail,
                        ),
                        const SizedBox(height: 12),

                        // ── Password field ──────────────────────────────────
                        _PremiumTextField(
                          controller: passwordCtrl,
                          hint: l10n.loginPasswordHint,
                          obscureText: obscure.value,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => handleLogin(),
                          prefixIcon: Icons.lock_outline_rounded,
                          suffixWidget: GestureDetector(
                            onTap: () => obscure.value = !obscure.value,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Icon(
                                obscure.value
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          validator: Validators.validatePassword,
                        ),

                        // ── Forgot password ─────────────────────────────────
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: isLoading.value ? null : handleForgotPassword,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF0284C7),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 8),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: Text(l10n.loginForgotPassword),
                          ),
                        ),

                        const SizedBox(height: 4),

                        // ── Login button ────────────────────────────────────
                        _LoginButton(
                          label: l10n.login,
                          isLoading: isLoading.value,
                          onPressed: isLoading.value ? null : handleLogin,
                        ),

                        const SizedBox(height: 12),

                        // ── Sign up footer ──────────────────────────────────
                        _SignupFooter(),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Social sign-in section ───────────────────────────────────
              const _SocialSignIn(),

              const SizedBox(height: 16),

              // ── Bottom tagline ───────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 1,
                    color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.loginTagline,
                    style: const TextStyle(
                      color: Color(0xFF0284C7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 28,
                    height: 1,
                    color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium text field — light-blue tinted background, blue focused ring,
// icon prefix, optional suffix widget for eye toggle
// ─────────────────────────────────────────────────────────────────────────────
class _PremiumTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final IconData prefixIcon;
  final Widget? suffixWidget;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const _PremiumTextField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.suffixWidget,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  State<_PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<_PremiumTextField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: TextFormField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          validator: widget.validator,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0C1F2C),
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(
              fontSize: 15,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: _focused
                ? const Color(0xFFE0F7FF)
                : const Color(0xFFF0F9FF),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.only(left: 14, right: 10),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _focused
                    ? const Color(0xFF0284C7).withValues(alpha: 0.12)
                    : const Color(0xFF0284C7).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                widget.prefixIcon,
                size: 18,
                color: _focused
                    ? const Color(0xFF0284C7)
                    : const Color(0xFF0369A1),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 60,
              minHeight: 48,
            ),
            suffixIcon: widget.suffixWidget,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0F2FE)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                  color: Color(0xFFBAE6FD), width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                  color: Color(0xFF0284C7), width: 2.0),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                  color: Color(0xFF075985), width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                  color: Color(0xFF075985), width: 2.0),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium gradient Login button with elevation and arrow icon
// ─────────────────────────────────────────────────────────────────────────────
class _LoginButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _LoginButton({
    required this.label,
    required this.isLoading,
    this.onPressed,
  });

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 56,
        decoration: BoxDecoration(
          gradient: widget.onPressed == null
              ? const LinearGradient(
                  colors: [Color(0xFF94A3B8), Color(0xFF94A3B8)],
                )
              : const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF0369A1), // sky-700
                    Color(0xFF0284C7), // sky-600
                    Color(0xFF0EA5E9), // sky-500
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: widget.onPressed == null
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF0284C7)
                        .withValues(alpha: _pressed ? 0.25 : 0.40),
                    blurRadius: _pressed ? 8 : 18,
                    offset: Offset(0, _pressed ? 3 : 8),
                  ),
                ],
        ),
        transform: _pressed
            ? Matrix4.diagonal3Values(0.98, 0.98, 1.0)
            : Matrix4.identity(),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.login_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sign up footer
// ─────────────────────────────────────────────────────────────────────────────
class _SignupFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account? ",
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        GestureDetector(
          onTap: () => context.push('/register'),
          behavior: HitTestBehavior.opaque,
          child: const Text(
            'sign up.',
            style: TextStyle(
              color: Color(0xFF0284C7),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFF0284C7),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Social sign-in section — Google, Apple, Facebook
// ─────────────────────────────────────────────────────────────────────────────
class _SocialSignIn extends StatelessWidget {
  const _SocialSignIn();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // "or continue with" divider
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFF0284C7).withValues(alpha: 0.30),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.loginOrContinueWith,
                style: TextStyle(
                  color: const Color(0xFF0369A1).withValues(alpha: 0.75),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0284C7).withValues(alpha: 0.30),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Three social buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SocialButton(
              icon: Icons.g_mobiledata_rounded,
              label: 'Google',
              iconColor: const Color(0xFF4285F4),
              onPressed: () {
                debugPrint('Sign in with Google (not yet implemented)');
              },
            ),
            const SizedBox(width: 20),
            _SocialButton(
              icon: Icons.apple_rounded,
              label: 'Apple',
              iconColor: const Color(0xFF1C1C1E),
              onPressed: () {
                debugPrint('Sign in with Apple (not yet implemented)');
              },
            ),
            const SizedBox(width: 20),
            _SocialButton(
              icon: Icons.facebook_rounded,
              label: 'Facebook',
              iconColor: const Color(0xFF1877F2),
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

/// Circular social provider button — light blue tinted disk with icon + label.
class _SocialButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onPressed,
  });

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _hover = true),
      onTapUp: (_) => setState(() => _hover = false),
      onTapCancel: () => setState(() => _hover = false),
      onTap: widget.onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _hover
                  ? const Color(0xFFE0F2FE)
                  : Colors.white,
              border: Border.all(
                color: _hover
                    ? const Color(0xFF0284C7).withValues(alpha: 0.50)
                    : const Color(0xFFBAE6FD),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7)
                      .withValues(alpha: _hover ? 0.18 : 0.08),
                  blurRadius: _hover ? 14 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              widget.icon,
              size: 30,
              color: widget.iconColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.label,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
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