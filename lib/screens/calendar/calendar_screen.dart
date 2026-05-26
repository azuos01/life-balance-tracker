import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/calendar_event_model.dart';
import '../../providers/calendar_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import 'event_form_screen.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarProvider>(
      builder: (context, cp, _) {
        return AppBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text('Agenda'),
              actions: [
                if (cp.isAuthorized)
                  IconButton(
                    icon: const Icon(Icons.refresh_outlined),
                    tooltip: 'Atualizar',
                    onPressed: cp.isLoading ? null : cp.loadEvents,
                  ),
              ],
            ),
            body: cp.isAuthorized
                ? _CalendarBody(cp: cp)
                : _UnauthorizedView(cp: cp),
            floatingActionButton: cp.isAuthorized
                ? FloatingActionButton.extended(
                    onPressed: () => _openForm(context, cp),
                    backgroundColor: AppTheme.primary,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Novo compromisso',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  Future<void> _openForm(BuildContext context, CalendarProvider cp) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EventFormScreen(initialDate: cp.selectedDate),
      ),
    );
    if (result == true) {
      cp.loadEvents();
    }
  }
}

// ── Corpo principal ────────────────────────────────────────────────────────────

class _CalendarBody extends StatelessWidget {
  final CalendarProvider cp;
  _CalendarBody({required this.cp});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MonthHeader(cp: cp),
        _WeekdayLabels(),
        _MonthGrid(cp: cp),
        Divider(height: 1, color: AppTheme.divider),
        Expanded(child: _DayEventsList(cp: cp)),
        if (cp.isLoading)
          LinearProgressIndicator(
            backgroundColor: AppTheme.surface,
            color: AppTheme.primary,
          ),
      ],
    );
  }
}

// ── Cabeçalho de navegação por mês ───────────────────────────────────────────

class _MonthHeader extends StatelessWidget {
  final CalendarProvider cp;
  _MonthHeader({required this.cp});

