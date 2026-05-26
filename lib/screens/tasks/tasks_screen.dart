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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TasksProvider>();

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${tp.pendingTasks.length}',
                  style: TextStyle(
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
              Tab(text: 'Eisenhower'),
              Tab(text: 'Kanban'),
              Tab(text: 'Histórico'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _MatrixView(tp: tp),
            _KanbanView(tp: tp),
            _HistoryView(tp: tp),
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

// ══════════════════════════════════════════════════════════════════════════════
// EISENHOWER MATRIX VIEW
// ══════════════════════════════════════════════════════════════════════════════

class _MatrixView extends StatelessWidget {
  final TasksProvider tp;
  const _MatrixView({required this.tp});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _AxisLabels(),
          const SizedBox(height: 8),
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
                  tasks: tp.byQuadrant(1),
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
                  tasks: tp.byQuadrant(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
                  tasks: tp.byQuadrant(3),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _Quadrant(
                  q: 4,
                  title: 'NÃO URGENTE\n+ NÃO IMPORTANTE',
                  action: 'Elimine',
                  emoji: '⚫',
                  color: Colors.grey,
                  tasks: tp.byQuadrant(4),
                ),
              ),
            ],
          ),
          SizedBox(height: 80),
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
        SizedBox(width: 4),
        Text(
          '←  NÃO URGENTE            URGENTE  →',
          style: TextStyle(fontSize: 9, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

class _Quadrant extends StatelessWidget {
  final int q;
  final String title, action, emoji;
  final Color color;
  final List<TaskModel> tasks;

  _Quadrant({
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
      constraints: BoxConstraints(minHeight: 160),
      padding: EdgeInsets.all(10),
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
          Row(
            children: [
              Text(emoji, style: TextStyle(fontSize: 14)),
              SizedBox(width: 4),
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
          SizedBox(height: 8),
          Divider(height: 1, color: AppTheme.divider),
          const SizedBox(height: 8),
          if (tasks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Nenhuma tarefa',
                  style:
                      TextStyle(fontSize: 11, color: color.withOpacity(0.5)),
                ),
              ),
            )
          else
            ...tasks.map((t) => _EisenhowerCard(task: t, accentColor: color)),
        ],
      ),
    );
  }
}

class _EisenhowerCard extends StatelessWidget {
  final TaskModel task;
  final Color accentColor;
  _EisenhowerCard({required this.task, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final area = kAreas.firstWhere(
      (a) => a.id == task.areaId,
      orElse: () => kAreas.first,
    );
    final isInProgress = task.status == 'in_progress';

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        margin: EdgeInsets.only(bottom: 6),
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
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
                  Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Text('⭐', style: TextStyle(fontSize: 10)),
                  ),
                if (task.isFromCalendar)
                  Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Text('🗓️', style: TextStyle(fontSize: 10)),
                  ),
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isInProgress)
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Color(0xFFFF9F1C).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '⚡',
                      style: TextStyle(fontSize: 9),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Text(area.icon, style: TextStyle(fontSize: 10)),
                SizedBox(width: 3),
                Expanded(
                  child: Text(
                    area.name,
                    style: TextStyle(
                        fontSize: 9, color: AppTheme.textSecondary),
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
              SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: task.progress,
                  minHeight: 3,
                  backgroundColor: AppTheme.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
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

// ══════════════════════════════════════════════════════════════════════════════
// KANBAN VIEW
// ══════════════════════════════════════════════════════════════════════════════

class _KanbanView extends StatelessWidget {
  final TasksProvider tp;
  const _KanbanView({required this.tp});

  static const _colorPlanned = AppTheme.primary;
  static const _colorInProgress = Color(0xFFFF9F1C);
  static const _colorDone = Color(0xFF34D399);

  @override
  Widget build(BuildContext context) {
    final planned = tp.plannedTasks;
    final inProgress = tp.inProgressTasks;
    final completed = tp.completedTasks;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Seção de Relatório ──────────────────────────────────────────
          _KanbanReport(
            planned: planned.length,
            inProgress: inProgress.length,
            completed: completed.length,
          ),
          const SizedBox(height: 12),
          // ── Colunas Kanban ──────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _KanbanColumn(
                  title: 'Planejadas',
                  icon: '📋',
                  color: _colorPlanned,
                  tasks: planned,
                  columnStatus: 'pending',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _KanbanColumn(
                  title: 'Em Execução',
                  icon: '⚡',
                  color: _colorInProgress,
                  tasks: inProgress,
                  columnStatus: 'in_progress',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _KanbanColumn(
                  title: 'Concluídas',
                  icon: '✅',
                  color: _colorDone,
                  tasks: completed,
                  columnStatus: 'completed',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Relatório Kanban ──────────────────────────────────────────────────────────

class _KanbanReport extends StatelessWidget {
  final int planned, inProgress, completed;
  _KanbanReport({
    required this.planned,
    required this.inProgress,
    required this.completed,
  });

  static const _colorPlanned = AppTheme.primary;
  static const _colorInProgress = Color(0xFFFF9F1C);
  static const _colorDone = Color(0xFF34D399);

  @override
  Widget build(BuildContext context) {
    final total = planned + inProgress + completed;
    final doneRate = total > 0 ? completed / total : 0.0;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('📊', style: TextStyle(fontSize: 16)),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Relatório Kanban',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Visão geral do fluxo de tarefas',
                      style: TextStyle(
                          fontSize: 10, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$total total',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Cards de status
          Row(
            children: [
              _StatusChip(
                label: 'Planejadas',
                count: planned,
                color: _colorPlanned,
                icon: '📋',
              ),
              SizedBox(width: 8),
              _StatusChip(
                label: 'Em Execução',
                count: inProgress,
                color: _colorInProgress,
                icon: '⚡',
              ),
              SizedBox(width: 8),
              _StatusChip(
                label: 'Concluídas',
                count: completed,
                color: _colorDone,
                icon: '✅',
              ),
            ],
          ),
          SizedBox(height: 16),
          // Barra de progresso segmentada
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progresso geral',
                style:
                    TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
              Text(
                '${(doneRate * 100).toInt()}% concluído',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _colorDone,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          _SegmentedBar(
            planned: planned,
            inProgress: inProgress,
            completed: completed,
          ),
          SizedBox(height: 8),
          // Legenda
          Row(
            children: [
              _LegendDot(color: _colorDone, label: 'Concluídas'),
              SizedBox(width: 14),
              _LegendDot(color: _colorInProgress, label: 'Em execução'),
              SizedBox(width: 14),
              _LegendDot(color: _colorPlanned, label: 'Planejadas'),
            ],
          ),
          // Taxa de conclusão detalhada
          if (planned + inProgress + completed > 0) ...[
            SizedBox(height: 12),
            Divider(height: 1, color: AppTheme.divider),
            const SizedBox(height: 12),
            Row(
              children: [
                _MiniStat(
                  label: 'Taxa conclusão',
                  value: '${(doneRate * 100).toInt()}%',
                  color: _colorDone,
                ),
                const SizedBox(width: 12),
                _MiniStat(
                  label: 'Em andamento',
                  value: total > 0
                      ? '${((inProgress / total) * 100).toInt()}%'
                      : '0%',
                  color: _colorInProgress,
                ),
                const SizedBox(width: 12),
                _MiniStat(
                  label: 'No backlog',
                  value: total > 0
                      ? '${((planned / total) * 100).toInt()}%'
                      : '0%',
                  color: _colorPlanned,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SegmentedBar extends StatelessWidget {
  final int planned, inProgress, completed;
  _SegmentedBar({
    required this.planned,
    required this.inProgress,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final total = planned + inProgress + completed;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          if (total == 0) {
            return Container(
              height: 10,
              color: AppTheme.surfaceLight,
            );
          }
          final w = constraints.maxWidth;
          final doneW = w * completed / total;
          final progW = w * inProgress / total;
          final planW = w * planned / total;
          return SizedBox(
            height: 10,
            child: Row(
              children: [
                if (completed > 0)
                  Container(
                    width: doneW,
                    color: const Color(0xFF34D399),
                  ),
                if (inProgress > 0)
                  Container(
                    width: progW,
                    color: const Color(0xFFFF9F1C),
                  ),
                if (planned > 0)
                  Container(
                    width: planW,
                    color: AppTheme.primary.withOpacity(0.65),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label, icon;
  final int count;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.22)),
        ),
        child: Column(
          children: [
            Text(icon, style: TextStyle(fontSize: 16)),
            SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                  fontSize: 9, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 9, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
                fontSize: 10, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Coluna Kanban ─────────────────────────────────────────────────────────────

class _KanbanColumn extends StatelessWidget {
  final String title, icon, columnStatus;
  final Color color;
  final List<TaskModel> tasks;

  _KanbanColumn({
    required this.title,
    required this.icon,
    required this.color,
    required this.tasks,
    required this.columnStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho da coluna
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.09),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
              border:
                  Border(bottom: BorderSide(color: color.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Text(icon, style: TextStyle(fontSize: 13)),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: color,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Conteúdo da coluna
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined,
                      color: color.withOpacity(0.28), size: 26),
                  const SizedBox(height: 6),
                  Text(
                    'Nenhuma\ntarefa',
                    style: TextStyle(
                        fontSize: 10, color: color.withOpacity(0.45)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: tasks
                    .map((t) => _KanbanCard(
                          task: t,
                          accentColor: color,
                          columnStatus: columnStatus,
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Card Kanban ───────────────────────────────────────────────────────────────

class _KanbanCard extends StatelessWidget {
  final TaskModel task;
  final Color accentColor;
  final String columnStatus;

  _KanbanCard({
    required this.task,
    required this.accentColor,
    required this.columnStatus,
  });

  @override
  Widget build(BuildContext context) {
    final area = kAreas.firstWhere(
      (a) => a.id == task.areaId,
      orElse: () => kAreas.first,
    );
    final isDone = columnStatus == 'completed';

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: task.isMIT
              ? Border.all(color: AppTheme.accent.withOpacity(0.5))
              : Border.all(color: AppTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título + MIT + Calendário
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.isMIT)
                  Padding(
                    padding: EdgeInsets.only(right: 3, top: 1),
                    child: Text('⭐', style: TextStyle(fontSize: 10)),
                  ),
                if (task.isFromCalendar)
                  Padding(
                    padding: EdgeInsets.only(right: 3, top: 1),
                    child: Text('🗓️', style: TextStyle(fontSize: 10)),
                  ),
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDone
                          ? AppTheme.textSecondary
                          : AppTheme.textPrimary,
                      decoration:
                          isDone ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            // Área + badge Eisenhower
            Row(
              children: [
                Text(area.icon, style: TextStyle(fontSize: 10)),
                SizedBox(width: 3),
                Expanded(
                  child: Text(
                    area.name,
                    style: TextStyle(
                        fontSize: 9, color: AppTheme.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: _qColor(task.eisenhowerQ).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${task.eisenhowerEmoji} Q${task.eisenhowerQ}',
                    style: TextStyle(
                      fontSize: 8,
                      color: _qColor(task.eisenhowerQ),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            // Barra de progresso das subtarefas
            if (task.subtasks.isNotEmpty) ...[
              SizedBox(height: 7),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: task.progress,
                        minHeight: 4,
                        backgroundColor: AppTheme.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            accentColor),
                      ),
                    ),
                  ),
                  SizedBox(width: 6),
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
            ],
            // Prazo
            if (task.dueDate != null) ...[
              SizedBox(height: 4),
              Text(
                '📅 ${_fmtDate(task.dueDate!)}',
                style: TextStyle(
                  fontSize: 9,
                  color: _isOverdue(task.dueDate!) && !isDone
                      ? Colors.redAccent
                      : AppTheme.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 8),
            // Ações de transição de status
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    if (columnStatus == 'pending') {
      return _ActionButton(
        label: 'Iniciar',
        icon: '⚡',
        color: Color(0xFFFF9F1C),
        onTap: () => context.read<TasksProvider>().moveToInProgress(task.id),
      );
    }

    if (columnStatus == 'in_progress') {
      return Column(
        children: [
          _ActionButton(
            label: 'Concluir',
            icon: '✓',
            color: Color(0xFF34D399),
            onTap: () =>
                context.read<TasksProvider>().completeTask(task.id),
          ),
          SizedBox(height: 4),
          GestureDetector(
            onTap: () =>
                context.read<TasksProvider>().moveToPending(task.id),
            child: Center(
              child: Text(
                '← Pausar',
                style: TextStyle(
                    fontSize: 10, color: AppTheme.textSecondary),
              ),
            ),
          ),
        ],
      );
    }

    // Coluna Concluídas → reabrir (não disponível para tarefas de calendário
    // que não têm reabertura significativa, mas mantemos para consistência)
    return GestureDetector(
      onTap: () => context.read<TasksProvider>().moveToPending(task.id),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Center(
          child: Text(
            '↩ Reabrir',
            style: TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Color _qColor(int q) => switch (q) {
        1 => Colors.red,
        2 => Colors.green,
        3 => Colors.orange,
        _ => Colors.grey,
      };

  bool _isOverdue(DateTime d) =>
      d.isBefore(DateTime.now().subtract(Duration(days: 1)));

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  void _showDetail(BuildContext context) {
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

class _ActionButton extends StatelessWidget {
  final String label, icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w700)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// HISTORY VIEW (tarefas concluídas — listagem detalhada)
// ══════════════════════════════════════════════════════════════════════════════

class _HistoryView extends StatelessWidget {
  final TasksProvider tp;
  _HistoryView({required this.tp});

  @override
  Widget build(BuildContext context) {
    final completed = tp.completedTasks;

    if (completed.isEmpty) {
      return Center(
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
      padding: EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: completed.length,
      itemBuilder: (ctx, i) {
        final t = completed[i];
        final area = kAreas.firstWhere(
          (a) => a.id == t.areaId,
          orElse: () => kAreas.first,
        );
        final areaIndex = kAreas.indexWhere((a) => a.id == t.areaId);
        final color = AppTheme.areaColors[
            areaIndex >= 0 ? areaIndex % AppTheme.areaColors.length : 0];

        return Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Color(0xFF34D399).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Color(0xFF34D399).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle,
                    color: Color(0xFF34D399), size: 18),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle),
                        ),
                        SizedBox(width: 5),
                        Text(
                          '${area.icon} ${area.name}',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary),
                        ),
                        Text(
                          ' • ',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary),
                        ),
                        Text(
                          '${t.eisenhowerEmoji} ${t.eisenhowerLabel}',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    if (t.subtasks.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        '${t.subtasks.length} subtarefa${t.subtasks.length > 1 ? 's' : ''}'
                        ' · ${t.totalEstimatedHours}h estimadas',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              if (t.completedAt != null)
                Text(
                  _fmtDate(t.completedAt!),
                  style: TextStyle(
                      fontSize: 10, color: AppTheme.textSecondary),
                ),
            ],
          ),
        );
      },
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}

// ══════════════════════════════════════════════════════════════════════════════
// TASK DETAIL SHEET (usado em ambas as views)
// ══════════════════════════════════════════════════════════════════════════════

class _TaskDetailSheet extends StatelessWidget {
  final TaskModel task;
  const _TaskDetailSheet({required this.task});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TasksProvider>();
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
        padding: EdgeInsets.all(20),
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
            SizedBox(height: 16),
            // Título + MIT
            Row(
              children: [
                if (current.isMIT)
                  Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Text('⭐', style: TextStyle(fontSize: 18)),
                  ),
                Expanded(
                  child: Text(
                    current.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            // Badges: área + Eisenhower + Kanban status + horas + calendário
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _Badge(
                    text: '${area.icon} ${area.name}',
                    color: AppTheme.primary),
                _Badge(
                  text:
                      '${current.eisenhowerEmoji} ${current.eisenhowerLabel}',
                  color: _qColor(current.eisenhowerQ),
                ),
                _Badge(
                  text: _statusLabel(current.status),
                  color: _statusColor(current.status),
                ),
                if (current.isFromCalendar)
                  _Badge(
                    text: '🗓️ Google Agenda',
                    color: Colors.blue,
                  ),
                if (current.totalEstimatedHours > 0)
                  _Badge(
                    text: '⏱ ${current.totalEstimatedHours}h',
                    color: Colors.blueGrey,
                  ),
              ],
            ),
            if (current.description.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                current.description,
                style: TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
            if (current.dueDate != null) ...[
              SizedBox(height: 8),
              Text(
                '📅 Prazo: ${current.dueDate!.day.toString().padLeft(2, '0')}/${current.dueDate!.month.toString().padLeft(2, '0')}/${current.dueDate!.year}',
                style: TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
            SizedBox(height: 16),
            // Transições Kanban
            if (current.status != 'completed') ...[
              Text(
                'Mover no Kanban',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  if (current.status == 'in_progress')
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context
                              .read<TasksProvider>()
                              .moveToPending(current.id);
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.arrow_back, size: 14),
                        label: Text('Pausar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          side:
                              BorderSide(color: AppTheme.divider),
                        ),
                      ),
                    ),
                  if (current.status == 'in_progress')
                    const SizedBox(width: 8),
                  if (current.status == 'pending')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context
                              .read<TasksProvider>()
                              .moveToInProgress(current.id);
                          Navigator.pop(context);
                        },
                        icon: const Text('⚡',
                            style: TextStyle(fontSize: 14)),
                        label: const Text('Iniciar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9F1C),
                        ),
                      ),
                    ),
                  if (current.status == 'in_progress')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await context
                              .read<TasksProvider>()
                              .completeTask(current.id);
                          if (context.mounted) Navigator.pop(context);
                        },
                        icon: Icon(Icons.check,
                            size: 16, color: Colors.white),
                        label: Text('Concluir',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF34D399)),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16),
            ],
            // Subtarefas
            if (current.subtasks.isNotEmpty) ...[
              Text(
                'Subtarefas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              ...current.subtasks.map((s) => _SubtaskTile(
                    subtask: s,
                    onToggle: () => context
                        .read<TasksProvider>()
                        .toggleSubtask(current.id, s.id),
                  )),
              SizedBox(height: 12),
            ],
            // Editar / Excluir (oculto para tarefas de calendário)
            if (!current.isFromCalendar) ...[
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
                      icon: Icon(Icons.edit_outlined, size: 16),
                      label: Text('Editar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: BorderSide(color: AppTheme.divider),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            backgroundColor: AppTheme.surface,
                            title: Text('Excluir tarefa?',
                                style:
                                    TextStyle(color: AppTheme.textPrimary)),
                            content: Text(
                              'Esta ação não pode ser desfeita.',
                              style:
                                  TextStyle(color: AppTheme.textSecondary),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(c, false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(c, true),
                                child: const Text('Excluir',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (ok == true && context.mounted) {
                          await context
                              .read<TasksProvider>()
                              .deleteTask(current.id);
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.delete_outline,
                          size: 16, color: Colors.red),
                      label: const Text('Excluir',
                          style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Colors.red, width: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Tarefa de calendário: mostra aviso de origem
              Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Evento sincronizado do Google Agenda. '
                        'Para editar ou excluir, acesse o Google Calendar.',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.withOpacity(0.85)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Color _qColor(int q) => switch (q) {
        1 => Colors.red,
        2 => Colors.green,
        3 => Colors.orange,
        _ => Colors.grey,
      };

  String _statusLabel(String s) => switch (s) {
        'pending' => '📋 Planejada',
        'in_progress' => '⚡ Em Execução',
        _ => '✅ Concluída',
      };

  Color _statusColor(String s) => switch (s) {
        'pending' => AppTheme.primary,
        'in_progress' => Color(0xFFFF9F1C),
        _ => Color(0xFF34D399),
      };
}

class _SubtaskTile extends StatelessWidget {
  final SubtaskModel subtask;
  final VoidCallback onToggle;

  _SubtaskTile({required this.subtask, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: EdgeInsets.only(bottom: 6),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              color: subtask.isCompleted
                  ? Colors.green
                  : AppTheme.textSecondary,
              size: 20,
            ),
            SizedBox(width: 10),
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