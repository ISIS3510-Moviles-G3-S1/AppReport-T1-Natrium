import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class SwapScreen extends StatefulWidget {
  const SwapScreen({super.key});

  @override
  State<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> {
  String _tab = 'browse';
  String? _photoPreview;
  bool _aiLoading = false;
  bool _aiDone = false;
  double _aiProgress = 0;
  bool _posted = false;
  int? _proposedId;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sizeController = TextEditingController();
  final _colorController = TextEditingController();
  final _categoryController = TextEditingController();
  final _wantDescController = TextEditingController();
  final _wantSizeController = TextEditingController();
  final _wantCategoryController = TextEditingController();
  String _condition = 'Good';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _sizeController.dispose();
    _colorController.dispose();
    _categoryController.dispose();
    _wantDescController.dispose();
    _wantSizeController.dispose();
    _wantCategoryController.dispose();
    super.dispose();
  }

  void _runAiTagging() {
    setState(() {
      _aiLoading = true;
      _aiDone = false;
      _aiProgress = 0;
    });
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 60));
      if (!_aiLoading) return false;
      setState(() {
        _aiProgress = (_aiProgress + 4).clamp(0, 100);
      });
      if (_aiProgress >= 100) {
        setState(() {
          _aiLoading = false;
          _aiDone = true;
          _titleController.text =
              _titleController.text.isEmpty ? 'Puffer Winter Jacket' : _titleController.text;
          _sizeController.text = 'L';
          _colorController.text = 'Black';
          _categoryController.text = 'Outerwear';
          _condition = 'Good';
        });
        return false;
      }
      return true;
    });
  }

  String get _ecoTip => _ecoTips[_posted ? 0 : (_ecoTips.length - 1)];

  @override
  Widget build(BuildContext context) {
    if (_posted) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.sage.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.swap_horiz_rounded,
                    size: 40,
                    color: AppTheme.sageDark,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Swap Listed!',
                  style: Theme.of(context).textTheme.headlineSmall ??
                      const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _ecoTip,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.mutedForeground),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.sage.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.sage.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, color: AppTheme.sage, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '+50 XP earned with Eco!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.foreground,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _posted = false;
                      _photoPreview = null;
                      _aiDone = false;
                      _aiLoading = false;
                      _titleController.clear();
                      _descriptionController.clear();
                      _sizeController.clear();
                      _colorController.clear();
                      _categoryController.clear();
                      _wantDescController.clear();
                      _wantSizeController.clear();
                      _wantCategoryController.clear();
                      _condition = 'Good';
                      _tab = 'browse';
                    });
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.sage,
                    foregroundColor: AppTheme.sageDark,
                  ),
                  child: const Text('Browse Swap Partners'),
                ),
              ],
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Transform.translate(
          offset: const Offset(0, 16),
          child: Container(
            height: 68,
            width: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.deepGreen.withOpacity(0.25),
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton(
              backgroundColor: AppTheme.sage,
              foregroundColor: AppTheme.sageDark,
              elevation: 0,
              shape: const CircleBorder(),
              onPressed: () => Navigator.of(context).pushNamed('/sell'),
              child: const Icon(Icons.add_rounded, size: 36),
            ),
          ),
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: 3,
          onTap: (_) {},
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.muted.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _SegmentButton(
                        label: 'Browse Swaps',
                        selected: _tab == 'browse',
                        onTap: () => setState(() => _tab = 'browse'),
                      ),
                    ),
                    Expanded(
                      child: _SegmentButton(
                        label: 'Post a Swap',
                        selected: _tab == 'post',
                        onTap: () => setState(() => _tab = 'post'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _tab == 'browse'
                  ? _BrowseTab(
                      proposedId: _proposedId,
                      onPropose: (id) => setState(() => _proposedId = id),
                    )
                  : _PostTab(
                      photoPreview: _photoPreview,
                      onPhotoDemo: () {
                        setState(() {
                          _photoPreview =
                              'https://images.unsplash.com/photo-1548126032-079a0fb0099d?w=400&h=400&fit=crop';
                        });
                        _runAiTagging();
                      },
                      onClearPhoto: () {
                        setState(() {
                          _photoPreview = null;
                          _aiDone = false;
                          _aiLoading = false;
                          _aiProgress = 0;
                        });
                      },
                      aiLoading: _aiLoading,
                      aiDone: _aiDone,
                      aiProgress: _aiProgress,
                      titleController: _titleController,
                      descriptionController: _descriptionController,
                      sizeController: _sizeController,
                      colorController: _colorController,
                      categoryController: _categoryController,
                      wantDescController: _wantDescController,
                      wantSizeController: _wantSizeController,
                      wantCategoryController: _wantCategoryController,
                      condition: _condition,
                      onConditionChanged: (c) => setState(() => _condition = c),
                      onPost: () {
                        if (_titleController.text.isEmpty) return;
                        setState(() => _posted = true);
                      },
                    )
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Transform.translate(
        offset: const Offset(0, 16),
        child: Container(
          height: 68,
          width: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.deepGreen.withOpacity(0.25),
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton(
            backgroundColor: AppTheme.sage,
            foregroundColor: AppTheme.sageDark,
            elevation: 0,
            shape: const CircleBorder(),
            onPressed: () => context.go('/sell'),
            child: const Icon(Icons.add_rounded, size: 36),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 3,
        onTap: (_) {},
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppTheme.deepGreen : AppTheme.mutedForeground,
          ),
        ),
      ),
    );
  }
}

