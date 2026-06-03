import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/task_model.dart';
import '../../providers/tasks_provider.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_l10n.dart';
import '../tasks/task_detail_sheet.dart';

// ── Enums e constantes ────────────────────────────────────────────────────────

const _kAll        = 'all';
const _kPending    = 'pending';
const _kInProgress = 'in_progress';
const _kCompleted  = 'completed';

enum _Period { week, month, quarter, semester, year, total }

// ── Tela principal ────────────────────────────────────────────────────────────

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with AutomaticKeepAliveClientMixin {
  // Preserva o estado (filtro + período) ao trocar de aba no TabBarView
  @override
  bool get wantKeepAlive => true;

  String _statusFilter = _kAll;
  _Period _period      = _Period.total;
  int     _year        = DateTime.now().year;

  // ── Janela de datas do período selecionado ────────────────────────────────
  ({DateTime? from, DateTime? to}) get _window {
    final now = DateTime.now();
    return switch (_period) {
      _Period.week     => (from: now.subtract(const Duration(days: 7)), to: null),
      _Period.month    => (from: now.subtract(const Duration(days: 30)), to: null),
      _Period.quarter  => (from: now.subtract(const Duration(days: 90)), to: null),
      _Period.semester => (from: now.subtract(const Duration(days: 180)), to: null),
      _Period.year     => (
          from: DateTime(_year),
          to: DateTime(_year + 1),
        ),
      _Period.total    => (from: null, to: null),
    };
  }

  // ── Lista filtrada por status ──────────────────────────────────────────────
  List<TaskModel> _filtered(TasksProvider tp) {
    var list = tp.tasks.toList();
    if (_statusFilter != _kAll) {
      list = list.where((t) => t.status == _statusFilter).toList();
    }
    list.sort((a, b) {
      const ord = {_kPending: 0, _kInProgress: 1, _kCompleted: 2};
      final cmp = (ord[a.status] ?? 0).compareTo(ord[b.status] ?? 0);
      return cmp != 0 ? cmp : b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // obrigatório para AutomaticKeepAliveClientMixin
    final tp    = context.watch<TasksProvider>();
    final l10n  = context.l10n;
    final tasks = _filtered(tp);
    final win   = _window;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── 1. KPIs ───────────────────────────────────────────────────────
          _KpiRow(tp: tp, l10n: l10n),
          const SizedBox(height: 16),

          // ── 2. Anel de conclusão + seletor de período ─────────────────────
          _ProgressSection(
            tp: tp,
            l10n: l10n,
            period: _period,
            selectedYear: _year,
            window: win,
            onPeriodChanged: (p) => setState(() => _period = p),
            onYearChanged:   (y) => setState(() => _year   = y),
          ),
          const SizedBox(height: 16),

          // ── 3. Origem (Manual vs Agenda) ──────────────────────────────────
          _OriginRow(tp: tp, l10n: l10n),
          const SizedBox(height: 24),

          // ── 4. Filtro por status ──────────────────────────────────────────
          _StatusFilterRow(
            selected: _statusFilter,
            tp: tp,
            onChanged: (v) => setState(() => _statusFilter = v),
            l10n: l10n,
          ),
          const SizedBox(height: 10),

          // ── 5. Lista de tarefas (filtrada) ────────────────────────────────
          if (tasks.isEmpty)
            _EmptyState(l10n: l10n)
          else
            ...tasks.map((t) => _TaskCard(task: t)),

          const SizedBox(height: 28),

          // ── 6. Distribuição por área ──────────────────────────────────────
          _AreaChart(tp: tp, l10n: l10n),
          const SizedBox(height: 28),

          // ── 7. Distribuição por quadrante Eisenhower ──────────────────────
          _QuadrantGrid(tp: tp, l10n: l10n),
        ],
      ),
    );
  }
}

// ── KPI Row ───────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  final TasksProvider tp;
  final L10n l10n;
  const _KpiRow({required this.tp, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _KpiCard(label: 'Total',           value: tp.totalTasks,     color: AppTheme.primary,          icon: Icons.list_alt_outlined),
      const SizedBox(width: 8),
      _KpiCard(label: l10n.toDo,         value: tp.pendingCount,   color: const Color(0xFF3B82F6),   icon: Icons.radio_button_unchecked),
      const SizedBox(width: 8),
      _KpiCard(label: l10n.inProgressLabel, value: tp.inProgressCount, color: AppTheme.accentGold,  icon: Icons.autorenew_outlined),
      const SizedBox(width: 8),
      _KpiCard(label: l10n.completedLabel, value: tp.completedCount, color: const Color(0xFF10B981), icon: Icons.check_circle_outline),
    ]);
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  const _KpiCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border(top: BorderSide(color: color, width: 3)),
        ),
        child: Column(children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(height: 5),
          Text(
            '$value',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color, height: 1),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
          ),
        ]),
      ),
    );
  }
}

