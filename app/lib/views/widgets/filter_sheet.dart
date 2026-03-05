import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../view_models/browse_view_model.dart';
import '../../data/mock_data.dart';

class FilterSheet extends StatelessWidget {
  final BrowseViewModel vm;

  const FilterSheet({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => vm.showFilters = false,
      child: Container(
        color: Colors.black54,
        child: Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: AppTheme.background,
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
                          color: AppTheme.foreground,
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
                            MockData.categories.map((c) {
                              final selected = vm.category == c;
                              return FilterChip(
                                label: Text(c),
                                selected: selected,
                                onSelected: (_) => vm.category = c,
                                selectedColor: AppTheme.sage,
                                labelStyle: TextStyle(
                                  color:
                                      selected
                                          ? AppTheme.sageDark
                                          : AppTheme.foreground,
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
                            MockData.sizes.map((s) {
                              final selected = vm.size == s;
                              return FilterChip(
                                label: Text(s),
                                selected: selected,
                                onSelected: (_) => vm.size = s,
                                selectedColor: AppTheme.sage,
                                labelStyle: TextStyle(
                                  color:
                                      selected
                                          ? AppTheme.sageDark
                                          : AppTheme.foreground,
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
                            MockData.conditions.map((c) {
                              final selected = vm.condition == c;
                              return FilterChip(
                                label: Text(c),
                                selected: selected,
                                onSelected: (_) => vm.condition = c,
                                selectedColor: AppTheme.sage,
                                labelStyle: TextStyle(
                                  color:
                                      selected
                                          ? AppTheme.sageDark
                                          : AppTheme.foreground,
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
                            MockData.colorFilters.map((c) {
                              final selected = vm.color == c.$1;
                              return GestureDetector(
                                onTap: () => vm.color = c.$1,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Color(c.$2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          selected
                                              ? AppTheme.sage
                                              : Colors.transparent,
                                      width: 2,
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
                        foregroundColor: AppTheme.foreground,
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
              color: AppTheme.mutedForeground,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}
