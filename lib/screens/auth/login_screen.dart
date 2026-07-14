import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../constants/app_colors.dart';
import '../../utils/validators.dart';
import '../../utils/error_handler.dart';
import '../../providers/auth_provider.dart';
import '../../models/enums/user_role.dart';
import '../../models/user_model.dart';
import '../../utils/logger.dart';
import '../../widgets/common/app_logo.dart';

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

const List<DemoAccount> demoAccounts = [
  DemoAccount(
    email: 'streetseller@samakifresh.com',
    password: 'password123',
    role: UserRole.streetSeller,
    name: 'Asha Street Seller',
    icon: Icons.storefront_rounded,
    color: Color(0xFFE65100),
  ),
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

  // ── Demo seller accounts ─────────────────────────────────────────────────
  // Each of these maps 1:1 with a seller-mirror doc under
  // `streetSellers/demo-<id>` so when the seller signs in and goes
  // online, the buyer sees a green marker with their name on the map.
  DemoAccount(
    email: 'fatma@samakifresh.com',
    password: 'password123',
    role: UserRole.streetSeller,
    name: 'Fatma Tuna Specialist',
    icon: Icons.store_rounded,
    color: Color(0xFFD32F2F),
  ),
  DemoAccount(
    email: 'babu@samakifresh.com',
    password: 'password123',
    role: UserRole.streetSeller,
    name: 'Babu Tilapia',
    icon: Icons.store_rounded,
    color: Color(0xFFE65100),
  ),
  DemoAccount(
    email: 'sara@samakifresh.com',
    password: 'password123',
    role: UserRole.streetSeller,
    name: 'Sara Mixed Fish',
    icon: Icons.store_rounded,
    color: Color(0xFFFFC107),
  ),
  DemoAccount(
    email: 'kwame@samakifresh.com',
    password: 'password123',
    role: UserRole.streetSeller,
    name: 'Kwame Market Stall',
    icon: Icons.store_rounded,
    color: Color(0xFF388E3C),
  ),
  DemoAccount(
    email: 'mama@samakifresh.com',
    password: 'password123',
    role: UserRole.streetSeller,
    name: 'Mama Zainab',
    icon: Icons.store_rounded,
    color: Color(0xFF1976D2),
  ),

  // ── Outer-island sellers (further from Stone Town) ────────────────────────
  DemoAccount(
    email: 'hassan@samakifresh.com',
    password: 'password123',
    role: UserRole.streetSeller,
    name: 'Hassan Nungwi Catch',
    icon: Icons.store_rounded,
    color: Color(0xFF0288D1),
  ),
  DemoAccount(
    email: 'salma@samakifresh.com',
    password: 'password123',
    role: UserRole.streetSeller,
    name: 'Salma Kendwa Seafood',
    icon: Icons.store_rounded,
    color: Color(0xFF0097A7),
  ),
  DemoAccount(
    email: 'yusuf@samakifresh.com',
    password: 'password123',
    role: UserRole.streetSeller,
    name: 'Yusuf Paje Surfside',
    icon: Icons.store_rounded,
    color: Color(0xFF7B1FA2),
  ),
  DemoAccount(
    email: 'rehema@samakifresh.com',
    password: 'password123',
    role: UserRole.streetSeller,
    name: 'Mama Rehema Jambiani',
    icon: Icons.store_rounded,
    color: Color(0xFFC2185B),
  ),
  DemoAccount(
    email: 'juma@samakifresh.com',
    password: 'password123',
    role: UserRole.streetSeller,
    name: 'Juma Makunduchi Deep',
    icon: Icons.store_rounded,
    color: Color(0xFF512DA8),
  ),
  DemoAccount(
    email: 'asha-pwani@samakifresh.com',
    password: 'password123',
    role: UserRole.streetSeller,
    name: 'Asha Pwani Mchangani',
    icon: Icons.store_rounded,
    color: Color(0xFF00695C),
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

    return const Scaffold(
      backgroundColor: Color(0xFFF8FAFF),
      body: Column(
        children: [
          // ── Hero header ────────────────────────────────────────────────────
          _HeroHeader(),

          // ── Form body ───────────────────────────────────────────────────────
          Expanded(
            child: _SignInTab(),
          ),
        ],
      ),
    );
  }
}

