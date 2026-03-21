import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/app_theme.dart';
import '../../view_models/home_view_model.dart';
import '../../view_models/session_view_model.dart';
import '../../models/listing.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _inactivityDialogShown = false;

  @override
  void initState() {
    super.initState();
    // Check for inactivity when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInactivity();
    });
  }

  Future<void> _checkInactivity() async {
    if (_inactivityDialogShown) return;

    final sessionVM = context.read<SessionViewModel>();
    if (sessionVM.currentUser != null) {
      try {
        final isInactive = await sessionVM.checkInactivity(days: 3);

        if (isInactive && mounted) {
          _showInactivityDialog();
          _inactivityDialogShown = true;
        }
      } catch (e) {
        debugPrint('Error checking inactivity: $e');
      }
    }
  }

  void _showInactivityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¡Te extrañamos! 👀'),
        content: const Text(
          'Han pasado unos días desde tu última visita. '
          '¡Hay nuevos artículos esperándote!'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/browse');
            },
            child: const Text('Ver artículos'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final mutedText =
      isDark ? colorScheme.onSurface.withValues(alpha: 0.72) : AppTheme.mutedForeground;
    final pillBorder =
      isDark ? colorScheme.outline.withValues(alpha: 0.55) : const Color(0xFFD0D6D1);
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
                  color:
                      isDark
                          ? Theme.of(context).scaffoldBackgroundColor
                          : AppTheme.background,
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
                      Align(
                        alignment: Alignment.centerRight,
                        child: Consumer<SessionViewModel>(
                          builder: (context, session, _) => SizedBox(
                            height: 34,
                            child: OutlinedButton.icon(
                              onPressed: session.isLoading
                                  ? null
                                  : () async {
                                      await session.signOut();
                                    },
                              icon: session.isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.logout_rounded, size: 18),
                              label: const Text('Log out', style: TextStyle(fontSize: 13)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.deepGreen,
                                side: BorderSide(color: AppTheme.deepGreen.withOpacity(0.5)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: const Size(88, 34),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Image.asset(
                        'assets/images/uni_market_logo.png',
                        height: 90,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          Text(
                            'Your Campus,',
                            textAlign: TextAlign.center,
                            style: (Theme.of(context).textTheme.headlineLarge ??
                                    const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                    ))
                                .copyWith(
                              height: 1.2,
                              color: AppTheme.deepGreen,
                            ),
                          ),
                          Text(
                            'Your Closet.',
                            textAlign: TextAlign.center,
                            style: (Theme.of(context).textTheme.headlineLarge ??
                                    const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                    ))
                                .copyWith(
                              height: 1.2,
                              color: colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Buy, sell, and swap second-hand clothes with students from your university. AI-powered tagging. Zero effort. Real impact.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? colorScheme.onSurface : AppTheme.foreground,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => context.go('/browse'),
                            icon: const Icon(Icons.arrow_back_rounded, size: 22),
                            label: const Text('Browse Items'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.sage,
                              foregroundColor: AppTheme.foreground,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              elevation: 0,
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => context.go('/sell'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.deepGreen,
                              side: BorderSide(color: pillBorder),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text('Start Selling'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => context.go('/donate'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.deepGreen,
                                  side: BorderSide(color: pillBorder),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.card_giftcard_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Donate'),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => context.go('/swap'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.deepGreen,
                                  side: BorderSide(color: pillBorder),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.compare_arrows_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Swap'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _FeaturedCard(listings: featured, vm: vm),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(26, 10, 26, 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? colorScheme.surface : AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color:
                            isDark
                                ? colorScheme.outline.withValues(alpha: 0.45)
                                : AppTheme.gray.withValues(alpha: 0.55),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              isDark
                                  ? Colors.black.withValues(alpha: 0.12)
                                  : Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/eco_llama.jpeg',
                          height: 58,
                          width: 58,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Hi! My name is Eco',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? colorScheme.onSurface : AppTheme.foreground,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.eco_rounded,
                                    size: 16,
                                    color: AppTheme.sage,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Welcome to your sustainable fashion journey!',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: mutedText,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final mutedText =
        isDark ? colorScheme.onSurface.withValues(alpha: 0.70) : AppTheme.mutedForeground;
    if (listings.isEmpty) return const SizedBox.shrink();
    final item = listings.first;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: item.hasPrimaryImage
              ? CachedNetworkImage(
                  imageUrl: item.primaryImageUrl,
                  height: 280,
                  width: 260,
                  fit: BoxFit.cover,
                  placeholder:
                      (_, __) => Container(
                        color: isDark ? colorScheme.surfaceContainerHighest : AppTheme.muted,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  errorWidget:
                      (_, __, ___) => const Icon(Icons.image_not_supported, size: 48),
                )
              : const Center(child: Icon(Icons.image_not_supported, size: 48)),
        ),
        Positioned(
          bottom: -12,
          left: -12,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surface : AppTheme.cardBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color:
                      isDark
                          ? Colors.black.withValues(alpha: 0.16)
                          : Colors.black26,
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
                        color: isDark ? colorScheme.onSurface : AppTheme.foreground,
                      ),
                    ),
                        Text(
                          item.conditionTag,
                      style: TextStyle(
                        fontSize: 10,
                        color: mutedText,
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
                  color:
                      isDark
                          ? Colors.black.withValues(alpha: 0.16)
                          : Colors.black26,
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
                      '${item.conditionTag} ✓',
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
