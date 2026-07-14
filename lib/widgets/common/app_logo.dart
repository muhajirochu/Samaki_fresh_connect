import 'package:flutter/material.dart';

/// Reusable brand logo for SamakiFresh Connect.
///
/// Wraps the asset `assets/images/logo/logo.png` (already registered in
/// `pubspec.yaml`) so every screen displays the same mark. Defaults use
/// [BoxFit.contain] so the artwork fits inside the parent without cropping
/// or distortion, even on screens with non-square containers.
///
/// Use [size] to control both width and height (square). Wrap in a parent
/// [Container] if you need a coloured background or shadow — this widget
/// renders only the image so it stays composable.
class AppLogo extends StatelessWidget {
  /// Edge length in logical pixels (the logo is rendered square).
  final double size;

  /// Optional border radius around the image (handy for the splash tile).
  final double borderRadius;

  /// Optional background colour drawn behind the logo. Leave null for a
  /// transparent background so the parent container's colour shows.
  final Color? backgroundColor;

  /// Asset path for the logo. Defaults to the registered brand asset.
  final String assetPath;

  const AppLogo({
    super.key,
    this.size = 48,
    this.borderRadius = 0,
    this.backgroundColor,
    this.assetPath = 'assets/images/logo/logo.png',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius > 0
            ? BorderRadius.circular(borderRadius)
            : null,
      ),
      clipBehavior: borderRadius > 0 ? Clip.antiAlias : Clip.none,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        // cacheWidth is a soft cap that helps with the 5 MB source PNG.
        // Skia decodes at this size, so we don't pay full-resolution cost.
        cacheWidth: (size * 3).round().clamp(96, 1024),
        errorBuilder: (context, error, stackTrace) {
          // Fall back to the brand mark colour if the asset is missing —
          // keeps the UI from showing a broken-image icon.
          return Container(
            color: const Color(0xFF0066B4),
            alignment: Alignment.center,
            child: Icon(
              Icons.water_drop_rounded,
              size: size * 0.5,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }
}