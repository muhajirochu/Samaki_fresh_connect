// Tests that tapping the Call / SMS tiles in SellerProfileSheet
// invokes `launchUrl` with the correct URI.
//
// We mock the platform's method channel so url_launcher never tries
// to talk to a real platform — the recording lives in the mock
// handler. A try/catch around the tap handles the fact that some
// test platforms raise PlatformException for `tel:` / `sms:` URIs —
// the assertion is on the recorded URI, not on the platform's reply.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:samakifresh_connect/l10n/app_localizations.dart';
import 'package:samakifresh_connect/models/street_seller_model.dart';
import 'package:samakifresh_connect/widgets/map/seller_profile_sheet.dart';

StreetSellerModel _testSeller() {
  return StreetSellerModel(
    sellerId: 'demo-fatma-tuna',
    fullName: 'Fatma Tuna Specialist',
    phoneNumber: '+255770000001',
    latitude: -6.1608,
    longitude: 39.2040,
    marketName: 'Stone Town',
    regionName: 'Mjini Magharibi',
    streetName: 'Creek Road',
    isActive: true,
    isOnline: false,
    isVerified: true,
    averageRating: 4.5,
    totalRatings: 12,
    totalOrders: 38,
    createdAt: DateTime(2026, 7, 3, 12),
    updatedAt: DateTime(2026, 7, 3, 12),
  );
}

Future<void> _pumpSheet(WidgetTester tester, StreetSellerModel seller) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(
        builder: (context) => Scaffold(
          body: SizedBox(
            width: 400,
            height: 1400,
            child: SellerProfileSheet(
              seller: seller,
              buyerLatitude: -6.1629,
              buyerLongitude: 39.2026,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // url_launcher routes through this channel. We intercept it so the
  // test never tries to talk to a real platform, and we record every
  // URI the production code asks to launch.
  final launchCalls = <MethodCall>[];
  const launchChannel = MethodChannel('plugins.flutter.io/url_launcher');

  setUp(() {
    launchCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(launchChannel, (call) async {
      launchCalls.add(call);
      if (call.method == 'canLaunch') return true;
      // For url_launcher 6.x, `launchUrl(Uri)` from the public API
      // delegates to the `launch` method on this channel.
      return true;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(launchChannel, null);
  });

  testWidgets(
    'tapping Call tile invokes the url_launcher channel with a tel: URI',
    (tester) async {
      await _pumpSheet(tester, _testSeller());

      // Scroll the contact strip into view first so the tap is
      // actually dispatched (defensive against future layout changes).
      await tester.scrollUntilVisible(
        find.byIcon(Icons.phone_rounded),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      final callTile = find.ancestor(
        of: find.byIcon(Icons.phone_rounded),
        matching: find.byType(InkWell),
      );
      expect(callTile, findsWidgets);

      try {
        await tester.tap(callTile.first);
        await tester.pumpAndSettle();
      } catch (_) {
        // Platform-only behaviour (e.g. PlatformException) shouldn't
        // crash the test. The recorded call below is the contract.
      }

      // url_launcher 6.x: `launchUrl(Uri)` from the public API
      // delegates to the `launch` method on `plugins.flutter.io/url_launcher`.
      final launchCall = launchCalls.firstWhere(
        (c) => c.method == 'launch',
        orElse: () => throw StateError(
          'expected url_launcher channel to receive a launch call, '
          'got: ${launchCalls.map((c) => c.method).toList()}',
        ),
      );
      final args = (launchCall.arguments as Map?) ?? const {};
      final url = (args['url'] as String?) ?? '';
      expect(Uri.parse(url).scheme, 'tel');
      expect(Uri.parse(url).path, '+255770000001');
    },
  );

  testWidgets(
    'tapping SMS tile invokes the url_launcher channel with an sms: URI',
    (tester) async {
      await _pumpSheet(tester, _testSeller());

      await tester.scrollUntilVisible(
        find.byIcon(Icons.sms_rounded),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      final smsTile = find.ancestor(
        of: find.byIcon(Icons.sms_rounded),
        matching: find.byType(InkWell),
      );
      expect(smsTile, findsWidgets);

      try {
        await tester.tap(smsTile.first);
        await tester.pumpAndSettle();
      } catch (_) {
        // Platform-only behaviour (e.g. PlatformException) shouldn't
        // crash the test.
      }

      final launchCall = launchCalls.firstWhere(
        (c) => c.method == 'launch',
        orElse: () => throw StateError(
          'expected url_launcher channel to receive a launch call, '
          'got: ${launchCalls.map((c) => c.method).toList()}',
        ),
      );
      final args = (launchCall.arguments as Map?) ?? const {};
      final url = (args['url'] as String?) ?? '';
      expect(Uri.parse(url).scheme, 'sms');
      expect(Uri.parse(url).path, '+255770000001');
    },
  );
}
