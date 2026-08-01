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
import 'services/demo_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize local storage first (before Firebase) and expose
    // the global [StorageService.instance] so providers (notably the
    // theme controller) can read/write persistent values.
    AppLogger.info('Initializing local storage...');
    await StorageService.bootstrap();
    AppLogger.info('Local storage initialized');

    // Read the persisted theme choice before the first build so the
    // app launches in the right colour scheme — no flash of the
    // wrong theme on cold start.
    AppLogger.info('Bootstrapping theme mode...');
    await migrateLegacyThemeSlot();
    await bootstrapThemeNotifier();
    AppLogger.info('Theme mode bootstrapped');

    // Read the persisted language choice before the first build so
    // the very first frame already renders in the right locale —
    // no flash of English on launch for Kiswahili users.
    AppLogger.info('Bootstrapping locale...');
    bootstrapLocale();
    AppLogger.info('Locale bootstrapped');

    // Initialize Firebase only if not already initialized (prevents duplicate-app error on hot-restart)
    if (Firebase.apps.isEmpty) {
      AppLogger.info('Initializing Firebase...');
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        AppLogger.info('Firebase initialized successfully');

        const useEmulator = bool.fromEnvironment(
          'USE_FIREBASE_EMULATOR',
          defaultValue: false,
        );
        if (useEmulator) {
          final emulatorHost = kIsWeb ||
                  defaultTargetPlatform != TargetPlatform.android
              ? 'localhost'
              : '10.0.2.2';
          AppLogger.info(
            'Connecting Firebase to emulators at $emulatorHost',
          );
          await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
          FirebaseFirestore.instance
              .useFirestoreEmulator(emulatorHost, 8080);
          AppLogger.info('Firebase emulators connected');
        }
      } on FirebaseException catch (e) {
        if (e.code == 'duplicate-app') {
          AppLogger.info(
              'Firebase already initialized; skipping (duplicate-app).');
        } else {
          AppLogger.error('Firebase initialization error: $e');
          // App continues in offline/demo mode
        }
      } catch (e) {
        AppLogger.error('Firebase initialization error: $e');
        // App continues in offline/demo mode
      }
    } else {
      AppLogger.info('Firebase already initialized, skipping...');
    }

    // Firebase emulators are enabled with:
    // flutter run --dart-define=USE_FIREBASE_EMULATOR=true
    // Android emulators reach the host machine through 10.0.2.2.

    // Seed demo accounts if they don't exist, only if Firebase is initialized
    if (Firebase.apps.isNotEmpty) {
      AppLogger.info('Seeding demo accounts...');
      await DemoSeeder.seedDemoAccounts();
    } else {
      AppLogger.info(
          'Firebase not initialized; skipping demo accounts seeding.');
    }

    // Initialize notification service
    AppLogger.info('Initializing notification service...');
    final notificationService = NotificationService();
    await notificationService.init();
    AppLogger.info('Notification service initialized');

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
          child: AnimatedTheme(
            data: Theme.of(context),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            child: child ?? const SizedBox.shrink(),
          ),
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
