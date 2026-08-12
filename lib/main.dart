import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'config/themes.dart';
import 'config/routes.dart';
import 'constants/app_colors.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'firebase_options.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Kick off all independent I/O in parallel — Firebase init
    // (network), SharedPreferences bootstrap (disk), and migration
    // reads. Each used to await serially in front of `runApp()`,
    // stacking their latencies; parallelising shaves up to the
    // slowest of these off the cold-start path.
    final storageFuture = StorageService.bootstrap();
    final firebaseFuture = _initFirebase();

    // Local-only init that must complete before the first frame so
    // the user never sees a flash of the wrong theme / language.
    await storageFuture;
    await migrateLegacyThemeSlot();
    await bootstrapThemeNotifier();
    bootstrapLocale();

    // Firebase init can finish in parallel with the above; await it
    // right before runApp() so the auth state is ready by the time
    // the router does its first redirect.
    await firebaseFuture;

    // Notification service init is non-blocking for first frame —
    // permissions and channel registration only matter once a
    // notification actually needs to fire. Fire-and-forget so it
    // doesn't add to critical-path latency.
    final notificationService = NotificationService();
    notificationService.init(); // ignore: discarded_futures

    final container = ProviderContainer(
      overrides: [
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
    );
    bindAuthProviderContainer(container);
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const SamakiFreshApp(),
      ),
    );
  } catch (e) {
    AppLogger.error('Error during app initialization: $e');
    rethrow;
  }
}

/// Initialises Firebase and (optionally) the local emulator suite.
/// Returns when Firebase is ready to issue auth + firestore calls.
Future<void> _initFirebase() async {
  if (Firebase.apps.isNotEmpty) return;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    const useEmulator = bool.fromEnvironment(
      'USE_FIREBASE_EMULATOR',
      defaultValue: false,
    );
    if (useEmulator) {
      final emulatorHost = kIsWeb ||
              defaultTargetPlatform != TargetPlatform.android
          ? 'localhost'
          : '10.0.2.2';
      await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
    }
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      AppLogger.error('Firebase initialization error: $e');
      // App continues in offline/demo mode
    }
  } catch (e) {
    AppLogger.error('Firebase initialization error: $e');
    // App continues in offline/demo mode
  }
}

class SamakiFreshApp extends ConsumerWidget {
  const SamakiFreshApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Riverpod's [themeModeProvider] (StateProvider) re-emits on
    // every theme change — MaterialApp below picks up the new
    // themeMode parameter and re-themes the whole tree.
    final mode = ref.watch(themeModeProvider);
    // Subscribe to the per-user theme bootstrap so the moment the
    // signed-in account changes (sign-in / sign-out / role switch)
    // we re-load that user's saved theme. Without this watch, the
    // [userThemeBootstrapProvider] would never trigger and the
    // theme would leak across accounts on the same device.
    ref.watch(userThemeBootstrapProvider);
    // Riverpod's [localeProvider] (NotifierProvider) re-emits on
    // every language change — MaterialApp's `locale` parameter
    // below picks up the new value so every widget reading
    // `AppLocalizations.of(context)` rebuilds with the new locale
    // immediately, no restart needed.
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Samaki Fresh Connect',
      debugShowCheckedModeBanner: false,
      theme: buildThemeForMode(AppThemeMode.light),
      darkTheme: buildThemeForMode(AppThemeMode.dark),
      themeMode: switch (mode) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      },
      // Localizations wiring — flutter_localizations drives the
      // generated AppLocalizations class. `locale` is the live
      // value out of `localeProvider`, so flipping the language
      // re-translates the whole tree instantly.
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: kSupportedLocales,
      locale: locale,
      localeResolutionCallback: (deviceLocale, supported) {
        if (deviceLocale == null) return locale;
        for (final l in supported) {
          if (l.languageCode == deviceLocale.languageCode) return l;
        }
        return locale;
      },
      // AnimatedTheme lerps colour schemes across rebuilds.
      builder: (context, child) {
        // Physical phones ship with the OS font size cranked up far more
        // often than emulators do. Left unclamped, a 1.5x–2.0x system
        // scale blows every fixed-height card and grid tile past its
        // constraints and the layout renders as overflow stripes. Cap the
        // scale so the design degrades gracefully instead of breaking.
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.20,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      // The router is built inside the Riverpod scope so it can
      // wire `refreshListenable` to the auth-state notifier.
      // `routerProvider` never re-emits, so this instance is
      // stable across theme/locale rebuilds.
      routerConfig: ref.watch(routerProvider),
    );
  }
}
