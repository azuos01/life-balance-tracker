import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/task_model.dart';
import '../../providers/tasks_provider.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_l10n.dart';

// ── Constantes de status ──────────────────────────────────────────────────────
const _kAll        = 'all';
const _kPending    = 'pending';
const _kInProgress = 'in_progress';
const _kCompleted  = 'completed';

// ── Tela principal ────────────────────────────────────────────────────────────

/// Tela de Relatórios de Tarefas.
///
/// Exibe KPIs de status, taxa de conclusão (anel animado), distribuição por
/// área e por quadrante Eisenhower, e a lista filtrada de tarefas com
/// possibilidade de filtro por status.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _statusFilter = _kAll;

  List<TaskModel> _filteredTasks(TasksProvider tp) {
    var list = tp.tasks.toList();
    if (_statusFilter != _kAll) {
      list = list.where((t) => t.status == _statusFilter).toList();
    }
    list.sort((a, b) {
      // pending < in_progress < completed
      const order = {_kPending: 0, _kInProgress: 1, _kCompleted: 2};
      final cmp =
          (order[a.status] ?? 0).compareTo(order[b.status] ?? 0);
      if (cmp != 0) return cmp;
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final tp    = context.watch<TasksProvider>();
    final l10n  = context.l10n;
    final tasks = _filteredTasks(tp);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverPadding(padding: EdgeInsets.only(top: 12)),

        // ── 1. KPIs ──────────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(child: _KpiRow(tp: tp, l10n: l10n)),
        ),

        const SliverPadding(padding: EdgeInsets.only(top: 16)),

        // ── 2. Anel de progresso ──────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
              child: _ProgressSection(tp: tp, l10n: l10n)),
        ),

        const SliverPadding(padding: EdgeInsets.only(top: 16)),

        // ── 3. Origem (Manual vs Agenda) ──────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
              child: _OriginRow(tp: tp, l10n: l10n)),
        ),

        const SliverPadding(padding: EdgeInsets.only(top: 24)),

        // ── 4. Filtro de status ───────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: _StatusFilterRow(
              selected: _statusFilter,
              onChanged: (v) => setState(() => _statusFilter = v),
              l10n: l10n,
            ),
          ),
        ),

        const SliverPadding(padding: EdgeInsets.only(top: 8)),

        // ── 5. Lista de tarefas filtrada ──────────────────────────────────────
        if (tasks.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(child: _EmptyState(l10n: l10n)),
          )
        else
          SliverPadding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _TaskCard(task: tasks[i]),
                childCount: tasks.length,
              ),
            ),
          ),

        const SliverPadding(padding: EdgeInsets.only(top: 28)),

        // ── 6. Distribuição por área ──────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
              child: _AreaChart(tp: tp, l10n: l10n)),
        ),

        const SliverPadding(padding: EdgeInsets.only(top: 28)),

        // ── 7. Distribuição por quadrante Eisenhower ──────────────────────────
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
              child: _QuadrantGrid(tp: tp, l10n: l10n)),
        ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
      ],
    );
  }
}

