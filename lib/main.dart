import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dashboard/dashboard.dart';
import 'storage.dart';
import 'package:provider/provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data_widget.dart';
import 'sidebar_menu.dart';
import 'transaction_history_page.dart';
import 'import_transaction_page.dart';
import 'providers/auth_provider.dart';
import 'providers/backup_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/widget_visibility_provider.dart';
import 'screens/login_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/user_selection_screen.dart';
import 'screens/investment_list_screen.dart';
import 'screens/backup_history_screen.dart';
import 'services/sync_manager.dart';
import 'transaction_service.dart';
import 'l10n/app_localizations.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'widgets/conflict_dialog.dart';
import 'widgets/backup_found_dialog.dart';
import 'models/backup_models.dart';
import 'widgets/glass_background.dart';
import 'widgets/glass_container.dart';

///
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

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
  Color getRandomColor() {
    var r = Random();
    return Color.fromRGBO(r.nextInt(256), r.nextInt(256), r.nextInt(256), 1);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _backupProvider),
        ChangeNotifierProvider(create: (_) => WidgetVisibilityProvider()),
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
                foregroundColor: Colors.white,
              ),
              dialogBackgroundColor: Colors.transparent,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF4285F4),
                brightness: Brightness.light,
              ),
            ),
            darkTheme: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: Colors.transparent,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
                foregroundColor: Colors.white,
              ),
              dialogBackgroundColor: Colors.transparent,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF2A5470),
                brightness: Brightness.dark,
                primary: const Color(0xFF4A90E2),
                secondary: const Color(0xFF5DADE2),
                surface: const Color(0xFF1A3A4A),
                background: const Color(0xFF0A1828),
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

  Future<void> _initBackupAndNavigate(BuildContext context, int userId) async {
    if (_backupInitialized) return;
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

class MySlotBackground extends SlotBackgroundBuilder<ColoredDashboardItem> {
  @override
  Widget? buildBackground(
    BuildContext context,
    ColoredDashboardItem? item,
    int x,
    int y,
    bool editing,
  ) {
    if (item != null) {
      return GlassContainer(
        color: Colors.red,
        opacity: 0.2,
        borderRadius: 10,
      );
    }

    return null;
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;
  final GlobalKey<TransactionHistoryPageState> _historyKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const DashboardWidget(),
          TransactionHistoryPage(key: _historyKey),
        ],
      ),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1A3A4A).withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.15),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF2A5470).withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      icon: Icons.dashboard,
                      label: AppLocalizations.of(context).dashboard,
                      isSelected: _currentIndex == 0,
                      onTap: () => setState(() => _currentIndex = 0),
                    ),
                    _buildFab(),
                    _buildNavItem(
                      icon: Icons.history,
                      label: AppLocalizations.of(context).history,
                      isSelected: _currentIndex == 1,
                      onTap: () => setState(() => _currentIndex = 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF4A90E2) : Colors.white54,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF4A90E2) : Colors.white54,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFab() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ImportTransactionPage(),
          ),
        );
        if (result == true) {
          _historyKey.currentState?.refresh();
          TransactionService().notifyTransactionUpdate();
        }
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF5DADE2)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A90E2).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

class DashboardWidget extends StatefulWidget {
  ///
  const DashboardWidget({super.key});

