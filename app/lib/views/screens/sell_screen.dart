import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/app_theme.dart';
import '../../view_models/sell_view_model.dart';
import '../../data/mock_data.dart';

class SellScreen extends StatelessWidget {
  const SellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SellViewModel>(
        builder: (context, vm, _) {
          if (vm.published) {
            return _PublishSuccess(vm: vm);
          }
          return _SellForm(vm: vm);
        },
      ),
    );
  }
}

class _PublishSuccess extends StatelessWidget {
  final SellViewModel vm;

  const _PublishSuccess({required this.vm});

  @override
  Widget build(BuildContext context) {
    final tip = SellViewModel.randomSustainabilityTip;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 64,
              color: AppTheme.sage,
            ),
            const SizedBox(height: 16),
            Text(
              'Listing Published!',
              style:
                  Theme.of(context).textTheme.headlineSmall ??
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              tip,
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, color: AppTheme.sage),
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
              onPressed: () => vm.resetAfterPublish(),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.deepGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('List Another Item'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SellForm extends StatelessWidget {
  final SellViewModel vm;

  const _SellForm({required this.vm});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
            decoration: const BoxDecoration(
              color: AppTheme.deepGreen,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'List an Item',
                  style:
                      Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                  'Upload a photo - our AI will tag it for you automatically',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Photo',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.foreground,
                  ),
                ),
                const SizedBox(height: 8),
                _PhotoUpload(vm: vm),
                if (vm.aiLoading || vm.aiDone) _AiTaggingBlock(vm: vm),
                const SizedBox(height: 20),
                _TextField(
                  label: 'Title',
                  value: vm.title,
                  onChanged: (v) => vm.title = v,
                  hint: 'e.g. Vintage Denim Jacket',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _TextField(
                        label: 'Price (\$)',
                        value: vm.price,
                        onChanged: (v) => vm.price = v,
                        hint: '0.00',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TextField(
                        label: 'Size',
                        value: vm.size,
                        onChanged: (v) => vm.size = v,
                        hint: 'XS / S / M / L / XL',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _TextField(
                        label: 'Color',
                        value: vm.color,
                        onChanged: (v) => vm.color = v,
                        hint: 'e.g. Blue',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TextField(
                        label: 'Category',
                        value: vm.category,
                        onChanged: (v) => vm.category = v,
                        hint: 'e.g. Jackets',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _TextField(
                  label: 'Description',
                  value: vm.description,
                  onChanged: (v) => vm.description = v,
                  hint: 'Describe the item...',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Condition',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.foreground,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      MockData.conditionsSell.map((c) {
                        final selected = vm.condition == c;
                        return ChoiceChip(
                          label: Text(c),
                          selected: selected,
                          onSelected: (_) => vm.condition = c,
                          selectedColor: AppTheme.deepGreen,
                          labelStyle: TextStyle(
                            color:
                                selected ? Colors.white : AppTheme.foreground,
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Exchange Type',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.foreground,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children:
                      MockData.exchangeTypes.map((e) {
                        final value = e.$1, label = e.$2, desc = e.$3;
                        final selected = vm.exchangeType == value;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => vm.exchangeType = value,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        selected
                                            ? AppTheme.deepGreen
                                            : AppTheme.muted,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            selected
                                                ? AppTheme.deepGreen
                                                : AppTheme.foreground,
                                      ),
                                    ),
                                    Text(
                                      desc,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            selected
                                                ? AppTheme.deepGreen
                                                : AppTheme.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: vm.title.isEmpty ? null : () => vm.publish(),
                  icon: const Icon(Icons.upload_rounded, size: 20),
                  label: const Text('Publish Listing'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.sage,
                    foregroundColor: AppTheme.sageDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoUpload extends StatelessWidget {
  final SellViewModel vm;

  const _PhotoUpload({required this.vm});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = vm.photoPath != null && vm.photoPath!.isNotEmpty;
    return GestureDetector(
      onTap: () async {
        // Simulate pick: use demo URL for now (no file picker dependency)
        vm.setPhotoFromUrl(
          'https://images.unsplash.com/photo-1601333144130-8cbb312386b6?w=400&h=400&fit=crop',
        );
      },
      child: Container(
        height: 200,
        width: double.infinity,
        constraints: const BoxConstraints(minWidth: 320, maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white, // fondo blanco SIEMPRE
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.deepGreen, // borde verde oscuro
            width: 2,
          ),
        ),
        child:
            hasPhoto
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child:
                      vm.photoPath!.startsWith('http')
                          ? CachedNetworkImage(
                            imageUrl: vm.photoPath!,
                            fit: BoxFit.cover,
                          )
                          : Image.file(File(vm.photoPath!), fit: BoxFit.cover),
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_rounded,
                      size: 48,
                      color: AppTheme.foreground, 
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to upload photo',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.foreground,
                      ),
                    ),
                    Text(
                      'JPG, PNG, WEBP up to 10MB',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

class _AiTaggingBlock extends StatelessWidget {
  final SellViewModel vm;

  const _AiTaggingBlock({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.muted),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                vm.aiDone ? Icons.auto_awesome : Icons.auto_awesome,
                color: vm.aiDone ? AppTheme.sage : AppTheme.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                vm.aiLoading
                    ? 'AI is analyzing your photo...'
                    : 'AI tagging complete!',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (vm.aiLoading) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: vm.aiProgress / 100,
              backgroundColor: AppTheme.muted,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
            ),
          ],
          if (vm.aiDone) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (vm.size.isNotEmpty)
                  Chip(
                    label: Text('Size: ${vm.size}'),
                    backgroundColor: AppTheme.cardBg,
                  ),
                if (vm.color.isNotEmpty)
                  Chip(
                    label: Text('Color: ${vm.color}'),
                    backgroundColor: AppTheme.cardBg,
                  ),
                if (vm.category.isNotEmpty)
                  Chip(
                    label: Text('Category: ${vm.category}'),
                    backgroundColor: AppTheme.cardBg,
                  ),
                if (vm.style.isNotEmpty)
                  Chip(
                    label: Text('Style: ${vm.style}'),
                    backgroundColor: AppTheme.cardBg,
                  ),
                Chip(
                  label: Text('Condition: ${vm.condition}'),
                  backgroundColor: AppTheme.cardBg,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TextField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;

  const _TextField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  State<_TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<_TextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _TextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) _controller.text = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.foreground,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: widget.hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
          keyboardType: widget.keyboardType,
          maxLines: widget.maxLines,
        ),
      ],
    );
  }
}
