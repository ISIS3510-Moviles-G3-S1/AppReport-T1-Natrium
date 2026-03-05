import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/app_theme.dart';
import '../../view_models/profile_view_model.dart';
import '../../models/profile_models.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                        color: Colors.white,
                      ) ??
                      const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Consumer<ProfileViewModel>(
                builder:
                    (context, vm, _) => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.deepGreen.withValues(alpha: 0.5),
                        border: Border(
                          bottom: BorderSide(color: AppTheme.deepGreen),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppTheme.accent,
                            backgroundImage: NetworkImage(vm.profileAvatar),
                            onBackgroundImageError: (_, __) {},
                            child: Text(
                              vm.profileName.substring(0, 2).toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.sageDark,
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
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '${vm.profileUniversity} · Member since ${vm.profileSince}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      size: 16,
                                      color: AppTheme.mustard,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${vm.profileRating}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      ' · ${vm.profileTransactions} transactions',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${vm.xp} XP Points',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accent,
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 64,
                      width: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
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
                            'Eco says:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.foreground,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "You've sold 3 items this month. You're just 220 XP away from Level 5 - Sustainability Star. Keep it up to unlock new badges and rewards!",
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.mutedForeground,
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
                                  color: AppTheme.mutedForeground,
                                ),
                              ),
                              Text(
                                'Level ${vm.currentLevel.level} – ${vm.currentLevel.name}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.foreground,
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
                                          color: AppTheme.mutedForeground,
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
                                          color: AppTheme.mutedForeground,
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
                                backgroundColor: AppTheme.muted,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.deepGreen,
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
                                      color: AppTheme.mutedForeground,
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
                                      color: AppTheme.mutedForeground,
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
                        labelColor: AppTheme.deepGreen,
                        unselectedLabelColor: AppTheme.mutedForeground,
                        indicatorColor: AppTheme.deepGreen,
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
                                              color: AppTheme.mutedForeground,
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
                                                  CachedNetworkImage(
                                                    imageUrl: listing.image,
                                                    fit: BoxFit.cover,
                                                    errorWidget:
                                                        (
                                                          _,
                                                          __,
                                                          ___,
                                                        ) => const Icon(
                                                          Icons.image_rounded,
                                                        ),
                                                  ),
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
                                                    listing.name,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    '\$${listing.price.toStringAsFixed(0)}',
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              badge.emoji,
              style: TextStyle(
                fontSize: 28,
                color: badge.earned ? null : Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.foreground,
              ),
            ),
            Text(
              badge.desc,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: AppTheme.mutedForeground),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    badge.earned
                        ? AppTheme.accent.withValues(alpha: 0.2)
                        : AppTheme.muted,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      badge.earned
                          ? AppTheme.accent.withValues(alpha: 0.3)
                          : AppTheme.muted,
                ),
              ),
              child: Text(
                '+${badge.xp} XP',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color:
                      badge.earned ? AppTheme.accent : AppTheme.mutedForeground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
