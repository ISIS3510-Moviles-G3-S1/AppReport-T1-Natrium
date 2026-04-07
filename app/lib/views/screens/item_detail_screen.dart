import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/app_theme.dart';
import '../../core/price_formatter.dart';
import '../../view_models/item_detail_view_model.dart';
import '../../view_models/session_view_model.dart';
import '../../models/item_detail.dart';
import '../../models/seller.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final backTextColor =
        isDark
            ? colorScheme.onSurface.withValues(alpha: 0.78)
            : AppTheme.mutedForeground;
    return Scaffold(
      body: SafeArea(
        child: Consumer<ItemDetailViewModel>(
          builder: (context, vm, _) {
            final item = vm.item;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => context.go('/browse'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.chevron_left_rounded,
                                  size: 20,
                                  color:
                                      isDark
                                          ? colorScheme.onSurface.withAlpha(200)
                                          : AppTheme.mutedForeground,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Back to Browse',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        isDark
                                            ? colorScheme.onSurface.withAlpha(
                                              200,
                                            )
                                            : AppTheme.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                            if (item != null) ...[
                              _Gallery(item: item!, vm: vm),
                              const SizedBox(height: 12),
                              _InfoSection(item: item!, vm: vm),
                            ],
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
    final currentIndex =
        item.images.isEmpty ? 0 : vm.activeImageIndex.clamp(0, item.images.length - 1);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 4 / 5,
            child:
                item.images.isNotEmpty
                    ? PageView.builder(
                      onPageChanged: vm.setActiveImage,
                      controller: PageController(initialPage: currentIndex),
                      itemCount: item.images.length,
                      itemBuilder: (context, index) {
                        return CachedNetworkImage(
                          imageUrl: item.images[index],
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(Icons.image_rounded),
                        );
                      },
                    )
                    : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_rounded, size: 80),
                    ),
          ),
          if (item.images.length > 1)
            Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final selected = index == currentIndex;
                    return GestureDetector(
                      onTap: () => vm.setActiveImage(index),
                      child: Container(
                        width: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? AppTheme.deepGreen
                                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: CachedNetworkImage(
                            imageUrl: item.images[index],
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Icon(Icons.image_rounded, size: 16),
                          ),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: item.images.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final ItemDetail item;
  final ItemDetailViewModel vm;

  const _InfoSection({required this.item, required this.vm});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final bodyTextColor = isDark ? colorScheme.onSurface : AppTheme.foreground;
    final secondaryTextColor =
        isDark
            ? colorScheme.onSurface.withValues(alpha: 0.76)
            : AppTheme.mutedForeground;
    // Chips in this section use a white background, so force dark text for readability.
    final chipTextColor = isDark ? AppTheme.black : AppTheme.foreground;
    final borderColor = isDark ? colorScheme.outline : AppTheme.foreground;
    final cardColor = isDark ? colorScheme.surface : AppTheme.cardBg;
    final currentUserId =
        context.read<SessionViewModel>().currentUser?.uid ?? '';
    final isSeller = currentUserId.isNotEmpty && currentUserId == item.sellerId;
    final canScanAsBuyer =
        currentUserId.isNotEmpty && currentUserId != item.sellerId;
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
            : secondaryTextColor;
    final exchangeLabel = _exchangeLabelFor(item.exchangeType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style:
                    Theme.of(context).textTheme.titleLarge ??
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              onPressed: () => vm.toggleSaved(context),
              icon: Icon(
                vm.saved ? Icons.favorite : Icons.favorite_border_outlined,
                color: vm.saved ? Colors.red : secondaryTextColor,
                size: 22,
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.ios_share_outlined,
                color: secondaryTextColor,
                size: 22,
              ),
            ),
          ],
        ),
        Text(
          PriceFormatter.formatCopFromNum(item.price),
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
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: chipTextColor,
                ),
              ),
              backgroundColor: AppTheme.cardBg,
              side: BorderSide(color: borderColor),
              shape: const StadiumBorder(),
            ),
            Chip(
              label: Text(
                exchangeLabel,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppTheme.sage.withValues(alpha: 0.35),
              side: BorderSide(color: AppTheme.sage.withValues(alpha: 0.6)),
              labelStyle: TextStyle(color: bodyTextColor, fontSize: 12),
              shape: const StadiumBorder(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.bolt_outlined, size: 16, color: secondaryTextColor),
            const SizedBox(width: 6),
            Text(
              'AI-GENERATED TAGS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: secondaryTextColor,
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
            ...item.tags
                .take(3)
                .map(
                  (t) => Chip(
                    label: Text(
                      t,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: chipTextColor,
                      ),
                    ),
                    backgroundColor: AppTheme.cardBg,
                    side: BorderSide(color: borderColor),
                    shape: const StadiumBorder(),
                  ),
                ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? colorScheme.outline : AppTheme.muted,
            ),
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
                          color: bodyTextColor,
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
                backgroundColor:
                    isDark
                        ? colorScheme.surfaceContainerHighest
                        : AppTheme.gray,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.deepGreen,
                ),
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Text(
                'Based on photo analysis of fabric quality, visible wear, and overall condition.',
                style: TextStyle(fontSize: 12, color: bodyTextColor),
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
            color: bodyTextColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.description,
          style: TextStyle(fontSize: 14, height: 1.5, color: bodyTextColor),
        ),
        const SizedBox(height: 16),
        _SellerCard(seller: item.seller),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: vm.messageSent ? null : () => vm.sendMessage(context),
                icon: Icon(
                  vm.messageSent
                      ? Icons.check_circle_outline
                      : Icons.mail_outline,
                  size: 18,
                ),
                label: Text(
                  vm.messageSent ? 'Message Sent!' : 'Message Seller',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: bodyTextColor,
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => vm.toggleSaved(context),
                icon: Icon(
                  vm.saved ? Icons.favorite : Icons.favorite_border_outlined,
                  size: 18,
                ),
                label: Text(vm.saved ? 'Saved' : 'Save Item'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: bodyTextColor,
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isSeller)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed:
                  () => context.push(
                    '/meetup/seller/${item.id}?sellerId=${item.sellerId}',
                  ),
              icon: const Icon(Icons.qr_code_2),
              label: const Text('Generate Meetup QR'),
            ),
          ),
        if (canScanAsBuyer)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.push('/meetup/scan'),
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Scan QR to Confirm Pickup'),
            ),
          ),
      ],
    );
  }
}