// ── Seção: KPIs ───────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  final TasksProvider tp;
  final L10n l10n;
  const _KpiRow({required this.tp, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _KpiCard(
          label: 'Total',
          value: '${tp.totalTasks}',
          color: AppTheme.primary,
          icon: Icons.list_alt_outlined,
        ),
        const SizedBox(width: 8),
        _KpiCard(
          label: l10n.toDo,
          value: '${tp.pendingCount}',
          color: const Color(0xFF3B82F6),
          icon: Icons.radio_button_unchecked,
        ),
        const SizedBox(width: 8),
        _KpiCard(
          label: l10n.inProgressLabel,
          value: '${tp.inProgressCount}',
          color: AppTheme.accentGold,
          icon: Icons.autorenew_outlined,
        ),
        const SizedBox(width: 8),
        _KpiCard(
          label: l10n.completedLabel,
          value: '${tp.completedCount}',
          color: const Color(0xFF10B981),
          icon: Icons.check_circle_outline,
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _KpiCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            top: BorderSide(color: color, width: 3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Seção: Anel de progresso ──────────────────────────────────────────────────

class _ProgressSection extends StatelessWidget {
  final TasksProvider tp;
  final L10n l10n;
  const _ProgressSection({required this.tp, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final rate  = tp.completionRate;
    final pct   = (rate * 100).round();
    final avg   = tp.avgCompletionTime;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.donut_large_outlined,
            label: l10n.completionRateLbl,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Donut chart
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(100, 100),
                      painter: _DonutPainter(
                        progress: rate,
                        fillColor: const Color(0xFF10B981),
                        trackColor: AppTheme.surfaceHigh,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$pct%',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          l10n.completedLabel,
                          style: TextStyle(
                            fontSize: 9,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Stats column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatRow(
                      icon: Icons.check_circle,
                      color: const Color(0xFF10B981),
                      label: '${l10n.completedLabel} (${l10n.thisWeek})',
                      value: '${tp.completedThisWeek}',
                    ),
                    const SizedBox(height: 10),
                    _StatRow(
                      icon: Icons.add_circle_outline,
                      color: const Color(0xFF3B82F6),
                      label: 'Criadas (${l10n.thisWeek})',
                      value: '${tp.createdThisWeek}',
                    ),
                    const SizedBox(height: 10),
                    _StatRow(
                      icon: Icons.timer_outlined,
                      color: AppTheme.accentGold,
                      label: l10n.avgTimeLbl,
                      value: avg == null
                          ? '—'
                          : avg.inHours > 0
                              ? '${avg.inHours}h'
                              : '${avg.inMinutes}min',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Seção: Origem das tarefas ─────────────────────────────────────────────────

class _OriginRow extends StatelessWidget {
  final TasksProvider tp;
  final L10n l10n;
  const _OriginRow({required this.tp, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final total   = tp.totalTasks;
    final userCnt = tp.userTasksCount;
    final calCnt  = tp.calendarTasksCount;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.source_outlined,
              size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            l10n.originLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
          const Spacer(),
          _OriginChip(
            label: l10n.userTasksLabel,
            count: userCnt,
            total: total,
            color: AppTheme.primary,
            icon: '✏️',
          ),
          const SizedBox(width: 8),
          _OriginChip(
            label: l10n.calendarTasksLbl,
            count: calCnt,
            total: total,
            color: const Color(0xFF3B82F6),
            icon: '🗓️',
          ),
        ],
      ),
    );
  }
}

class _OriginChip extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  final String icon;
  const _OriginChip({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : ((count / total) * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count ($pct%)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Seção: Filtro de status ───────────────────────────────────────────────────

class _StatusFilterRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final L10n l10n;
  const _StatusFilterRow({
    required this.selected,
    required this.onChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      (_kAll,        l10n.allTasks,        Colors.grey),
      (_kPending,    l10n.toDo,            const Color(0xFF3B82F6)),
      (_kInProgress, l10n.inProgressLabel, AppTheme.accentGold),
      (_kCompleted,  l10n.completedLabel,  const Color(0xFF10B981)),
    ];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (value, label, color) = filters[i];
          final active = selected == value;
          return GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? color.withOpacity(0.15)
                    : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? color : AppTheme.divider,
                  width: active ? 1.5 : 1,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? color : AppTheme.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Seção: Card de tarefa ─────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  const _TaskCard({required this.task});

  Color get _statusColor => switch (task.status) {
        _kPending    => const Color(0xFF3B82F6),
        _kInProgress => AppTheme.accentGold,
        _kCompleted  => const Color(0xFF10B981),
        _            => AppTheme.primary,
      };

  String get _statusLabel => switch (task.status) {
        _kPending    => 'A Fazer',
        _kInProgress => 'Em Andamento',
        _kCompleted  => 'Concluída',
        _            => task.status,
      };

  @override
  Widget build(BuildContext context) {
    final area =
        kAreas.where((a) => a.id == task.areaId).firstOrNull;
    final areaIdx =
        area == null ? 0 : kAreas.indexOf(area);
    final areaColor = AppTheme.areaColors[areaIdx % AppTheme.areaColors.length];

    final fmt = DateFormat('dd/MM/yy', 'pt_BR');
    final dateLabel = task.status == _kCompleted && task.completedAt != null
        ? '✅ ${fmt.format(task.completedAt!)}'
        : '🗓 ${fmt.format(task.createdAt)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: _statusColor, width: 4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      decoration: task.status == _kCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
                if (task.isMIT) ...[
                  const SizedBox(width: 6),
                  const Text('⭐',
                      style: TextStyle(fontSize: 12)),
                ],
                if (task.isFromCalendar) ...[
                  const SizedBox(width: 4),
                  const Text('🗓️',
                      style: TextStyle(fontSize: 12)),
                ],
              ],
            ),
            const SizedBox(height: 6),
            // Meta row
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                // Status pill
                _MicroBadge(
                  text: _statusLabel,
                  color: _statusColor,
                ),
                // Area badge
                if (area != null)
                  _MicroBadge(
                    text: '${area.icon} ${area.name}',
                    color: areaColor,
                  ),
                // Quadrant badge
                _MicroBadge(
                  text: '${task.eisenhowerEmoji} ${task.eisenhowerLabel}',
                  color: _quadrantColor(task.eisenhowerQ),
                ),
                // Date
                Text(
                  dateLabel,
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
  }

  Color _quadrantColor(int q) => switch (q) {
        1 => const Color(0xFFEF4444),
        2 => const Color(0xFF10B981),
        3 => const Color(0xFFF59E0B),
        _ => const Color(0xFF6B7280),
      };
}

class _MicroBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _MicroBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Seção: Estado vazio ───────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final L10n l10n;
  const _EmptyState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.search_off_outlined,
              size: 48, color: AppTheme.textSecondary),
          const SizedBox(height: 12),
          Text(
            l10n.noTasksFound,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Seção: Gráfico de barras por área ─────────────────────────────────────────

class _AreaChart extends StatelessWidget {
  final TasksProvider tp;
  final L10n l10n;
  const _AreaChart({required this.tp, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final counts  = tp.taskCountByArea();
    if (counts.isEmpty) return const SizedBox.shrink();

    final maxVal = counts.values.reduce(math.max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.bar_chart_outlined,
            label: l10n.byArea,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (_, constraints) {
              return Column(
                children: kAreas.map((area) {
                  final count = counts[area.id] ?? 0;
                  if (count == 0) return const SizedBox.shrink();
                  final areaIdx = kAreas.indexOf(area);
                  final color = AppTheme.areaColors[areaIdx];
                  final barFraction = count / maxVal;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        // Area label
                        SizedBox(
                          width: 28,
                          child: Text(
                            area.icon,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 80,
                          child: Text(
                            area.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Bar
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Stack(
                              children: [
                                // Track
                                Container(
                                  height: 10,
                                  color: AppTheme.surfaceHigh,
                                ),
                                // Fill
                                FractionallySizedBox(
                                  widthFactor: barFraction,
                                  child: Container(
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Count
                        SizedBox(
                          width: 20,
                          child: Text(
                            '$count',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Seção: Grid por quadrante Eisenhower ──────────────────────────────────────

class _QuadrantGrid extends StatelessWidget {
  final TasksProvider tp;
  final L10n l10n;
  const _QuadrantGrid({required this.tp, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final dist = tp.activeTasksByQuadrant;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.grid_view_outlined,
            label: '${l10n.byQuadrant} (tarefas ativas)',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _QuadrantCell(
                        q: 1,
                        count: dist[1]!,
                        label: 'Faça Agora',
                        color: const Color(0xFFEF4444)),
                    const SizedBox(height: 8),
                    _QuadrantCell(
                        q: 3,
                        count: dist[3]!,
                        label: 'Delegue',
                        color: const Color(0xFFF59E0B)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: [
                    _QuadrantCell(
                        q: 2,
                        count: dist[2]!,
                        label: 'Agende',
                        color: const Color(0xFF10B981)),
                    const SizedBox(height: 8),
                    _QuadrantCell(
                        q: 4,
                        count: dist[4]!,
                        label: 'Elimine',
                        color: const Color(0xFF6B7280)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Legend row
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: const [
              _QLabel(color: Color(0xFFEF4444), text: '🔴 Urgente + Importante'),
              _QLabel(color: Color(0xFF10B981), text: '🟢 Não Urgente + Importante'),
              _QLabel(color: Color(0xFFF59E0B), text: '🟡 Urgente + Não Importante'),
              _QLabel(color: Color(0xFF6B7280), text: '⚫ Não Urgente + Não Importante'),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuadrantCell extends StatelessWidget {
  final int q;
  final int count;
  final String label;
  final Color color;
  const _QuadrantCell({
    required this.q,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _QLabel extends StatelessWidget {
  final Color color;
  final String text;
  const _QLabel({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        color: AppTheme.textSecondary,
      ),
    );
  }
}

// ── Widgets de suporte ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppTheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _StatRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ── CustomPainter: Anel de conclusão ─────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  final double progress; // 0.0 a 1.0
  final Color fillColor;
  final Color trackColor;

  const _DonutPainter({
    required this.progress,
    required this.fillColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center   = Offset(size.width / 2, size.height / 2);
    final radius   = (math.min(size.width, size.height) - 18) / 2;
    const strokeW  = 12.0;
    const startAngle = -math.pi / 2;

    // Track (fundo)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi * 2,
      false,
      Paint()
        ..style       = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..color       = trackColor,
    );

    // Arco de progresso
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        math.pi * 2 * progress.clamp(0.0, 1.0),
        false,
        Paint()
          ..style       = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap   = StrokeCap.round
          ..color       = fillColor,
      );
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress || old.fillColor != fillColor;
}
