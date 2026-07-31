// Regression tests for layout overflow on small physical phones.
//
// The bug these guard against only reproduces on a narrow viewport:
// desktop emulators are wide enough that stat tiles, cards and banners
// all fit, so overflow stripes never appear during development and
// then show up on a real 5-inch Android handset.
//
// Every test below pumps a widget at 360x640 (the common low-end
// Android logical size) and asserts Flutter recorded no overflow. The
// Swahili strings are deliberately long — that is the realistic worst
// case for this app's copy.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:samakifresh_connect/constants/app_sizes.dart';
import 'package:samakifresh_connect/l10n/app_localizations.dart';
import 'package:samakifresh_connect/widgets/common/premium_components.dart';

/// A 360x640 phone. `textScaler` is settable so we can prove the
/// layouts survive a user who has bumped their system font size.
const Size kSmallPhone = Size(360, 640);

Widget _phoneApp({
  required Widget child,
  double textScale = 1.0,
}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('sw')],
    locale: const Locale('sw'),
    home: MediaQuery(
      data: MediaQueryData(
        size: kSmallPhone,
        textScaler: TextScaler.linear(textScale),
      ),
      child: Scaffold(body: child),
    ),
  );
}

Future<void> _pumpAtPhoneSize(WidgetTester tester, Widget widget) async {
  tester.view.physicalSize = kSmallPhone;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(widget);
  await tester.pump();
}

void main() {
  group('EmptyState on a 360x640 phone', () {
    testWidgets('does not overflow inside the fixed 320dp placeholder box',
        (tester) async {
      // The listings/orders screens wrap this in SizedBox(height: 320).
      await _pumpAtPhoneSize(
        tester,
        _phoneApp(
          child: const SizedBox(
            height: 320,
            child: EmptyState(
              icon: Icons.inbox_rounded,
              title: 'Hakuna samaki waliopatikana kwa sasa',
              subtitle: 'Jaribu kubadilisha vichujio vyako au rudi baadaye '
                  'kuona samaki wapya walioongezwa na wauzaji.',
              actionLabel: 'Jaribu tena',
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('does not overflow with a long error string as subtitle',
        (tester) async {
      // Error callers pass a raw `e.toString()`, which can be very long.
      await _pumpAtPhoneSize(
        tester,
        _phoneApp(
          child: SizedBox(
            height: 320,
            child: EmptyState(
              icon: Icons.error_rounded,
              title: 'Imeshindwa kupakia',
              subtitle: 'Exception: ${'firebase-permission-denied ' * 20}',
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('BannerHeader on a 360x640 phone', () {
    testWidgets('does not overflow with a long Swahili title and subtitle',
        (tester) async {
      await _pumpAtPhoneSize(
        tester,
        _phoneApp(
          child: const BannerHeader(
            title: 'Karibu kwenye Soko la Samaki Freshi',
            subtitle: 'Pata samaki wabichi kutoka kwa wauzaji walio karibu '
                'nawe, kwa bei nafuu na uwasilishaji wa haraka.',
            trailingIcon: Icons.notifications_rounded,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('does not overflow at 1.3x system font scale', (tester) async {
      // A very common setting on low-end Android handsets.
      await _pumpAtPhoneSize(
        tester,
        _phoneApp(
          textScale: 1.3,
          child: const BannerHeader(
            title: 'Karibu kwenye Soko la Samaki Freshi',
            subtitle: 'Pata samaki wabichi kutoka kwa wauzaji walio karibu '
                'nawe, kwa bei nafuu na uwasilishaji wa haraka.',
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('Stat-tile grid geometry', () {
    testWidgets(
        'a 2-column childAspectRatio 1.25 tile fits icon + value + label',
        (tester) async {
      // Mirrors the admin dashboard / reports grids. At the old ratio of
      // 1.5 the tile was ~101dp tall and this content needed ~116dp.
      await _pumpAtPhoneSize(
        tester,
        _phoneApp(
          child: GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.all(AppSizes.paddingLG),
            mainAxisSpacing: AppSizes.paddingMD,
            crossAxisSpacing: AppSizes.paddingMD,
            childAspectRatio: 1.25,
            children: List.generate(
              4,
              (i) => Container(
                padding: const EdgeInsets.all(AppSizes.paddingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.people_rounded, size: 22),
                    ),
                    const Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text('TZS 1,250,000',
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          SizedBox(height: 2),
                          Text('Maombi Yaliyokamilika',
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
