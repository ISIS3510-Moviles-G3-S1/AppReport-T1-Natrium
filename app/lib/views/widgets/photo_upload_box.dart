import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class PhotoUploadBox extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback onDemo;
  final bool hasPhoto;
  final Widget? photoWidget;
  final String mainText;
  final String subText;
  final bool showDemo;

  const PhotoUploadBox({
    super.key,
    required this.onTap,
    required this.onDemo,
    required this.hasPhoto,
    this.photoWidget,
    this.mainText = 'Tap to upload photo',
    this.subText = 'JPG, PNG, WEBP up to 10MB',
    this.showDemo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: onTap,
          child: hasPhoto && photoWidget != null
              ? Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.muted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.deepGreen,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: photoWidget,
                  ),
                )
              : Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.muted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.deepGreen,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(24),
                        height: 56,
                        width: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.deepGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          color: AppTheme.deepGreen,
                          size: 36,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mainText,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: AppTheme.foreground,
                              ),
                            ),
                            Text(
                              subText,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        if (showDemo)
          const SizedBox(height: 8),
        if (showDemo)
          GestureDetector(
            onTap: onDemo,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.accent.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
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
    );
  }
}
