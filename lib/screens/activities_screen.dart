import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/activities_provider.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import 'logging/add_activity_screen.dart';

class ActivitiesScreen extends StatelessWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final acts = context.watch<ActivitiesProvider>().activities;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('📝 Atividades')),
        body: acts.isEmpty
            ? _EmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: acts.length,
                itemBuilder: (context, i) {
                final act = acts[i];
                final areaConfig = kAreas.firstWhere(
                  (c) => c.id == act.areaId,
                  orElse: () => kAreas.first,
                );
                final areaIndex =
                    kAreas.indexWhere((c) => c.id == act.areaId);
                final color = AppTheme.areaColors[
                    areaIndex >= 0 ? areaIndex % AppTheme.areaColors.length : 0];

                return Dismissible(
                  key: Key(act.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20),
                    color: Colors.red.withOpacity(0.2),
                    child: Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  onDismissed: (_) {
                    context.read<ActivitiesProvider>().deleteActivity(act.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Atividade removida')),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 10),
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: color.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              areaConfig.icon,
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                act.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    areaConfig.name,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    ' • ',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${act.durationMinutes} min',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    ' • ',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  _DifficultyChip(difficulty: act.difficulty),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '+${act.xpEarned} XP',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _formatDate(act.createdAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddActivityScreen()),
          ),
          backgroundColor: AppTheme.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hoje';
    if (diff == 1) return 'Ontem';
    return '${dt.day}/${dt.month}';
  }
}

class _DifficultyChip extends StatelessWidget {
  final String difficulty;
  _DifficultyChip({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (difficulty) {
      'easy' => ('Fácil', Color(0xFF2ED573)),
      'hard' => ('Difícil', Color(0xFFFF4757)),
      _ => ('Médio', Color(0xFFFFD32A)),
    };
    return Text(
      label,
      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📝', style: TextStyle(fontSize: 48)),
          SizedBox(height: 16),
          Text(
            'Nenhuma atividade ainda',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Toque em + para registrar\nsua primeira atividade',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}