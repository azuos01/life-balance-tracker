import 'package:flutter/material.dart';
import '../models/area_model.dart';
import '../theme/app_theme.dart';
import '../constants/app_constants.dart';

class AreaCard extends StatelessWidget {
  final AreaModel area;
  final int colorIndex;
  final VoidCallback? onTap;

  AreaCard({
    super.key,
    required this.area,
    required this.colorIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.areaColors[colorIndex % AppTheme.areaColors.length];
    final config = kAreas.firstWhere(
      (c) => c.id == area.id,
      orElse: () => kAreas.first,
    );
    final score = area.currentScore;
    final pct = score / 10;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withOpacity(0.18),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.10),
              blurRadius: 16,
              spreadRadius: -4,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra colorida no topo
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.4)],
                ),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          area.icon,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          config.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        score.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: color,
                          height: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '/10',
                          style: TextStyle(
                            fontSize: 12,
                            color: color.withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Mini circular indicator
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          value: pct,
                          strokeWidth: 3,
                          backgroundColor: color.withOpacity(0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Linear bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 4,
                      backgroundColor: color.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}