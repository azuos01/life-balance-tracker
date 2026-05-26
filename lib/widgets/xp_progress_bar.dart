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

    final tierColor = _tierColor(tier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDetails) ...[
          Row(
            children: [
              // Nível badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [tierColor, tierColor.withOpacity(0.6)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Nv $level',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tier,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: tierColor,
                    ),
                  ),
                  Text(
                    '$totalXP XP acumulados',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: tierColor,
                    ),
                  ),
                  Text(
                    'para nv ${level + 1}',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        // Barra de progresso com gradiente
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              // Background
              Container(
                height: showDetails ? 10 : 5,
                decoration: BoxDecoration(
                  color: tierColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // Fill
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: showDetails ? 10 : 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [tierColor, tierColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: tierColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _tierColor(String tier) => switch (tier) {
        'Iniciante'  => const Color(0xFF9CA3AF),
        'Praticante' => const Color(0xFF34D399),
        'Guerreiro'  => const Color(0xFF60A5FA),
        'Mestre'     => const Color(0xFFA78BFA),
        _            => AppTheme.accentGold,     // Lenda
      };
}