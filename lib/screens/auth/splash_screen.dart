import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_logo.dart';

/// Premium brand splash for Samaki Fresh Connect.
///
/// Visually identical in light and dark mode: deep-navy radial gradient
/// background with a brand-coloured glow halo, animated logo, brand name,
/// tagline chips and a loading spinner. The deep-navy background is the
/// "brand moment" and is intentionally identical regardless of theme —
/// this is the only place hardcoded brand colours are acceptable.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _waveCtrl;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _logoSlide;
  late Animation<double> _textFade;
  late Animation<double> _textSlide;
  late Animation<double> _taglineFade;
  late Animation<double> _pulse;
  late Animation<double> _wave;

  // Hardcoded brand colour tokens — splash always renders as the brand
  // moment regardless of light/dark theme.
  static const Color _scaffoldNavy = AppColors.darkNavy900;
  static const Color _accentBlue = AppColors.primaryBlue;

  @override
  void initState() {
    super.initState();

    // Main sequence controller — 1.4s total
    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Looping pulse for glow ring
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Looping wave
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();

    // ── Logo: 0 → 0.65 ──────────────────────────────────────────────
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.00, 0.45, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.00, 0.65, curve: Curves.elasticOut),
      ),
    );
    _logoSlide = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.00, 0.60, curve: Curves.easeOutCubic),
      ),
    );

    // ── App name: 0.40 → 0.80 ───────────────────────────────────────
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.40, 0.80, curve: Curves.easeOut),
      ),
    );
    _textSlide = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.40, 0.80, curve: Curves.easeOutCubic),
      ),
    );

    // ── Tagline: 0.65 → 1.0 ─────────────────────────────────────────
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.65, 1.00, curve: Curves.easeOut),
      ),
    );

    // Pulse glow
    _pulse = Tween<double>(begin: 0.30, end: 0.70).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Wave
    _wave = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _waveCtrl, curve: Curves.linear),
    );

    _start();
  }

  Future<void> _start() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _mainCtrl.forward();
    // Navigate after animations finish + brief hold
    await Future.delayed(const Duration(milliseconds: 2600));
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
          context.go(_routeForRole(userModel.role.name));
          return;
        }
      } catch (_) {}
    }
    if (mounted) context.go('/login');
  }

  String _routeForRole(String role) => switch (role) {
        'buyer' => '/dashboard/buyer',
        'streetSeller' => '/dashboard/street_seller',
        'admin' => '/dashboard/admin',
        _ => '/login',
      };

  @override
  void dispose() {
    _mainCtrl.dispose();
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    // Adaptive icon size — looks great on both phone and desktop
    final double iconSize = (sw * 0.33).clamp(110.0, 200.0);

    return Scaffold(
      backgroundColor: _scaffoldNavy,
      body: AnimatedBuilder(
        animation: Listenable.merge([_mainCtrl, _pulseCtrl, _waveCtrl]),
        builder: (context, _) {
          return Stack(
            children: [
              // ── Deep gradient background ──────────────────────────────────
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.0, -0.3),
                      radius: 1.4,
                      colors: [
                        Color(0xFF003567),
                        Color(0xFF001E45),
                        AppColors.darkNavy900,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Animated wave at bottom ───────────────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: CustomPaint(
                  size: Size(sw, sh * 0.30),
                  painter: _WavePainter(phase: _wave.value),
                ),
              ),

              // ── Radial glow halo behind icon ──────────────────────────────
              Positioned(
                top: sh * 0.18,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: iconSize * 1.9,
                    height: iconSize * 1.9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primaryBrightBlue
                              .withValues(alpha: _pulse.value * 0.20),
                          _accentBlue.withValues(alpha: _pulse.value * 0.10),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Decorative corner particles ───────────────────────────────
              ..._particles(sw, sh),

              // ── Main centred content ──────────────────────────────────────
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Opacity(
                      opacity: _logoFade.value.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, _logoSlide.value),
                        child: Transform.scale(
                          scale: _logoScale.value.clamp(0.0, 1.0),
                          child: AppLogo(
                            size: iconSize,
                            withGlow: true,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // App name
                    Opacity(
                      opacity: _textFade.value.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, _textSlide.value),
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (r) => const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.white,
                                  Color(0xFFAADFFF),
                                ],
                              ).createShader(r),
                              blendMode: BlendMode.srcIn,
                              child: Text(
                                'SamakiFresh',
                                style: TextStyle(
                                  fontSize: (sw * 0.092).clamp(30.0, 46.0),
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.white,
                                  letterSpacing: -1.0,
                                  height: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'C O N N E C T',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                                color: Color(0xFF7DD3FC),
                                letterSpacing: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Decorative divider
                    Opacity(
                      opacity: _taglineFade.value.clamp(0.0, 1.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _gradLine(rtl: true),
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryBrightBlue
                                  .withValues(alpha: 0.85),
                            ),
                          ),
                          _gradLine(rtl: false),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Tagline chips
                    Opacity(
                      opacity: _taglineFade.value.clamp(0.0, 1.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 11),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _chip(Icons.verified_rounded, 'Bei ya Haki'),
                            _dot(),
                            _chip(Icons.water_drop_rounded, 'Samaki Safi'),
                            _dot(),
                            _chip(Icons.bolt_rounded, 'Haraka'),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: sh * 0.08),

                    // Loading spinner
                    Opacity(
                      opacity: _taglineFade.value.clamp(0.0, 1.0),
                      child: Column(
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
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _gradLine({required bool rtl}) => Container(
        width: 44,
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: rtl ? Alignment.centerRight : Alignment.centerLeft,
            end: rtl ? Alignment.centerLeft : Alignment.centerRight,
            colors: [
              AppColors.white.withValues(alpha: 0.40),
              Colors.transparent,
            ],
          ),
        ),
      );

  Widget _chip(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF7DD3FC)),
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

  Widget _dot() => Container(
        width: 3,
        height: 3,
        margin: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.white.withValues(alpha: 0.30),
        ),
      );

  List<Widget> _particles(double sw, double sh) {
    const specs = [
      (0.06, 0.10, 3.0),
      (0.88, 0.07, 2.0),
      (0.94, 0.50, 4.0),
      (0.04, 0.70, 2.5),
      (0.78, 0.90, 3.0),
      (0.48, 0.03, 1.8),
    ];
    return specs.map((s) {
      final (x, y, r) = s;
      return Positioned(
        left: sw * x,
        top: sh * y,
        child: Opacity(
          opacity: _pulse.value * 0.55,
          child: Container(
            width: r * 2,
            height: r * 2,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryBrightBlue,
            ),
          ),
        ),
      );
    }).toList();
  }
}

// ── Wave painter ────────────────────────────────────────────────────────────────

/// Efficient wave painter using quadratic bezier curves instead of per-pixel
/// sin() loops. Only 8 control points per wave = ~24 ops total vs ~3240.
/// Uses a fixed snapshot so it doesn't need a repaint loop.
class _WavePainter extends CustomPainter {
  final double phase;
  const _WavePainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    _drawWave(canvas, size, 0.72, 28, 0.55, AppColors.accentTealGreen, 0.08);
    _drawWave(canvas, size, 0.82, 20, 0.35, AppColors.primaryBlue, 0.10);
    _drawWave(canvas, size, 0.90, 14, 0.25, const Color(0xFF002855), 0.14);
  }

  void _drawWave(Canvas canvas, Size size, double yRatio, double amp,
      double speed, Color color, double opacity) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final baseY = h * yRatio;
    final p = phase * speed;

    // 8 control points using quadratic bezier — smooth and very fast
    final path = Path()
      ..moveTo(0, h);

    // Build wave with quadraticBezierTo — 4 arcs across the screen
    final segW = w / 4;
    for (int i = 0; i < 4; i++) {
      final x1 = segW * (i + 0.5);
      final x2 = segW * (i + 1);
      final cy = baseY + amp * math.sin(math.pi * (i + 0.5) / 2 + p) *
          (i % 2 == 0 ? 1 : -1);
      final ey = baseY + amp * math.sin(math.pi * (i + 1) / 2 + p) *
          (i % 2 == 0 ? -1 : 1);
      path.quadraticBezierTo(x1, cy, x2, ey);
    }

    path
      ..lineTo(w, h)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.phase != phase;
}