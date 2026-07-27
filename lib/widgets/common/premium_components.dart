// Reusable premium UI primitives for Samaki Fresh Connect.
//
// Every component reads colours exclusively from `Theme.of(context)`
// and the theme extensions defined in `lib/config/theme_extensions.dart`,
// so they render correctly in both the Light and Dark themes.
//
// Catalogue:
//   • `PremiumCard`         — rounded surface with soft shadow
//   • `GlassCard`           — frosted-glass panel
//   • `GradientButton`      — primary action with brand gradient
//   • `OutlineIconButton`   — bordered icon with subtle hover
//   • `StatChip`            — coloured badge for stats / counts
//   • `StatusPill`          — coloured status indicator with dot
//   • `SectionHeader`       — section title + optional CTA
//   • `FormField`           — premium text input
//   • `EmptyState`          — modern empty-state placeholder
//   • `BannerHeader`        — coloured hero bar with title/subtitle
//   • `PageHeader`          — sliver-friendly page header
//   • `NeonAccentDot`       — small glowing dot for badges / status

import 'package:flutter/material.dart';

import '../../config/theme_extensions.dart';
import '../../constants/app_sizes.dart';

/// Soft rounded surface card with a brand-tinted shadow. Use this for
/// every "raised" panel in the app — the shadow colour tracks the
/// current theme so dark mode looks coherent.
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final VoidCallback? onTap;
  final Color? accent;
  final bool elevated;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = AppSizes.radiusLG,
    this.onTap,
    this.accent,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = BackgroundStyle.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: tokens.border, width: 0.6),
        boxShadow: elevated
            ? [
                BoxShadow(
                  // Theme-aware shadow — slightly darker in dark mode
                  // so the card reads as raised against the deep navy
                  // background.
                  color: isDark
                      ? cs.shadow.withValues(alpha: 0.50)
                      : cs.shadow.withValues(alpha: 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSizes.paddingMD),
          child: child,
        ),
      ),
    );

    if (onTap == null) return card;

    final tint = accent ?? cs.primary;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        splashColor: tint.withValues(alpha: 0.06),
        highlightColor: tint.withValues(alpha: 0.04),
        child: card,
      ),
    );
  }
}

/// Frosted-glass card. Use sparingly for hero panels (auth screens,
/// profile header) where the translucent feel adds luxury.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final VoidCallback? onTap;
  final Color? tint;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = AppSizes.radiusLG,
    this.onTap,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final glass = GlassStyle.of(context);
    final cs = Theme.of(context).colorScheme;
    final panel = Container(
      decoration: BoxDecoration(
        gradient: glass.highlight,
        color: tint ?? glass.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: glass.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            // Theme-aware shadow on glass card — slightly stronger so
            // the frosted panel reads as elevated on either theme.
            color: cs.shadow.withValues(alpha: 0.32),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSizes.paddingLG),
          child: child,
        ),
      ),
    );

    if (onTap == null) return panel;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: panel,
      ),
    );
  }
}

/// Primary CTA with the brand gradient as background and a subtle
/// shadow tinted with the primary colour. Drops a brighter, softer
/// shadow on hover.
class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? prefixIcon;
  final Gradient? gradient;
  final double height;
  final double width;
  final EdgeInsetsGeometry padding;
  final bool fullWidth;
  final bool isLoading;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.prefixIcon,
    this.gradient,
    this.height = AppSizes.buttonHeight,
    this.width = 200,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSizes.paddingXL,
    ),
    this.fullWidth = true,
    this.isLoading = false,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gradients = AppGradients.of(context);
    final gradient = widget.gradient ?? gradients.brand;

    final radius = BorderRadius.circular(AppSizes.radiusLG);
    final size = Size(
      widget.fullWidth ? double.infinity : widget.width,
      widget.height,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: radius,
          boxShadow: widget.onPressed == null
              ? null
              : [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: _hover ? 0.35 : 0.22),
                    blurRadius: _hover ? 22 : 14,
                    offset: Offset(0, _hover ? 10 : 6),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isLoading ? null : widget.onPressed,
            borderRadius: radius,
            // Theme-aware splash/highlight (white-on-brand stays white,
            // but read through onPrimary so a future theme override
            // propagates here).
            splashColor: cs.onPrimary.withValues(alpha: 0.10),
            highlightColor: cs.onPrimary.withValues(alpha: 0.06),
            child: Center(
              child: Padding(
                padding: widget.padding,
                child: widget.isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(cs.onPrimary),
                        ),
                      )
                    : Row(
                        mainAxisSize: widget.fullWidth
                            ? MainAxisSize.max
                            : MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.prefixIcon != null) ...[
                            Icon(widget.prefixIcon,
                                color: cs.onPrimary, size: 20),
                            const SizedBox(width: AppSizes.paddingSM),
                          ],
                          Flexible(
                            child: Text(
                              widget.label,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: cs.onPrimary,
                                fontSize: AppSizes.fontMD,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small coloured badge for stats — used in summary tiles / headers.
class StatChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;
  final EdgeInsetsGeometry padding;

  const StatChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSizes.paddingSM,
      vertical: 4,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill-shaped status badge with a coloured dot. The dot uses an
/// Inner Shadow effect so it looks like it's lit from the centre.
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool pulse;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.pulse = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingSM,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(color: color, pulse: pulse),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final Color color;
  final bool pulse;
  const _Dot({required this.color, required this.pulse});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.pulse) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.pulse) {
      return Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      );
    }
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, _) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        return SizedBox(
          width: 14,
          height: 14,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.25 * (1 - t)),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Section title with optional CTA on the right. Use this between
