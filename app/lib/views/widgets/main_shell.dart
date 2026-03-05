import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_theme.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      backgroundColor: AppTheme.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.sage,
        foregroundColor: AppTheme.sageDark,
        elevation: 0,
        shape: const CircleBorder(),
        onPressed: () => navigationShell.goBranch(2),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 4,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavIcon(
                icon: Icons.home_rounded,
                index: 0,
                currentIndex: navigationShell.currentIndex,
                onTap: () => navigationShell.goBranch(0),
              ),
              _NavIcon(
                icon: Icons.grid_view_rounded,
                index: 1,
                currentIndex: navigationShell.currentIndex,
                onTap: () => navigationShell.goBranch(1),
              ),
              const SizedBox(width: 48), // space under the center FAB
              _NavIcon(
                icon: Icons.list_rounded,
                index: 3,
                currentIndex: navigationShell.currentIndex,
                onTap: () => navigationShell.goBranch(3),
              ),
              _NavIcon(
                icon: Icons.person_rounded,
                index: 3,
                currentIndex: navigationShell.currentIndex,
                onTap: () => navigationShell.goBranch(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool selected = index == currentIndex;
    final Color color =
        selected ? AppTheme.foreground : AppTheme.mutedForeground;
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: color),
      splashRadius: 24,
    );
  }
}
