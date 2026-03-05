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
      floatingActionButton: Transform.translate(
        offset: const Offset(0, 40),
        child: Container(
          height: 68,
          width: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.deepGreen.withOpacity(0.25),
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton(
            backgroundColor: AppTheme.sage,
            foregroundColor: AppTheme.sageDark,
            elevation: 0,
            shape: const CircleBorder(),
            onPressed: () => navigationShell.goBranch(2),
            child: const Icon(Icons.add_rounded, size: 36),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 4,
        shape: const CircularNotchedRectangle(),
        notchMargin: 4,
        child: SizedBox(
          height: 56,
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
                icon: Icons.search_rounded,
                index: 1,
                currentIndex: navigationShell.currentIndex,
                onTap: () => navigationShell.goBranch(1),
              ),
              const SizedBox(width: 48), // space under the center FAB
              Transform.translate(
                offset: const Offset(0, 4),
                child: _NavIcon(
                  icon: Icons.list_rounded,
                  index: 3,
                  currentIndex: navigationShell.currentIndex,
                  onTap: () => navigationShell.goBranch(3),
                ),
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
        selected ? AppTheme.sage : AppTheme.deepGreen;
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: color),
      splashRadius: 24,
    );
  }
}