// ── Seção de progresso + seletor de período ───────────────────────────────────

class _ProgressSection extends StatelessWidget {
  final TasksProvider tp;
  final L10n l10n;
  final _Period period;
  final int selectedYear;
  final ({DateTime? from, DateTime? to}) window;
  final ValueChanged<_Period> onPeriodChanged;
  final ValueChanged<int> onYearChanged;

  const _ProgressSection({
    required this.tp,
    required this.l10n,
    required this.period,
    required this.selectedYear,
    required this.window,
    required this.onPeriodChanged,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    final from = window.from;
    final to   = window.to;

    final completedN = from == null
        ? tp.completedCount
        : tp.completedInPeriod(from, to: to);
    final createdN = from == null
        ? tp.totalTasks
        : tp.createdInPeriod(from, to: to);
    final rate = createdN == 0 ? 0.0 : completedN / createdN;
    final pct  = (rate * 100).round();
    final avg  = tp.avgCompletionTime;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionHeader(icon: Icons.donut_large_outlined, label: l10n.completionRateLbl),
        const SizedBox(height: 12),

        // ── Chips de período ──────────────────────────────────────────────────
        _PeriodChips(
          selected: period,
          selectedYear: selectedYear,
          years: tp.taskYears,
          onPeriodChanged: onPeriodChanged,
          onYearChanged: onYearChanged,
        ),
        const SizedBox(height: 16),

        // ── Anel + stats ──────────────────────────────────────────────────────
        Row(children: [
          // Donut
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
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    '$pct%',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, height: 1),
                  ),
                  Text(l10n.completedLabel, style: TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Stats
          Expanded(
            child: Column(children: [
              _StatRow(
                icon: Icons.check_circle,
                color: const Color(0xFF10B981),
                label: '${l10n.completedLabel} (período)',
                value: '$completedN',
              ),
              const SizedBox(height: 9),
              _StatRow(
                icon: Icons.add_circle_outline,
                color: const Color(0xFF3B82F6),
                label: 'Criadas (período)',
                value: '$createdN',
              ),
              const SizedBox(height: 9),
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
            ]),
          ),
        ]),
      ]),
    );
  }
}

// ── Chips de seleção de período ───────────────────────────────────────────────

class _PeriodChips extends StatelessWidget {
  final _Period selected;
  final int selectedYear;
  final List<int> years;
  final ValueChanged<_Period> onPeriodChanged;
  final ValueChanged<int> onYearChanged;

  const _PeriodChips({
    required this.selected,
    required this.selectedYear,
    required this.years,
    required this.onPeriodChanged,
    required this.onYearChanged,
  });

  static const _labels = {
    _Period.week:     'Semana',
    _Period.month:    'Mês',
    _Period.quarter:  'Trimestre',
    _Period.semester: 'Semestre',
    _Period.year:     'Ano',
    _Period.total:    'Total',
  };

  @override
  Widget build(BuildContext context) {
    final minYear = years.isEmpty ? DateTime.now().year : years.last;
    final maxYear = DateTime.now().year;

    // ⚠️ Wrap + InkWell em vez de ListView + GestureDetector
    //    (evita conflito de gestos com o SingleChildScrollView externo)
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: _Period.values.map((p) {
          final active = selected == p;
          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onPeriodChanged(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: active
                      ? AppTheme.primary.withOpacity(0.15)
                      : AppTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active ? AppTheme.primary : AppTheme.divider,
                    width: active ? 2 : 1,
                  ),
                ),
                child: Text(
                  _labels[p]!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                    color: active ? AppTheme.primary : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),

      // Seletor de ano (visível apenas quando _Period.year)
      if (selected == _Period.year) ...[
        const SizedBox(height: 8),
        Row(mainAxisSize: MainAxisSize.min, children: [
          _YearArrow(
            icon: Icons.chevron_left,
            enabled: selectedYear > minYear,
            onTap: () => onYearChanged(selectedYear - 1),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$selectedYear',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.primary),
            ),
          ),
          _YearArrow(
            icon: Icons.chevron_right,
            enabled: selectedYear < maxYear,
            onTap: () => onYearChanged(selectedYear + 1),
          ),
        ]),
      ],
    ]);
  }
}

