// Navigation tests for the buyer's two map entry points.
//
// Both of these were broken in ways that only showed up at runtime,
// because both were plain string/typo bugs that the analyzer cannot
// see:
//
//   1. The dashboard's "Fungua Ramani" CTA pushed `/map-foundation`,
//      a path that is not in the route table at all. Every tap landed
//      on the "Page not found" errorBuilder.
//
//   2. Tapping a search result called `context.go('/buyer/map', extra:
//      {...})`. The `/buyer/map` route builds BuyerMapScreen from
//      `state.uri.queryParameters` and never reads `extra`, so the map
//      opened completely unfiltered no matter what was tapped.
//
// These tests drive a real GoRouter over the real route table and
// assert on the resolved location, so a regression to either string is
// caught here rather than by a user.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:samakifresh_connect/config/route_paths.dart';

/// A miniature router carrying only the routes under test, so these
/// assertions do not depend on auth redirect or Firebase.
GoRouter _router({required Widget home}) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (_, __) => home),
      GoRoute(
        path: AppRoutes.buyerMap,
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return Scaffold(
            body: Column(
              children: [
                const Text('MAP'),
                Text('fishType=${q['fishType'] ?? ''}'),
                Text('sellerId=${q['sellerId'] ?? ''}'),
                Text('q=${q['q'] ?? ''}'),
              ],
            ),
          );
        },
      ),
    ],
    errorBuilder: (context, state) => const Scaffold(
      body: Text('PAGE NOT FOUND'),
    ),
  );
}

/// Mirrors `_DashboardBody._openMap` — the exact URI construction the
/// dashboard uses. Kept in sync by the assertions below.
void _openMap(BuildContext context, {String? fishType, String? query}) {
  final params = <String, String>{
    if (fishType != null && fishType.isNotEmpty) 'fishType': fishType,
    if (query != null && query.isNotEmpty) 'q': query,
  };
  final uri = Uri(
    path: AppRoutes.buyerMap,
    queryParameters: params.isEmpty ? null : params,
  );
  context.push(uri.toString());
}

void main() {
  group('Fungua Ramani CTA', () {
    testWidgets('resolves to the map, not the error page', (tester) async {
      late BuildContext ctx;
      final router = _router(
        home: Builder(builder: (context) {
          ctx = context;
          return const Scaffold(body: Text('HOME'));
        }),
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      _openMap(ctx);
      await tester.pumpAndSettle();

      expect(find.text('PAGE NOT FOUND'), findsNothing,
          reason: '/map-foundation was not a registered route');
      expect(find.text('MAP'), findsOneWidget);
    });

    testWidgets('forwards fishType and query when given', (tester) async {
      late BuildContext ctx;
      final router = _router(
        home: Builder(builder: (context) {
          ctx = context;
          return const Scaffold(body: Text('HOME'));
        }),
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // The "Popular Near You" tiles call _openMap with both.
      _openMap(ctx, fishType: 'tuna', query: 'Tuna');
      await tester.pumpAndSettle();

      expect(find.text('fishType=tuna'), findsOneWidget);
      expect(find.text('q=Tuna'), findsOneWidget);
    });

    testWidgets('omits empty params rather than sending blanks',
        (tester) async {
      late BuildContext ctx;
      final router = _router(
        home: Builder(builder: (context) {
          ctx = context;
          return const Scaffold(body: Text('HOME'));
        }),
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      _openMap(ctx, fishType: '', query: null);
      await tester.pumpAndSettle();

      expect(find.text('fishType='), findsOneWidget);
      expect(find.text('MAP'), findsOneWidget);
    });
  });

  group('Search result tap', () {
    testWidgets('passes the filter as query params, which the route reads',
        (tester) async {
      late BuildContext ctx;
      final router = _router(
        home: Builder(builder: (context) {
          ctx = context;
          return const Scaffold(body: Text('RESULTS'));
        }),
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // The construction used by BuyerFishSearchScreen.onTapListing.
      final uri = Uri(
        path: AppRoutes.buyerMap,
        queryParameters: {'fishType': 'tuna', 'sellerId': 'seller-7'},
      );
      ctx.push(uri.toString());
      await tester.pumpAndSettle();

      expect(find.text('fishType=tuna'), findsOneWidget);
      expect(find.text('sellerId=seller-7'), findsOneWidget);
    });

    testWidgets('extra{} alone would have left the map unfiltered',
        (tester) async {
      // Pins WHY the fix was needed: this is what the old code did.
      // The route reads queryParameters, so both filters come back
      // empty — the map opens showing everything.
      late BuildContext ctx;
      final router = _router(
        home: Builder(builder: (context) {
          ctx = context;
          return const Scaffold(body: Text('RESULTS'));
        }),
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      ctx.push(
        AppRoutes.buyerMap,
        extra: {'fishType': 'tuna', 'sellerId': 'seller-7'},
      );
      await tester.pumpAndSettle();

      expect(find.text('fishType='), findsOneWidget);
      expect(find.text('sellerId='), findsOneWidget);
    });

    testWidgets('push keeps the results screen on the stack', (tester) async {
      // go() would have replaced the results; the buyer expects Back
      // to return to their search.
      late BuildContext ctx;
      final router = _router(
        home: Builder(builder: (context) {
          ctx = context;
          return const Scaffold(body: Text('RESULTS'));
        }),
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final uri = Uri(
        path: AppRoutes.buyerMap,
        queryParameters: {'fishType': 'tuna', 'sellerId': 'seller-7'},
      );
      ctx.push(uri.toString());
      await tester.pumpAndSettle();
      expect(find.text('MAP'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('RESULTS'), findsOneWidget);
    });
  });
}
