import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_theme.dart';
import '../../views/screens/clothing_analysis_screen.dart';
import '../../views/screens/photo_analysis_screen.dart';
import '../../core/photo_quality_analyzer.dart';
import '../../core/photo_quality_vision_service.dart';
import '../../view_models/sell_view_model.dart';

// For AnalysisResult_WithImage type
export 'clothing_analysis_screen.dart' show AnalysisResult_WithImage;

class SellScreen extends StatelessWidget {
  const SellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SellViewModel>(
        builder: (context, vm, _) {
          if (vm.published) return _PublishSuccess(vm: vm);
          return _SellForm(vm: vm);
        },
      ),
    );
  }
}

Widget _buildImagePreview(dynamic image, {double width = 140, double height = 160}) {
  if (image is XFile) {
    return _PickedImagePreview(image: image, width: width, height: height);
  }
  if (image is Uint8List) {
    return Image.memory(image, width: width, height: height, fit: BoxFit.cover);
  }
  if (image is File) {
    return Image.file(image, width: width, height: height, fit: BoxFit.cover);
  }
  if (image is String) {
    return CachedNetworkImage(
      imageUrl: image,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => Container(
        width: width,
        height: height,
        color: Colors.grey.shade300,
        child: const Icon(Icons.broken_image_rounded, size: 40),
      ),
    );
  }
  return Container(
    width: width,
    height: height,
    color: Colors.grey.shade300,
    child: const Icon(Icons.image, size: 40),
  );
}

class _PickedImagePreview extends StatelessWidget {
  final XFile image;
  final double width;
  final double height;

  const _PickedImagePreview({required this.image, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && image.path.isNotEmpty) {
      return Image.file(File(image.path), width: width, height: height, fit: BoxFit.cover);
    }

    return FutureBuilder<Uint8List>(
      future: image.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done || !snapshot.hasData) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey.shade300,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        return Image.memory(snapshot.data!, width: width, height: height, fit: BoxFit.cover);
      },
    );
  }
}

class _PublishSuccess extends StatelessWidget {
  final SellViewModel vm;

