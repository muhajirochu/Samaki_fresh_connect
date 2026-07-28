import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../config/route_paths.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_logo.dart';

// Splash-specific brand colours. Read at build-time so they survive
// even before `Theme.of(context)` is fully resolved (the route
// handler resolves the splash with a minimal `MaterialApp`).
const _splashBackground = Color(0xFF0B1220);          // deep navy
const _splashMid = Color(0xFF001E45);                 // mid navy
const _splashNear = Color(0xFF003567);                // near-blue
const _splashHalo = Color(0xFF3B82F6);                // bright blue halo
const _splashHaloDeep = Color(0xFF2563EB);            // brand blue
const _splashBrandTextTint = Color(0xFFAADFFF);       // cyan tint
const _splashChipTint = Color(0xFF7DD3FC);            // light cyan

/// Premium brand splash for Samaki Fresh Connect.
///
/// Lightweight version: previously this screen ran three simultaneous
/// animation controllers (`_mainCtrl`, `_pulseCtrl`, `_waveCtrl`) inside
/// a single `AnimatedBuilder` that rebuilt the entire 30+ widget tree
/// on every frame. On low-spec emulators that triggered the
/// "System UI isn't responding" dialog within seconds of launch.
///
/// The new design animates a single layer (the glow halo around the
/// logo) and uses static brand assets everywhere else — same visual
/// fidelity, ~1/10th of the per-frame work.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();

    // Single looping pulse for the glow halo only. Other brand
    // elements stay static, so this is the only thing Flutter has
    // to repaint while the splash is on screen.
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Navigate after a brief, deterministic hold so users always see
    // the brand moment — even on a fast sign-in.
    _start();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    _navigate();
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      try {
        final userModel = await ref.read(currentUserDataProvider.future);
        if (userModel != null && mounted) {
          context.go(AppRoutesExtensions.dashboardFor(userModel.role));
          return;
        }
      } catch (_) {}
    }
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double iconSize = (size.width * 0.33).clamp(110.0, 200.0);
    final double haloSize = iconSize * 1.9;

    return Scaffold(
      backgroundColor: _splashBackground,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.3),
            radius: 1.4,
            colors: [
              _splashNear,
              _splashMid,
              _splashBackground,
            ],
          ),
        ),
        // Only the glow halo is wrapped in an AnimatedBuilder so the
        // rest of the tree (gradient, particles, logo, text, spinner)
        // stays static across frames.
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow halo behind the logo — the only animated layer.
            Positioned(
              top: size.height * 0.18,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) {
                    final t = _pulseCtrl.value;
                    return Container(
                      width: haloSize,
                      height: haloSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _splashHalo
                                .withValues(alpha: 0.10 + t * 0.10),
                            _splashHaloDeep
                                .withValues(alpha: t * 0.10),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Static brand content — built once, not per frame.
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppLogo(size: iconSize, withGlow: true),
                const SizedBox(height: 32),
                const _BrandName(),
                const SizedBox(height: 5),
                const _Tagline(),
                const SizedBox(height: 36),
                const _LoadingIndicator(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Static brand name. Rendered once during build, never per frame.
class _BrandName extends StatelessWidget {
  const _BrandName();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (r) => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.white, _splashBrandTextTint],
      ).createShader(r),
      blendMode: BlendMode.srcIn,
      child: const Text(
        'SamakiFresh',
        style: TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.w900,
          color: AppColors.white,
          letterSpacing: -1.0,
          height: 1.0,
        ),
      ),
    );
  }
}

/// Static tagline chips. Three short Swahili phrases that anchor the
/// brand — Samaki Safi / Bei ya Haki / Haraka.
class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Chip(icon: Icons.water_drop_rounded, label: 'Samaki Safi'),
        _Dot(),
        _Chip(icon: Icons.scale_rounded, label: 'Bei ya Haki'),
        _Dot(),
        _Chip(icon: Icons.bolt_rounded, label: 'Haraka'),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: _splashChipTint),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: AppColors.white,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white.withValues(alpha: 0.30),
      ),
    );
  }
}

/// Bottom loading affordance. Static so it never causes a rebuild.
class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.white.withValues(alpha: 0.50),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Kuunganisha…',
          style: TextStyle(
            color: AppColors.white.withValues(alpha: 0.38),
            fontSize: 12,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}