import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_notifier.dart';
import 'providers/settings_notifier.dart';
import 'providers/backup_notifier.dart';
import 'providers/budget_notifier.dart';
import 'router/app_router.dart';
import 'services/interfaces/interfaces.dart';
import 'services/journal_initializer.dart';
import 'widgets/glass_background.dart';
import 'di/service_locator.dart';
import 'theme/app_colors.dart';
import 'l10n/app_localizations.dart';

///
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // isOptional: true prevents failure when the file is missing or empty
  // (e.g., in CI/web builds where .env is not committed to git).
  // On web, env vars come from --dart-define at build time instead.
  await dotenv.load(fileName: "app.env", isOptional: true);
  await setupServiceLocator();

  // Temporary: catch all Flutter errors to log stack traces
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('=== FLUTTER ERROR ===');
    debugPrint('${details.exception}');
    debugPrint('${details.stack}');
    FlutterError.presentError(details);
  };

  runApp(const ProviderScope(child: MyApp()));
}

///
class MyApp extends ConsumerStatefulWidget {
  ///
  const MyApp({super.key});

  ///
  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();

    _setupConnectivity();

    // Listen for auth state transitions to perform post-auth service setup.
    ref.listenManual<AuthState>(authNotifierProvider, (AuthState? previous, AuthState next) {
      if (next is AuthAuthenticated) {
        _onAuthenticated(next.user.id);
      }
    });
  }

  void _setupConnectivity() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final bool isConnected =
          results.isNotEmpty && !results.contains(ConnectivityResult.none);
      sl<ISyncManager>().onConnectivityChanged(isConnected);
    });
  }

  Future<void> _onAuthenticated(int userId) async {
    // Set current user on transaction and budget services.
    sl<ITransactionService>().setCurrentUser(userId);
    ref.read(budgetNotifierProvider.notifier).setCurrentUser(userId);

    // Register post-restore callbacks on the backup notifier so that restored
    // data is reflected in the UI immediately.
    final BackupNotifier backupNotifier = ref.read(backupNotifierProvider.notifier);

    backupNotifier.addPostRestoreCallback(() async {
      sl<ITransactionService>().notifyTransactionUpdate();
      await sl<IBillService>().notifyBillUpdate();
      ref.invalidate(budgetNotifierProvider);
    });

    // Initialize backup for the authenticated user.
    await backupNotifier.initialize(userId);

    // Initialize the Go journal before the dashboard loads.
    await sl<JournalInitializer>().initialize();

    // TODO: Consent dialogs (cloud backup conflict resolution, T&C for local
    // users, and data-consent for OAuth users) require a BuildContext with a
    // Navigator to show modal dialogs. These have been removed from here
    // because this listener runs outside the widget tree's Navigator scope.
    // They will be handled by a dedicated splash/consent route in a later task.
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  ///
  @override
  Widget build(BuildContext context) {
    final SettingsState settings = ref.watch(settingsNotifierProvider);
    final GoRouter router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      title: 'Plutus',
      locale: settings.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('vi', ''),
      ],
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.textOnLight,
        ),
        dialogTheme: const DialogThemeData(backgroundColor: AppColors.surfaceLight),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: AppColors.textOnLight),
          displayMedium: TextStyle(color: AppColors.textOnLight),
          displaySmall: TextStyle(color: AppColors.textOnLight),
          headlineLarge: TextStyle(color: AppColors.textOnLight),
          headlineMedium: TextStyle(color: AppColors.textOnLight),
          headlineSmall: TextStyle(color: AppColors.textOnLight),
          titleLarge: TextStyle(color: AppColors.textOnLight),
          titleMedium: TextStyle(color: AppColors.textOnLight),
          titleSmall: TextStyle(color: AppColors.textOnLight),
          bodyLarge: TextStyle(color: AppColors.textOnLight),
          bodyMedium: TextStyle(color: AppColors.textOnLight),
          bodySmall: TextStyle(color: AppColors.textOnLightSecondary),
          labelLarge: TextStyle(color: AppColors.textOnLight),
          labelMedium: TextStyle(color: AppColors.textOnLight),
          labelSmall: TextStyle(color: AppColors.textOnLightSecondary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textOnLight),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.textOnDark,
        ),
        dialogTheme: const DialogThemeData(backgroundColor: AppColors.surfaceDark),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.borderDark,
          brightness: Brightness.dark,
          primary: AppColors.primaryDark,
          secondary: AppColors.accent,
          surface: AppColors.surfaceDark,
        ),
      ),
      themeMode: settings.themeMode,
      builder: (BuildContext context, Widget? child) {
        return GlassBackground(child: child!);
      },
    );
  }
}
