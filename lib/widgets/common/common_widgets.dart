import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import 'premium_components.dart' as premium;

/// Primary CTA used across the app. By default this now renders as the
/// premium [GradientButton], but if the caller passes a custom [style]
/// (legacy `FilledButton.styleFrom(...)`) we fall back to a
/// [FilledButton] so the existing call-sites — e.g. the Logout button
/// that wants a white-on-red bordered variant — keep their visuals.
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final ButtonStyle? style;
  final bool isLoading;
  final IconData? prefixIcon;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style,
    this.isLoading = false,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Legacy callers that pass an explicit ButtonStyle (usually to recolour
    // the button) still get the FilledButton they expect.
    if (style != null) {
      return FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(cs.onPrimary),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (prefixIcon != null) ...[
                    Icon(prefixIcon),
                    const SizedBox(width: AppSizes.paddingMD),
                  ],
                  Text(label),
                ],
              ),
      );
    }

    // New default — premium gradient CTA.
    return premium.GradientButton(
      label: label,
      onPressed: isLoading ? null : onPressed,
      prefixIcon: prefixIcon,
      isLoading: isLoading,
    );
  }
}

/// Premium text input. Re-implemented as a thin wrapper around the
/// shared [FormField] from `premium_components.dart` so it inherits
/// the themed fill, focus ring, and rounded corners.
class CustomTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool isPasswordField;
  final int? maxLines;
  final int? minLines;

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.isPasswordField = false,
    this.maxLines = 1,
    this.minLines,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPasswordField;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Password fields need a toggleable suffix; everything else can
    // delegate straight to the shared premium FormField.
    if (widget.isPasswordField) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          premium.FormField(
            label: widget.label,
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            prefixIcon: widget.prefixIcon,
            suffixIcon: _obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            obscure: true,
            maxLines: 1,
            minLines: widget.minLines,
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () =>
                  setState(() => _obscureText = !_obscureText),
              icon: Icon(
                _obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 16,
              ),
              label: Text(_obscureText ? l10n.show : l10n.hide),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      );
    }

    return premium.FormField(
      label: widget.label,
      hint: widget.hint,
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      prefixIcon: widget.prefixIcon,
      suffixIcon: widget.suffixIcon,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
    );
  }
}

/// Themed loading spinner. Uses the active theme's primary colour so
/// it remains coherent with the rest of the surface.
class LoadingIndicator extends StatelessWidget {
  final String? message;

  const LoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSizes.paddingMD),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

/// Backwards-compatible alias for [EmptyState] in `premium_components.dart`.
/// Existing callers continue to pass an `onRetry` callback (mapped to
/// the new `onAction` slot with a "Retry" label).
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onRetry;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return premium.EmptyState(
      icon: icon,
      title: title,
      subtitle: subtitle,
      actionLabel: onRetry == null ? null : l10n.retry,
      onAction: onRetry,
    );
  }
}