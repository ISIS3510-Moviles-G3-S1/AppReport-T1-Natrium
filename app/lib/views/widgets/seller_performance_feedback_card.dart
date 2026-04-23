import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/seller_performance_period.dart';
import '../../view_models/seller_performance_view_model.dart';
import '../../view_models/session_view_model.dart';

/// A small dashboard card that answers the Type 2 business question:
/// "Out of the items uploaded by a seller, how many have been successfully
/// sold within a given period?"
class SellerPerformanceFeedbackCard extends StatelessWidget {
  const SellerPerformanceFeedbackCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedText =
        isDark ? colorScheme.onSurface.withValues(alpha: 0.72) : AppTheme.mutedForeground;

    return Consumer2<SessionViewModel, SellerPerformanceViewModel>(
      builder: (context, sessionVm, vm, _) {
        final user = sessionVm.currentUser;

        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 460;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppTheme.sage.withValues(alpha: isDark ? 0.28 : 0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.trending_up_rounded,
                                color: isDark ? colorScheme.primary : AppTheme.deepGreen,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Seller performance feedback',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Real-time feedback based on sold listings.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: mutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            width: compact ? double.infinity : 170,
                            child: DropdownButtonFormField<SellerPerformancePeriod>(
                              value: vm.selectedPeriod,
                              isDense: true,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Period',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              items: SellerPerformancePeriod.values
                                  .map(
                                    (period) => DropdownMenuItem(
                                      value: period,
                                      child: Text(period.label, overflow: TextOverflow.ellipsis),
                                    ),
                                  )
                                  .toList(),
                              onChanged: vm.isLoading
                                  ? null
                                  : (period) {
                                      if (period != null) {
                                        vm.setSelectedPeriod(period);
                                      }
                                    },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                if (vm.isLoading) ...[
                  const LinearProgressIndicator(minHeight: 4),
                  const SizedBox(height: 12),
                  Text(
                    'Loading your seller results...',
                    style: TextStyle(fontSize: 13, color: mutedText),
                  ),
                ] else if (user == null) ...[
                  _MessageBox(
                    icon: Icons.login_rounded,
                    title: 'Sign in required',
                    message: 'Log in to view how many items you have sold in the selected period.',
                  ),
                ] else if (vm.hasError) ...[
                  _MessageBox(
                    icon: Icons.error_outline_rounded,
                    title: 'Could not load sales data',
                    message: vm.errorMessage ?? 'Please try again later.',
                    isError: true,
                  ),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        vm.soldCountDisplay,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isDark ? colorScheme.primary : AppTheme.deepGreen,
                            ),
                      ),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          vm.soldCount == 1 ? 'item sold' : 'items sold',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: mutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Period: ${vm.periodLabel}',
                    style: TextStyle(fontSize: 12, color: mutedText),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    vm.feedbackMessage,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MessageBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final bool isError;

  const _MessageBox({
    required this.icon,
    required this.title,
    required this.message,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = isError ? colorScheme.error : AppTheme.deepGreen;
    final background = baseColor.withValues(alpha: 0.10);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: baseColor.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: baseColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: colorScheme.onSurface.withValues(alpha: 0.82),
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
