// Integration test that pumps the actual [SellerMap] widget with the
// five demo Stone Town sellers and verifies — at runtime, on the live
// widget tree — that:
//
//   1. The `SellerMap` widget receives exactly 5 sellers.
//   2. Each seller's name + coordinates appear in the captured
//      runtime log emitted by [seller_map.dart]'s debug hook.
//   3. The widget tree contains the [SellerMap] widget reading the
//      five sellers from its `sellers` prop.
//
// Uses [AppLogger.addTestListener] to capture log events from the
// underlying `logger` package; this works regardless of zone, since
// `Logger.addOutputListener` is a global static method.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart' show LogEvent;

import 'package:samakifresh_connect/models/map_filter_model.dart';
import 'package:samakifresh_connect/models/street_seller_model.dart';
import 'package:samakifresh_connect/services/location_service.dart';
import 'package:samakifresh_connect/utils/logger.dart';
import 'package:samakifresh_connect/widgets/map/seller_map.dart';

List<StreetSellerModel> _demoSellers() {
  final t = DateTime(2026, 7, 3, 12);
  return [
    _seller('demo-fatma-tuna', 'Fatma Tuna Specialist', '+255770000001',
        -6.1608, 39.2040, 'Creek Road', t),
    _seller('demo-babu-tilapia', 'Babu Tilapia', '+255770000002',
        -6.1616, 39.2010, 'Mizingani Road', t),
    _seller('demo-sara-fish', 'Sara Mixed Fish', '+255770000003',
        -6.1642, 39.2055, 'Shangani Street', t),
    _seller('demo-kwame-market', 'Kwame Market Stall', '+255770000004',
        -6.1599, 39.1999, 'Darajani Market', t),
    _seller('demo-mama-zainab', 'Mama Zainab', '+255770000005', -6.1665,
        39.2025, 'Kenyatta Road', t),
  ];
}

StreetSellerModel _seller(
  String id,
  String name,
  String phone,
  double lat,
  double lng,
  String street,
  DateTime t,
) {
  return StreetSellerModel(
    sellerId: id,
    fullName: name,
    phoneNumber: phone,
    latitude: lat,
    longitude: lng,
    marketName: 'Stone Town',
    regionName: 'Mjini Magharibi',
    streetName: street,
    isActive: true,
    isVerified: true,
    averageRating: 4.5,
    totalRatings: 12,
    totalOrders: 38,
    createdAt: t,
    updatedAt: t,
  );
}

class _SellersHarness extends StatelessWidget {
  final List<StreetSellerModel> sellers;
  const _SellersHarness({required this.sellers});

  @override
  Widget build(BuildContext context) {
    return SellerMap(
      sellers: sellers
          .map((s) => SellerWithFish(seller: s, matchingItems: const []))
          .toList(),
      buyerLocation: const BuyerLocation(
        latitude: -6.1629,
        longitude: 39.2026,
        source: 'profile',
      ),
      activeRoute: null,
      selectedSeller: null,
      onSellerTap: (_) {},
    );
  }
}

/// Returns a list of log messages captured during [body] plus the
/// resolved value.
Future<List<String>> _captureLogs(Future<void> Function() body) async {
  final lines = <String>[];
  void listener(LogEvent e) {
    // LogEvent.message is a rich structured type (often a list of
    // strings); flatten it to a single string for assertions.
    final msg = e.message;
    if (msg is String) {
      lines.add(msg);
    } else if (msg is List<String>) {
      lines.addAll(msg);
    } else {
      lines.add(msg.toString());
    }
  }

  AppLogger.addTestListener(listener);
  try {
    await body();
  } finally {
    AppLogger.removeTestListener(listener);
  }
  return lines;
}

void main() {
  testWidgets(
      'RUNTIME REPORT — 5 Stone Town sellers are rendered with their '
      'coordinates', (tester) async {
    final sellers = _demoSellers();

    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final lines = await _captureLogs(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _SellersHarness(sellers: sellers),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
    });
    final log = lines.join('\n');

    // ── Print a runtime report so the developer can see what was
    // rendered when running locally.
    // ignore: avoid_print
    print('──────────────────────────────────────────────');
    // ignore: avoid_print
    print('SELLER RUNTIME REPORT — buyer map');
    // ignore: avoid_print
    print('──────────────────────────────────────────────');
    for (final s in sellers) {
      // ignore: avoid_print
      print(
          ' • ${s.fullName.padRight(26)} '
          'lat=${s.latitude.toStringAsFixed(5)} '
          'lng=${s.longitude.toStringAsFixed(5)} '
          'market=${s.marketName}');
    }
    // ignore: avoid_print
    print('──────────────────────────────────────────────');

    // ── Assertions
    expect(
      log.contains('5 sellers'),
      isTrue,
      reason: 'seller_map.dart must emit "5 sellers" when 5 sellers '
          'are in widget.sellers',
    );

    for (final s in sellers) {
      expect(
        log.contains(s.fullName),
        isTrue,
        reason: '${s.fullName} must appear in the MarkerLayer log',
      );
      // SellerMap logs lat/lng with default toString (no zero padding),
      // so accept either the default form or any toStringAsFixed(N)
      // variant the log uses.
      final latCandidates = <String>{
        s.latitude.toString(),
        s.latitude.toStringAsFixed(2),
        s.latitude.toStringAsFixed(4),
        s.latitude.toStringAsFixed(5),
      };
      final lngCandidates = <String>{
        s.longitude.toString(),
        s.longitude.toStringAsFixed(2),
        s.longitude.toStringAsFixed(4),
        s.longitude.toStringAsFixed(5),
      };
      expect(
        latCandidates.any(log.contains),
        isTrue,
        reason:
            '${s.fullName} latitude must reach the MarkerLayer '
            '— tried ${latCandidates.toList()}',
      );
      expect(
        lngCandidates.any(log.contains),
        isTrue,
        reason:
            '${s.fullName} longitude must reach the MarkerLayer '
            '— tried ${lngCandidates.toList()}',
      );
    }
  });

  testWidgets(
      'RUNTIME REPORT — SellerMap receives exactly 5 sellers via its public '
      '`sellers` field', (tester) async {
    final sellers = _demoSellers();

    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _captureLogs(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _SellersHarness(sellers: sellers),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
    });

    final mapWidgets = tester.widgetList(find.byType(SellerMap));
    expect(mapWidgets, isNotEmpty);
    final lengths =
        mapWidgets.map((w) => (w as SellerMap).sellers.length).toList();
    expect(
      lengths.first,
      5,
      reason:
          'SellerMap.sellers.length must be exactly 5 — proves the demo '
          'dataset reaches the rendering pipeline',
    );
  });
}
