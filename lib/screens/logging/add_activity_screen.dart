import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/user_provider.dart';
import '../../providers/activities_provider.dart';
import '../../models/activity_model.dart';
import '../../constants/app_constants.dart';
import '../../theme/app_theme.dart';

class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({super.key});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  String _selectedAreaId = kAreas.first.id;
  final _descriptionController = TextEditingController();
  int _duration = 30;
  String _difficulty = 'medium';
  bool _loading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Descreva a atividade')),
      );
      return;
    }
    setState(() => _loading = true);

    final userProvider = context.read<UserProvider>();
    final activitiesProvider = context.read<ActivitiesProvider>();
    final user = userProvider.user!;

    final activity = ActivityModel(
      id: const Uuid().v4(),
      userId: user.id,
      areaId: _selectedAreaId,
      description: _descriptionController.text.trim(),
      durationMinutes: _duration,
      difficulty: _difficulty,
      createdAt: DateTime.now(),
    );

    final xp = await activitiesProvider.addActivity(activity);
    await userProvider.addXP(xp);

    final totalActivities = activitiesProvider.totalActivities;
    await userProvider.checkFirstActivityAchievement(totalActivities);

    // Check equilibrist achievement
    final areasThisWeek = activitiesProvider.areasActiveThisWeek();
    if (areasThisWeek.length >= 10) {
      await userProvider.unlockAchievement('equilibrist');
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Atividade salva! +$xp XP'),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('+ Nova Atividade'),
        leading: CloseButton(),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: Text(
              'Salvar',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Área',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 10),
            _AreaSelector(
              selectedId: _selectedAreaId,
              onChanged: (id) => setState(() => _selectedAreaId = id),
            ),
            SizedBox(height: 20),
            Text(
              'O que você fez?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              autofocus: true,
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Descreva sua atividade...',
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Duração (min)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8),
                      _DurationPicker(
                        value: _duration,
                        onChanged: (v) => setState(() => _duration = v),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dificuldade',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _DifficultySelector(
                        value: _difficulty,
                        onChanged: (v) => setState(() => _difficulty = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _XpPreview(difficulty: _difficulty),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _save,
                      child: const Text('Salvar Atividade'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaSelector extends StatelessWidget {
  final String selectedId;
  final ValueChanged<String> onChanged;

  _AreaSelector({required this.selectedId, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kAreas.length,
        separatorBuilder: (_, __) => SizedBox(width: 8),
        itemBuilder: (context, i) {
          final area = kAreas[i];
          final selected = area.id == selectedId;
          final color = AppTheme.areaColors[i % AppTheme.areaColors.length];
          return GestureDetector(
            onTap: () => onChanged(area.id),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              width: 72,
              decoration: BoxDecoration(
                color: selected ? color.withOpacity(0.2) : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? color : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(area.icon, style: TextStyle(fontSize: 22)),
                  SizedBox(height: 4),
                  Text(
                    area.name.split(' ').first,
                    style: TextStyle(
                      fontSize: 9,
                      color: selected ? color : AppTheme.textSecondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DurationPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  _DurationPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = [15, 30, 45, 60, 90, 120];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: options.map((min) {
        final selected = value == min;
        return GestureDetector(
          onTap: () => onChanged(min),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.primary.withOpacity(0.2)
                  : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? AppTheme.primary : Colors.transparent,
              ),
            ),
            child: Text(
              '$min',
              style: TextStyle(
                fontSize: 12,
                color: selected ? AppTheme.primary : AppTheme.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DifficultySelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  _DifficultySelector({required this.value, required this.onChanged});

  static const _items = [
    ('easy', '😌 Fácil', Color(0xFF2ED573)),
    ('medium', '💪 Médio', Color(0xFFFFD32A)),
    ('hard', '🔥 Difícil', Color(0xFFFF4757)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _items.map((item) {
        final (id, label, color) = item;
        final selected = value == id;
        return GestureDetector(
          onTap: () => onChanged(id),
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 6),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? color.withOpacity(0.15) : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? color : Colors.transparent,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selected ? color : AppTheme.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _XpPreview extends StatelessWidget {
  final String difficulty;
  const _XpPreview({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final xp = difficulty == 'easy'
        ? kXpEasy
        : difficulty == 'hard'
            ? kXpHard
            : kXpMedium;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Text(
            'Você vai ganhar +$xp XP',
            style: TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}