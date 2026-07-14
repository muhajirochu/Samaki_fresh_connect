// Unit tests for [GpsHelper].
//
// Pure functions only — no Flutter binding required.

import 'package:flutter_test/flutter_test.dart';
import 'package:samakifresh_connect/features/map/utils/gps_helper.dart';

void main() {
  group('mpsToKmph', () {
    test('converts 0 m/s to 0 km/h', () {
      expect(GpsHelper.mpsToKmph(0), 0.0);
    });

    test('converts 10 m/s to 36 km/h', () {
      expect(GpsHelper.mpsToKmph(10), 36.0);
    });

    test('clamps negative speeds to 0', () {
      expect(GpsHelper.mpsToKmph(-5), 0.0);
    });

    test('returns 0 for NaN', () {
      expect(GpsHelper.mpsToKmph(double.nan), 0.0);
    });
  });

  group('formatSpeed', () {
    test('renders 1 decimal', () {
      expect(GpsHelper.formatSpeed(11.11), '40.0 km/h');
    });

    test('handles 0', () {
      expect(GpsHelper.formatSpeed(0), '0.0 km/h');
    });
  });

  group('formatAccuracy', () {
    test('renders meters with 1 decimal', () {
      expect(GpsHelper.formatAccuracy(8.34), '8.3 m');
    });

    test('returns dash for negative', () {
      expect(GpsHelper.formatAccuracy(-1), '—');
    });
  });

  group('formatCoordinates', () {
    test('renders 5 decimal places', () {
      expect(
        GpsHelper.formatCoordinates(-6.162912345, 39.202634567),
        '-6.16291, 39.20263',
      );
    });
  });

  group('formatRelativeTime', () {
    final now = DateTime(2026, 7, 3, 12, 0, 0);

    test('returns "Just now" for under 5 seconds', () {
      final then = now.subtract(const Duration(seconds: 2));
      expect(GpsHelper.formatRelativeTime(then, now: now), 'Just now');
    });

    test('returns "N seconds ago" between 5 and 59 seconds', () {
      final then = now.subtract(const Duration(seconds: 30));
      expect(GpsHelper.formatRelativeTime(then, now: now), '30 seconds ago');
    });

    test('returns "1 minute ago" exactly at 60s', () {
      final then = now.subtract(const Duration(seconds: 60));
      expect(GpsHelper.formatRelativeTime(then, now: now), '1 minute ago');
    });

    test('returns "N minutes ago" between 2 and 59 minutes', () {
      final then = now.subtract(const Duration(minutes: 5));
      expect(GpsHelper.formatRelativeTime(then, now: now), '5 minutes ago');
    });

    test('returns "N hours ago" between 1 and 23 hours', () {
      final then = now.subtract(const Duration(hours: 3));
      expect(GpsHelper.formatRelativeTime(then, now: now), '3 hours ago');
    });

    test('returns "N days ago" between 1 and 6 days', () {
      final then = now.subtract(const Duration(days: 4));
      expect(GpsHelper.formatRelativeTime(then, now: now), '4 days ago');
    });

    test('handles future timestamps (clock skew) gracefully', () {
      final then = now.add(const Duration(minutes: 1));
      expect(GpsHelper.formatRelativeTime(then, now: now), 'Just now');
    });
  });

  group('haversineMeters', () {
    test('returns 0 for the same point', () {
      expect(GpsHelper.haversineMeters(-6.1629, 39.2026, -6.1629, 39.2026), 0.0);
    });

    test('computes ~111km for 1 degree of latitude', () {
      // 1 degree of latitude ≈ 111,195 m.
      final m = GpsHelper.haversineMeters(0, 0, 1, 0);
      expect(m, closeTo(111195, 500));
    });

    test('computes ~111km for 1 degree of longitude at the equator', () {
      final m = GpsHelper.haversineMeters(0, 0, 0, 1);
      expect(m, closeTo(111195, 500));
    });

    test('is symmetric', () {
      final a = GpsHelper.haversineMeters(-6.1629, 39.2026, -6.1640, 39.2030);
      final b = GpsHelper.haversineMeters(-6.1640, 39.2030, -6.1629, 39.2026);
      expect(a, closeTo(b, 0.001));
    });
  });
}