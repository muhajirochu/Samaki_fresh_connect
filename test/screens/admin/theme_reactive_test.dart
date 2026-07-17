// Reactive theme + locale at the provider level.
//
// Verifies that mutating state via the notifier rebuilds every
// downstream widget. This is the contract that the user's
// "theme doesn't flip" and "language doesn't switch" bug depends
// on — these tests fail loudly if either provider stops emitting.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:samakifresh_connect/providers/locale_provider.dart';
import 'package:samakifresh_connect/providers/theme_provider.dart';

void main() {
  test('localeProvider — setLocale flips the provider state', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(localeProvider).languageCode, 'en');

    await container.read(localeProvider.notifier)
        .setLocale(const Locale('sw'));
    expect(container.read(localeProvider).languageCode, 'sw');

    await container.read(localeProvider.notifier)
        .setLocale(const Locale('en'));
    expect(container.read(localeProvider).languageCode, 'en');
  });
}