String _exchangeLabelFor(String exchangeType) {
  switch (exchangeType.trim().toLowerCase()) {
    case 'free':
    case 'donate':
    case 'free/donate':
    case 'free-donate':
      return 'Free / Donate';
    case 'swap':
      return 'Swap';
    case 'sell':
    default:
      return 'For Sale';
  }
}

class _SellerCard extends StatelessWidget {
  final Seller seller;

  const _SellerCard({required this.seller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    // Seller card is white in both themes, so keep text dark for contrast.
    final bodyTextColor = AppTheme.foreground;
    final secondaryTextColor =
        isDark
            ? AppTheme.black.withValues(alpha: 0.62)
            : AppTheme.mutedForeground;
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
                  style: TextStyle(fontSize: 12, color: secondaryTextColor),
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
                        color: bodyTextColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${seller.sales} items sold',
                      style: TextStyle(fontSize: 12, color: secondaryTextColor),
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
                  onTap: () => context.go('/item/${s['id']}'),
                  child: SizedBox(
                    width: 140,
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: CachedNetworkImage(
                              imageUrl: s['image'],
                              fit: BoxFit.cover,
                              errorWidget:
                                  (context, url, error) =>
                                      const Icon(Icons.image_rounded),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s['name'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  PriceFormatter.formatCopFromNum(
                                    (s['price'] as num?) ?? 0,
                                  ),
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