  ///
  @override
  State<DashboardWidget> createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget> {
  ///
  final ScrollController scrollController = ScrollController();

  ///
  late DashboardItemController<ColoredDashboardItem> _itemController;

  bool refreshing = false;

  late MyItemStorage storage;

  DashboardItemController<ColoredDashboardItem> get itemController =>
      _itemController;

  int? slot;
  String? _selectedWidget;

  List<String> _lastVisibilityKey = [];

  @override
  void initState() {
    super.initState();
    storage = MyItemStorage();
    _itemController = DashboardItemController<ColoredDashboardItem>.withDelegate(
      itemStorageDelegate: storage,
    );
  }

  setSlot() {
    var w = MediaQuery.of(context).size.width;
    setState(() {
      slot = w > 600
          ? w > 900
                ? 6
                : 4
          : 2;
    });
  }

  void _updateHiddenItems(List<String> visibleWidgets) async {
    // Show loading state
    setState(() {
      refreshing = true;
    });
    
    // Create new storage with updated filter
    storage = MyItemStorage();
    storage.setVisibilityFilter(visibleWidgets);
    
    // Create new controller with new storage
    _itemController = DashboardItemController.withDelegate(
      itemStorageDelegate: storage,
    );
    
    // Wait for controller to initialize
    await Future.delayed(const Duration(milliseconds: 200));
    
    if (mounted) {
      setState(() {
        refreshing = false;
      });
    }
  }

  double _getAspectRatio(double width) {
    if (width < 600) return 0.85; // mobile: taller slots
    if (width < 900) return 0.95;
    return 1.0;
  }

  ///
  @override
  Widget build(BuildContext context) {
    var w = MediaQuery.of(context).size.width;
    slot = w > 600
        ? w > 900
              ? 6
              : 4
        : 2;
    final aspectRatio = _getAspectRatio(w);
    return Scaffold(
      drawer: SidebarMenu(
        onMenuItemSelected: (widgetId) {
          setState(() {
            _selectedWidget = widgetId;
          });
        },
      ),
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A3A4A).withValues(alpha: 0.3)
            : const Color(0xFF4285F4).withValues(alpha: 0.2),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        automaticallyImplyLeading: true,
        title: Text(
          'PLUTUS',
          style: TextStyle(
            fontWeight: FontWeight.w300,
            letterSpacing: 2.0,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF5DADE2)
                : Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await storage.clear();
              setState(() {
                refreshing = true;
              });
              storage = MyItemStorage();
              _itemController = DashboardItemController.withDelegate(
                itemStorageDelegate: storage,
              );
              Future.delayed(const Duration(milliseconds: 150)).then((value) {
                setState(() {
                  refreshing = false;
                });
              });
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () {
              _itemController.isEditing = !_itemController.isEditing;
              setState(() {});
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<WidgetVisibilityProvider>(
          builder: (context, visibilityProvider, _) {
            final visibleWidgets = visibilityProvider.getVisibleWidgets();
            final visibilityKey = visibleWidgets.join(',');
            
            // Detect visibility changes and update
            final oldKey = _lastVisibilityKey.isNotEmpty ? _lastVisibilityKey.first : '';
            if (oldKey != visibilityKey) {
              _lastVisibilityKey = [visibilityKey];
              
              // Only trigger update if key actually changed and not first load
              if (oldKey.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _updateHiddenItems(visibleWidgets);
                });
              }
            }
            
            return _selectedWidget != null
                ? _buildWidgetPreview(_selectedWidget!)
                : (refreshing
                      ? const Center(child: CircularProgressIndicator())
                      : Dashboard<ColoredDashboardItem>(
                          key: ValueKey(visibleWidgets.join(',')),
                          shrinkToPlace: true,
                          slideToTop: true,
                          absorbPointer: false,
                          slotBackgroundBuilder: SlotBackgroundBuilder.withFunction(
                            (context, item, x, y, editing) {
                              return const GlassContainer(
                                borderRadius: 10,
                                borderOpacity: 0.1,
                                opacity: 0.05,
                              );
                            },
                          ),
                          padding: const EdgeInsets.all(8),
                          horizontalSpace: 8,
                          verticalSpace: 8,
                          slotAspectRatio: aspectRatio,
                          animateEverytime: true,
                          dashboardItemController: itemController,
                          slotCount: slot ?? 2,
                          errorPlaceholder: (e, s) {
                            return Text("$e , $s");
                          },
                          emptyPlaceholder: Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                const Icon(Icons.dashboard_customize,
                                    size: 48, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(context).noWidgetsSelected,
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppLocalizations.of(context).openMenuEnableWidgets,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                              ),
                            ),
                          ),
                          itemStyle: ItemStyle(
                            color: Colors.transparent,
                            clipBehavior: Clip.antiAliasWithSaveLayer,
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          physics: const RangeMaintainingScrollPhysics(),
                          editModeSettings: EditModeSettings(
                            draggableOutside: false,
                            paintBackgroundLines: true,
                            autoScroll: true,
                            resizeCursorSide: 15,
                            curve: Curves.easeOut,
                            duration: const Duration(milliseconds: 150),
                            backgroundStyle: const EditModeBackgroundStyle(
                              lineColor: Colors.white24,
                              lineWidth: 1,
                              dualLineHorizontal: false,
                              dualLineVertical: false,
                            ),
                          ),
                          itemBuilder: (ColoredDashboardItem item) {
                            var layout = item.layoutData;

                            if (item.data != null) {
                              return DataWidget(item: item);
                            }

                            return LayoutBuilder(
                              builder: (_, c) {
                                return Stack(
                                  children: [
                                    GlassContainer(
                                      padding: const EdgeInsets.all(10),
                                      color: item.color,
                                      opacity: 0.3,
                                      borderRadius: 10,
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: double.infinity,
                                        child: Text(
                                          "ID: ${item.identifier}\n${["x: ${layout.startX}", "y: ${layout.startY}", "w: ${layout.width}", "h: ${layout.height}"].join("\n")}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_itemController.isEditing)
                                      Positioned(
                                        right: 5,
                                        top: 5,
                                        child: InkResponse(
                                          radius: 20,
                                          onTap: () {
                                            _itemController.delete(item.identifier);
                                          },
                                          child: const Icon(
                                            Icons.clear,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            );
                          },
                        ));
          },
        ),
      ),
    );
  }

  Widget _buildWidgetPreview(String widgetId) {
    // Create a dummy ColoredDashboardItem for preview
    final dummyItem = ColoredDashboardItem(
      color: Colors.blue,
      width: 2,
      height: 2,
      startX: 0,
      startY: 0,
      identifier: 'preview',
      data: widgetId,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Widget Preview: $widgetId',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectedWidget = null;
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DataWidget(item: dummyItem),
          ),
        ),
      ],
    );
  }

}