  const _PublishSuccess({required this.vm});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mutedText = colorScheme.onSurface.withOpacity(0.72);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, size: 72, color: AppTheme.sage),
            const SizedBox(height: 16),
            Text(
              'Your listing is live!',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Remember to reuse and recycle.',
              style: TextStyle(color: mutedText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => vm.resetAfterPublish(),
              child: const Text('List another item'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final mutedText = isDark ? colorScheme.onSurface.withOpacity(0.72) : AppTheme.mutedForeground;
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
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white) ??
                      const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Upload a photo, then open AI Analyze to generate editable tags.',
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
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                ),
                const SizedBox(height: 8),
                _PhotoUpload(vm: vm),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    final initialImage = vm.images.isNotEmpty ? vm.images.first : null;
                    final result = await Navigator.push<AnalysisResult_WithImage>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClothingAnalysisScreen(initialImage: initialImage),
                      ),
                    );
                    if (result != null) {
                      vm.applyAnalysisTags(result.tags);
                      if (result.analyzedImage != null && (vm.images.isEmpty || vm.images.first.path != result.analyzedImage?.path)) {
                        // Directly add the analyzed image, or add your own prompt here if needed
                        vm.addImage(result.analyzedImage!);
                      }
                    }
                  },
                  icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                  label: const Text('AI Analyze'),
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark ? colorScheme.primary : AppTheme.deepGreen,
                    foregroundColor: isDark ? colorScheme.onPrimary : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                if (vm.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Suggested tags',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: vm.tags.map((tag) => Chip(label: Text(tag))).toList(),
                  ),
                ],
                const SizedBox(height: 20),
                _TextField(
                  label: 'Title',
                  value: vm.title,
                  onChanged: (v) => vm.title = v,
                  hint: 'e.g. Vintage Denim Jacket',
                ),
                const SizedBox(height: 12),
                _TextField(
                  label: 'Price (COP)',
                  value: vm.price,
                  onChanged: (v) => vm.price = v,
                  hint: '0.00',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _TextField(
                  label: 'Tags (comma separated)',
                  value: vm.tagsInput,
                  onChanged: (v) => vm.tagsInput = v,
                  hint: 'e.g. jackets, denim, blue',
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
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const ['New', 'Like New', 'Good', 'Fair', 'Poor'].map((c) {
                    final selected = vm.condition == c;
                    return ChoiceChip(
                      label: Text(c),
                      selected: selected,
                      onSelected: (_) => vm.condition = c,
                      selectedColor: isDark ? colorScheme.primary : AppTheme.deepGreen,
                      labelStyle: TextStyle(
                        color: selected
                            ? (isDark ? colorScheme.onPrimary : Colors.white)
                            : (isDark ? colorScheme.onSurface : AppTheme.foreground),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Exchange Type',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    ('sell', 'Sell', 'Direct sale'),
                    ('swap', 'Swap', 'Exchange with another item'),
                    ('donate', 'Donate', 'Give away for free')
                  ].map((e) {
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
                                color: selected
                                    ? (isDark ? colorScheme.primary : AppTheme.deepGreen)
                                    : (isDark ? colorScheme.outline : AppTheme.muted),
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
                                    color: selected
                                        ? (isDark ? colorScheme.primary : AppTheme.deepGreen)
                                        : (isDark ? colorScheme.onSurface : AppTheme.foreground),
                                  ),
                                ),
                                Text(
                                  desc,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: selected
                                        ? (isDark ? colorScheme.primary : AppTheme.deepGreen)
                                        : mutedText,
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
                    backgroundColor: isDark ? colorScheme.primary : AppTheme.sage,
                    foregroundColor: isDark ? colorScheme.onPrimary : AppTheme.sageDark,
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



  Future<XFile?> _pickImages(BuildContext context) async {
    final picker = ImagePicker();
    final remaining = 5 - vm.images.length;
    if (remaining <= 0) return null;
    final pickedFiles = await picker.pickMultiImage(imageQuality: 85);
    if (pickedFiles == null || pickedFiles.isEmpty) return null;
    final filesToAdd = pickedFiles.take(remaining).toList();
    // If called for retake, return the first picked image
    if (ModalRoute.of(context)?.isCurrent != true) {
      return filesToAdd.first;
    }
    // Otherwise, add all images as usual
    for (final file in filesToAdd) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PhotoAnalysisScreen(
            photo: file,
            sourceType: PhotoSourceType.gallery,
            onRetake: (ctx) async {
              final picked = await _pickImages(ctx);
              if (picked != null) {
                Navigator.of(ctx).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => PhotoAnalysisScreen(
                      photo: picked,
                      sourceType: PhotoSourceType.gallery,
                      onRetake: (ctx2) async {
                        final picked2 = await _pickImages(ctx2);
                        if (picked2 != null) {
                          Navigator.of(ctx2).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => PhotoAnalysisScreen(
                                photo: picked2,
                                sourceType: PhotoSourceType.gallery,
                                onRetake: (ctx3) async {},
                                onKeep: () {
                                  vm.addImage(picked2);
                                  Navigator.of(ctx2).popUntil((route) => route.isFirst || route.settings.name == '/');
                                },
                              ),
                            ),
                          );
                        }
                      },
                      onKeep: () {
                        vm.addImage(picked);
                        Navigator.of(ctx).popUntil((route) => route.isFirst || route.settings.name == '/');
                      },
                    ),
                  ),
                );
              }
            },
            onKeep: () {
              vm.addImage(file);
              Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == '/');
            },
          ),
        ),
      );
      if (vm.images.length >= 5) break;
    }
    return null;
  }

  Future<XFile?> _takePhoto(BuildContext context) async {
    final picker = ImagePicker();
    final remaining = 5 - vm.images.length;
    if (remaining <= 0) return null;
    final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (photo == null) return null;
    // If called for retake, return the photo
    if (ModalRoute.of(context)?.isCurrent != true) {
      return photo;
    }
    // Otherwise, add as usual
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoAnalysisScreen(
          photo: photo,
          sourceType: PhotoSourceType.camera,
          onRetake: (ctx) async {
            final retaken = await _takePhoto(ctx);
            if (retaken != null) {
              Navigator.of(ctx).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => PhotoAnalysisScreen(
                    photo: retaken,
                    sourceType: PhotoSourceType.camera,
                    onRetake: (ctx2) async {
                      final retaken2 = await _takePhoto(ctx2);
                      if (retaken2 != null) {
                        Navigator.of(ctx2).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => PhotoAnalysisScreen(
                              photo: retaken2,
                              sourceType: PhotoSourceType.camera,
                              onRetake: (ctx3) async {},
                              onKeep: () {
                                vm.addImage(retaken2);
                                Navigator.of(ctx2).popUntil((route) => route.isFirst || route.settings.name == '/');
                              },
                            ),
                          ),
                        );
                      }
                    },
                    onKeep: () {
                      vm.addImage(retaken);
                      Navigator.of(ctx).popUntil((route) => route.isFirst || route.settings.name == '/');
                    },
                  ),
                ),
              );
            }
          },
          onKeep: () {
            vm.addImage(photo);
            Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == '/');
          },
        ),
      ),
    );
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mutedText = colorScheme.onSurface.withOpacity(0.72);
    final images = vm.images;
    final tileCount = images.length < 5 ? images.length + 1 : 5;
    const imageSize = 110.0;
    const addTileWidth = 180.0;
    const tileHeight = 120.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: images.length >= 5 ? null : () => _pickImages(context),
                icon: const Icon(Icons.photo_library_rounded),
                label: Text('Gallery  ${images.length}/5'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  // No backgroundColor/foregroundColor: usa los del tema
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: images.length >= 5 ? null : () => _takePhoto(context),
                icon: const Icon(Icons.camera_alt_rounded),
                label: Text('Camera  ${images.length}/5'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  // No backgroundColor/foregroundColor: usa los del tema
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(images.length, (idx) {
            return SizedBox(
              width: imageSize,
              height: tileHeight,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildImagePreview(
                      images[idx],
                      width: imageSize,
                      height: tileHeight,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => vm.removeImageAt(idx),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 20, color: colorScheme.onSurface),
              const SizedBox(width: 8),
              Text(
                'JPG, PNG, WEBP up to 10MB. Máx 5 photos.',
                style: TextStyle(fontSize: 12, color: mutedText),
              ),
            ],
          ),
        ),
      ],
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
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: widget.hint,
            filled: true,
            fillColor: colorScheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          keyboardType: widget.keyboardType,
          maxLines: widget.maxLines,
        ),
      ],
    );
  }
}