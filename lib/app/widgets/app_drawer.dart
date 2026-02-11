import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.currentPath});

  final String currentPath;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const ListTile(
              title: Text(
                'SDD WebChat',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('Menu'),
            ),
            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.chat_bubble_outline,
              label: 'Chat',
              path: '/chat',
              currentPath: currentPath,
            ),
            _DrawerItem(
              icon: Icons.folder_open_outlined,
              label: 'Projects',
              path: '/projects',
              currentPath: currentPath,
            ),
            _DrawerItem(
              icon: Icons.history,
              label: 'History',
              path: '/history',
              currentPath: currentPath,
            ),
            _DrawerItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              path: '/settings',
              currentPath: currentPath,
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.currentPath,
  });

  final IconData icon;
  final String label;
  final String path;
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final selected = currentPath == path;
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: selected,
      onTap: () {
        Navigator.of(context).pop();
        if (!selected) {
          context.go(path);
        }
      },
    );
  }
}