  static const _months = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ];

  @override
  Widget build(BuildContext context) {
    final m = cp.viewMonth;
    return Padding(
      padding: EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: cp.isLoading ? null : cp.prevMonth,
            icon: Icon(Icons.chevron_left, color: AppTheme.textPrimary),
          ),
          Text(
            '${_months[m.month - 1]} ${m.year}',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            onPressed: cp.isLoading ? null : cp.nextMonth,
            icon: Icon(Icons.chevron_right, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}

// ── Labels de dias da semana ──────────────────────────────────────────────────

class _WeekdayLabels extends StatelessWidget {
  static const _labels = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: _labels
            .map((l) => Expanded(
                  child: Center(
                    child: Text(
                      l,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: l == 'Dom' || l == 'Sáb'
                            ? AppTheme.textSecondary.withOpacity(0.7)
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ── Grid do mês ───────────────────────────────────────────────────────────────

class _MonthGrid extends StatelessWidget {
  final CalendarProvider cp;
  const _MonthGrid({required this.cp});

  @override
  Widget build(BuildContext context) {
    final vm = cp.viewMonth;
    // Primeiro dia do mês (0=Mon … 6=Sun em DateTime.weekday)
    // Queremos domingo como coluna 0: (weekday % 7) onde Sun=7→0, Mon=1→1 …
    final firstDay = DateTime(vm.year, vm.month, 1);
    final startOffset = firstDay.weekday % 7; // Dom=0, Seg=1 … Sáb=6
    final daysInMonth = DateUtils.getDaysInMonth(vm.year, vm.month);

    final today = DateTime.now();
    final cells = startOffset + daysInMonth;
    final rows = (cells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: List.generate(rows, (row) {
          return Row(
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final dayNum = cellIndex - startOffset + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const Expanded(child: SizedBox(height: 44));
              }
              final date = DateTime(vm.year, vm.month, dayNum);
              final isToday = DateUtils.isSameDay(date, today);
              final isSelected =
                  DateUtils.isSameDay(date, cp.selectedDate);
              final hasEvents = cp.hasEventsOnDate(date);

              return Expanded(
                child: GestureDetector(
                  onTap: () => cp.selectDate(date),
                  child: Container(
                    height: 44,
                    margin: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary
                          : isToday
                              ? AppTheme.primary.withOpacity(0.15)
                              : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNum',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isToday || isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isSelected
                                ? Colors.white
                                : isToday
                                    ? AppTheme.primary
                                    : col == 0 || col == 6
                                        ? AppTheme.textSecondary
                                        : AppTheme.textPrimary,
                          ),
                        ),
                        if (hasEvents)
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.8)
                                  : AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }
}

// ── Lista de eventos do dia selecionado ───────────────────────────────────────

class _DayEventsList extends StatelessWidget {
  final CalendarProvider cp;
  _DayEventsList({required this.cp});

  static const _weekdays = [
    '', 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'
  ];
  static const _months = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez'
  ];

  String _fmtDay(DateTime d) =>
      '${_weekdays[d.weekday]}, ${d.day} de ${_months[d.month - 1]}';

  @override
  Widget build(BuildContext context) {
    final events = cp.selectedDateEvents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Text(
            _fmtDay(cp.selectedDate),
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ),
        Expanded(
          child: events.isEmpty
              ? _EmptyDay()
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(12, 0, 12, 80),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => SizedBox(height: 6),
                  itemBuilder: (context, i) => _EventTile(
                    event: events[i],
                    cp: cp,
                  ),
                ),
        ),
      ],
    );
  }
}

class _EmptyDay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 40,
            color: AppTheme.textSecondary.withOpacity(0.4),
          ),
          SizedBox(height: 10),
          Text(
            'Nenhum compromisso',
            style: TextStyle(
              color: AppTheme.textSecondary.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final CalendarEventModel event;
  final CalendarProvider cp;
  _EventTile({required this.event, required this.cp});

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openEdit(context),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            // Color accent bar
            Container(
              width: 3,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: 12),
            // Event info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        event.isAllDay
                            ? Icons.wb_sunny_outlined
                            : Icons.access_time_outlined,
                        size: 12,
                        color: AppTheme.textSecondary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        event.isAllDay
                            ? 'Dia inteiro'
                            : '${_fmtTime(event.start)} – ${_fmtTime(event.end)}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      if (event.location.isNotEmpty) ...[
                        SizedBox(width: 8),
                        Icon(Icons.location_on_outlined,
                            size: 12, color: AppTheme.textSecondary),
                        SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            event.location,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                size: 18, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Future<void> _openEdit(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EventFormScreen(existingEvent: event),
      ),
    );
    if (result == true) {
      cp.loadEvents();
    }
  }
}

// ── Estado não-autorizado ────────────────────────────────────────────────────

class _UnauthorizedView extends StatelessWidget {
  final CalendarProvider cp;
  const _UnauthorizedView({required this.cp});

  @override
  Widget build(BuildContext context) {
    if (!cp.isGoogleUser) {
      return _InfoCard(
        icon: Icons.account_circle_outlined,
        title: 'Login com Google necessário',
        subtitle:
            'Para acessar a Agenda, entre com uma conta Google. Isso permite sincronizar seus compromissos com o Google Calendar.',
        buttonLabel: null,
        onButton: null,
      );
    }

    // É Google user mas não tem token
    return _InfoCard(
      icon: Icons.calendar_month_outlined,
      title: 'Conectar Google Calendar',
      subtitle:
          'Autorize o acesso à sua agenda do Google para visualizar, criar e editar compromissos diretamente no app.',
      buttonLabel: cp.isLoading ? 'Conectando…' : 'Autorizar acesso',
      onButton: cp.isLoading
          ? null
          : () async {
              final ok = await cp.requestAccess();
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Não foi possível obter acesso ao Google Calendar. Tente novamente.'),
                  ),
                );
              }
            },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onButton;

  _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onButton,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
              ),
              child: Icon(icon, size: 38, color: Colors.white),
            ),
            SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonLabel != null) ...[
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onButton,
                  icon: const Icon(Icons.open_in_browser,
                      color: Colors.white, size: 18),
                  label: Text(
                    buttonLabel!,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}