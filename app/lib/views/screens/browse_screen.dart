import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/app_theme.dart';
import '../../view_models/browse_view_model.dart';
import '../../models/listing.dart';
import '../widgets/filter_sheet.dart';

class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              color: AppTheme.background,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Browse',
                        style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(color: AppTheme.deepGreen) ??
                            const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.deepGreen,
                            ),
                      ),
                      Image.asset(
                        'assets/images/uni_market_logo.png',
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Consumer<BrowseViewModel>(
                    builder:
                        (context, vm, _) => Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              size: 22,
                              color: AppTheme.mutedForeground,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                onChanged: (v) => vm.search = v,
                                decoration: InputDecoration(
                                  hintText: 'Search items...',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(999),
                                    borderSide: BorderSide(
                                      color: AppTheme.gray.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => vm.aiSearch = !vm.aiSearch,
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.deepGreen,
                                side: BorderSide(
                                  color: AppTheme.gray.withValues(alpha: 0.8),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              icon: const Icon(Icons.camera_alt_rounded),
                            ),
                            IconButton(
                              onPressed: () => vm.showFilters = true,
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.deepGreen,
                                side: BorderSide(
                                  color: AppTheme.gray.withValues(alpha: 0.8),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              icon: const Icon(Icons.tune_rounded),
                            ),
                          ],
                        ),
                  ),
                  Consumer<BrowseViewModel>(
                    builder: (context, vm, _) {
                      if (!vm.aiSearch) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.accent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Upload a photo to find similar items',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'Upload',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<BrowseViewModel>(
                builder: (context, vm, _) {
                  final items = vm.filteredAndSorted;
                  return Stack(
                    children: [
                      ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          Text(
                            '${items.length} items',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.mutedForeground,
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
                                        color: AppTheme.foreground,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Try different filters',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.72,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                              itemCount: items.length,
                              itemBuilder:
                                  (context, index) => _ListingCard(
                                    listing: items[index],
                                    vm: vm,
                                  ),
                            ),
                        ],
                      ),
                      if (vm.showFilters) FilterSheet(vm: vm),
                    ],
                  );
                },
              ),
            ),
          ],
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
                          color: AppTheme.muted,
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
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        child: Icon(
                          vm.isSaved(listing.id)
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 18,
                          color:
                              vm.isSaved(listing.id)
                                  ? Colors.red
                                  : AppTheme.mutedForeground,
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.foreground),
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
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: AppTheme.mustard,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${listing.rating}',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    listing.seller,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.mutedForeground,
                    ),
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