class _YearArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _YearArrow({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(
          icon,
          size: 22,
          color: enabled ? AppTheme.primary : AppTheme.textSecondary.withOpacity(0.4),
        ),
      ),
    );
  }
}

// ── Origem das tarefas ────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(children: [
        Icon(Icons.source_outlined, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        Text(l10n.originLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
        const Spacer(),
        _OriginChip(label: l10n.userTasksLabel,   count: userCnt, total: total, color: AppTheme.primary,        icon: '✏️'),
        const SizedBox(width: 8),
        _OriginChip(label: l10n.calendarTasksLbl, count: calCnt,  total: total, color: const Color(0xFF3B82F6), icon: '🗓️'),
      ]),
    );
  }
}

class _OriginChip extends StatelessWidget {
  final String label, icon;
  final int count, total;
  final Color color;
  const _OriginChip({required this.label, required this.icon, required this.count, required this.total, required this.color});

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
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 5),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$count ($pct%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        ]),
      ]),
    );
  }
}

// ── Filtro de status com contadores ──────────────────────────────────────────
//
// ⚠️ NÃO usar ListView + GestureDetector aqui.
// O scroll horizontal do ListView absorve os taps antes do GestureDetector.
// Solução correta: Wrap + InkWell (sem scroll aninhado, sem conflito de gestos).

class _StatusFilterRow extends StatelessWidget {
  final String selected;
  final TasksProvider tp;
  final ValueChanged<String> onChanged;
  final L10n l10n;
  const _StatusFilterRow({
    required this.selected,
    required this.tp,
    required this.onChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final filters = <(String, String, int, Color)>[
      (_kAll,        l10n.allTasks,        tp.totalTasks,      const Color(0xFF8E8EBB)),
      (_kPending,    l10n.toDo,            tp.pendingCount,    const Color(0xFF3B82F6)),
      (_kInProgress, l10n.inProgressLabel, tp.inProgressCount, AppTheme.accentGold),
      (_kCompleted,  l10n.completedLabel,  tp.completedCount,  const Color(0xFF10B981)),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filters.map((f) {
        final (value, label, count, color) = f;
        final active = selected == value;
        return _StatusChipButton(
          label: label,
          count: count,
          color: color,
          active: active,
          onTap: () => onChanged(value),
        );
      }).toList(),
    );
  }
}

/// Chip de filtro de status — usa InkWell para garantir que o toque
/// seja registrado sem conflito com ScrollViews ao redor.
class _StatusChipButton extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _StatusChipButton({
    required this.label,
    required this.count,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.15) : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? color : AppTheme.divider,
              width: active ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (active)
                Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: Icon(Icons.check_circle, size: 13, color: color),
                ),
              Text(
                '$label  $count',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                  color: active ? color : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Card de tarefa (clicável → abre TaskDetailSheet) ─────────────────────────

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

  Color _quadrantColor(int q) => switch (q) {
        1 => const Color(0xFFEF4444),
        2 => const Color(0xFF10B981),
        3 => const Color(0xFFF59E0B),
        _ => const Color(0xFF6B7280),
      };

  @override
  Widget build(BuildContext context) {
    final area = kAreas.where((a) => a.id == task.areaId).firstOrNull;
    final areaIdx = area == null ? 0 : kAreas.indexOf(area);
    final areaColor = AppTheme.areaColors[areaIdx % AppTheme.areaColors.length];
    final fmt = DateFormat('dd/MM/yy', 'pt_BR');
    final dateLabel = task.status == _kCompleted && task.completedAt != null
        ? '✅ ${fmt.format(task.completedAt!)}'
        : '🗓 ${fmt.format(task.createdAt)}';

    return GestureDetector(
      onTap: () => showTaskDetailSheet(context, task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: _statusColor, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Título
            Row(children: [
              Expanded(
                child: Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    decoration: task.status == _kCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (task.isMIT) ...[const SizedBox(width: 4), const Text('⭐', style: TextStyle(fontSize: 12))],
              if (task.isFromCalendar) ...[const SizedBox(width: 4), const Text('🗓️', style: TextStyle(fontSize: 12))],
              if (task.hasLocation) ...[const SizedBox(width: 4), const Icon(Icons.location_on, size: 13, color: Color(0xFF10B981))],
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, size: 16),
            ]),
            const SizedBox(height: 6),
            // Badges
            Wrap(spacing: 6, runSpacing: 4, children: [
              _MicroBadge(text: _statusLabel,                              color: _statusColor),
              if (area != null)
                _MicroBadge(text: '${area.icon} ${area.name}',            color: areaColor),
              _MicroBadge(text: '${task.eisenhowerEmoji} ${task.eisenhowerLabel}', color: _quadrantColor(task.eisenhowerQ)),
              Text(dateLabel, style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            ]),
          ]),
        ),
      ),
    );
  }
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
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

