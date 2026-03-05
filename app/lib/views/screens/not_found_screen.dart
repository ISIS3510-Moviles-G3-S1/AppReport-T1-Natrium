import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_theme.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.muted,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '404',
                style:
                    Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ) ??
                    const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Oops! Page not found',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.mutedForeground,
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Return to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
