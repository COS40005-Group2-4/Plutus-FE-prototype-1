import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/glass_container.dart';
import 'data_widget.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/widget_visibility_provider.dart';

class SidebarMenu extends StatefulWidget {
  final Function(String)? onMenuItemSelected;

  const SidebarMenu({super.key, this.onMenuItemSelected});

  @override
  State<SidebarMenu> createState() => _SidebarMenuState();
}

class _SidebarMenuState extends State<SidebarMenu> {
  final List<MenuItemData> _menuItems = [
    MenuItemData(
      id: 'budget',
      label: 'Budget Tracking',
      icon: Icons.account_balance_wallet,
      color: blue,
    ),
    MenuItemData(
      id: 'history',
      label: 'Transaction History',
      icon: Icons.history,
      color: green,
    ),
    MenuItemData(
      id: 'import',
      label: 'Import Report',
      icon: Icons.upload_file,
      color: yellow,
    ),
    MenuItemData(
      id: 'export',
      label: 'Export Report',
      icon: Icons.download,
      color: red,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<WidgetVisibilityProvider>(
      builder: (context, visibilityProvider, _) {
        return Drawer(
          backgroundColor: Colors.transparent,
          child: GlassContainer(
            borderRadius: 0,
            color: const Color(0xFF2C3E50),
            opacity: 0.6,
            blur: 15,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // User Info or Guest status
                DrawerHeader(
                  decoration: BoxDecoration(color: const Color(0xFF4285F4).withValues(alpha: 0.3)),
                  child: Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            auth.isAuthenticated ? 'Plutus Menu' : 'Plutus (Guest)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            auth.isAuthenticated 
                                ? 'Welcome, ${auth.userName}'
                                : 'Toggle Dashboard Widgets',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dashboard Widgets',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._menuItems.map((item) {
                        final isVisible = visibilityProvider.isWidgetVisible(item.id);
                        return GlassContainer(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          borderRadius: 8,
                          color: isVisible ? item.color : Colors.transparent,
                          opacity: isVisible ? 0.2 : 0,
                          blur: isVisible ? 5 : 0,
                          borderOpacity: isVisible ? 0.2 : 0,
                          child: CheckboxListTile(
                            value: isVisible,
                            onChanged: (value) {
                              if (value == true) {
                                visibilityProvider.showWidget(item.id);
                              } else {
                                visibilityProvider.hideWidget(item.id);
                              }
                            },
                            title: Text(
                              item.label,
                              style: TextStyle(
                                color: isVisible ? item.color : Colors.white,
                                fontWeight: isVisible
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            secondary: Icon(
                              item.icon,
                              color: isVisible ? item.color : Colors.white54,
                            ),
                            activeColor: item.color,
                            checkColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Visible: ${visibilityProvider.visibleWidgetsCount}/${_menuItems.length}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
                const Divider(color: Colors.white24),
                // Theme toggle
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      final isDarkMode = themeProvider.isDarkMode;
                      return SwitchListTile(
                        value: isDarkMode,
                        onChanged: (value) {
                          themeProvider.setThemeMode(
                            value ? ThemeMode.dark : ThemeMode.light,
                          );
                        },
                        title: Text(
                          isDarkMode ? 'Dark Mode' : 'Light Mode',
                          style: const TextStyle(color: Colors.white),
                        ),
                        secondary: Icon(
                          isDarkMode ? Icons.dark_mode : Icons.light_mode,
                          color: Colors.white70,
                        ),
                        activeColor: Colors.blueAccent,
                        inactiveThumbColor: Colors.white70,
                        inactiveTrackColor: Colors.white24,
                      );
                    },
                  ),
                ),
                const Divider(color: Colors.white24),
                // Settings
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.settings, color: Colors.white70),
                    title: const Text(
                      'Settings',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/settings');
                    },
                    hoverColor: Colors.blue.withValues(alpha: 0.2),
                  ),
                ),
                const Divider(color: Colors.white24),
                // Sign Out / Sign In
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return ListTile(
                        leading: Icon(
                          auth.isAuthenticated ? Icons.logout : Icons.login,
                          color: auth.isAuthenticated ? Colors.redAccent : Colors.greenAccent,
                        ),
                        title: Text(
                          auth.isAuthenticated ? 'Sign Out' : 'Sign In',
                          style: TextStyle(
                            color: auth.isAuthenticated ? Colors.redAccent : Colors.greenAccent,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          if (auth.isAuthenticated) {
                            _handleSignOut(context);
                          } else {
                            Navigator.pushNamed(context, '/login');
                          }
                        },
                        hoverColor: auth.isAuthenticated 
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.green.withValues(alpha: 0.1),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class MenuItemData {
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  MenuItemData({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });
}
