import 'dart:async';
import 'dart:math';
import 'dart:ui';

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
import 'providers/settings_provider.dart';
import 'providers/widget_visibility_provider.dart';
import 'screens/login_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/user_selection_screen.dart';
import 'transaction_service.dart';
import 'l10n/app_localizations.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
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

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await _authProvider.initialize();
    setState(() {});
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
              ),
              dialogBackgroundColor: Colors.transparent,
            ),
            darkTheme: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: Colors.transparent,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              dialogBackgroundColor: Colors.transparent,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
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
                Navigator.pushReplacementNamed(context, "/dashboard");
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
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: IndexedStack(
          index: _currentIndex,
          children: [
            const DashboardWidget(),
            TransactionHistoryPage(key: _historyKey),
          ],
        ),
      ),
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          BottomNavigationBar(
            currentIndex: _currentIndex == 2 ? 0 : _currentIndex,
            onTap: (index) {
              if (index == 1) {
                setState(() => _currentIndex = 1);
              } else {
                setState(() => _currentIndex = 0);
              }
            },
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.dashboard),
                label: AppLocalizations.of(context).dashboard,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.history),
                label: AppLocalizations.of(context).history,
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            child: Material(
              elevation: 8,
              shape: const CircleBorder(),
              child: GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ImportTransactionPage(),
                    ),
                  );
                  if (result == true) {
                    _historyKey.currentState?.refresh();
                    // Notify transaction service to emit update to all listeners
                    TransactionService().notifyTransactionUpdate();
                  }
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ],
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
          : 3;
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

  ///
  @override
  Widget build(BuildContext context) {
    var w = MediaQuery.of(context).size.width;
    slot = w > 600
        ? w > 900
              ? 6
              : 4
        : 3;
    return Scaffold(
      drawer: SidebarMenu(
        onMenuItemSelected: (widgetId) {
          setState(() {
            _selectedWidget = widgetId;
          });
        },
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4285F4).withValues(alpha: 0.2),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        automaticallyImplyLeading: true,
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
                          slotAspectRatio: 1,
                          animateEverytime: true,
                          dashboardItemController: itemController,
                          slotCount: slot ?? 3,
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
                                          "ID: ${item.identifier}\n${["x: ${layout.startX}", "y: ${layout.startY}", "w: ${layout.width}", "h: ${layout.height}", if (layout.minWidth != 1) "minW: ${layout.minWidth}", if (layout.minHeight != 1) "minH: ${layout.minHeight}", if (layout.maxWidth != null) "maxW: ${layout.maxWidth}", if (layout.maxHeight != null) "maxH : ${layout.maxHeight}"].join("\n")}",
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
      minWidth: 1,
      minHeight: 1,
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
