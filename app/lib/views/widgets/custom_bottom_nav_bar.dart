import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import 'package:go_router/go_router.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    void _handleTap(int index) {
      switch (index) {
        case 0:
          context.go('/');
          break;
        case 1:
          context.go('/browse');
          break;
        case 2:
          context.go('/swap');
          break;
        case 3:
          context.go('/sell');
          break;
        case 4:
          context.go('/profile');
          break;
      }
      onTap(index);
    }
    return BottomAppBar(
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
              currentIndex: currentIndex,
              onTap: () => _handleTap(0),
            ),
            _NavIcon(
              icon: Icons.grid_view_rounded,
              index: 1,
              currentIndex: currentIndex,
              onTap: () => _handleTap(1),
            ),
            const SizedBox(width: 48), // space under the center FAB
            _NavIcon(
              icon: Icons.list_rounded,
              index: 3,
              currentIndex: currentIndex,
              onTap: () => _handleTap(3),
            ),
            _NavIcon(
              icon: Icons.person_rounded,
              index: 4,
              currentIndex: currentIndex,
              onTap: () => _handleTap(4),
            ),
          ],
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
    final Color color = selected ? AppTheme.foreground : AppTheme.mutedForeground;
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: color),
      splashRadius: 24,
    );
  }
}
