// Widget tests for [LocationInformationCard].

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samakifresh_connect/features/map/models/current_location_model.dart';
import 'package:samakifresh_connect/features/map/services/permission_service.dart';
import 'package:samakifresh_connect/features/map/widgets/location_information_card.dart';

CurrentLocationModel _fix({DateTime? ts}) => CurrentLocationModel(
      latitude: -6.1629,
      longitude: 39.2026,
      accuracy: 4.0,
      altitude: 12.0,
      heading: 90.0,
      speed: 1.2,
      timestamp: ts ?? DateTime(2026, 7, 3, 12),
    );

Widget _wrap(Widget child, {double width = 400}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  group('LocationInformationCard', () {
    testWidgets('renders the address header', (tester) async {
      await tester.pumpWidget(_wrap(
        LocationInformationCard(
          location: _fix(),
          address: 'Kenyatta Road, Stone Town',
          gpsEnabled: true,
          permissionStatus: LocationPermissionState.granted,
          lastUpdatedAt: DateTime(2026, 7, 3, 12),
        ),
      ));

      expect(find.text('Kenyatta Road, Stone Town'), findsOneWidget);
      expect(find.text('CURRENT ADDRESS'), findsOneWidget);
    });

    testWidgets('renders all telemetry rows', (tester) async {
      await tester.pumpWidget(_wrap(
        LocationInformationCard(
          location: _fix(),
          address: 'Test Address',
          gpsEnabled: true,
          permissionStatus: LocationPermissionState.granted,
          lastUpdatedAt: DateTime(2026, 7, 3, 12),
        ),
      ));

      expect(find.text('COORDINATES'), findsOneWidget);
      expect(find.text('ACCURACY'), findsOneWidget);
      expect(find.text('ALTITUDE'), findsOneWidget);
      expect(find.text('SPEED'), findsOneWidget);
      expect(find.text('HEADING'), findsOneWidget);
      expect(find.text('LAST UPDATED'), findsOneWidget);
    });

    testWidgets('shows "Just now" when timestamp == now', (tester) async {
      // The widget computes "now" inside its own state, so we use the
      // platform's wall clock — anything within the last 5 seconds
      // renders as "Just now".
      final now = DateTime.now();
      await tester.pumpWidget(_wrap(
        LocationInformationCard(
          location: _fix(ts: now),
          address: 'Test',
          gpsEnabled: true,
          permissionStatus: LocationPermissionState.granted,
          lastUpdatedAt: now,
        ),
      ));

      expect(find.text('Just now'), findsOneWidget);
    });

    testWidgets('switches to 3-column layout above 600 px', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpWidget(_wrap(
        LocationInformationCard(
          location: _fix(),
          address: 'Test',
          gpsEnabled: true,
          permissionStatus: LocationPermissionState.granted,
          lastUpdatedAt: DateTime(2026, 7, 3, 12),
        ),
        width: 700,
      ));
      await tester.pumpAndSettle();

      expect(find.text('COORDINATES'), findsOneWidget);
      expect(find.text('ACCURACY'), findsOneWidget);
      expect(find.text('ALTITUDE'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('renders denied badge for denied permission', (tester) async {
      await tester.pumpWidget(_wrap(
        LocationInformationCard(
          location: _fix(),
          address: 'Test',
          gpsEnabled: true,
          permissionStatus: LocationPermissionState.denied,
          lastUpdatedAt: DateTime(2026, 7, 3, 12),
        ),
      ));

      expect(find.text('Denied'), findsOneWidget);
    });
  });
}
