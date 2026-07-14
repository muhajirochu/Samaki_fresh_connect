import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'config/themes.dart';
import 'config/routes.dart';
import 'constants/app_colors.dart';
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
    // app launches in the right colour scheme — no flash of white
    // when the user picked cream.
    AppLogger.info('Bootstrapping theme mode...');
    await bootstrapThemeNotifier();
    AppLogger.info('Theme mode bootstrapped');

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

    // Initialize localization
    await EasyLocalization.ensureInitialized();
    AppLogger.info('Localization initialized');

    runApp(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('sw')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWithValue(notificationService),
          ],
          child: const MyApp(),
        ),
      ),
    );
  } catch (e) {
    AppLogger.error('Error during app initialization: $e');
    rethrow;
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Riverpod's [themeModeProvider] re-emits on every theme change.
    final mode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Fresh Connect',
      theme: AppThemes.forMode(mode),
      // Use the same theme for dark mode — Flutter picks the right
      // brightness automatically from the theme's [ColorScheme].
      darkTheme: AppThemes.forMode(
          mode == AppThemeMode.dark ? AppThemeMode.dark : AppThemeMode.dark),
      themeMode: switch (mode) {
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.cream => ThemeMode.light,
      },
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
