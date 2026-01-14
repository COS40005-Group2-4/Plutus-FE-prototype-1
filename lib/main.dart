import 'dart:async';
import 'dart:math';

import 'package:dashboard/dashboard.dart';
import 'storage.dart';

import 'package:flutter/material.dart';

import 'add_dialog.dart';
import 'data_widget.dart';
import 'sidebar_menu.dart';
import 'transaction_history_page.dart';
import 'import_transaction_page.dart';

///
void main() {
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
  ///
  Color getRandomColor() {
    var r = Random();
    return Color.fromRGBO(r.nextInt(256), r.nextInt(256), r.nextInt(256), 1);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dashboard online demo',
      onGenerateInitialRoutes: (r) {
        return r == "/dashboard"
            ? [
                MaterialPageRoute(
                  builder: (c) {
                    return const DashboardWidget();
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
        "/dashboard": (c) => const MainNavigationPage(),
        "/history": (c) => const TransactionHistoryPage(),
        "/import": (c) => const ImportTransactionPage(),
      },
      theme: ThemeData(primarySwatch: Colors.blue),
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
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Plutus", textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Container(
            alignment: Alignment.center,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, "/dashboard");
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 30),
                child: Text("Log in"),
              ),
            ),
          ),
        ],
      ),
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
      return Container(
        decoration: BoxDecoration(
          color: Colors.red.withValues(),
          borderRadius: BorderRadius.circular(10),
        ),
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
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'History',
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
  late var _itemController =
      DashboardItemController<ColoredDashboardItem>.withDelegate(
        itemStorageDelegate: storage,
      );

  bool refreshing = false;

  var storage = MyItemStorage();

  //var dummyItemController =
  //    DashboardItemController<ColoredDashboardItem>(items: []);

  DashboardItemController<ColoredDashboardItem> get itemController =>
      _itemController;

  int? slot;
  String? _selectedWidget;

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

  List<String> d = [];

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
        backgroundColor: const Color(0xFF4285F4),
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
              itemController.clear();
            },
            icon: const Icon(Icons.delete),
          ),
          IconButton(
            onPressed: () {
              add(context);
            },
            icon: const Icon(Icons.add),
          ),
          IconButton(
            onPressed: () {
              itemController.isEditing = !itemController.isEditing;
              setState(() {});
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: SafeArea(
        child: _selectedWidget != null
            ? _buildWidgetPreview(_selectedWidget!)
            : (refreshing
                  ? const Center(child: CircularProgressIndicator())
                  : Dashboard<ColoredDashboardItem>(
                      shrinkToPlace: false,
                      slideToTop: true,
                      absorbPointer: false,
                      slotBackgroundBuilder: SlotBackgroundBuilder.withFunction(
                        (context, item, x, y, editing) {
                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.black12,
                                width: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          );
                        },
                      ),
                      padding: const EdgeInsets.all(8),
                      horizontalSpace: 8,
                      verticalSpace: 8,
                      slotAspectRatio: 1,
                      animateEverytime: true,
                      dashboardItemController: itemController,
                      slotCount: slot!,
                      errorPlaceholder: (e, s) {
                        return Text("$e , $s");
                      },
                      emptyPlaceholder: const Center(child: Text("Empty")),
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
                        paintBackgroundLines: false,
                        autoScroll: true,
                        resizeCursorSide: 15,
                        curve: Curves.easeOut,
                        duration: const Duration(milliseconds: 300),
                        backgroundStyle: const EditModeBackgroundStyle(
                          lineColor: Colors.black38,
                          lineWidth: 0.5,
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
                                Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: item.color,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
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
                                if (itemController.isEditing)
                                  Positioned(
                                    right: 5,
                                    top: 5,
                                    child: InkResponse(
                                      radius: 20,
                                      onTap: () {
                                        itemController.delete(item.identifier);
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
                    )),
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
              Text(
                'Widget Preview: $widgetId',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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

  Future<void> add(BuildContext context) async {
    var res = await showDialog(
      context: context,
      builder: (c) {
        return const AddDialog();
      },
    );

    if (res != null) {
      itemController.add(
        ColoredDashboardItem(
          color: res[6],
          width: res[0],
          height: res[1],
          startX: 0,
          startY: 0,
          identifier: (Random().nextInt(100000) + 4).toString(),
          minWidth: res[2],
          minHeight: res[3],
          maxWidth: res[4] == 0 ? null : res[4],
          maxHeight: res[5] == 0 ? null : res[5],
        ),
        mountToTop: false,
      );
    }
  }
}
