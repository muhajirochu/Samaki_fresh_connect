import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_release_config.dart';
import '../../config/theme_extensions.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../services/installation_card_pdf_service.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/premium_components.dart';

/// App Distribution / Download Page for SamakiFresh Connect.
///
/// Provides a single Material 3 surface that:
///   1. Detects the user's platform (Android vs iOS) and highlights the
///      correct install path. The QR code, button set, and PDF card all
///      read from [AppReleaseConfig] so a new APK or TestFlight release
///      only requires editing one file.
///   2. Renders the same QR code everywhere — in-app, enlarged dialog,
///      and the PDF installation card. The QR encodes the *permanent*
///      public download page URL ([AppReleaseConfig.publicDownloadPageUrl]),
///      so the same printed PDF keeps working across version updates.
///   3. Lets the user share the link via the OS share sheet (WhatsApp,
///      Telegram, email, …) or download a professionally laid-out
///      installation-card PDF via the `printing` package's native share.
class AppDownloadScreen extends StatelessWidget {
  const AppDownloadScreen({super.key});

  // ── Action handlers ─────────────────────────────────────────────

  Future<void> _handleDownloadApk(BuildContext context) async {
    final uri = Uri.parse(AppReleaseConfig.downloadUrl);
    final l10n = AppLocalizations.of(context);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        _showErrorSnackBar(
          context,
          l10n.appDownloadShareFailed,
        );
        await Clipboard.setData(
          const ClipboardData(text: AppReleaseConfig.downloadUrl),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, l10n.appDownloadShareFailed);
        await Clipboard.setData(
          const ClipboardData(text: AppReleaseConfig.downloadUrl),
        );
      }
    }
  }

  Future<void> _handleOpenIosLink(BuildContext context) async {
    const uri = AppReleaseConfig.iosDownloadUrl;
    final l10n = AppLocalizations.of(context);
    if (uri == null || uri.isEmpty) {
      _showIosComingSoonSnackBar(context);
      return;
    }

    try {
      final launched = await launchUrl(
        Uri.parse(uri),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        _showErrorSnackBar(context, l10n.appDownloadShareFailed);
        await Clipboard.setData(ClipboardData(text: uri));
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, l10n.appDownloadShareFailed);
        await Clipboard.setData(ClipboardData(text: uri));
      }
    }
  }

  Future<void> _handleShareLink(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final shareText = l10n.appDownloadShareBody(
      AppReleaseConfig.appName,
      AppReleaseConfig.fullVersion,
      AppReleaseConfig.publicDownloadPageUrl,
    );

    try {
      final result = await Share.share(
        shareText,
        subject: l10n.appDownloadShareSubject,
      );

      if (result.status == ShareResultStatus.success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.appDownloadSharedSuccess),
            backgroundColor: cs.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      await Clipboard.setData(
        const ClipboardData(text: AppReleaseConfig.publicDownloadPageUrl),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.appDownloadCopied),
            backgroundColor: cs.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleCopyLink(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(
      const ClipboardData(text: AppReleaseConfig.publicDownloadPageUrl),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.appDownloadCopied),
          backgroundColor: cs.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleSharePdf(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    // Show a progress snackbar so the user knows the PDF is being built.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary),
              ),
            ),
            const SizedBox(width: AppSizes.paddingMD),
            Text(l10n.appDownloadPdfGenerating),
          ],
        ),
        backgroundColor: cs.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    final ok = await InstallationCardPdfService.share(l10n: l10n);
    if (!context.mounted) return;
    if (!ok) {
      _showErrorSnackBar(context, l10n.appDownloadPdfShareFailed);
    }
  }

  // ── Snackbars ──────────────────────────────────────────────────

  void _showErrorSnackBar(BuildContext context, String message) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: cs.error,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: l10n.appDownloadCopyLink.toUpperCase(),
          textColor: Colors.white,
          onPressed: () {
            Clipboard.setData(
              const ClipboardData(
                text: AppReleaseConfig.publicDownloadPageUrl,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showIosComingSoonSnackBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.appDownloadIosComingSoon),
        backgroundColor: cs.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showQrDialog(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        ),
        backgroundColor: cs.surface,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.appDownloadQrDialogTitle,
                    style: tt.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingMD),
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingLG),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusLG),
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: AppReleaseConfig.publicDownloadPageUrl,
                  version: QrVersions.auto,
                  size: 260.0,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF0C1F2C),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF0C1F2C),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingLG),
              Text(
                l10n.appDownloadQrDialogHelp,
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppSizes.paddingSM),
              SelectableText(
                AppReleaseConfig.publicDownloadPageUrl,
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final gradients = AppGradients.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final platform = defaultTargetPlatform;
    final isAndroid = platform == TargetPlatform.android;
    final isIOS = platform == TargetPlatform.iOS;

    // Skip the auto-detected platform card on web / desktop — there's
    // no native install path there. Show it only on Android + iOS.
    final showDetectedCard = isAndroid || isIOS;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.appDownloadTitle),
        elevation: 0,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: l10n.appDownloadShareLink,
            onPressed: () => _handleShareLink(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSizes.paddingXXL),
        child: Column(
          children: [
            // ── Hero Brand Header ─────────────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: gradients.brand,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppSizes.radiusXL),
                  bottomRight: Radius.circular(AppSizes.radiusXL),
                ),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                vertical: AppSizes.paddingXXL,
                horizontal: AppSizes.paddingLG,
              ),
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const ClipOval(
                      child: AppLogo(size: 76),
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingMD),
                  Text(
                    AppReleaseConfig.appName,
                    style: tt.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppReleaseConfig.appTagline,
                    textAlign: TextAlign.center,
                    style: tt.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.90),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingMD),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingMD,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isIOS
                              ? Icons.apple_rounded
                              : Icons.android_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          '${AppReleaseConfig.fullVersion} · ${AppReleaseConfig.releaseDate}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
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

            const SizedBox(height: AppSizes.paddingXL),

            // ── Main Content Container ───────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingLG,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Detected-Platform Card ───────────────────────
                  if (showDetectedCard)
                    _DetectedPlatformCard(
                      isAndroid: isAndroid,
                      isIOS: isIOS,
                      onAndroid: () => _handleDownloadApk(context),
                      onIOS: () => _handleOpenIosLink(context),
                      onIosDisabledTap: () =>
                          _showIosComingSoonSnackBar(context),
                    ),

                  if (showDetectedCard)
                    const SizedBox(height: AppSizes.paddingXL),

                  // ── QR Code Card ─────────────────────────────────
                  PremiumCard(
                    padding: const EdgeInsets.all(AppSizes.paddingLG),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: cs.primary
                                        .withValues(alpha: 0.10),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.qr_code_2_rounded,
                                    color: cs.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  l10n.appDownloadScanHeader,
                                  style: tt.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.zoom_in_rounded),
                              tooltip: l10n.appDownloadEnlargeQr,
                              onPressed: () => _showQrDialog(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.paddingMD),
                        InkWell(
                          onTap: () => _showQrDialog(context),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusLG,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(
                              AppSizes.paddingLG,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusLG,
                              ),
                              border: Border.all(
                                color: cs.primary.withValues(alpha: 0.25),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: cs.shadow.withValues(
                                    alpha: isDark ? 0.4 : 0.08,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                QrImageView(
                                  data: AppReleaseConfig
                                      .publicDownloadPageUrl,
                                  version: QrVersions.auto,
                                  size: 190.0,
                                  backgroundColor: Colors.white,
                                  eyeStyle: const QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: Color(0xFF0C1F2C),
                                  ),
                                  dataModuleStyle:
                                      const QrDataModuleStyle(
                                    dataModuleShape:
                                        QrDataModuleShape.square,
                                    color: Color(0xFF0C1F2C),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.touch_app_rounded,
                                      size: 14,
                                      color: AppColors.primaryTealDark,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.appDownloadScanOrTap,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors
                                            .textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingMD),
                        Text(
                          l10n.appDownloadScanHint,
                          textAlign: TextAlign.center,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.70),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingSM),
                        // Direct download URL — selectable so power users
                        // can copy it without invoking the share sheet.
                        SelectableText(
                          AppReleaseConfig.publicDownloadPageUrl,
                          textAlign: TextAlign.center,
                          style: tt.bodySmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.paddingXL),

                  // ── Primary CTA: detected platform ─────────────
                  if (isAndroid)
                    GradientButton(
                      label: l10n.appDownloadDownloadApk(
                        AppReleaseConfig.apkSize,
                      ),
                      prefixIcon: Icons.download_rounded,
                      onPressed: () => _handleDownloadApk(context),
                    )
                  else if (isIOS)
                    _IosPrimaryButton(
                      enabled:
                          AppReleaseConfig.iosDownloadUrl != null &&
                              AppReleaseConfig.iosDownloadUrl!.isNotEmpty,
                      label: l10n.appDownloadInstallIos,
                      onTap: () => _handleOpenIosLink(context),
                    )
                  else
                    // Web / desktop — no native install. Guide the user
                    // to scan the QR from a phone.
                    GradientButton(
                      label: l10n.appDownloadScanHeader,
                      prefixIcon: Icons.qr_code_scanner_rounded,
                      onPressed: () => _showQrDialog(context),
                    ),

                  const SizedBox(height: AppSizes.paddingMD),

                  // ── Share + Copy row ────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleShareLink(context),
                          icon: const Icon(
                            Icons.share_rounded,
                            size: 18,
                          ),
                          label: Text(l10n.appDownloadShareLink),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: cs.primary,
                            side: BorderSide(
                              color: cs.primary.withValues(alpha: 0.5),
                            ),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusLG,
                              ),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.paddingSM),
                      IconButton.outlined(
                        onPressed: () => _handleCopyLink(context),
                        icon: const Icon(Icons.copy_rounded),
                        tooltip: l10n.appDownloadCopyLink,
                        style: IconButton.styleFrom(
                          foregroundColor: cs.primary,
                          side: BorderSide(
                            color: cs.primary.withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusLG,
                            ),
                          ),
                          minimumSize: const Size(48, 48),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSizes.paddingXL),

                  // ── Manual install buttons ─────────────────────
                  SectionHeader(
                    title: l10n.appDownloadManualHeader,
                    leadingIcon: Icons.install_mobile_rounded,
                  ),
                  const SizedBox(height: AppSizes.paddingMD),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleDownloadApk(context),
                          icon: const Icon(
                            Icons.android_rounded,
                            size: 18,
                          ),
                          label: Text(l10n.appDownloadInstallAndroid),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: cs.primary,
                            side: BorderSide(
                              color: cs.primary.withValues(alpha: 0.5),
                            ),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusLG,
                              ),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.paddingSM),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleOpenIosLink(context),
                          icon: const Icon(
                            Icons.apple_rounded,
                            size: 18,
                          ),
                          label: Text(l10n.appDownloadInstallIos),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                AppReleaseConfig.iosDownloadUrl == null
                                    ? cs.onSurface.withValues(alpha: 0.4)
                                    : cs.secondary,
                            side: BorderSide(
                              color: (AppReleaseConfig.iosDownloadUrl ==
                                          null
                                      ? cs.onSurface
                                      : cs.secondary)
                                  .withValues(alpha: 0.5),
                            ),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusLG,
                              ),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSizes.paddingXXL),

                  // ── PDF Installation Card ───────────────────────
                  SectionHeader(
                    title: l10n.appDownloadPdfCard,
                    subtitle: null,
                    leadingIcon: Icons.picture_as_pdf_rounded,
                  ),
                  const SizedBox(height: AppSizes.paddingMD),
                  PremiumCard(
                    padding: const EdgeInsets.all(AppSizes.paddingLG),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.picture_as_pdf_rounded,
                            size: 28,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(width: AppSizes.paddingMD),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.appDownloadPdfCard,
                                style: tt.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.appDownloadTitle,
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurface
                                      .withValues(alpha: 0.70),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSizes.paddingSM),
                        FilledButton.tonalIcon(
                          onPressed: () => _handleSharePdf(context),
                          icon: const Icon(Icons.ios_share_rounded),
                          label: Text(l10n.appDownloadPdfShare),
                          style: FilledButton.styleFrom(
                            backgroundColor: cs.primaryContainer,
                            foregroundColor: cs.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.paddingXXL),

                  // ── APK Information Sheet ───────────────────────
                  SectionHeader(
                    title: l10n.appDownloadSpecsHeader,
                    subtitle: l10n.appDownloadSpecsSubtitle,
                    leadingIcon: Icons.info_rounded,
                  ),
                  const SizedBox(height: AppSizes.paddingMD),
                  PremiumCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _SpecTile(
                          icon: isIOS
                              ? Icons.apple_rounded
                              : Icons.android_rounded,
                          title: l10n.appDownloadSpecsPlatform,
                          value: AppReleaseConfig.iosDownloadUrl != null
                              ? '${l10n.appDownloadSpecsPlatformAndroid}'
                                  ' + ${l10n.appDownloadSpecsPlatformIos}'
                              : l10n.appDownloadSpecsPlatformAndroid,
                          showDivider: true,
                        ),
                        _SpecTile(
                          icon: Icons.verified_rounded,
                          title: l10n.appDownloadSpecsVersion,
                          value: AppReleaseConfig.fullVersion,
                          showDivider: true,
                        ),
                        _SpecTile(
                          icon: Icons.data_usage_rounded,
                          title: l10n.appDownloadSpecsSize,
                          value: AppReleaseConfig.apkSize,
                          showDivider: true,
                        ),
                        _SpecTile(
                          icon: Icons.phonelink_setup_rounded,
                          title: l10n.appDownloadSpecsOs,
                          value: AppReleaseConfig.iosDownloadUrl != null
                              ? '${AppReleaseConfig.minAndroidVersion}'
                                  ' · ${AppReleaseConfig.minIosVersion}'
                              : AppReleaseConfig.minAndroidVersion,
                          showDivider: true,
                        ),
                        _SpecTile(
                          icon: Icons.calendar_today_rounded,
                          title: l10n.appDownloadSpecsRelease,
                          value: AppReleaseConfig.releaseDate,
                          showDivider: true,
                        ),
                        _SpecTile(
                          icon: Icons.cloud_done_rounded,
                          title: l10n.appDownloadSpecsStatus,
                          value: AppReleaseConfig.status,
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.paddingXXL),

                  // ── Direct Installation Guide ──────────────────
                  SectionHeader(
                    title: l10n.appDownloadInstallGuide,
                    subtitle: l10n.appDownloadInstallGuideSubtitle,
                    leadingIcon: Icons.build_circle_rounded,
                  ),
                  const SizedBox(height: AppSizes.paddingMD),

                  PremiumCard(
                    padding: const EdgeInsets.all(AppSizes.paddingLG),
                    child: Column(
                      children: AppReleaseConfig.installationSteps
                          .map(
                            (step) => _StepTile(
                              step: step,
                              isLast: step.stepNumber ==
                                  AppReleaseConfig
                                      .installationSteps.length,
                            ),
                          )
                          .toList(),
                    ),
                  ),

                  const SizedBox(height: AppSizes.paddingXXL),

                  // ── Footer ──────────────────────────────────────
                  Center(
                    child: Text(
                      l10n.appDownloadFooter,
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Detected-platform card (above the QR) ────────────────────────

class _DetectedPlatformCard extends StatelessWidget {
  final bool isAndroid;
  final bool isIOS;
  final VoidCallback onAndroid;
  final VoidCallback onIOS;
  final VoidCallback onIosDisabledTap;

  const _DetectedPlatformCard({
    required this.isAndroid,
    required this.isIOS,
    required this.onAndroid,
    required this.onIOS,
    required this.onIosDisabledTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    final platformLabel = isAndroid
        ? 'Android'
        : isIOS
            ? 'iOS'
            : 'Web';

    final ctaLabel = isAndroid
        ? l10n.appDownloadDownloadApk(AppReleaseConfig.apkSize)
        : isIOS
            ? l10n.appDownloadInstallIos
            : l10n.appDownloadScanHeader;

    return PremiumCard(
      padding: const EdgeInsets.all(AppSizes.paddingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppGradients.of(context).brand,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  isIOS
                      ? Icons.apple_rounded
                      : Icons.android_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSizes.paddingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.appDownloadDetectedYou(platformLabel),
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ctaLabel,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingMD),
          if (isAndroid)
            GradientButton(
              label: ctaLabel,
              prefixIcon: Icons.download_rounded,
              onPressed: onAndroid,
            )
          else if (isIOS)
            _IosPrimaryButton(
              enabled: AppReleaseConfig.iosDownloadUrl != null &&
                  AppReleaseConfig.iosDownloadUrl!.isNotEmpty,
              label: ctaLabel,
              onTap: onIOS,
            )
          else
            // Web / desktop — no native install path. Tell the user to
            // scan the QR below with their phone.
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMD,
                vertical: AppSizes.paddingSM,
              ),
              decoration: BoxDecoration(
                color: cs.secondary.withValues(alpha: 0.10),
                borderRadius:
                    BorderRadius.circular(AppSizes.radiusMD),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: cs.secondary,
                  ),
                  const SizedBox(width: AppSizes.paddingSM),
                  Expanded(
                    child: Text(
                      ctaLabel,
                      style: tt.bodySmall?.copyWith(
                        color: cs.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// iOS primary CTA: full-width brand-coloured button. Same widget is
// reused in the detected-platform card and the standalone CTA below
// the QR code so behaviour stays identical.
class _IosPrimaryButton extends StatelessWidget {
  final bool enabled;
  final String label;
  final VoidCallback onTap;

  const _IosPrimaryButton({
    required this.enabled,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeight,
      child: FilledButton.icon(
        onPressed: enabled ? onTap : null,
        icon: const Icon(Icons.apple_rounded),
        label: Text(
          label,
          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: enabled ? cs.secondary : cs.onSurface
              .withValues(alpha: 0.12),
          foregroundColor:
              enabled ? cs.onSecondary : cs.onSurface.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLG),
          ),
        ),
      ),
    );
  }
}

// ── Private spec tile ─────────────────────────────────────────────

class _SpecTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool showDivider;

  const _SpecTile({
    required this.icon,
    required this.title,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMD),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: cs.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.70),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                value,
                style: tt.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 60,
            endIndent: 16,
            color: Theme.of(context).dividerColor,
          ),
      ],
    );
  }
}

// ── Private install-step tile ─────────────────────────────────────

class _StepTile extends StatelessWidget {
  final InstallationStep step;
  final bool isLast;

  const _StepTile({
    required this.step,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSizes.paddingLG),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppGradients.of(context).brand,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${step.stepNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.paddingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.description,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.75),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}