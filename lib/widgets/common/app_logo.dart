import 'package:flutter/material.dart';

/// Reusable brand logo for SamakiFresh Connect.
///
/// Renders `assets/images/logo/logo.png` at the requested [size].
/// The icon image already carries its own deep-ocean rounded-square
/// background, so we use [BoxFit.contain] (never cover/crop) and let
/// the image fill the square exactly.
///
/// Set [withGlow] to true for a soft cyan ambient glow — best on dark
/// or gradient backgrounds such as the splash screen.
class AppLogo extends StatelessWidget {
  /// Edge length in logical pixels. The widget is always square.
  final double size;

  /// Corner radius for the clip. Defaults to size × 0.22 which matches
  /// the icon artwork's own internal rounding.
  final double? borderRadius;

  /// Adds a soft cyan/navy ambient shadow behind the icon.
  final bool withGlow;

  /// Asset path — override only in tests.
  final String assetPath;

  const AppLogo({
    super.key,
    this.size = 48,
    this.borderRadius,
    this.withGlow = false,
    this.assetPath = 'assets/images/logo/logo.png',
  });

  @override
  Widget build(BuildContext context) {
    final double r = borderRadius ?? size * 0.22;

    // The clipped image — BoxFit.contain so nothing is cropped.
    final Widget img = ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => _FallbackIcon(size: size, radius: r),
      ),
    );

    if (!withGlow) return SizedBox(width: size, height: size, child: img);

    // Use theme tokens so the glow reads correctly in both light
    // and dark mode. Bright Blue + Teal Green on light, primary +
    // accent on dark — same gradient family, theme-aware.
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(r),
          boxShadow: [
            // Outer brand glow
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.40),
              blurRadius: size * 0.55,
              spreadRadius: 0,
              offset: Offset(0, size * 0.06),
            ),
            // Depth shadow
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.28),
              blurRadius: size * 0.35,
              spreadRadius: 0,
              offset: Offset(0, size * 0.10),
            ),
          ],
        ),
        child: img,
      ),
    );
  }
}

/// Shown when the PNG asset fails to load (e.g., first cold-start before
/// assets are bundled). Keeps the UI intact with brand colours.
class _FallbackIcon extends StatelessWidget {
  final double size;
  final double radius;
  const _FallbackIcon({required this.size, required this.radius});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        // Brand gradient — primary → accent, read from the active
        // theme so it tracks Material 3 surface tints automatically.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, cs.secondary],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.set_meal_rounded,
        size: size * 0.5,
        color: cs.onPrimary,
      ),
    );
  }
}