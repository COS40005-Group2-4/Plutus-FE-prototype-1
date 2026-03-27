import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'transaction_history_page.dart';
import 'import_transaction_page.dart';
import 'providers/auth_provider.dart';
import 'providers/backup_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/dashboard_provider.dart';
import 'screens/login_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/user_selection_screen.dart';
import 'screens/investment_list_screen.dart';
import 'screens/backup_history_screen.dart';
import 'screens/main_navigation_page.dart';
import 'services/sync_manager.dart';
import 'transaction_service.dart';
import 'l10n/app_localizations.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'widgets/conflict_dialog.dart';
import 'widgets/backup_found_dialog.dart';
import 'models/backup_models.dart';
import 'widgets/glass_background.dart';
import 'di/service_locator.dart';
import 'theme/app_colors.dart';

///
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await setupServiceLocator();

  ///
  runApp(const MyApp());
}

///
class MyApp extends StatefulWidget {
  ///
  const MyApp({super.key});

  ///
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AuthProvider _authProvider;
  late BackupProvider _backupProvider;
  late SyncManager _syncManager;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _syncManager = SyncManager();
    _backupProvider = BackupProvider(syncManager: _syncManager);
    _authProvider = AuthProvider();
    _initializeAuth();
    _setupConnectivity();
  }

  Future<void> _initializeAuth() async {
    await _authProvider.initialize();
    setState(() {});
  }

  void _setupConnectivity() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final isConnected =
          results.isNotEmpty && !results.contains(ConnectivityResult.none);
      _syncManager.onConnectivityChanged(isConnected);
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  ///
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _backupProvider),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Plutus',
            onGenerateInitialRoutes: (r) {
              return r == "/dashboard"
                  ? [
                      MaterialPageRoute(
                        builder: (c) {
                          return const MainNavigationPage();
                        },
                      ),
                    ]
                  : [
                      MaterialPageRoute(
                        builder: (c) {
                          return const MainPage();
                        },
                      ),
                    ];
            },
            initialRoute: "/",
            routes: {
              "/": (c) => const MainPage(),
              "/user_selection": (c) => const UserSelectionScreen(),
              "/login": (c) => const LoginScreen(),
              "/dashboard": (c) => const MainNavigationPage(),
              "/history": (c) => const TransactionHistoryPage(),
              "/import": (c) => const ImportTransactionPage(),
              "/settings": (c) => const SettingsScreen(),
              "/investments": (c) => const InvestmentListScreen(),
              "/backup-history": (c) => const BackupHistoryScreen(),
            },
            locale: settingsProvider.locale,
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
              dialogBackgroundColor: Colors.transparent,
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
              dialogBackgroundColor: Colors.transparent,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.borderDark,
                brightness: Brightness.dark,
                primary: AppColors.primaryDark,
                secondary: AppColors.accent,
                surface: AppColors.surfaceDark,
              ),
            ),
            themeMode: settingsProvider.themeMode,
            builder: (context, child) {
              return GlassBackground(child: child!);
            },
          );
        },
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool _backupInitialized = false;
  bool _consentChecked = false;

  Future<void> _initBackupAndNavigate(BuildContext context, int userId) async {
    if (_backupInitialized) return;

    // Check data consent for OAuth users
    if (!_consentChecked) {
      _consentChecked = true;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // If user has OAuth but hasn't consented, show consent dialog
      if (authProvider.currentUser?.hasOAuth == true &&
          authProvider.currentUser?.dataConsent != true) {
        // Store context before async call
        final scaffoldContext = context;
        final consented = await authProvider.checkDataConsent(scaffoldContext);
        if (!consented) {
          // User declined - they are now in guest mode, continue to dashboard
          if (!mounted) return;
        }
      }
    }

    _backupInitialized = true;

    final backupProvider =
        Provider.of<BackupProvider>(context, listen: false);
    await backupProvider.initialize(userId);

    if (!mounted) return;

    if (backupProvider.hasConflict) {
      if (!backupProvider.isBackupEnabled && backupProvider.hasRemoteBackup) {
        // New device: backup not enabled but remote data exists
        final restore = await showBackupFoundDialog(context);
        if (restore == true) {
          await backupProvider.resolveConflict(ConflictChoice.overrideLocal);
          await backupProvider.setBackupEnabled(true);
        }
      } else {
        // Existing device: backup enabled, data differs
        final choice = await showConflictDialog(context);
        if (choice != null) {
          await backupProvider.resolveConflict(choice);
        }
      }
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, "/dashboard");
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (!authProvider.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              if (authProvider.currentUser != null) {
                // User is logged in, set up transaction service and go to dashboard
                final transactionService = TransactionService();
                transactionService.setCurrentUser(authProvider.currentUserId!);
                _initBackupAndNavigate(context, authProvider.currentUserId!);
              } else {
                // No user logged in, show user selection screen
                Navigator.pushReplacementNamed(context, "/user_selection");
              }
            }
          });
        }
        
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

// MainNavigationPage and DashboardWidget have been extracted to:
// - lib/screens/main_navigation_page.dart
// - lib/screens/dashboard_screen.dart
