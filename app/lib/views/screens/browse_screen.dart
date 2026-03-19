import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/app_theme.dart';
import '../../view_models/browse_view_model.dart';
import '../../models/listing.dart';
import '../widgets/filter_sheet.dart';
import 'for_you_screen.dart';

class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final mutedText =
        isDark ? colorScheme.onSurface.withOpacity(0.72) : AppTheme.mutedForeground;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Consumer<BrowseViewModel>(
          builder: (context, vm, _) {
            final items = vm.filteredAndSorted;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top tab bar
                Container(
                  color: colorScheme.surface,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: colorScheme.primary.withOpacity(0.12),
                            foregroundColor: colorScheme.primary,
                          ),
                          onPressed: () {}, // Already on Browse
                          child: Text('Browse', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: colorScheme.onSurface,
                          ),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ForYouScreen()),
                          ),
                          child: Text('For You', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                // Search bar and filters
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 22,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => vm.search = v,
                          decoration: const InputDecoration(
                            hintText: 'Search items...'
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => vm.showFilters = true,
                        icon: const Icon(Icons.tune_rounded),
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                // Item grid with scrolling
                Expanded(
                  child: Stack(
                    children: [
                      ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          Text(
                            '${items.length} items',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: mutedText,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (items.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 48),
                                child: Column(
                                  children: [
                                    const Text(
                                      '🔍',
                                      style: TextStyle(fontSize: 48),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No items found',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Try different filters',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: mutedText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const ClampingScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.72,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                              itemCount: items.length,
                              itemBuilder: (context, index) =>
                                  _ListingCard(
                                    listing: items[index],
                                    vm: vm,
                                  ),
                            ),
                        ],
                      ),
                      if (vm.showFilters) FilterSheet(vm: vm),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final Listing listing;
  final BrowseViewModel vm;

  const _ListingCard({required this.listing, required this.vm});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final mutedText = isDark ? colorScheme.onSurface.withOpacity(0.70) : AppTheme.mutedForeground;
    return GestureDetector(
      onTap: () => context.push('/item/${listing.id}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: listing.image,
                    fit: BoxFit.cover,
                    placeholder:
                        (_, __) => Container(
                          color: isDark ? colorScheme.surfaceContainerHighest : AppTheme.muted,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    errorWidget:
                        (_, __, ___) =>
                            const Icon(Icons.image_not_supported, size: 40),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => vm.toggleSave(listing.id),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            isDark
                                ? colorScheme.surface.withOpacity(0.92)
                                : Colors.white.withOpacity(0.9),
                        child: Icon(
                          vm.isSaved(listing.id)
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 18,
                          color:
                              vm.isSaved(listing.id)
                                  ? Colors.red
                                  : mutedText,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? colorScheme.surface : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDark ? colorScheme.outline : AppTheme.foreground,
                        ),
                      ),
                      child: Text(
                        listing.condition,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${listing.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.sage,
                        ),
                      ),
                      Text(
                        listing.seller,
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
          ],
        ),
      ),
    );
  }
}
