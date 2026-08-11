// Build + share + save the SamakiFresh Connect Installation Card PDF.
//
// Single source of truth for the layout: every label, every install step,
// every spec value flows from `AppReleaseConfig` + `AppLocalizations`. The
// in-app Download page and this PDF are guaranteed to stay in sync —
// update `AppReleaseConfig` once and both surfaces reflect the change.
//
// The QR encodes the *permanent* `AppReleaseConfig.publicDownloadPageUrl`,
// not the artifact URL. That means a new APK release does NOT require
// regenerating the QR — the same printed PDF keeps working as long as the
// public landing page is live and routes users to the latest artifact.
//
// Public API:
//   • [InstallationCardPdfService.buildPdfBytes] — pure, in-memory. The
//     building block used by both [share] and [saveToDocuments]. Returns
//     a `Uint8List` containing the PDF.
//   • [InstallationCardPdfService.share] — build + open the native share
//     sheet on mobile (uses the `printing` package's `Printing.sharePdf`).
//   • [InstallationCardPdfService.saveToDocuments] — build + write to the
//     device's documents directory and return the absolute file path.
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io' show File;

import '../config/app_release_config.dart';
import '../l10n/app_localizations.dart';
import '../utils/logger.dart';

/// Static-method service. No state — `AppReleaseConfig` is the only input.
class InstallationCardPdfService {
  const InstallationCardPdfService._();

  /// Filename used for both the share sheet and the saved PDF.
  static const String _filename = 'samakifresh-install-card.pdf';

  /// Build the installation card PDF in memory.
  ///
  /// [l10n] provides every user-visible string (English or Kiswahili,
  /// depending on which `AppLocalizations` the caller passes). The QR
  /// encodes [AppReleaseConfig.publicDownloadPageUrl], so a new APK or
  /// TestFlight release does not require re-printing the PDF.
  ///
  /// Throws on font/asset loading failures — callers should handle
  /// exceptions (the screen surfaces a snackbar on catch).
  static Future<Uint8List> buildPdfBytes({
    required AppLocalizations l10n,
  }) async {
    final doc = pw.Document(
      title: AppReleaseConfig.appName,
      author: AppReleaseConfig.appName,
      creator: 'SamakiFresh Connect',
      subject: '${AppReleaseConfig.appName} — ${l10n.appDownloadPdfCard}',
    );

    // Load the brand logo once. `rootBundle.load` is cached after the
    // first call, so subsequent page renders reuse the same bytes.
    pw.MemoryImage? logoImage;
    try {
      final ByteData logoData =
          await rootBundle.load('assets/images/logo/logo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      // Don't fail the whole PDF if the logo asset is missing — the
      // header still renders with just the wordmark.
      AppLogger.warning('InstallationCardPdfService: logo asset missing: $e');
    }

    final qrCode = pw.Barcode.qrCode();
    final pageFormat = PdfPageFormat.letter.copyWith(
      marginLeft: 18,
      marginRight: 18,
      marginTop: 18,
      marginBottom: 18,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        header: (ctx) => _pageHeader(logoImage, l10n),
        footer: (ctx) => _pageFooter(ctx, l10n),
        build: (ctx) => [
          _buildQrSection(ctx, qrCode, l10n),
          pw.SizedBox(height: 18),
          _buildSpecsTable(l10n),
          pw.SizedBox(height: 18),
          _buildInstallGuideIntro(l10n),
        ],
      ),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        header: (ctx) => _pageHeader(logoImage, l10n),
        footer: (ctx) => _pageFooter(ctx, l10n),
        build: (ctx) => [
          _buildPlatformSteps(l10n),
        ],
      ),
    );

