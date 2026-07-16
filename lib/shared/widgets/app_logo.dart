import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

/// Wordmark used on the splash and login screens. Drawn rather than loaded
/// from an asset so it works before any images are added to `pubspec.yaml`.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 72,
    this.showName = true,
    this.showTagline = false,
  });

  final double size;
  final bool showName;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            color: colors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.25),
                blurRadius: size * 0.5,
                spreadRadius: size * 0.05,
              ),
            ],
          ),
          child: Icon(
            Icons.directions_bus_rounded,
            size: size * 0.5,
            color: colors.onPrimary,
          ),
        ),
        if (showName) ...[
          SizedBox(height: size * 0.3),
          Text(
            AppStrings.appName,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
        if (showTagline) ...[
          const SizedBox(height: 8),
          Text(
            AppStrings.tagline,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ],
    );
  }
}
