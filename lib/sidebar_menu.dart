import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data_widget.dart';
import 'providers/auth_provider.dart';

class SidebarMenu extends StatefulWidget {
  final Function(String)? onMenuItemSelected;

  const SidebarMenu({super.key, this.onMenuItemSelected});

  @override
  State<SidebarMenu> createState() => _SidebarMenuState();
}

class _SidebarMenuState extends State<SidebarMenu> {
  String? _selectedMenuItem;

  final List<MenuItemData> _menuItems = [
    MenuItemData(id: 'welcome', label: 'Welcome', icon: Icons.home, color: red),
    MenuItemData(
      id: 'description',
      label: 'Description',
      icon: Icons.description,
      color: yellow,
    ),
    MenuItemData(
      id: 'transform',
      label: 'Transform',
      icon: Icons.transform,
      color: red,
    ),
    MenuItemData(id: 'add', label: 'Add', icon: Icons.add, color: blue),
    MenuItemData(
      id: 'delete',
      label: 'Delete',
      icon: Icons.delete,
      color: green,
    ),
    MenuItemData(
      id: 'refresh',
      label: 'Refresh',
      icon: Icons.refresh,
      color: yellow,
    ),
    MenuItemData(id: 'info', label: 'Info', icon: Icons.info, color: blue),
    MenuItemData(
      id: 'github',
      label: 'GitHub',
      icon: Icons.code,
      color: Colors.white,
    ),
    MenuItemData(
      id: 'twitter',
      label: 'Twitter',
      icon: Icons.share,
      color: const Color(0xFF1DA0F1),
    ),
    MenuItemData(
      id: 'linkedin',
      label: 'LinkedIn',
      icon: Icons.people,
      color: const Color(0xFF0A66C2),
    ),
    MenuItemData(
      id: 'pub',
      label: 'Pub.dev',
      icon: Icons.public,
      color: Colors.white,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFF2C3E50),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF4285F4)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Dashboard Widgets',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            ..._menuItems.map((item) {
              final isSelected = _selectedMenuItem == item.id;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isSelected
                      ? item.color.withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
                child: ListTile(
                  leading: Icon(
                    item.icon,
                    color: isSelected ? item.color : Colors.white70,
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected ? item.color : Colors.white,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedMenuItem = item.id;
                    });
                    widget.onMenuItemSelected?.call(item.id);
                    Navigator.pop(context);
                  },
                  hoverColor: item.color.withValues(alpha: 0.2),
                ),
              );
            }).toList(),
            const Divider(color: Colors.white24),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Widgets: ${_menuItems.length}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
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
                hoverColor: Colors.blue.withOpacity(0.2),
              ),
            ),
            // Sign Out
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleSignOut(context);
                },
                hoverColor: Colors.red.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
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
