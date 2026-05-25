import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/areas_provider.dart';
import '../providers/user_provider.dart';
import '../models/area_model.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final areas = context.watch<AreasProvider>().areas;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('🎯 Objetivos')),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: areas.length,
          itemBuilder: (context, i) {
            final area = areas[i];
            if (area.goals.isEmpty) return const SizedBox();
            return _AreaGoalsSection(area: area, colorIndex: i);
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddGoalSheet(context),
          backgroundColor: AppTheme.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Novo Objetivo',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  void _showAddGoalSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<AreasProvider>(),
        child: ChangeNotifierProvider.value(
          value: context.read<UserProvider>(),
          child: const _AddGoalSheet(),
        ),
      ),
    );
  }
}

class _AreaGoalsSection extends StatelessWidget {
  final AreaModel area;
  final int colorIndex;

  const _AreaGoalsSection({required this.area, required this.colorIndex});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.areaColors[colorIndex % AppTheme.areaColors.length];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Text(area.icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                area.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        ...area.goals.map((goal) => _GoalTile(goal: goal, area: area, color: color)),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _GoalTile extends StatelessWidget {
  final GoalModel goal;
  final AreaModel area;
  final Color color;

  const _GoalTile({
    required this.goal,
    required this.area,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = goal.status == 'completed';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? color.withOpacity(0.5) : AppTheme.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? AppTheme.textSecondary
                        : AppTheme.textPrimary,
                    decoration:
                        isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              _GoalTypeBadge(type: goal.type, color: color),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _toggleComplete(context),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: isCompleted ? color : AppTheme.textSecondary,
                  size: 22,
                ),
              ),
            ],
          ),
          if (goal.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              goal.description,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: goal.progress / 100,
                    minHeight: 4,
                    backgroundColor: AppTheme.surfaceLight,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${goal.progress.toInt()}%',
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleComplete(BuildContext context) {
    final areasProvider = context.read<AreasProvider>();
    final isCompleted = goal.status == 'completed';
    goal.status = isCompleted ? 'in_progress' : 'completed';
    goal.progress = isCompleted ? 50 : 100;
    if (!isCompleted) goal.completedAt = DateTime.now();
    areasProvider.updateGoal(area.id, goal);

    if (!isCompleted) {
      context.read<UserProvider>().addXP(kXpObjective);
      context.read<UserProvider>().unlockAchievement('goal_crusher');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎯 Objetivo concluído! +$kXpObjective XP'),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
  }
}

class _GoalTypeBadge extends StatelessWidget {
  final String type;
  final Color color;

  const _GoalTypeBadge({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    final label = type == 'annual'
        ? 'Anual'
        : type == 'quarterly'
            ? 'Trimestral'
            : 'Mensal';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AddGoalSheet extends StatefulWidget {
  const _AddGoalSheet();

  @override
  State<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<_AddGoalSheet> {
  String _selectedAreaId = kAreas.first.id;
  String _type = 'quarterly';
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) return;
    final goal = GoalModel(
      id: const Uuid().v4(),
      areaId: _selectedAreaId,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      type: _type,
      createdAt: DateTime.now(),
    );
    await context.read<AreasProvider>().addGoal(_selectedAreaId, goal);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Novo Objetivo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedAreaId,
            dropdownColor: AppTheme.surface,
            decoration: const InputDecoration(labelText: 'Área'),
            items: kAreas.map((a) {
              return DropdownMenuItem(
                value: a.id,
                child: Text(
                  '${a.icon} ${a.name}',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
            onChanged: (v) => setState(() => _selectedAreaId = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(labelText: 'Título do objetivo'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _type,
            dropdownColor: AppTheme.surface,
            decoration: const InputDecoration(labelText: 'Prazo'),
            items: const [
              DropdownMenuItem(
                value: 'monthly',
                child: Text('Mensal', style: TextStyle(color: AppTheme.textPrimary)),
              ),
              DropdownMenuItem(
                value: 'quarterly',
                child: Text('Trimestral', style: TextStyle(color: AppTheme.textPrimary)),
              ),
              DropdownMenuItem(
                value: 'annual',
                child: Text('Anual', style: TextStyle(color: AppTheme.textPrimary)),
              ),
            ],
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Criar Objetivo'),
            ),
          ),
        ],
      ),
    );
  }
}
