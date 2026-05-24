import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../constants/app_constants.dart';

class XpProgressBar extends StatelessWidget {
  final int totalXP;
  final bool showDetails;

  const XpProgressBar({
    super.key,
    required this.totalXP,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    final level = levelFromXP(totalXP);
    final tier = tierFromXP(totalXP);
    final nextXP = xpForNextLevel(totalXP);
    final prevXP = level > 1 ? xpForNextLevel(totalXP - 1) : 0;
    final progress = nextXP > prevXP
        ? ((totalXP - prevXP) / (nextXP - prevXP)).clamp(0.0, 1.0)
        : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDetails)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nível $level — $tier',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '$totalXP XP',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                'próx. $nextXP XP',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        if (showDetails) const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: showDetails ? 8 : 4,
            backgroundColor: AppTheme.surfaceLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ),
      ],
    );
  }
}