// ── Estado vazio ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final L10n l10n;
  const _EmptyState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(children: [
        Icon(Icons.search_off_outlined, size: 48, color: AppTheme.textSecondary),
        const SizedBox(height: 12),
        Text(l10n.noTasksFound, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
      ]),
    );
  }
}

// ── Gráfico de barras por área ────────────────────────────────────────────────

class _AreaChart extends StatelessWidget {
  final TasksProvider tp;
  final L10n l10n;
  const _AreaChart({required this.tp, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final counts = tp.taskCountByArea();
    if (counts.isEmpty) return const SizedBox.shrink();
    final maxVal = counts.values.reduce(math.max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionHeader(icon: Icons.bar_chart_outlined, label: l10n.byArea),
        const SizedBox(height: 14),
        ...kAreas.map((area) {
          final count = counts[area.id] ?? 0;
          if (count == 0) return const SizedBox.shrink();
          final areaIdx = kAreas.indexOf(area);
          final color = AppTheme.areaColors[areaIdx];
          final fraction = count / maxVal;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              SizedBox(width: 26, child: Text(area.icon, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15))),
              const SizedBox(width: 6),
              SizedBox(
                width: 78,
                child: Text(area.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(children: [
                    Container(height: 10, color: AppTheme.surfaceHigh),
                    FractionallySizedBox(
                      widthFactor: fraction,
                      child: Container(height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                    ),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 20,
                child: Text('$count', textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
              ),
            ]),
          );
        }),
      ]),
    );
  }
}

// ── Grid por quadrante Eisenhower ─────────────────────────────────────────────

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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionHeader(icon: Icons.grid_view_outlined, label: '${l10n.byQuadrant} (ativas)'),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: Column(children: [
            _QCell(count: dist[1]!, label: 'Faça Agora',  color: const Color(0xFFEF4444)),
            const SizedBox(height: 8),
            _QCell(count: dist[3]!, label: 'Delegue',     color: const Color(0xFFF59E0B)),
          ])),
          const SizedBox(width: 8),
          Expanded(child: Column(children: [
            _QCell(count: dist[2]!, label: 'Agende',   color: const Color(0xFF10B981)),
            const SizedBox(height: 8),
            _QCell(count: dist[4]!, label: 'Elimine',  color: const Color(0xFF6B7280)),
          ])),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 10, runSpacing: 4, children: const [
          _QLegend(color: Color(0xFFEF4444), text: '🔴 Urgente + Importante'),
          _QLegend(color: Color(0xFF10B981), text: '🟢 Não Urgente + Importante'),
          _QLegend(color: Color(0xFFF59E0B), text: '🟡 Urgente + Não Importante'),
          _QLegend(color: Color(0xFF6B7280), text: '⚫ Não Urgente + Não Importante'),
        ]),
      ]),
    );
  }
}

class _QCell extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _QCell({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(children: [
        Text('$count', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color, height: 1)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color.withOpacity(0.8))),
      ]),
    );
  }
}

class _QLegend extends StatelessWidget {
  final Color color;
  final String text;
  const _QLegend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(fontSize: 10, color: AppTheme.textSecondary));
  }
}

// ── Widgets de suporte ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 15, color: AppTheme.primary),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
    ]);
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  const _StatRow({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 6),
      Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
    ]);
  }
}

// ── Donut painter ─────────────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  final double progress;
  final Color fillColor, trackColor;
  const _DonutPainter({required this.progress, required this.fillColor, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - 18) / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0, math.pi * 2, false,
      Paint()..style = PaintingStyle.stroke ..strokeWidth = 12 ..color = trackColor,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        math.pi * 2 * progress.clamp(0.0, 1.0),
        false,
        Paint()..style = PaintingStyle.stroke ..strokeWidth = 12 ..strokeCap = StrokeCap.round ..color = fillColor,
      );
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress || old.fillColor != fillColor;
}
