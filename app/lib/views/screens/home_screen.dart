import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/app_theme.dart';
import '../../view_models/home_view_model.dart';
import '../../models/listing.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<HomeViewModel>(
        builder: (context, vm, _) {
          final featured = vm.featured;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
                  color: AppTheme.background,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.accent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.eco_rounded,
                              size: 14,
                              color: AppTheme.accent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Sustainable Fashion for Students',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your Campus,\nYour Closet.',
                        textAlign: TextAlign.center,
                        style: (Theme.of(context).textTheme.headlineLarge ??
                                const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ))
                            .copyWith(
                          height: 1.2,
                          color: AppTheme.foreground,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Buy, sell, and swap second-hand clothes with students from your university. AI-powered tagging. Zero effort. Real impact.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.foreground,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => context.go('/browse'),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                            color: AppTheme.foreground,
                          ),
                          label: const Text('Browse Items'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.sage,
                            foregroundColor: AppTheme.foreground,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => context.go('/sell'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.deepGreen,
                            side: BorderSide(
                              color: AppTheme.gray.withValues(alpha: 0.6),
                              width: 1,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: const Text('Start Selling'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context.go('/donate'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.deepGreen,
                                side: BorderSide(
                                  color: AppTheme.gray.withValues(alpha: 0.6),
                                  width: 1,
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: const Text('Donate'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context.go('/swap'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.deepGreen,
                                side: BorderSide(
                                  color: AppTheme.gray.withValues(alpha: 0.6),
                                  width: 1,
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: const Text('Swap'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _FeaturedCard(listings: featured, vm: vm),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        height: 56,
                        width: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/eco_llama.jpeg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi! My name is Eco 🌿',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.foreground,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Welcome to your sustainable fashion journey!',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final List<Listing> listings;
  final HomeViewModel vm;

  const _FeaturedCard({required this.listings, required this.vm});

  @override
  Widget build(BuildContext context) {
    if (listings.isEmpty) return const SizedBox.shrink();
    final item = listings.first;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: item.image,
            height: 280,
            width: 260,
            fit: BoxFit.cover,
            placeholder:
                (_, __) => Container(
                  color: AppTheme.muted,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            errorWidget:
                (_, __, ___) => const Icon(Icons.image_not_supported, size: 48),
          ),
        ),
        Positioned(
          bottom: -12,
          left: -12,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, color: AppTheme.accent, size: 20),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'AI Tagged',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.foreground,
                      ),
                    ),
                    Text(
                      'Size ${item.size} · ${item.style} · ${item.condition}',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: -12,
          right: -12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.sage,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${item.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.sageDark,
                  ),
                ),
                Text(
                  '${item.condition} ✓',
                  style: TextStyle(fontSize: 10, color: AppTheme.sageDark),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
