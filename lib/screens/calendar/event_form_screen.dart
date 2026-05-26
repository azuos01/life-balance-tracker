import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/calendar_event_model.dart';
import '../../providers/calendar_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';

class EventFormScreen extends StatefulWidget {
  final CalendarEventModel? existingEvent;
  final DateTime? initialDate;

  const EventFormScreen({super.key, this.existingEvent, this.initialDate});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late DateTime _startDate;
  late DateTime _endDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _isAllDay = false;
  bool _saving = false;

  bool get _isEditing => widget.existingEvent != null;

  @override
  void initState() {
    super.initState();
    final ev = widget.existingEvent;
    final base = widget.initialDate ?? DateTime.now();

    if (ev != null) {
      _titleCtrl.text = ev.title;
      _descCtrl.text = ev.description;
      _locationCtrl.text = ev.location;
      _startDate = ev.start;
      _endDate = ev.end;
      _startTime = TimeOfDay.fromDateTime(ev.start);
      _endTime = TimeOfDay.fromDateTime(ev.end);
      _isAllDay = ev.isAllDay;
    } else {
      _startDate = DateTime(base.year, base.month, base.day, 9);
      _endDate = DateTime(base.year, base.month, base.day, 10);
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 10, minute: 0);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(_isEditing ? 'Editar Compromisso' : 'Novo Compromisso'),
          actions: [
            if (_isEditing)
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red),
                onPressed: _confirmDelete,
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Título ─────────────────────────────────────────────────
                _SectionLabel('Título'),
                TextFormField(
                  controller: _titleCtrl,
                  style: TextStyle(
                      color: AppTheme.textPrimary, fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: 'Nome do compromisso',
                    prefixIcon: Icon(Icons.title, color: AppTheme.primary),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Informe o título' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // ── Dia inteiro ────────────────────────────────────────────
                _toggleAllDay(),
                const SizedBox(height: 16),

                // ── Data e hora de início ──────────────────────────────────
                _SectionLabel('Início'),
                Row(
                  children: [
                    Expanded(
                      child: _DateButton(
                        label: _fmtDate(_startDate),
                        onTap: () => _pickDate(isStart: true),
                      ),
                    ),
                    if (!_isAllDay) ...[
                      const SizedBox(width: 8),
                      _TimeButton(
                        label: _startTime.format(context),
                        onTap: () => _pickTime(isStart: true),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 10),

                // ── Data e hora de fim ─────────────────────────────────────
                _SectionLabel('Término'),
                Row(
                  children: [
                    Expanded(
                      child: _DateButton(
                        label: _fmtDate(_endDate),
                        onTap: () => _pickDate(isStart: false),
                      ),
                    ),
                    if (!_isAllDay) ...[
                      SizedBox(width: 8),
                      _TimeButton(
                        label: _endTime.format(context),
                        onTap: () => _pickTime(isStart: false),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 16),

                // ── Local ──────────────────────────────────────────────────
                _SectionLabel('Local (opcional)'),
                TextFormField(
                  controller: _locationCtrl,
                  style: TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Endereço ou link',
                    prefixIcon:
                        Icon(Icons.location_on_outlined, color: AppTheme.primary),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: 16),

                // ── Descrição ──────────────────────────────────────────────
                _SectionLabel('Descrição (opcional)'),
                TextFormField(
                  controller: _descCtrl,
                  style: TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Notas sobre o compromisso',
                    prefixIcon: Icon(Icons.notes_outlined,
                        color: AppTheme.primary),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 28),

                // ── Botão Salvar ───────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Icon(
                            _isEditing ? Icons.save_outlined : Icons.add,
                            color: Colors.white),
                    label: Text(
                      _isEditing ? 'Salvar alterações' : 'Criar compromisso',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Widgets auxiliares ────────────────────────────────────────────────────

  Widget _toggleAllDay() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.wb_sunny_outlined,
              size: 18, color: AppTheme.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Dia inteiro',
              style: TextStyle(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
            ),
          ),
          Switch(
            value: _isAllDay,
            onChanged: (v) => setState(() => _isAllDay = v),
            activeColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }

  // ── Pickers ───────────────────────────────────────────────────────────────

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppTheme.primary,
            onPrimary: Colors.white,
            surface: AppTheme.surface,
            onSurface: AppTheme.textPrimary,
          ),
          dialogBackgroundColor: AppTheme.surface,
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        // Ajusta end date se ficou antes do start
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = picked;
        if (_endDate.isBefore(_startDate)) _startDate = _endDate;
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppTheme.primary,
            onPrimary: Colors.white,
            surface: AppTheme.surface,
            onSurface: AppTheme.textPrimary,
          ),
          dialogBackgroundColor: AppTheme.surface,
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
        // Se end time ficou antes de start time no mesmo dia, avança 1h
        if (_sameDay(_startDate, _endDate)) {
          final startMins = picked.hour * 60 + picked.minute;
          final endMins = _endTime.hour * 60 + _endTime.minute;
          if (endMins <= startMins) {
            final newEnd = startMins + 60;
            _endTime = TimeOfDay(hour: newEnd ~/ 60, minute: newEnd % 60);
          }
        }
      } else {
        _endTime = picked;
      }
    });
  }

  // ── Save / Delete ─────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    DateTime buildDt(DateTime date, TimeOfDay time) =>
        DateTime(date.year, date.month, date.day, time.hour, time.minute);

    final start = _isAllDay ? _startDate : buildDt(_startDate, _startTime);
    final end = _isAllDay ? _endDate : buildDt(_endDate, _endTime);

    if (!_isAllDay && !end.isAfter(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('O horário de término deve ser após o início')),
      );
      return;
    }

    setState(() => _saving = true);

    final cp = context.read<CalendarProvider>();
    final event = CalendarEventModel(
      id: widget.existingEvent?.id,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      start: start,
      end: end,
      isAllDay: _isAllDay,
    );

    final ok = _isEditing
        ? await cp.updateEvent(event) != null
        : await cp.addEvent(event) != null;

    if (mounted) {
      setState(() => _saving = false);
      if (ok) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(cp.errorMessage ?? 'Erro ao salvar compromisso')),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Excluir compromisso?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('Esta ação não pode ser desfeita.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child:
                  const Text('Excluir', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _saving = true);
    final deleted = await context
        .read<CalendarProvider>()
        .deleteEvent(widget.existingEvent!.id!);
    if (mounted) {
      setState(() => _saving = false);
      if (deleted) Navigator.pop(context, true);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static const _months = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez'
  ];
  static const _weekdays = [
    '', 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'
  ];

  String _fmtDate(DateTime d) =>
      '${_weekdays[d.weekday]}, ${d.day} de ${_months[d.month - 1]} de ${d.year}';

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Componentes reutilizáveis ─────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  _DateButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 16, color: AppTheme.primary),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                    color: AppTheme.textPrimary, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  _TimeButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_outlined,
                size: 16, color: AppTheme.primary),
            SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: AppTheme.textPrimary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}