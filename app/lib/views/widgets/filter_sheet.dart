import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../view_models/browse_view_model.dart';

class FilterSheet extends StatelessWidget {
  final BrowseViewModel vm;

  const FilterSheet({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final sectionText =
        isDark ? colorScheme.onSurface.withValues(alpha: 0.78) : AppTheme.mutedForeground;
    final chipBg = isDark ? colorScheme.surfaceContainerHigh : null;
    final chipBorderColor =
        isDark ? colorScheme.outline.withValues(alpha: 0.60) : null;
    return GestureDetector(
      onTap: () => vm.showFilters = false,
      child: Container(
        color: Colors.black.withValues(alpha: isDark ? 0.68 : 0.54),
        child: Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: isDark ? colorScheme.surface : AppTheme.background,
            child: SizedBox(
              width: 280,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? colorScheme.onSurface : AppTheme.foreground,
                        ),
                      ),
                      IconButton(
                        onPressed: () => vm.showFilters = false,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    title: 'Type',
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            const [
                              'Jackets', 'Tops', 'Bottoms', 'Shoes', 'Accessories', 'Other'
                            ].map((c) {
                              final selected = vm.category == c;
                              return FilterChip(
                                label: Text(c),
                                selected: selected,
                                onSelected: (_) => vm.category = c,
                                selectedColor: AppTheme.sage,
                                backgroundColor: chipBg,
                                side:
                                    chipBorderColor == null
                                        ? null
                                        : BorderSide(color: chipBorderColor),
                                labelStyle: TextStyle(
                                  color:
                                      selected
                                          ? AppTheme.sageDark
                                          : (isDark
                                              ? colorScheme.onSurface
                                              : AppTheme.foreground),
                                  fontSize: 12,
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                  _Section(
                    title: 'Size',
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            const [
                              'XS', 'S', 'M', 'L', 'XL', 'XXL'
                            ].map((s) {
                              final selected = vm.size == s;
                              return FilterChip(
                                label: Text(s),
                                selected: selected,
                                onSelected: (_) => vm.size = s,
                                selectedColor: AppTheme.sage,
                                backgroundColor: chipBg,
                                side:
                                    chipBorderColor == null
                                        ? null
                                        : BorderSide(color: chipBorderColor),
                                labelStyle: TextStyle(
                                  color:
                                      selected
                                          ? AppTheme.sageDark
                                          : (isDark
                                              ? colorScheme.onSurface
                                              : AppTheme.foreground),
                                  fontSize: 12,
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                  _Section(
                    title: 'Condition',
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            const [
                              'New', 'Like New', 'Good', 'Fair', 'Poor'
                            ].map((c) {
                              final selected = vm.condition == c;
                              return FilterChip(
                                label: Text(c),
                                selected: selected,
                                onSelected: (_) => vm.condition = c,
                                selectedColor: AppTheme.sage,
                                backgroundColor: chipBg,
                                side:
                                    chipBorderColor == null
                                        ? null
                                        : BorderSide(color: chipBorderColor),
                                labelStyle: TextStyle(
                                  color:
                                      selected
                                          ? AppTheme.sageDark
                                          : (isDark
                                              ? colorScheme.onSurface
                                              : AppTheme.foreground),
                                  fontSize: 12,
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                  _Section(
                    title: 'Color',
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            const [
                              ('Blue', 'Blue'), ('Black', 'Black'), ('White', 'White'), ('Red', 'Red'), ('Green', 'Green'), ('Yellow', 'Yellow'), ('Pink', 'Pink'), ('Purple', 'Purple'), ('Brown', 'Brown'), ('Gray', 'Gray'), ('Other', 'Other')
                            ].map((c) {
                              final selected = vm.color == c.$1;
                              return GestureDetector(
                                onTap: () => vm.color = c.$1,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: selected ? AppTheme.sage : chipBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: chipBorderColor == null ? null : Border.all(color: chipBorderColor),
                                  ),
                                  child: Text(
                                    c.$2,
                                    style: TextStyle(
                                      color: selected ? AppTheme.sageDark : (isDark ? colorScheme.onSurface : AppTheme.foreground),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                  if (vm.hasFilters)
                    TextButton.icon(
                      onPressed: vm.clearFilters,
                      icon: const Icon(Icons.close_rounded, size: 14),
                      label: const Text('Clear filters'),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => vm.showFilters = false,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor:
                            isDark ? colorScheme.onSurface : AppTheme.foreground,
                      ),
                      child: const Text('Apply Filters'),
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

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color:
                  isDark
                      ? colorScheme.onSurface.withValues(alpha: 0.78)
                      : AppTheme.mutedForeground,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}
