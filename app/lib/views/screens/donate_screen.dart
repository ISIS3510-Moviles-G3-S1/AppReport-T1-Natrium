import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key});

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  String? _photoPreview;
  bool _aiLoading = false;
  bool _aiDone = false;
  double _aiProgress = 0;
  bool _donated = false;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sizeController = TextEditingController();
  final _categoryController = TextEditingController();
  String _condition = 'Good';
  String _recipient = 'anyone';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _sizeController.dispose();
    _categoryController.dispose();
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
              _titleController.text.isEmpty ? 'Knit Cardigan' : _titleController.text;
          _sizeController.text = 'S';
          _categoryController.text = 'Knitwear';
          _condition = 'Good';
        });
        return false;
      }
      return true;
    });
  }

  String get _ecoTip => _ecoTips[_donated ? 0 : (_ecoTips.length - 1)];

  @override
  Widget build(BuildContext context) {
    if (_donated) {
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
                    Icons.favorite_rounded,
                    size: 40,
                    color: AppTheme.sageDark,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Item Donated!',
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
                        '+75 XP earned with Eco!',
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
                      _donated = false;
                      _photoPreview = null;
                      _aiDone = false;
                      _aiLoading = false;
                      _aiProgress = 0;
                      _titleController.clear();
                      _descriptionController.clear();
                      _sizeController.clear();
                      _categoryController.clear();
                      _condition = 'Good';
                      _recipient = 'anyone';
                    });
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.sage,
                    foregroundColor: AppTheme.sageDark,
                  ),
                  child: const Text('Donate Another Item'),
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
          currentIndex: 2,
          onTap: (_) {},
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              color: AppTheme.deepGreen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.eco_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Zero Waste',
                          style: const TextStyle(fontSize: 11, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Donate an Item',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                        ) ??
                        const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Give clothes a second life — for free',
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  Text(
                    'Photo',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.foreground,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (_photoPreview != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Image.network(
                              _photoPreview!,
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
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _photoPreview = null;
                                  _aiDone = false;
                                  _aiLoading = false;
                                  _aiProgress = 0;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _photoPreview =
                                  'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=400&h=400&fit=crop';
                            });
                            _runAiTagging();
                          },
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
                          onTap: () {
                            setState(() {
                              _photoPreview =
                                  'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=400&h=400&fit=crop';
                            });
                            _runAiTagging();
                          },
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
                  if (_aiLoading || _aiDone) ...[
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
                                color: _aiDone ? AppTheme.sage : AppTheme.accent,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _aiLoading
                                    ? 'AI is analyzing your photo...'
                                    : 'AI tagging complete!',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (_aiLoading) ...[
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: _aiProgress / 100,
                              backgroundColor: AppTheme.muted,
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                            ),
                          ],
                          if (_aiDone) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                if (_sizeController.text.isNotEmpty)
                                  _tagChip('Size: ${_sizeController.text}'),
                                if (_categoryController.text.isNotEmpty)
                                  _tagChip('Category: ${_categoryController.text}'),
                                _tagChip('Condition: $_condition'),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _labeledTextField(
                    label: 'Title',
                    controller: _titleController,
                    hint: 'e.g. Cream Knit Cardigan',
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _labeledTextField(
                          label: 'Size',
                          controller: _sizeController,
                          hint: 'XS / S / M / L / XL',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _labeledTextField(
                          label: 'Category',
                          controller: _categoryController,
                          hint: 'e.g. Knitwear',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _labeledTextField(
                    label: 'Description',
                    controller: _descriptionController,
                    hint: 'Any brand, material, or details worth sharing...',
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
                      final selected = c == _condition;
                      return ChoiceChip(
                        label: Text(c),
                        selected: selected,
                        onSelected: (_) => setState(() => _condition = c),
                        selectedColor: AppTheme.deepGreen,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppTheme.foreground,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Who should receive it?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.foreground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: _recipients.map((r) {
                      final selected = r.value == _recipient;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => setState(() => _recipient = r.value),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? AppTheme.deepGreen
                                    : AppTheme.muted,
                              ),
                              color: selected
                                  ? AppTheme.deepGreen.withValues(alpha: 0.05)
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  r.icon,
                                  style: const TextStyle(fontSize: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.label,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.foreground,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        r.desc,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: selected
                                              ? AppTheme.deepGreen
                                              : AppTheme.mutedForeground,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
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
                        const Icon(Icons.eco_rounded,
                            size: 18, color: AppTheme.sageDark),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Eco Impact: Donating this item saves an estimated 4 kg of textile waste and earns you +75 XP.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.foreground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed:
                          _titleController.text.isEmpty ? null : () => setState(() => _donated = true),
                      icon: const Icon(Icons.favorite_rounded, size: 20),
                      label: const Text('Donate Item'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.sage,
                        foregroundColor: AppTheme.sageDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
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
        currentIndex: 2,
        onTap: (_) {},
      ),
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

class _RecipientOption {
  final String value;
  final String label;
  final String desc;
  final String icon;

  const _RecipientOption({
    required this.value,
    required this.label,
    required this.desc,
    required this.icon,
  });
}

const _conditions = ['Like New', 'Good', 'Fair'];

const _recipients = [
  _RecipientOption(
    value: 'anyone',
    label: 'Anyone on Campus',
    desc: 'First come, first served',
    icon: '👋',
  ),
  _RecipientOption(
    value: 'bank',
    label: 'Clothing Bank',
    desc: 'Donated to campus charity',
    icon: '🏦',
  ),
  _RecipientOption(
    value: 'student',
    label: 'Student in Need',
    desc: 'Matched to a verified request',
    icon: '🤝',
  ),
];

const _ecoTips = [
  "You're giving this item a second life — that's real impact!",
  'Donating saves ~4kg of textile waste per item.',
  'Every donation earns you Eco XP and keeps clothes out of landfills.',
  'Your generosity helps fellow students dress sustainably.',
];