    return doc.save();
  }

  /// Build the PDF and open the native share sheet on mobile.
  ///
  /// On web/desktop where the share sheet is not available, falls back to
  /// `Printing.layoutPdf` which opens the native print dialog (which can
  /// save-as-PDF on every desktop OS).
  ///
  /// Returns `true` if the user completed the share / print, `false` if
  /// they cancelled. Returns `false` and logs an error if PDF generation
  /// itself failed.
  static Future<bool> share({
    required AppLocalizations l10n,
  }) async {
    try {
      final Uint8List bytes = await buildPdfBytes(l10n: l10n);

      // Web / desktop: no native share sheet — open the system print
      // dialog. `Printing.layoutPdf` is supported across all
      // desktop + web targets that `printing` ships.
      if (kIsWeb ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux) {
        return await Printing.layoutPdf(
          name: _filename,
          onLayout: (PdfPageFormat format) async => bytes,
        );
      }

      // Mobile (Android, iOS): native share sheet, which also lets the
      // user save to Files / Drive / email / WhatsApp / Telegram etc.
      return await Printing.sharePdf(
        bytes: bytes,
        filename: _filename,
        subject: l10n.appDownloadShareSubject,
        body: l10n.appDownloadShareBody(
          AppReleaseConfig.appName,
          AppReleaseConfig.fullVersion,
          AppReleaseConfig.publicDownloadPageUrl,
        ),
      );
    } catch (e, st) {
      AppLogger.error('InstallationCardPdfService.share failed', e, st);
      return false;
    }
  }

  /// Build the PDF and write it to the device's documents directory.
  ///
  /// Returns the absolute file path of the saved file. Useful when the
  /// caller wants to hand the path to another tool (email attachment,
  /// clipboard, file picker) without going through the share sheet.
  ///
  /// On web this is not supported (no filesystem path) and throws
  /// [UnsupportedError]. The UI checks `kIsWeb` and routes to share
  /// instead.
  static Future<String> saveToDocuments({
    required AppLocalizations l10n,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError(
        'saveToDocuments is not supported on web — use share() instead.',
      );
    }
    final Uint8List bytes = await buildPdfBytes(l10n: l10n);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_filename');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  // ── Page-level helpers ─────────────────────────────────────────────

  static pw.Widget _pageHeader(pw.MemoryImage? logo, AppLocalizations l10n) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.6),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logo != null)
            pw.Container(
              width: 36,
              height: 36,
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.ClipRRect(
                horizontalRadius: 8,
                verticalRadius: 8,
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              ),
            ),
          if (logo != null) pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  AppReleaseConfig.appName,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#0EA5E9'),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  AppReleaseConfig.appTagline,
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#0EA5E9'),
              borderRadius: pw.BorderRadius.circular(99),
            ),
            child: pw.Text(
              '${AppReleaseConfig.fullVersion} · ${AppReleaseConfig.releaseDate}',
              style: pw.TextStyle(
                fontSize: 8,
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pageFooter(pw.Context ctx, AppLocalizations l10n) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.6),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            l10n.appDownloadFooter,
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
          pw.Text(
            '${ctx.pageNumber} / ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  // ── Page 1: QR + specs + guide intro ───────────────────────────────

  static pw.Widget _buildQrSection(
    pw.Context ctx,
    pw.Barcode qrCode,
    AppLocalizations l10n,
  ) {
    const url = AppReleaseConfig.publicDownloadPageUrl;

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F0F9FF'),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(
          color: PdfColor.fromHex('#BAE6FD'),
          width: 0.6,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            l10n.appDownloadScanHeader.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0C1F2C'),
              letterSpacing: 0.8,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(
                color: PdfColor.fromHex('#0EA5E9'),
                width: 1,
              ),
            ),
            child: pw.BarcodeWidget(
              barcode: qrCode,
              data: url,
              width: 130,
              height: 130,
              color: PdfColor.fromHex('#0C1F2C'),
              backgroundColor: PdfColors.white,
              drawText: false,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            l10n.appDownloadScanHint,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            l10n.appDownloadDirectUrlLabel,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 2),
          // Clickable hyperlink annotation so the URL is tappable in any
          // PDF viewer (Preview, Adobe, Chrome, mobile readers).
          pw.UrlLink(
            destination: url,
            child: pw.Text(
              url,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColor.fromHex('#0284C7'),
                decoration: pw.TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSpecsTable(AppLocalizations l10n) {
    final specs = <List<String>>[
      [l10n.appDownloadSpecsPlatform, _platformLabel(l10n)],
      [l10n.appDownloadSpecsVersion, AppReleaseConfig.fullVersion],
      [l10n.appDownloadSpecsSize, AppReleaseConfig.apkSize],
      [l10n.appDownloadSpecsOs, _osLabel()],
      [l10n.appDownloadSpecsStatus, AppReleaseConfig.status],
      [l10n.appDownloadSpecsRelease, AppReleaseConfig.releaseDate],
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          l10n.appDownloadSpecsHeader,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#0C1F2C'),
          ),
        ),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(
            color: PdfColor.fromHex('#E0F2FE'),
            width: 0.6,
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(1),
            1: pw.FlexColumnWidth(1.4),
          },
          cellAlignment: pw.Alignment.centerLeft,
          cellPadding: const pw.EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 5,
          ),
          cellStyle: const pw.TextStyle(fontSize: 9),
          oddCellStyle: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
          data: specs,
        ),
      ],
    );
  }

  static pw.Widget _buildInstallGuideIntro(AppLocalizations l10n) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            l10n.appDownloadInstallGuide,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0C1F2C'),
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            l10n.appDownloadInstallGuideSubtitle,
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Page 2: platform-specific install steps ────────────────────────

  static pw.Widget _buildPlatformSteps(AppLocalizations l10n) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: _androidCard(l10n)),
        pw.SizedBox(width: 14),
        pw.Expanded(child: _iosCard(l10n)),
      ],
    );
  }

  static pw.Widget _androidCard(AppLocalizations l10n) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(
          color: PdfColor.fromHex('#BAE6FD'),
          width: 0.6,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 28,
                height: 28,
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#0EA5E9'),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'A',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                l10n.appDownloadAndroidStepsTitle,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#0C1F2C'),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          ...AppReleaseConfig.installationSteps.map(
            (step) => _stepRow(step.stepNumber, step.title, step.description),
          ),
          pw.SizedBox(height: 10),
          pw.UrlLink(
            destination: AppReleaseConfig.downloadUrl,
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#0EA5E9'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Center(
                child: pw.Text(
                  l10n.appDownloadDownloadApk(AppReleaseConfig.apkSize),
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _iosCard(AppLocalizations l10n) {
    const iosUrl = AppReleaseConfig.iosDownloadUrl;
    final hasIos = iosUrl != null && iosUrl.isNotEmpty;

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(
          color: PdfColor.fromHex('#BAE6FD'),
          width: 0.6,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 28,
                height: 28,
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#0C1F2C'),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'i',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                l10n.appDownloadIosStepsTitle,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#0C1F2C'),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          if (hasIos) ...[
            _stepRow(
              1,
              l10n.appDownloadInstallIos,
              'Tap the button below to open TestFlight / App Store.',
            ),
            _stepRow(
              2,
              l10n.appDownloadInstallAndroid,
              'Tap "Install" in TestFlight or the App Store.',
            ),
            _stepRow(
              3,
              l10n.appDownloadTitle,
              'Launch SamakiFresh Connect from your home screen.',
            ),
            pw.SizedBox(height: 10),
            pw.UrlLink(
              destination: iosUrl,
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#0C1F2C'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Center(
                  child: pw.Text(
                    l10n.appDownloadInstallIos,
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            _stepRow(1, l10n.appDownloadIosStepsTitle,
                l10n.appDownloadIosComingSoonSteps),
          ],
        ],
      ),
    );
  }

  static pw.Widget _stepRow(int number, String title, String body) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 18,
            height: 18,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#0EA5E9'),
              shape: pw.BoxShape.circle,
            ),
            alignment: pw.Alignment.center,
            child: pw.Text(
              '$number',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#0C1F2C'),
                  ),
                ),
                pw.SizedBox(height: 1),
                pw.Text(
                  body,
                  style: const pw.TextStyle(
                    fontSize: 8.5,
                    color: PdfColors.grey800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Cross-platform label helpers ───────────────────────────────────

  static String _platformLabel(AppLocalizations l10n) {
    if (AppReleaseConfig.iosDownloadUrl != null &&
        AppReleaseConfig.iosDownloadUrl!.isNotEmpty) {
      return '${l10n.appDownloadSpecsPlatformAndroid} + '
          '${l10n.appDownloadSpecsPlatformIos}';
    }
    return l10n.appDownloadSpecsPlatformAndroid;
  }

  static String _osLabel() {
    if (AppReleaseConfig.iosDownloadUrl != null &&
        AppReleaseConfig.iosDownloadUrl!.isNotEmpty) {
      return '${AppReleaseConfig.minAndroidVersion} · ${AppReleaseConfig.minIosVersion}';
    }
    return AppReleaseConfig.minAndroidVersion;
  }
}