/// card groups so visual rhythm matches Notion / Linear dashboards.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final IconData? leadingIcon;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leadingIcon != null) ...[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSizes.radiusSM),
            ),
            child: Icon(leadingIcon, color: cs.primary, size: 18),
          ),
          const SizedBox(width: AppSizes.paddingSM),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: tt.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle!,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.70),
                      height: 1.3,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton.icon(
            onPressed: onAction,
            icon: Icon(actionIcon ?? Icons.arrow_forward_rounded, size: 16),
            label: Text(actionLabel!),
            style: TextButton.styleFrom(
              foregroundColor: cs.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}

/// Premium text input. Replaces the legacy `CustomTextField` for new
/// screens — keeps themed fill / focus ring / rounded corners.
class FormField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool obscure;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLines;
  final int? minLines;

  const FormField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.minLines,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.80),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
        ),
        const SizedBox(height: AppSizes.paddingXS),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          maxLines: obscure ? 1 : maxLines,
          minLines: minLines,
          cursorColor: cs.primary,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.40),
                ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: cs.primary, size: 20)
                : null,
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon, color: cs.onSurface.withValues(alpha: 0.55))
                : null,
            filled: true,
            fillColor: cs.surfaceContainerHighest,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMD,
              vertical: AppSizes.paddingMD,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMD),
              borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMD),
              borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMD),
              borderSide: BorderSide(color: cs.primary, width: 1.6),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMD),
              borderSide: BorderSide(color: cs.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMD),
              borderSide: BorderSide(color: cs.error, width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}

/// Modern empty-state placeholder with a soft gradient blob behind
/// the icon. Replaces the plain `EmptyStateWidget`.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 132,
              height: 132,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          cs.primary.withValues(alpha: 0.10),
                          cs.primary.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 38, color: cs.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.paddingLG),
            Text(
              title,
              style: tt.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSizes.paddingXS),
              Text(
                subtitle!,
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.65),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSizes.paddingLG),
              GradientButton(
                label: actionLabel!,
                onPressed: onAction,
                fullWidth: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingXL,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Coloured banner used as a page header — fits behind a SliverAppBar
/// or on top of a regular scroll view.
class BannerHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Gradient? gradient;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingTap;
  final double height;
  final Widget? leading;

  const BannerHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.gradient,
    this.trailingIcon,
    this.onTrailingTap,
    this.height = 140,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gradients = AppGradients.of(context);
    final brandGradient = gradient ?? gradients.brand;

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: brandGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppSizes.radiusXL),
          bottomRight: Radius.circular(AppSizes.radiusXL),
        ),
        boxShadow: [
          BoxShadow(
            // Theme-aware shadow — reads correctly on either surface.
            color: cs.shadow.withValues(alpha: 0.36),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative glow blob top-right
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    cs.onPrimary.withValues(alpha: 0.18),
                    cs.onPrimary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          // Decorative glow blob bottom-left
          Positioned(
            bottom: -50,
            left: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    cs.onPrimary.withValues(alpha: 0.10),
                    cs.onPrimary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: AppSizes.paddingSM),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: cs.onPrimary,
                            fontSize: AppSizes.fontXXL,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              color: cs.onPrimary.withValues(alpha: 0.85),
                              fontSize: AppSizes.fontSM,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: AppSizes.paddingSM),
                    Material(
                      color: cs.onPrimary.withValues(alpha: 0.18),
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: onTrailingTap,
                        icon: Icon(trailingIcon, color: cs.onPrimary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
