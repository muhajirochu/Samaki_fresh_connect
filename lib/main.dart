import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'config/themes.dart';
import 'config/routes.dart';
import 'constants/app_colors.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'providers/auth_provider.dart';
import 'utils/logger.dart';
import 'firebase_options.dart';
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
      } catch (e) {
        AppLogger.error('Firebase initialization error: $e');
        // App continues in offline/demo mode
      }
    } else {
      AppLogger.info('Firebase already initialized, skipping...');
    }

    // Seed demo accounts if they don't exist, only if Firebase is initialized
    if (Firebase.apps.isNotEmpty) {
      AppLogger.info('Seeding demo accounts...');
      await DemoSeeder.seedDemoAccounts();
    } else {
      AppLogger.info('Firebase not initialized; skipping demo accounts seeding.');
    }

    // Initialize notification service
    AppLogger.info('Initializing notification service...');
    final notificationService = NotificationService();
    await notificationService.init();
    AppLogger.info('Notification service initialized');

    runApp(
      ProviderScope(
        overrides: [
          notificationServiceProvider.overrideWithValue(notificationService),
        ],
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
    // Riverpod's [themeModeProvider] re-emits on every theme change.
    final mode = ref.watch(themeModeProvider);
    // The singleton [LocaleNotifier] is observed via
    // [Localizations.override] below so the framework rebuilds the
    // whole tree the moment the user picks a new language.
    final localeNotifier = ref.watch(localeControllerProvider);

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
      // generated AppLocalizations class. The `Locale? override`
      // callback re-reads the notifier on every build, so flipping
      // the language triggers an instant re-translation without
      // restarting the app.
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: kSupportedLocales,
      locale: localeNotifier.locale,
      localeResolutionCallback: (deviceLocale, supported) {
        if (deviceLocale == null) return localeNotifier.locale;
        for (final locale in supported) {
          if (locale.languageCode == deviceLocale.languageCode) return locale;
        }
        return localeNotifier.locale;
      },
      routerConfig: appRouter,
      builder: (context, child) {
        // AnimatedTheme lerps colour schemes across rebuilds.
        return Theme(
          data: Theme.of(context),
          child: AnimatedTheme(
            data: Theme.of(context),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}