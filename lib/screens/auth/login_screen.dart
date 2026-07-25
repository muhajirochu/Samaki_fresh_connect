import 'package:flutter/material.dart' hide FormField;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../config/theme_extensions.dart';
import '../../constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/validators.dart';
import '../../utils/error_handler.dart';
import '../../providers/auth_provider.dart';
import '../../models/enums/user_role.dart';
import '../../models/user_model.dart';
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
    email: 'admin@samakifresh.com',
    password: 'password123',
    role: UserRole.admin,
    name: 'Admin User',
    icon: Icons.admin_panel_settings_rounded,
    color: Color(0xFFC62828),
  ),
];

// ── Route helper ──────────────────────────────────────────────────────────────
String _routeForRole(UserRole role) {
  switch (role) {
    case UserRole.buyer:
      return '/dashboard/buyer';
    case UserRole.streetSeller:
      return '/dashboard/street_seller';
    case UserRole.admin:
      return '/dashboard/admin';
  }
}

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Transparent status bar for full-bleed header
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
          // ── Hero header ────────────────────────────────────────────────────
          _HeroHeader(gradient: gradients.hero),

          // ── Form body ───────────────────────────────────────────────────────
          const Expanded(
            child: _SignInTab(),
          ),
        ],
      ),
    );
  }
}

// ── Hero header with gradient + segment control ──────────────────────────────
class _HeroHeader extends StatelessWidget {
  final LinearGradient gradient;
  const _HeroHeader({required this.gradient});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final statusBarH = MediaQuery.of(context).padding.top;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(top: statusBarH + 16, bottom: 0),
        child: Column(
          children: [
            // Logo + title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const AppLogo(
                    size: 48,
                    withGlow: true,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SamakiFresh',
                        style: tt.titleLarge?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'CONNECT',
                        style: tt.bodySmall?.copyWith(
                          color: AppColors.white.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w300,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Welcome text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back',
                      style: tt.headlineSmall?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to continue to your dashboard',
                      style: tt.bodyMedium?.copyWith(
                        color: AppColors.white.withValues(alpha: 0.80),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.login,
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.push('/register'),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        child: Text(
                          l10n.signup,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
    final userService = ref.watch(userServiceProvider);

    Future<void> handleLogin() async {
      if (!formKey.currentState!.validate()) return;
      isLoading.value = true;

      final email = emailCtrl.text.trim();
      final password = passwordCtrl.text;

      // Check demo credentials first (offline bypass)
      final demo = demoAccounts.cast<DemoAccount?>().firstWhere(
            (d) =>
                d!.email.toLowerCase() == email.toLowerCase() &&
                d.password == password,
            orElse: () => null,
          );

      if (demo != null) {
        AppLogger.info('Demo login: ${demo.email}');
        await Future.delayed(const Duration(milliseconds: 500));
        final now = DateTime.now();
        setMockUser(UserModel(
          userId: 'demo_${demo.role.name}',
          email: demo.email,
          fullName: demo.name,
          phoneNumber: '0700000000',
          role: demo.role,
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ));
        ref.invalidate(authStateProvider);
        ref.invalidate(currentUserProvider);
        ref.invalidate(currentUserStreamProvider);
        ref.invalidate(currentUserDataProvider);
        isLoading.value = false;
        if (context.mounted) context.go(_routeForRole(demo.role));
        return;
      }

      try {
        setMockUser(null);
        ref.invalidate(authStateProvider);
        ref.invalidate(currentUserProvider);
        ref.invalidate(currentUserStreamProvider);

        final user = await authService.signIn(email: email, password: password);
        if (user != null && context.mounted) {
          final userData = await userService.fetchUserById(user.uid);
          if (userData != null && context.mounted) {
            // Best-effort activity log — never blocks the sign-in.
            try {
              final log = ref.read(adminActivityLogServiceProvider);
              await log.write(
                type: 'login',
                actorUid: userData.userId,
                actorRole: userData.role.name,
                title: 'User signed in',
                subtitle: userData.email,
              );
            } catch (_) {/* swallow — audit-only */}
            if (context.mounted) context.go(_routeForRole(userData.role));
          } else if (context.mounted) {
            _showSnack(context, 'Failed to fetch user data. Try again.',
                isError: true);
          }
        }
      } catch (e) {
        if (context.mounted) {
          _showSnack(context, ErrorHandler.getErrorMessage(e), isError: true);
        }
      } finally {
        isLoading.value = false;
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
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email
            const _PremiumInputLabel(
                label: 'Email address', icon: Icons.email_rounded),
            const SizedBox(height: 8),
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: themedInputDec(context, hint: 'you@example.com'),
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 20),

            // Password
            const _PremiumInputLabel(
                label: 'Password', icon: Icons.lock_rounded),
            const SizedBox(height: 8),
            TextFormField(
              controller: passwordCtrl,
              obscureText: obscure.value,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => handleLogin(),
              decoration: themedInputDec(
                context,
                hint: '••••••••',
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
            const SizedBox(height: 28),

            // Demo section
            _DemoSection(isLoading: isLoading.value),
          ],
        ),
      ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      await Future.delayed(const Duration(milliseconds: 300));

      final now = DateTime.now();
      setMockUser(UserModel(
        userId: 'demo_${demo.role.name}',
        email: demo.email,
        fullName: demo.name,
        phoneNumber: '0700000000',
        role: demo.role,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ));
      ref.invalidate(authStateProvider);
      ref.invalidate(currentUserProvider);
      ref.invalidate(currentUserStreamProvider);
      ref.invalidate(currentUserDataProvider);

      if (context.mounted) context.go(_routeForRole(demo.role));
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

// ── Field label + theme-aware input decoration ────────────────────────────────
class _PremiumInputLabel extends StatelessWidget {
  final String label;
  final IconData icon;

  const _PremiumInputLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: cs.onSurface.withValues(alpha: 0.65)),
        const SizedBox(width: 6),
        Text(
          label,
          style: tt.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withValues(alpha: 0.80),
          ),
        ),
      ],
    );
  }
}

/// Builds a theme-aware [InputDecoration] from the current theme.
InputDecoration themedInputDec(
  BuildContext context, {
  required String hint,
  Widget? suffix,
}) {
  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;

  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: cs.surfaceContainerHighest,
    hintStyle: tt.bodyMedium
        ?.copyWith(color: cs.onSurface.withValues(alpha: 0.40), fontSize: 15),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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