class _BrowseTab extends StatelessWidget {
  final int? proposedId;
  final ValueChanged<int> onPropose;

  const _BrowseTab({
    required this.proposedId,
    required this.onPropose,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _swapListings.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${_swapListings.length} students looking to swap near you',
              style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground),
            ),
          );
        }
        final listing = _swapListings[index - 1];
        final isProposed = proposedId == listing.id;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 180,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      listing.offeringImage,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Wrap(
                        spacing: 4,
                        children: listing.tags
                            .map(
                              (t) => Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  t,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          listing.offeringCondition,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundImage: NetworkImage(listing.avatar),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          listing.seller,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppTheme.accent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            '⭐ ${listing.xp} XP',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      listing.offering,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.foreground,
                      ),
                    ),
                    Text(
                      'Size ${listing.offeringSize}',
                      style:
                          TextStyle(fontSize: 11, color: AppTheme.mutedForeground),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.muted.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.swap_horiz_rounded,
                            size: 18,
                            color: AppTheme.mutedForeground,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Wants in return',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.mutedForeground,
                                  ),
                                ),
                                Text(
                                  listing.wanting,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.foreground,
                                  ),
                                ),
                                Text(
                                  'Size: ${listing.wantingSize}',
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
                    const SizedBox(height: 8),
                    if (isProposed)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 18, color: AppTheme.sage),
                          const SizedBox(width: 6),
                          Text(
                            'Swap proposed! Waiting for reply…',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.sageDark,
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => onPropose(listing.id),
                          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                          label: const Text('Propose Swap'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.sage,
                            foregroundColor: AppTheme.sageDark,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PostTab extends StatelessWidget {
  final String? photoPreview;
  final VoidCallback onPhotoDemo;
  final VoidCallback onClearPhoto;
  final bool aiLoading;
  final bool aiDone;
  final double aiProgress;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController sizeController;
  final TextEditingController colorController;
  final TextEditingController categoryController;
  final TextEditingController wantDescController;
  final TextEditingController wantSizeController;
  final TextEditingController wantCategoryController;
  final String condition;
  final ValueChanged<String> onConditionChanged;
  final VoidCallback onPost;

  const _PostTab({
    required this.photoPreview,
    required this.onPhotoDemo,
    required this.onClearPhoto,
    required this.aiLoading,
    required this.aiDone,
    required this.aiProgress,
    required this.titleController,
    required this.descriptionController,
    required this.sizeController,
    required this.colorController,
    required this.categoryController,
    required this.wantDescController,
    required this.wantSizeController,
    required this.wantCategoryController,
    required this.condition,
    required this.onConditionChanged,
    required this.onPost,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        Text(
          "What you're offering",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.foreground,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Photo',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.foreground,
          ),
        ),
        const SizedBox(height: 6),
        if (photoPreview != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    photoPreview!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.black.withValues(alpha: 0.6),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close_rounded,
                        size: 16, color: Colors.white),
                    onPressed: onClearPhoto,
                  ),
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              GestureDetector(
                onTap: onPhotoDemo,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.muted,
                      style: BorderStyle.solid,
                      width: 2,
                    ),
                    color: AppTheme.muted.withValues(alpha: 0.3),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.deepGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: AppTheme.deepGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Take or select a photo',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.foreground,
                            ),
                          ),
                          Text(
                            'Camera · Photo Library',
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
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onPhotoDemo,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.accent.withValues(alpha: 0.4),
                    ),
                    color: AppTheme.accent.withValues(alpha: 0.1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: AppTheme.foreground,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Try AI Demo',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.foreground,
                            ),
                          ),
                          Text(
                            'Use a sample photo to see AI tagging',
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
              ),
            ],
          ),
        if (aiLoading || aiDone) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.muted),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 18,
                      color: aiDone ? AppTheme.sage : AppTheme.accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      aiLoading
                          ? 'AI is analyzing your photo...'
                          : 'AI tagging complete!',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (aiLoading) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: aiProgress / 100,
                    backgroundColor: AppTheme.muted,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                  ),
                ],
                if (aiDone) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (sizeController.text.isNotEmpty)
                        _tagChip('Size: ${sizeController.text}'),
                      if (colorController.text.isNotEmpty)
                        _tagChip('Color: ${colorController.text}'),
                      if (categoryController.text.isNotEmpty)
                        _tagChip('Category: ${categoryController.text}'),
                      _tagChip('Condition: $condition'),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        _labeledTextField(
          label: 'Item Title',
          controller: titleController,
          hint: 'e.g. Puffer Winter Jacket',
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _labeledTextField(
                label: 'Size',
                controller: sizeController,
                hint: 'XS / S / M / L / XL',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _labeledTextField(
                label: 'Category',
                controller: categoryController,
                hint: 'e.g. Outerwear',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _labeledTextField(
          label: 'Description',
          controller: descriptionController,
          hint: 'Brand, material, any wear to note...',
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        Text(
          'Condition',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.foreground,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _conditions.map((c) {
            final selected = c == condition;
            return ChoiceChip(
              label: Text(c),
              selected: selected,
              onSelected: (_) => onConditionChanged(c),
              selectedColor: AppTheme.deepGreen,
              labelStyle: TextStyle(
                color: selected ? Colors.white : AppTheme.foreground,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Divider(color: AppTheme.muted),
        const SizedBox(height: 16),
        Text(
          'What you want in return',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.foreground,
          ),
        ),
        const SizedBox(height: 10),
        _labeledTextField(
          label: "Describe what you're looking for",
          controller: wantDescController,
          hint: 'e.g. Any cozy sweater or hoodie in good condition',
          maxLines: 3,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _labeledTextField(
                label: 'Preferred Size',
                controller: wantSizeController,
                hint: 'e.g. S–M',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _labeledTextField(
                label: 'Category',
                controller: wantCategoryController,
                hint: 'e.g. Knitwear',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.sage.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.sage.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.eco_rounded, size: 18, color: AppTheme.sageDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Eco Impact: Every swap saves an estimated 7 kg of CO₂ versus buying new, '
                  'and earns you +50 XP.',
                  style: TextStyle(fontSize: 12, color: AppTheme.foreground),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: titleController.text.isEmpty ? null : onPost,
            icon: const Icon(Icons.swap_horiz_rounded, size: 20),
            label: const Text('Post Swap'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.sage,
              foregroundColor: AppTheme.sageDark,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _labeledTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.foreground,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
          ),
        ),
      ],
    );
  }

  Widget _tagChip(String text) {
    return Chip(
      label: Text(text),
      backgroundColor: AppTheme.cardBg,
      side: BorderSide(color: AppTheme.foreground),
    );
  }
}

class _SwapListing {
  final int id;
  final String seller;
  final String avatar;
  final String offering;
  final String offeringImage;
  final String offeringSize;
  final String offeringCondition;
  final String wanting;
  final String wantingSize;
  final List<String> tags;
  final int xp;

  const _SwapListing({
    required this.id,
    required this.seller,
    required this.avatar,
    required this.offering,
    required this.offeringImage,
    required this.offeringSize,
    required this.offeringCondition,
    required this.wanting,
    required this.wantingSize,
    required this.tags,
    required this.xp,
  });
}

const _swapListings = [
  _SwapListing(
    id: 1,
    seller: 'Sofia R.',
    avatar:
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=80&h=80&fit=crop&crop=face',
    offering: "Vintage Levi's Jacket",
    offeringImage:
        'https://images.unsplash.com/photo-1601333144130-8cbb312386b6?w=300&h=300&fit=crop',
    offeringSize: 'M',
    offeringCondition: 'Good',
    wanting: 'Any cozy sweater or hoodie',
    wantingSize: 'S–M',
    tags: ['Casual', 'Denim'],
    xp: 120,
  ),
  _SwapListing(
    id: 2,
    seller: 'Maria G.',
    avatar:
        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=80&h=80&fit=crop&crop=face',
    offering: 'Floral Summer Dress',
    offeringImage:
        'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=300&h=300&fit=crop',
    offeringSize: 'S',
    offeringCondition: 'Like New',
    wanting: 'Trousers or jeans, any colour',
    wantingSize: 'S',
    tags: ['Feminine', 'Summer'],
    xp: 95,
  ),
  _SwapListing(
    id: 3,
    seller: 'Emma T.',
    avatar:
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=80&h=80&fit=crop&crop=face',
    offering: 'Cream Knit Sweater',
    offeringImage:
        'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=300&h=300&fit=crop',
    offeringSize: 'L',
    offeringCondition: 'Good',
    wanting: 'Jacket or coat for autumn',
    wantingSize: 'M–L',
    tags: ['Cosy', 'Knitwear'],
    xp: 80,
  ),
  _SwapListing(
    id: 4,
    seller: 'Ana L.',
    avatar:
        'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=80&h=80&fit=crop&crop=face',
    offering: 'Ripped Denim Pants',
    offeringImage:
        'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=300&h=300&fit=crop',
    offeringSize: 'M',
    offeringCondition: 'Fair',
    wanting: 'Casual dress or skirt',
    wantingSize: 'S–M',
    tags: ['Smart Casual', 'Basics'],
    xp: 60,
  ),
];

const _conditions = ['Like New', 'Good', 'Fair'];

const _ecoTips = [
  'Every swap saves ~7 kg of CO₂ compared to buying new.',
  'Swapping keeps clothes in circulation longer — real circular fashion!',
  'You just matched with a swap partner and earned 50 XP!',
];

