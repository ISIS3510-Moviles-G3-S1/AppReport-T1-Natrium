import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/app_theme.dart';
import '../../view_models/item_detail_view_model.dart';
import '../../models/item_detail.dart';
import '../../models/seller.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ItemDetailViewModel>(
        builder: (context, vm, _) {
          final item = vm.item;
          if (item == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/browse'),
                      child: Row(
                        children: [
                          Icon(
                            Icons.chevron_left_rounded,
                            size: 18,
                            color: AppTheme.mutedForeground,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Back to Browse',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Image.asset(
                      'assets/images/uni_market_logo.png',
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Gallery(item: item, vm: vm),
                          const SizedBox(height: 12),
                          _InfoSection(item: item, vm: vm),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SimilarSection(vm: vm),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Gallery extends StatelessWidget {
  final ItemDetail item;
  final ItemDetailViewModel vm;

  const _Gallery({required this.item, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
            aspectRatio: 4 / 5,
            child: CachedNetworkImage(
              imageUrl: item.images[vm.activeImageIndex],
              fit: BoxFit.cover,
              placeholder:
                  (_, __) => Container(
                    color: AppTheme.muted,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              errorWidget:
                  (_, __, ___) =>
                      const Icon(Icons.image_not_supported, size: 48),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(item.images.length, (i) {
            final active = vm.activeImageIndex == i;
            return GestureDetector(
              onTap: () => vm.setActiveImage(i),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active ? AppTheme.deepGreen : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: item.images[i],
                    fit: BoxFit.cover,
                    errorWidget:
                        (_, __, ___) => const Icon(Icons.image_rounded),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final ItemDetail item;
  final ItemDetailViewModel vm;

  const _InfoSection({required this.item, required this.vm});

  @override
  Widget build(BuildContext context) {
    final scoreLabel =
        item.aiScore >= 90
            ? 'Excellent'
            : item.aiScore >= 80
            ? 'Good'
            : item.aiScore >= 70
            ? 'Fair'
            : 'Poor';
    final scoreColor =
        item.aiScore >= 90
            ? AppTheme.sage
            : item.aiScore >= 80
            ? AppTheme.warmBeige
            : AppTheme.mutedForeground;
    final exchangeLabel =
        item.exchangeType == 'sell'
            ? 'For Sale'
            : item.exchangeType == 'swap'
            ? 'For Swap'
            : 'Free / Donate';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: Theme.of(context).textTheme.titleLarge ??
                    const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            IconButton(
              onPressed: vm.toggleSaved,
              icon: Icon(
                vm.saved
                    ? Icons.favorite
                    : Icons.favorite_border_outlined,
                color: vm.saved ? Colors.red : AppTheme.mutedForeground,
                size: 22,
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.ios_share_outlined,
                color: AppTheme.mutedForeground,
                size: 22,
              ),
            ),
          ],
        ),
        Text(
          '\$${item.price.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppTheme.sage,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              label: Text(
                item.condition,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppTheme.cardBg,
              side: BorderSide(color: AppTheme.foreground),
              shape: const StadiumBorder(),
            ),
            Chip(
              label: Text(
                exchangeLabel,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppTheme.sage.withValues(alpha: 0.35),
              side: BorderSide(color: AppTheme.sage.withValues(alpha: 0.6)),
              labelStyle: TextStyle(color: AppTheme.foreground, fontSize: 12),
              shape: const StadiumBorder(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.bolt_outlined, size: 16, color: AppTheme.mutedForeground),
            const SizedBox(width: 6),
            Text(
              'AI-GENERATED TAGS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.mutedForeground,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            Chip(
              label: Text(
                'Size ${item.size}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppTheme.cardBg,
              side: BorderSide(color: AppTheme.foreground),
              shape: const StadiumBorder(),
            ),
            Chip(
              label: Text(
                item.color,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppTheme.cardBg,
              side: BorderSide(color: AppTheme.foreground),
              shape: const StadiumBorder(),
            ),
            Chip(
              label: Text(
                item.category,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppTheme.cardBg,
              side: BorderSide(color: AppTheme.foreground),
              shape: const StadiumBorder(),
            ),
            Chip(
              label: Text(
                item.style,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppTheme.cardBg,
              side: BorderSide(color: AppTheme.foreground),
              shape: const StadiumBorder(),
            ),
            ...item.tags
                .take(3)
                .map(
                  (t) => Chip(
                    label: Text(
                      t,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: AppTheme.cardBg,
                    side: BorderSide(color: AppTheme.foreground),
                    shape: const StadiumBorder(),
                  ),
                ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.muted),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        size: 18,
                        color: AppTheme.accent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'AI Quality Score',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.black,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${item.aiScore}% - $scoreLabel',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.sage,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: item.aiScore / 100,
                backgroundColor: AppTheme.gray,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.deepGreen),
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Text(
                'Based on photo analysis of fabric quality, visible wear, and overall condition.',
                style: TextStyle(fontSize: 12, color: AppTheme.foreground),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Description',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.foreground,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.description,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppTheme.foreground,
          ),
        ),
        const SizedBox(height: 16),
        _SellerCard(seller: item.seller),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: vm.messageSent ? null : vm.sendMessage,
                icon: Icon(
                  vm.messageSent ? Icons.check_circle_outline : Icons.mail_outline,
                  size: 18,
                ),
                label: Text(
                  vm.messageSent ? 'Message Sent!' : 'Message Seller',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.foreground,
                  side: BorderSide(color: AppTheme.foreground),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: vm.toggleSaved,
                icon: Icon(
                  vm.saved ? Icons.favorite : Icons.favorite_border_outlined,
                  size: 18,
                ),
                label: Text(vm.saved ? 'Saved' : 'Save Item'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.foreground,
                  side: BorderSide(color: AppTheme.foreground),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SellerCard extends StatelessWidget {
  final Seller seller;

  const _SellerCard({required this.seller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.muted),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(seller.avatar),
            onBackgroundImageError: (_, __) {},
            child: Text(
              seller.name.substring(0, 2).toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.foreground,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      seller.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.foreground,
                      ),
                    ),
                    if (seller.verified) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.accent.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 12,
                              color: AppTheme.accent,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'Verified',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  seller.university,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.mutedForeground,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 14, color: AppTheme.mustard),
                    const SizedBox(width: 2),
                    Text(
                      '${seller.rating}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${seller.sales} items sold',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimilarSection extends StatelessWidget {
  final ItemDetailViewModel vm;

  const _SimilarSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    final similar = vm.similarItems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Similar Items',
          style:
              Theme.of(context).textTheme.titleLarge ??
              const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: similar.length,
            itemBuilder: (context, i) {
              final s = similar[i];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => context.go('/item/${s.id}'),
                  child: SizedBox(
                    width: 140,
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: CachedNetworkImage(
                              imageUrl: s.image,
                              fit: BoxFit.cover,
                              errorWidget:
                                  (_, __, ___) =>
                                      const Icon(Icons.image_rounded),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '\$${s.price.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.sage,
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
              );
            },
          ),
        ),
      ],
    );
  }
}