// ── Hero header with gradient + segment control ──────────────────────────────
class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    final statusBarH = MediaQuery.of(context).padding.top;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF003D6B), Color(0xFF0066B4), Color(0xFF00A896)],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
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
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const AppLogo(
                      size: 36,
                      borderRadius: 8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SamakiFresh',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Connect',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
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
                    const Text(
                      'Welcome back 👋',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to continue to your dashboard',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
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
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
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
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.white,
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
        mockUser = UserModel(
          userId: 'demo_${demo.role.name}',
          email: demo.email,
          fullName: demo.name,
          phoneNumber: '0700000000',
          role: demo.role,
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );
        ref.invalidate(authStateProvider);
        ref.invalidate(currentUserProvider);
        ref.invalidate(currentUserStreamProvider);
        ref.invalidate(currentUserDataProvider);
        isLoading.value = false;
        if (context.mounted) context.go(_routeForRole(demo.role));
        return;
      }

      try {
        mockUser = null;
        ref.invalidate(authStateProvider);
        ref.invalidate(currentUserProvider);
        ref.invalidate(currentUserStreamProvider);

        final user = await authService.signIn(email: email, password: password);
        if (user != null && context.mounted) {
          final userData = await userService.fetchUserById(user.uid);
          if (userData != null && context.mounted) {
            context.go(_routeForRole(userData.role));
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
            const _FieldLabel(
                label: 'Email address', icon: Icons.email_rounded),
            const SizedBox(height: 8),
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: _inputDec(hint: 'you@example.com'),
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 20),

            // Password
            const _FieldLabel(label: 'Password', icon: Icons.lock_rounded),
            const SizedBox(height: 8),
            TextFormField(
              controller: passwordCtrl,
              obscureText: obscure.value,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => handleLogin(),
              decoration: _inputDec(
                hint: '••••••••',
                suffix: IconButton(
                  icon: Icon(
                    obscure.value
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: AppColors.gray500,
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
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                ),
                child: const Text('Forgot password?',
                    style: TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(height: 8),

            // Sign in button
            FilledButton(
              onPressed: isLoading.value ? null : handleLogin,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                backgroundColor: AppColors.primaryBlue,
              ),
              child: isLoading.value
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : const Text('Sign In',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        GestureDetector(
          onTap: () => expanded.value = !expanded.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bolt_rounded,
                      color: AppColors.primaryBlue, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Demo Access',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.gray900,
                        ),
                      ),
                      Text(
                        'Tap a role to auto-login instantly',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: expanded.value ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more_rounded,
                      color: AppColors.gray500),
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
    Future<void> handleTap() async {
      if (isLoading) return;

      AppLogger.info('Demo card tapped: ${demo.email}');
      await Future.delayed(const Duration(milliseconds: 300));

      final now = DateTime.now();
      mockUser = UserModel(
        userId: 'demo_${demo.role.name}',
        email: demo.email,
        fullName: demo.name,
        phoneNumber: '0700000000',
        role: demo.role,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );
      ref.invalidate(authStateProvider);
      ref.invalidate(currentUserProvider);
      ref.invalidate(currentUserStreamProvider);
      ref.invalidate(currentUserDataProvider);

      if (context.mounted) context.go(_routeForRole(demo.role));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.gray900,
                        ),
                      ),
                      Text(
                        demo.name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.gray500,
                        ),
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

// ── Shared helpers ────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;
  final IconData icon;

  const _FieldLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.gray600),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.gray700,
          ),
        ),
      ],
    );
  }
}

InputDecoration _inputDec({required String hint, Widget? suffix}) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 15),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    suffixIcon: suffix,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.gray200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.gray200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.errorRed),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
    ),
  );
}

void _showSnack(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppColors.errorRed : AppColors.successGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ),
  );
}
