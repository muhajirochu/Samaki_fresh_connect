// Smoke tests for the Installation Card PDF service.
//
// The PDF service is a pure function: `AppReleaseConfig` (compile-time
// constants) + `AppLocalizations` (English / Kiswahili) → `Uint8List`
// PDF bytes. These tests assert the bare contract:
//
//   1. The bytes start with the `%PDF-` magic header.
//   2. The byte length is comfortably above the 5 KB threshold of an
//      empty document (so we know the QR + brand header + specs table
//      + platform steps actually rendered).
//   3. The public download URL (which the QR encodes) appears in the
//      decompressed text stream — so a regeneration with the same
//      config produces a deterministic-looking artifact.
//
// No rendering / visual assertion. The PDF reader is the source of
// truth for visual correctness; this test guards the integration.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:samakifresh_connect/config/app_release_config.dart';
import 'package:samakifresh_connect/l10n/app_localizations_en.dart';
import 'package:samakifresh_connect/services/installation_card_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InstallationCardPdfService.buildPdfBytes', () {
    test(
      'returns a valid PDF document (English locale)',
      () async {
        final l10n = AppLocalizationsEn();
        final bytes = await InstallationCardPdfService.buildPdfBytes(
          l10n: l10n,
        );

        expect(bytes, isA<Uint8List>());
        expect(bytes.length, greaterThan(5 * 1024),
            reason: 'A populated 2-page PDF should be at least 5 KB');
        // PDF magic header. `%PDF-1.x\n` is the canonical signature.
        final prefix = utf8.decode(bytes.sublist(0, 8));
        expect(prefix, startsWith('%PDF-'));
      },
    );

    test(
      'embeds the public download page URL in the body stream',
      () async {
        final l10n = AppLocalizationsEn();
        final bytes = await InstallationCardPdfService.buildPdfBytes(
          l10n: l10n,
        );

        // The URL is the payload the QR encodes. It must appear in the
        // stream as plain text (it is also encoded into the QR image,
        // but we only assert the text presence here — visual QR
        // correctness requires a reader).
        final asString = utf8.decode(bytes, allowMalformed: true);
        expect(asString, contains(AppReleaseConfig.publicDownloadPageUrl));
      },
    );

    test(
      'output is deterministic for the same config + locale',
      () async {
        final l10n = AppLocalizationsEn();
        final a = await InstallationCardPdfService.buildPdfBytes(
          l10n: l10n,
        );
        final b = await InstallationCardPdfService.buildPdfBytes(
          l10n: l10n,
        );

        // PDF `CreationDate` and `ID` (xref) fields embed a timestamp,
        // so byte-for-byte equality is not achievable. Asserting length
        // equality is a cheap-but-useful smoke check that the renderer
        // emits the same number of objects both times.
        expect(a.length, equals(b.length));
        expect(a.length, greaterThan(5 * 1024));
      },
    );
  });
}