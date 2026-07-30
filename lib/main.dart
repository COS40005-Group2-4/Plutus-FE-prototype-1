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
import 'providers/profile_notifier.dart';
import 'providers/insights_notifier.dart';
import 'providers/dashboard_data_provider.dart';
import 'router/app_router.dart';
import 'services/interfaces/interfaces.dart';
import 'services/journal_initializer.dart';
import 'widgets/animated_theme_scope.dart';
import 'widgets/core/app_canvas.dart';
import 'di/service_locator.dart';
import 'theme/app_theme.dart';
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
      // Notify service streams so StreamBuilder-based widgets refresh
      sl<ITransactionService>().notifyTransactionUpdate();
      await sl<IBillService>().notifyBillUpdate();

      // Invalidate all Riverpod providers so they re-fetch from restored DB
      ref.invalidate(budgetNotifierProvider);
      ref.invalidate(profileNotifierProvider);
      ref.invalidate(insightsNotifierProvider);
      ref.invalidate(dashboardDataProvider);

      // Explicitly reload profile for the current user after invalidation
      final authState = ref.read(authNotifierProvider);
      if (authState is AuthAuthenticated) {
        await ref.read(profileNotifierProvider.notifier).loadProfile(authState.user.id);
      }
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
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      // Disable MaterialApp's built-in AnimatedTheme so AnimatedThemeScope
      // owns the tween — otherwise the two animations stack and interfere.
      themeAnimationDuration: Duration.zero,
      builder: (BuildContext context, Widget? child) {
        return AnimatedThemeScope(
          child: AppCanvas(child: child!),
        );
      },
    );
  }
}
