import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/analysis_result.dart';
import '../../models/clothing_tag.dart';
import '../../view_models/clothing_analysis_view_model.dart';
import '../widgets/loading_analysis_view.dart';

class AnalysisResult_WithImage {
  final Map<String, List<String>> tags;
  final XFile? analyzedImage;

  AnalysisResult_WithImage({required this.tags, required this.analyzedImage});
}

class ClothingAnalysisScreen extends StatelessWidget {
  final XFile? initialImage;

  const ClothingAnalysisScreen({super.key, this.initialImage});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClothingAnalysisViewModel(initialImage: initialImage),
      child: const _ClothingAnalysisView(),
    );
  }
}

class _ClothingAnalysisView extends StatelessWidget {
  const _ClothingAnalysisView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clothing Analysis'),
      ),
      body: Consumer<ClothingAnalysisViewModel>(
        builder: (context, vm, _) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: switch (vm.status) {
              ClothingAnalysisStatus.initial => _InitialState(onTakePhoto: vm.takePhoto, onChooseGallery: vm.chooseFromGallery),
              ClothingAnalysisStatus.loading => const LoadingAnalysisView(),
              ClothingAnalysisStatus.results => _ResultsState(provider: vm),
              ClothingAnalysisStatus.error => _ErrorState(provider: vm),
            },
          );
        },
      ),
    );
  }
}

class _InitialState extends StatelessWidget {
  final VoidCallback onTakePhoto;
  final VoidCallback onChooseGallery;

  const _InitialState({
    required this.onTakePhoto,
    required this.onChooseGallery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - 48),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.checkroom_rounded, size: 72, color: scheme.primary),
                  const SizedBox(height: 20),
                  Text(
                    'Analyze a clothing item',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Take a photo or pick one from your gallery to generate editable tags.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: onTakePhoto,
                    icon: const Icon(Icons.photo_camera_rounded),
                    label: const Text('Take Photo'),
                    style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: onChooseGallery,
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Choose from Gallery'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      foregroundColor: scheme.onSurface,
                      side: BorderSide(color: Colors.grey[400] ?? Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultsState extends StatelessWidget {
  final ClothingAnalysisViewModel provider;

  const _ResultsState({required this.provider});

  @override
  Widget build(BuildContext context) {
    final result = provider.result;
    if (result == null) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final categoryTags = provider.tagsFor(TagCategory.category);
    final colorTags = provider.tagsFor(TagCategory.color);
    final styleTags = provider.tagsFor(TagCategory.style);
    final patternTags = provider.tagsFor(TagCategory.pattern);

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Analysis Complete header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.deepGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: AppTheme.deepGreen, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Analysis Complete',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                        ),
                        const Spacer(),
                        Text(
                          '${result.processingTimeMs}ms',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Item Type section
                  if (categoryTags.isNotEmpty) ...[
                    Text('ITEM TYPE', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: categoryTags
                                  .map(
                                    (tag) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        tag.name,
                                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Confidence',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(result.confidence * 100).round()}%',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Colors section
                  if (colorTags.isNotEmpty) ...[
                    // Section headers
                    Text(
                      'COLORS',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.6,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: colorTags
                          .map(
                            (tag) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ColorChip(
                                tag: tag,
                                onRemove: () => provider.removeTag(tag.id),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Style section
                  if (styleTags.isNotEmpty) ...[
                    Text('STYLE', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: styleTags
                          .map(
                            (tag) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ColorChip(
                                tag: tag,
                                onRemove: () => provider.removeTag(tag.id),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Pattern section
                  if (patternTags.isNotEmpty) ...[
                    Text('PATTERN', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: patternTags
                          .map(
                            (tag) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ColorChip(
                                tag: tag,
                                onRemove: () => provider.removeTag(tag.id),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Info message
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBBDEFB)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_rounded, color: const Color(0xFF1976D2), size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You can edit or remove tags before creating your listing',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.black,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: provider.analyzeAnotherItem,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Analyze Another Item'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.sage,
                      side: const BorderSide(color: AppTheme.sage),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: // Filled button
              FilledButton.icon(
                onPressed: () {
                  final output = AnalysisResult_WithImage(
                    tags: provider.buildListingTags(),
                    analyzedImage: provider.selectedImage,
                  );
                  Navigator.pop<AnalysisResult_WithImage>(context, output);
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Listing'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.sage,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ),
        ],
      ),
    );
  }
}

class _ColorChip extends StatelessWidget {
  final ClothingTag tag;
  final VoidCallback onRemove;

  const _ColorChip({required this.tag, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.chipBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E5DC)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tag.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.black,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(tag.confidence * 100).round()}%',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.secondaryText,
                    ),
              ),
            ],
          ),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppTheme.chipCloseBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final AnalysisResult result;

  const _SummaryCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(result.category, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Confidence ${(result.confidence * 100).round()}% · ${result.processingTimeMs} ms'),
          const SizedBox(height: 6),
          Text('Colors: ${result.colors.join(', ')}'),
          if (result.style != null) Text('Style: ${result.style}'),
          if (result.pattern != null) Text('Pattern: ${result.pattern}'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final ClothingAnalysisViewModel provider;

  const _ErrorState({required this.provider});

  @override
  Widget build(BuildContext context) {
    final error = provider.error;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 72, color: scheme.error),
              const SizedBox(height: 16),
              Text(error?.userMessage ?? 'Something went wrong.', style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                error?.recoverySuggestion ?? 'Please try again with a different image.',
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: provider.retry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: provider.startOver,
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Start Over'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}