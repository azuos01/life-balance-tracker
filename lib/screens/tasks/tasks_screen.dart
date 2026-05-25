import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/user_provider.dart';
import '../../constants/app_constants.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import 'task_create_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksProvider = context.watch<TasksProvider>();

    return AppBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('⚡', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            const Text('Tarefas'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${tasksProvider.pendingTasks.length}',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Matriz Eisenhower'),
            Tab(text: 'Concluídas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MatrixView(tasksProvider: tasksProvider),
          _CompletedView(tasksProvider: tasksProvider),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TaskCreateScreen()),
        ),
        backgroundColor: AppTheme.primary,
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nova Tarefa',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      ),
    );
  }
}

// ── Matriz 2×2 de Eisenhower ──────────────────────────────────────────────────

class _MatrixView extends StatelessWidget {
  final TasksProvider tasksProvider;
  const _MatrixView({required this.tasksProvider});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Legenda de eixos
          _AxisLabels(),
          const SizedBox(height: 8),
          // Q1 e Q2 (linha superior)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Quadrant(
                  q: 1,
                  title: 'URGENTE\n+ IMPORTANTE',
                  action: 'Faça Agora',
                  emoji: '🔴',
                  color: Colors.red,
                  tasks: tasksProvider.byQuadrant(1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Quadrant(
                  q: 2,
                  title: 'NÃO URGENTE\n+ IMPORTANTE',
                  action: 'Agende',
                  emoji: '🟢',
                  color: Colors.green,
                  tasks: tasksProvider.byQuadrant(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Q3 e Q4 (linha inferior)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Quadrant(
                  q: 3,
                  title: 'URGENTE\n+ NÃO IMPORTANTE',
                  action: 'Delegue',
                  emoji: '🟡',
                  color: Colors.orange,
                  tasks: tasksProvider.byQuadrant(3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Quadrant(
                  q: 4,
                  title: 'NÃO URGENTE\n+ NÃO IMPORTANTE',
                  action: 'Elimine',
                  emoji: '⚫',
                  color: Colors.grey,
                  tasks: tasksProvider.byQuadrant(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _AxisLabels extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 4),
        const Text(
          '←  NÃO URGENTE      URGENTE  →',
          style: TextStyle(fontSize: 9, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

// ── Quadrante ─────────────────────────────────────────────────────────────────

class _Quadrant extends StatelessWidget {
  final int q;
  final String title;
  final String action;
  final String emoji;
  final Color color;
  final List<TaskModel> tasks;

  const _Quadrant({
    required this.q,
    required this.title,
    required this.action,
    required this.emoji,
    required this.color,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 160),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 14,
            spreadRadius: -4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          Text(
            action,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppTheme.divider),
          const SizedBox(height: 8),
          // Tasks list
          if (tasks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Nenhuma tarefa',
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withOpacity(0.5),
                  ),
                ),
              ),
            )
          else
            ...tasks.map((t) => _TaskCard(task: t, accentColor: color)),
        ],
      ),
    );
  }
}

// ── Task Card ─────────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final Color accentColor;

  const _TaskCard({required this.task, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final area = kAreas.firstWhere(
      (a) => a.id == task.areaId,
      orElse: () => kAreas.first,
    );

    return GestureDetector(
      onTap: () => _showTaskDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: task.isMIT
              ? Border.all(color: AppTheme.accent.withOpacity(0.5))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (task.isMIT)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Text('⭐', style: TextStyle(fontSize: 12)),
                  ),
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(area.icon, style: const TextStyle(fontSize: 10)),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    area.name,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (task.subtasks.isNotEmpty)
                  Text(
                    '${task.completedSubtasks}/${task.subtasks.length}',
                    style: TextStyle(
                      fontSize: 9,
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            if (task.subtasks.isNotEmpty) ...[
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: task.progress,
                  minHeight: 3,
                  backgroundColor: AppTheme.surfaceLight,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showTaskDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<TasksProvider>(),
        child: ChangeNotifierProvider.value(
          value: context.read<UserProvider>(),
          child: _TaskDetailSheet(task: task),
        ),
      ),
    );
  }
}

// ── Task Detail Sheet ─────────────────────────────────────────────────────────

class _TaskDetailSheet extends StatelessWidget {
  final TaskModel task;
  const _TaskDetailSheet({required this.task});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TasksProvider>();
    // Refresh task from provider (may have updated subtasks)
    final current = tp.tasks.firstWhere(
      (t) => t.id == task.id,
      orElse: () => task,
    );
    final area = kAreas.firstWhere(
      (a) => a.id == current.areaId,
      orElse: () => kAreas.first,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Title + badges
            Row(
              children: [
                if (current.isMIT)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Text('⭐', style: TextStyle(fontSize: 18)),
                  ),
                Expanded(
                  child: Text(
                    current.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Area + Eisenhower badges
            Wrap(
              spacing: 8,
              children: [
                _Badge(text: '${area.icon} ${area.name}', color: AppTheme.primary),
                _Badge(
                  text: '${current.eisenhowerEmoji} ${current.eisenhowerLabel}',
                  color: _qColor(current.eisenhowerQ),
                ),
                if (current.totalEstimatedHours > 0)
                  _Badge(
                    text: '⏱ ${current.totalEstimatedHours}h estimadas',
                    color: Colors.blueGrey,
                  ),
              ],
            ),
            if (current.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                current.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
            if (current.dueDate != null) ...[
              const SizedBox(height: 8),
              Text(
                '📅 Prazo: ${current.dueDate!.day.toString().padLeft(2, '0')}/${current.dueDate!.month.toString().padLeft(2, '0')}/${current.dueDate!.year}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 20),
            // Subtasks
            if (current.subtasks.isNotEmpty) ...[
              const Text(
                'Subtarefas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ...current.subtasks.map((s) => _SubtaskTile(
                    subtask: s,
                    onToggle: () => context
                        .read<TasksProvider>()
                        .toggleSubtask(current.id, s.id),
                  )),
              const SizedBox(height: 16),
            ],
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TaskCreateScreen(existingTask: current),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Editar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: const BorderSide(color: AppTheme.divider),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await context
                          .read<TasksProvider>()
                          .completeTask(current.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check, size: 16, color: Colors.white),
                    label: const Text(
                      'Concluir',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      backgroundColor: AppTheme.surface,
                      title: const Text('Excluir tarefa?',
                          style: TextStyle(color: AppTheme.textPrimary)),
                      content: const Text(
                        'Esta ação não pode ser desfeita.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Excluir',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) {
                    await context.read<TasksProvider>().deleteTask(current.id);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                label: const Text('Excluir tarefa',
                    style: TextStyle(color: Colors.red)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Color _qColor(int q) {
    return switch (q) {
      1 => Colors.red,
      2 => Colors.green,
      3 => Colors.orange,
      _ => Colors.grey,
    };
  }
}

class _SubtaskTile extends StatelessWidget {
  final SubtaskModel subtask;
  final VoidCallback onToggle;

  const _SubtaskTile({required this.subtask, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: subtask.isCompleted
              ? Colors.green.withOpacity(0.08)
              : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              subtask.isCompleted
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: subtask.isCompleted ? Colors.green : AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                subtask.title,
                style: TextStyle(
                  fontSize: 13,
                  color: subtask.isCompleted
                      ? AppTheme.textSecondary
                      : AppTheme.textPrimary,
                  decoration: subtask.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
            Text(
              '${subtask.estimatedHours}h',
              style: TextStyle(
                fontSize: 11,
                color: subtask.isCompleted
                    ? AppTheme.textSecondary
                    : AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Completed View ────────────────────────────────────────────────────────────

class _CompletedView extends StatelessWidget {
  final TasksProvider tasksProvider;
  const _CompletedView({required this.tasksProvider});

  @override
  Widget build(BuildContext context) {
    final completed = tasksProvider.completedTasks;
    if (completed.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎯', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text(
              'Nenhuma tarefa concluída ainda.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            SizedBox(height: 4),
            Text(
              'Complete suas MITs e elas aparecerão aqui.',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: completed.length,
      itemBuilder: (ctx, i) {
        final t = completed[i];
        final area = kAreas.firstWhere(
          (a) => a.id == t.areaId,
          orElse: () => kAreas.first,
        );
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    Text(
                      '${area.icon} ${area.name} • ${t.eisenhowerEmoji} Q${t.eisenhowerQ}',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
