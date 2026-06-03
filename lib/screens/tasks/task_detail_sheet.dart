import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_constants.dart';
import '../../models/task_model.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import 'task_create_screen.dart';

// ── Função pública ─────────────────────────────────────────────────────────────

/// Abre o bottom-sheet de detalhes de uma tarefa.
/// Pode ser chamada a partir de qualquer tela que tenha acesso ao contexto.
void showTaskDetailSheet(BuildContext context, TaskModel task) {
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
        child: TaskDetailSheet(task: task),
      ),
    ),
  );
}

// ── Widget: Detalhe da tarefa ─────────────────────────────────────────────────

class TaskDetailSheet extends StatelessWidget {
  final TaskModel task;
  const TaskDetailSheet({super.key, required this.task});

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
      initialChildSize: 0.72,
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

            // Título + MIT star
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Badges: área, quadrante, status, calendário, horas
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                TaskBadge(
                  text: '${area.icon} ${area.name}',
                  color: AppTheme.primary,
                ),
                TaskBadge(
                  text: '${current.eisenhowerEmoji} ${current.eisenhowerLabel}',
                  color: _qColor(current.eisenhowerQ),
                ),
                TaskBadge(
                  text: _statusLabel(current.status),
                  color: _statusColor(current.status),
                ),
                if (current.isFromCalendar)
                  const TaskBadge(
                    text: '🗓️ Google Agenda',
                    color: Colors.blue,
                  ),
                if (current.totalEstimatedHours > 0)
                  TaskBadge(
                    text: '⏱ ${current.totalEstimatedHours}h',
                    color: Colors.blueGrey,
                  ),
                if (current.hasLocation)
                  _LocationBadge(task: current),
              ],
            ),

            if (current.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                current.description,
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
            if (current.dueDate != null) ...[
              const SizedBox(height: 8),
              Text(
                '📅 Prazo: ${_fmtFull(current.dueDate!)}',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
            const SizedBox(height: 16),

            // ── Transições Kanban ─────────────────────────────────────────────
            if (current.status != 'completed') ...[
              Text(
                'Mover no Kanban',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (current.status == 'in_progress')
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.read<TasksProvider>().moveToPending(current.id);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_back, size: 14),
                        label: const Text('Pausar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          side: BorderSide(color: AppTheme.divider),
                        ),
                      ),
                    ),
                  if (current.status == 'in_progress') const SizedBox(width: 8),
                  if (current.status == 'pending')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.read<TasksProvider>().moveToInProgress(current.id);
                          Navigator.pop(context);
                        },
                        icon: const Text('⚡', style: TextStyle(fontSize: 14)),
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
                          await context.read<TasksProvider>().completeTask(current.id);
                          if (context.mounted) Navigator.pop(context);
                        },
                        icon: const Icon(Icons.check, size: 16, color: Colors.white),
                        label: const Text('Concluir',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF34D399)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ] else ...[
              // Reabrir tarefa concluída
              OutlinedButton.icon(
                onPressed: () {
                  context.read<TasksProvider>().moveToPending(current.id);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('Reabrir'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: BorderSide(color: AppTheme.divider),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Subtarefas ────────────────────────────────────────────────────
            if (current.subtasks.isNotEmpty) ...[
              Text(
                'Subtarefas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ...current.subtasks.map(
                (s) => TaskSubtaskTile(
                  subtask: s,
                  onToggle: () => context
                      .read<TasksProvider>()
                      .toggleSubtask(current.id, s.id),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Editar / Excluir (editável para TODAS as tarefas) ────────────
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
                      side: BorderSide(color: AppTheme.divider),
                    ),
                  ),
                ),
                // Excluir disponível apenas para tarefas manuais
                if (!current.isFromCalendar) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            backgroundColor: AppTheme.surface,
                            title: Text(
                              'Excluir tarefa?',
                              style: TextStyle(color: AppTheme.textPrimary),
                            ),
                            content: Text(
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
                      icon: const Icon(Icons.delete_outline,
                          size: 16, color: Colors.red),
                      label: const Text('Excluir',
                          style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red, width: 0.5),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            // Aviso para tarefas de calendário (abaixo dos botões)
            if (current.isFromCalendar) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Evento do Google Agenda. Título e descrição '
                        'voltam ao original na próxima sincronização.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.withOpacity(0.85),
                        ),
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
        'pending'     => '📋 Planejada',
        'in_progress' => '⚡ Em Execução',
        _             => '✅ Concluída',
      };

  Color _statusColor(String s) => switch (s) {
        'pending'     => AppTheme.primary,
        'in_progress' => const Color(0xFFFF9F1C),
        _             => const Color(0xFF34D399),
      };

  String _fmtFull(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';
}

// ── Widget: Badge ─────────────────────────────────────────────────────────────

class TaskBadge extends StatelessWidget {
  final String text;
  final Color color;
  const TaskBadge({super.key, required this.text, required this.color});

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

// ── Widget: Subtarefa ─────────────────────────────────────────────────────────

class TaskSubtaskTile extends StatelessWidget {
  final SubtaskModel subtask;
  final VoidCallback onToggle;
  const TaskSubtaskTile({
    super.key,
    required this.subtask,
    required this.onToggle,
  });

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
                  decoration:
                      subtask.isCompleted ? TextDecoration.lineThrough : null,
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

// ── Widget: Badge de localização ──────────────────────────────────────────────

/// Badge clicável que exibe o endereço da tarefa e abre o Google Maps ao tocar.
class _LocationBadge extends StatelessWidget {
  final TaskModel task;
  const _LocationBadge({required this.task});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final url = task.googleMapsUrl;
        if (url != null) {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF10B981).withOpacity(0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on,
                size: 13, color: Color(0xFF10B981)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                task.locationAddress!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.open_in_new,
                size: 11, color: Color(0xFF10B981)),
          ],
        ),
      ),
    );
  }
}
