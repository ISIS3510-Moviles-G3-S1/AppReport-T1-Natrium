import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/app_theme.dart';
import '../../core/price_formatter.dart';
import '../../view_models/profile_view_model.dart';
import '../../view_models/browse_view_model.dart';
import '../../view_models/session_view_model.dart';
import '../../models/profile_models.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const String _selectedAvatarUrl =
      'https://api.dicebear.com/7.x/adventurer/png?seed=Valentina&backgroundColor=f2f2f2';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final mutedText =
        isDark ? colorScheme.onSurface.withValues(alpha: 0.72) : AppTheme.mutedForeground;
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                color: AppTheme.deepGreen,
                child: Text(
                  'Profile',
                  style:
                      Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: colorScheme.onPrimary,
                      ) ??
                      TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Consumer<ProfileViewModel>(
                builder:
                    (context, vm, _) => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        border: Border(
                          bottom: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.60),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.sage, width: 2),
                            ),
                            child: ClipOval(
                              child: Image.network(
                                _selectedAvatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => Container(
                                      color: const Color(0xFFF2F2F2),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.person_rounded,
                                        size: 34,
                                        color: AppTheme.deepGreen,
                                      ),
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vm.profileName,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? colorScheme.onSurface : AppTheme.deepGreen,
                                  ),
                                ),
                                Text(
                                  '${vm.profileUniversity} · Member since ${vm.profileSince}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: mutedText,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 21,
                                      color: Color(0xFF2F2F2F),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${vm.profileRating}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      ' · ${vm.profileTransactions} transactions',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: mutedText,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${vm.xp} XP Points',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
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
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 108,
                      width: 86,
                      child: Image.asset(
                        'assets/images/eco_llama.jpeg',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Eco says:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "You've sold 3 items this month. You're just 220 XP away from Level 5 - Sustainability Star. Keep it up to unlock new badges and rewards!",
                            style: TextStyle(
                              fontSize: 13,
                              color: mutedText,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Consumer<ProfileViewModel>(
                  builder:
                      (context, vm, _) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sustainability Level',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: mutedText,
                                ),
                              ),
                              Text(
                                'Level ${vm.currentLevel.level} – ${vm.currentLevel.name}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              if (vm.nextLevel != null) ...[
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Next up',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: mutedText,
                                        ),
                                      ),
                                      Text(
                                        'Level ${vm.nextLevel!.level} · ${vm.nextLevel!.name}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${vm.nextLevel!.minXp - vm.xp} XP to go',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: mutedText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: vm.levelProgress / 100,
                                minHeight: 10,
                                backgroundColor: colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDark ? colorScheme.primary : AppTheme.deepGreen,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${vm.currentLevel.minXp} XP',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: mutedText,
                                    ),
                                  ),
                                  Text(
                                    '${vm.xp} XP',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    vm.nextLevel?.minXp.toString() ?? 'MAX',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: mutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'Favorites',
                  style: Theme.of(context).textTheme.titleLarge ??
                      const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Consumer<BrowseViewModel>(
                builder: (context, browseVm, _) {
                  final savedListings = browseVm.filteredAndSorted.where((l) => browseVm.isSaved(l.id)).toList();
                  if (savedListings.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('No favorites yet.', style: TextStyle(color: AppTheme.mutedForeground)),
                    );
                  }
                  return SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: savedListings.length,
                      itemBuilder: (context, i) {
                        final item = savedListings[i];
                        return Container(
                          width: 140,
                          margin: const EdgeInsets.only(right: 12),
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => context.go('/item/${item.id}'),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: CachedNetworkImage(
                                      imageUrl: item.imageURLs.isNotEmpty ? item.imageURLs[0] : item.imagePath,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => const Icon(Icons.image_rounded),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          PriceFormatter.formatCopFromNum(item.price),
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.sage),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'Badges & Rewards',
                  style:
                      Theme.of(context).textTheme.titleLarge ??
                      const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: Consumer<ProfileViewModel>(
                builder:
                    (context, vm, _) => SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _BadgeCard(badge: vm.badges[index]),
                        childCount: vm.badges.length,
                      ),
                    ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: isDark ? colorScheme.primary : AppTheme.deepGreen,
                        unselectedLabelColor: mutedText,
                        indicatorColor: isDark ? colorScheme.primary : AppTheme.deepGreen,
                        tabs: const [
                          Tab(text: 'Activity Feed'),
                          Tab(text: 'My Listings'),
                        ],
                      ),
                      SizedBox(
                        height: 400,
                        child: Consumer<ProfileViewModel>(
                          builder:
                              (context, vm, _) => TabBarView(
                                children: [
                                  ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: vm.activityFeed.length,
                                    itemBuilder: (context, i) {
                                      final a = vm.activityFeed[i];
                                      return Card(
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: ListTile(
                                          leading: Text(
                                            a.icon,
                                            style: const TextStyle(
                                              fontSize: 24,
                                            ),
                                          ),
                                          title: Text(
                                            a.text,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          subtitle: Text(
                                            a.time,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: mutedText,
                                            ),
                                          ),
                                          trailing: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.sage.withValues(
                                                alpha: 0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: AppTheme.sage.withValues(
                                                  alpha: 0.3,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              '+${a.xp} XP',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.sageDark,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: vm.listings.length + 1,
                                    itemBuilder: (context, i) {
                                      if (i == vm.listings.length) {
                                        return GestureDetector(
                                          onTap: () => context.go('/sell'),
                                          child: Card(
                                            child: Container(
                                              height: 160,
                                              alignment: Alignment.center,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.add_rounded,
                                                    size: 40,
                                                    color:
                                                        AppTheme
                                                            .mutedForeground,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Add New Listing',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          AppTheme
                                                              .mutedForeground,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      final listing = vm.listings[i];
                                      return Card(
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            SizedBox(
                                              height: 120,
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  if (listing.hasPrimaryImage)
                                                    CachedNetworkImage(
                                                      imageUrl: listing.primaryImageUrl,
                                                      fit: BoxFit.cover,
                                                      errorWidget: (_, __, ___) => const Icon(Icons.image_rounded),
                                                    )
                                                  else
                                                    const Center(child: Icon(Icons.image_rounded)),
                                                  Positioned(
                                                    top: 8,
                                                    left: 8,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            listing.status ==
                                                                    'Active'
                                                                ? AppTheme.sage
                                                                : AppTheme
                                                                    .muted,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        listing.status,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              listing.status ==
                                                                      'Active'
                                                                  ? AppTheme
                                                                      .sageDark
                                                                  : AppTheme
                                                                      .mutedForeground,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    listing.title,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    PriceFormatter.formatCop(listing.price),
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppTheme.accent,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: OutlinedButton.icon(
                                                          onPressed:
                                                              () => context.push(
                                                                '/item/${listing.id}',
                                                              ),
                                                          icon: const Icon(
                                                            Icons.edit_rounded,
                                                            size: 14,
                                                          ),
                                                          label: const Text(
                                                            'Edit',
                                                          ),
                                                          style: OutlinedButton.styleFrom(
                                                            foregroundColor:
                                                                AppTheme
                                                                    .deepGreen,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      IconButton(
                                                        onPressed:
                                                            () => vm
                                                                .deleteListing(
                                                                  listing.id,
                                                                ),
                                                        icon: const Icon(
                                                          Icons
                                                              .delete_outline_rounded,
                                                          color:
                                                              AppTheme
                                                                  .destructive,
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
                                    },
                                  ),
                                ],
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                child: Consumer<SessionViewModel>(
                  builder: (context, session, _) => SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: session.isLoading
                          ? null
                          : () async {
                              await session.signOut();
                            },
                      child: session.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Log out'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final ProfileBadge badge;

  const _BadgeCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final isLocked = !badge.earned;

    return Card(
      elevation: 0,
      color: isLocked
          ? const Color.fromRGBO(214, 221, 219, 0.46)
          : const Color.fromRGBO(214, 221, 219, 0.30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: const Color(0xFFD6DDDB).withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                ColorFiltered(
                  colorFilter: isLocked
                      ? const ColorFilter.mode(
                          Color(0xFFBDBDBD),
                          BlendMode.modulate,
                        )
                      : const ColorFilter.mode(
                          Colors.transparent,
                          BlendMode.dst,
                        ),
                  child: Text(
                    badge.emoji,
                    style: const TextStyle(fontSize: 34),
                  ),
                ),
                if (isLocked)
                  const Positioned(
                    right: -2,
                    bottom: 0,
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 15,
                      color: Color(0xFFB0B0B0),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isLocked ? const Color(0xFF8E8E8E) : AppTheme.foreground,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              badge.desc,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isLocked
                    ? (isDark
                        ? colorScheme.onSurface.withValues(alpha: 0.46)
                        : const Color(0xFF9EB0B3))
                    : (isDark
                        ? colorScheme.onSurface.withValues(alpha: 0.72)
                        : AppTheme.mutedForeground),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isLocked
                    ? (isDark
                        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.9)
                        : const Color(0xFFD6DDDB))
                    : AppTheme.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isLocked
                      ? (isDark
                          ? colorScheme.outline.withValues(alpha: 0.7)
                          : const Color(0xFFD6DDDB))
                      : AppTheme.accent.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '+${badge.xp} XP',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isLocked
                      ? (isDark
                          ? colorScheme.onSurface.withValues(alpha: 0.92)
                          : const Color(0xFF9CB1B5))
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.90)
                          : AppTheme.accent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
