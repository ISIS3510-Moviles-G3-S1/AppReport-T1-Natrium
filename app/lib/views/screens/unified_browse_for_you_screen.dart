import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_theme.dart';
import '../../view_models/browse_view_model.dart';
import '../widgets/filter_sheet.dart';
import '../../models/listing.dart';

class UnifiedBrowseForYouScreen extends StatefulWidget {
  const UnifiedBrowseForYouScreen({Key? key}) : super(key: key);

  @override
  State<UnifiedBrowseForYouScreen> createState() => _UnifiedBrowseForYouScreenState();
}

class _UnifiedBrowseForYouScreenState extends State<UnifiedBrowseForYouScreen> {
  int selectedTab = 0; // 0 = Browse, 1 = For You

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final mutedText = isDark ? colorScheme.onSurface.withOpacity(0.72) : AppTheme.mutedForeground;
    return Consumer<BrowseViewModel>(
      builder: (context, vm, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: colorScheme.surface,
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => setState(() => selectedTab = 0),
                      child: Text('Browse', style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: selectedTab == 0 ? colorScheme.primary : mutedText)),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => setState(() => selectedTab = 1),
                      child: Text('For You', style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: selectedTab == 1 ? colorScheme.primary : mutedText)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: selectedTab == 0
                ? _BrowseContent(vm: vm, colorScheme: colorScheme, mutedText: mutedText)
                : _ForYouContent(vm: vm, colorScheme: colorScheme, mutedText: mutedText),
            ),
          ],
        );
      },
    );
  }
}

class _BrowseContent extends StatelessWidget {
  final BrowseViewModel vm;
  final ColorScheme colorScheme;
  final Color mutedText;

  const _BrowseContent({required this.vm, required this.colorScheme, required this.mutedText});

  @override
  Widget build(BuildContext context) {
    final items = vm.filteredItems;
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Row(
              children: [
                Icon(Icons.search_rounded, size: 22, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (v) => vm.search = v,
                    decoration: const InputDecoration(hintText: 'Search items...'),
                  ),
                ),
                IconButton(
                  onPressed: () => vm.showFilters = true,
                  icon: const Icon(Icons.tune_rounded),
                  color: colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: Column(
                    children: [
                      const Text('🔍', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 8),
                      Text('No items found', style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                      const SizedBox(height: 4),
                      Text('Try different filters', style: TextStyle(fontSize: 12, color: mutedText)),
                    ],
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) => _ListingCard(
                  listing: items[index],
                  vm: vm,
                  onTap: () => context.push('/item/${items[index].id}'),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
        if (vm.showFilters) FilterSheet(vm: vm),
      ],
    );
  }
}

class _ForYouContent extends StatelessWidget {
  final BrowseViewModel vm;
  final ColorScheme colorScheme;
  final Color mutedText;

  const _ForYouContent({required this.vm, required this.colorScheme, required this.mutedText});

  @override
  Widget build(BuildContext context) {
    final filteredItems = vm.forYouRecommendations.where((item) {
      final searchLower = vm.search.toLowerCase();
      return item.name.toLowerCase().contains(searchLower) ||
          item.category.toLowerCase().contains(searchLower);
    }).toList();
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Row(
              children: [
                Icon(Icons.search_rounded, size: 22, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (v) => vm.search = v,
                    decoration: const InputDecoration(hintText: 'Search personalized items...'),
                  ),
                ),
                IconButton(
                  onPressed: () => vm.showFilters = true,
                  icon: const Icon(Icons.tune_rounded),
                  color: colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (filteredItems.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: Column(
                    children: [
                      const Text('🔍', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 8),
                      Text('No recommendations found', style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                      const SizedBox(height: 4),
                      Text('Try different filters', style: TextStyle(fontSize: 12, color: mutedText)),
                    ],
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) => _ListingCard(
                  listing: filteredItems[index],
                  vm: vm,
                  onTap: () => context.push('/item/${filteredItems[index].id}'),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
        if (vm.showFilters) FilterSheet(vm: vm),
      ],
    );
  }
}

class _ListingCard extends StatelessWidget {
  final Listing listing;
  final BrowseViewModel vm;
  final VoidCallback? onTap;

  const _ListingCard({required this.listing, required this.vm, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final mutedText = isDark ? colorScheme.onSurface.withOpacity(0.70) : AppTheme.mutedForeground;
    return GestureDetector(
      onTap: onTap,
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
                    placeholder: (_, __) => Container(
                      color: isDark ? colorScheme.surfaceContainerHighest : AppTheme.muted,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported, size: 40),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => vm.toggleSave(listing.id),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: isDark ? colorScheme.surface.withOpacity(0.92) : Colors.white.withOpacity(0.9),
                        child: Icon(
                          vm.isSaved(listing.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 18,
                          color: vm.isSaved(listing.id) ? Colors.red : mutedText,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? colorScheme.surface : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isDark ? colorScheme.outline : AppTheme.foreground),
                      ),
                      child: Text(
                        listing.condition,
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500),
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
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ' 24${listing.price.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.sage),
                      ),
                      Text(
                        listing.seller,
                        style: TextStyle(fontSize: 10, color: mutedText),
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
