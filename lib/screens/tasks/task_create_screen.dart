import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/task_model.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/area_classifier.dart';
import '../../constants/app_constants.dart';
import '../../theme/app_theme.dart';

class TaskCreateScreen extends StatefulWidget {
  final TaskModel? existingTask; // null = criação, non-null = edição

  const TaskCreateScreen({super.key, this.existingTask});

  @override
  State<TaskCreateScreen> createState() => _TaskCreateScreenState();
}

class _TaskCreateScreenState extends State<TaskCreateScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool _isUrgent = false;
  bool _isImportant = true;
  bool _isMIT = false;
  String _areaId = 'career';
  String _autoAreaId = 'career'; // sugerido pelo classificador
  DateTime? _dueDate;

  final List<_SubtaskEntry> _subtasks = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.existingTask;
    if (t != null) {
      _titleCtrl.text = t.title;
      _descCtrl.text = t.description;
      _isUrgent = t.eisenhowerQ == 1 || t.eisenhowerQ == 3;
      _isImportant = t.eisenhowerQ == 1 || t.eisenhowerQ == 2;
      _isMIT = t.isMIT;
      _areaId = t.areaId;
      _autoAreaId = t.areaId;
      _dueDate = t.dueDate;
      for (final s in t.subtasks) {
        _subtasks.add(_SubtaskEntry(
          id: s.id,
          titleCtrl: TextEditingController(text: s.title),
          hours: s.estimatedHours,
        ));
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    for (final s in _subtasks) {
      s.titleCtrl.dispose();
    }
    super.dispose();
  }

  int get _eisenhowerQ {
    if (_isUrgent && _isImportant) return 1;
    if (!_isUrgent && _isImportant) return 2;
    if (_isUrgent && !_isImportant) return 3;
    return 4;
  }

  void _onTitleChanged(String v) {
    final suggested = AreaClassifier.instance.classify(v, _descCtrl.text);
    setState(() {
      _autoAreaId = suggested;
      // só atualiza a área se o usuário não mudou manualmente
      if (_areaId == _autoAreaId || widget.existingTask == null) {
        _areaId = suggested;
      }
    });
  }

  void _addSubtask() {
    setState(() {
      _subtasks.add(_SubtaskEntry(
        id: const Uuid().v4(),
        titleCtrl: TextEditingController(),
        hours: 4,
      ));
    });
  }

  void _removeSubtask(int index) {
    setState(() {
      _subtasks[index].titleCtrl.dispose();
      _subtasks.removeAt(index);
    });
  }

  String? _validateSubtasks() {
    for (final s in _subtasks) {
      if (s.titleCtrl.text.trim().isEmpty) {
        return 'Preencha o título de todas as subtarefas.';
      }
      if (s.hours < 2 || s.hours > 8) {
        return 'Cada subtarefa deve ter entre 2 e 8 horas estimadas.';
      }
    }
    return null;
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o título da tarefa.')),
      );
      return;
    }

    final subError = _validateSubtasks();
    if (subError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(subError)));
      return;
    }

    final tasksProvider = context.read<TasksProvider>();
    if (_isMIT && !tasksProvider.canAddMIT) {
      // verifica se já tem 3 MITs (exceto a própria tarefa sendo editada)
      final existingMITId = widget.existingTask?.id;
      final mitCount = tasksProvider.activeMITs
          .where((t) => t.id != existingMITId)
          .length;
      if (mitCount >= 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Você já tem 3 tarefas MIT. Remova uma antes de adicionar outra.'),
          ),
        );
        return;
      }
    }

    setState(() => _saving = true);

    final userId = context.read<UserProvider>().user?.id ?? 'demo';
    final subtasks = _subtasks
        .map((s) => SubtaskModel(
              id: s.id,
              title: s.titleCtrl.text.trim(),
              estimatedHours: s.hours,
            ))
        .toList();

    final existing = widget.existingTask;
    final task = TaskModel(
      id: existing?.id ?? const Uuid().v4(),
      userId: userId,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      areaId: _areaId,
      eisenhowerQ: _eisenhowerQ,
      isMIT: _isMIT,
      mitOrder: existing?.mitOrder ?? 0,
      status: existing?.status ?? 'pending',
      dueDate: _dueDate,
      subtasks: subtasks,
      createdAt: existing?.createdAt ?? DateTime.now(),
      completedAt: existing?.completedAt,
    );

    if (existing != null) {
      await tasksProvider.updateTask(task);
    } else {
      await tasksProvider.addTask(task);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final areaConfig = kAreas.firstWhere(
      (a) => a.id == _areaId,
      orElse: () => kAreas.first,
    );
    final canMIT = context.watch<TasksProvider>().canAddMIT ||
        (widget.existingTask?.isMIT ?? false);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingTask == null ? 'Nova Tarefa' : 'Editar Tarefa'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Título ─────────────────────────────────────────────────────
            TextField(
              controller: _titleCtrl,
              onChanged: _onTitleChanged,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                labelText: 'Título da tarefa *',
                hintText: 'Ex: Preparar apresentação do trimestre',
              ),
            ),
            const SizedBox(height: 12),

            // ── Descrição ──────────────────────────────────────────────────
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
              ),
            ),
            const SizedBox(height: 20),

            // ── Matriz de Eisenhower ───────────────────────────────────────
            _SectionLabel(
              icon: '⚡',
              title: 'Matriz de Eisenhower',
              subtitle: 'Classifique a urgência e importância',
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _ToggleChip(
                  label: 'Urgente',
                  selected: _isUrgent,
                  activeColor: Colors.orange,
                  onTap: () => setState(() => _isUrgent = !_isUrgent),
                ),
                const SizedBox(width: 10),
                _ToggleChip(
                  label: 'Importante',
                  selected: _isImportant,
                  activeColor: AppTheme.primary,
                  onTap: () => setState(() => _isImportant = !_isImportant),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _EisenhowerBadge(q: _eisenhowerQ),
            const SizedBox(height: 20),

            // ── Área da Vida ───────────────────────────────────────────────
            _SectionLabel(
              icon: '🎯',
              title: 'Área da Vida',
              subtitle: 'Auto-sugerido: ${kAreas.firstWhere((a) => a.id == _autoAreaId, orElse: () => kAreas.first).name}',
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _areaId,
                  isExpanded: true,
                  dropdownColor: AppTheme.surface,
                  onChanged: (v) => setState(() => _areaId = v!),
                  items: kAreas.map((a) {
                    return DropdownMenuItem(
                      value: a.id,
                      child: Row(
                        children: [
                          Text(a.icon),
                          const SizedBox(width: 8),
                          Text(
                            a.name,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          if (a.id == _autoAreaId) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'sugerido',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── MIT ─────────────────────────────────────────────────────────
            _SectionLabel(
              icon: '⭐',
              title: 'MIT — Tarefa Mais Importante',
              subtitle: 'Máx. 3 MITs simultâneos',
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                if (!canMIT && !_isMIT) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Limite de 3 MITs atingido. Conclua ou remova uma antes.'),
                    ),
                  );
                  return;
                }
                setState(() => _isMIT = !_isMIT);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isMIT
                      ? AppTheme.accent.withOpacity(0.12)
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isMIT
                        ? AppTheme.accent.withOpacity(0.5)
                        : AppTheme.divider,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isMIT ? Icons.star : Icons.star_outline,
                      color: _isMIT ? AppTheme.accent : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isMIT ? 'É uma tarefa MIT' : 'Marcar como MIT',
                            style: TextStyle(
                              color: _isMIT
                                  ? AppTheme.accent
                                  : AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'MIT = Most Important Task. Foco total nela hoje.',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Data de prazo ───────────────────────────────────────────────
            _SectionLabel(icon: '📅', title: 'Prazo', subtitle: 'Opcional'),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppTheme.primary,
                        onPrimary: Colors.white,
                        surface: AppTheme.surface,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: AppTheme.textSecondary, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      _dueDate != null
                          ? '${_dueDate!.day.toString().padLeft(2, '0')}/${_dueDate!.month.toString().padLeft(2, '0')}/${_dueDate!.year}'
                          : 'Selecionar data de prazo',
                      style: TextStyle(
                        color: _dueDate != null
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    if (_dueDate != null) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _dueDate = null),
                        child: const Icon(Icons.close,
                            size: 16, color: AppTheme.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Subtarefas ──────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionLabel(
                  icon: '📋',
                  title: 'Subtarefas',
                  subtitle: 'Cada uma: 2–8 horas',
                ),
                TextButton.icon(
                  onPressed: _addSubtask,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Adicionar'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                  ),
                ),
              ],
            ),
            if (_subtasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Quebre a tarefa em etapas de 2–8 horas para facilitar a execução.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ..._subtasks.asMap().entries.map((e) {
              final i = e.key;
              final s = e.value;
              return _SubtaskEditor(
                key: ValueKey(s.id),
                entry: s,
                onRemove: () => _removeSubtask(i),
                onChanged: () => setState(() {}),
              );
            }),
            if (_subtasks.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  'Total estimado: ${_subtasks.fold(0, (sum, s) => sum + s.hours)}h',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 32),

            // ── Botão salvar ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.existingTask == null
                            ? 'Criar Tarefa'
                            : 'Salvar Alterações',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Eisenhower Badge ──────────────────────────────────────────────────────────

class _EisenhowerBadge extends StatelessWidget {
  final int q;
  const _EisenhowerBadge({required this.q});

  @override
  Widget build(BuildContext context) {
    final (label, desc, color) = switch (q) {
      1 => ('🔴 Q1 — Faça Agora', 'Urgente + Importante', Colors.red),
      2 => ('🟢 Q2 — Agende', 'Não Urgente + Importante', Colors.green),
      3 => ('🟡 Q3 — Delegue', 'Urgente + Não Importante', Colors.orange),
      _ => ('⚫ Q4 — Elimine', 'Não Urgente + Não Importante',
          Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: color, fontSize: 13)),
          const SizedBox(width: 8),
          Text(desc,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;

  const _SectionLabel(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    fontSize: 14)),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ],
    );
  }
}

// ── Toggle Chip ───────────────────────────────────────────────────────────────

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? activeColor.withOpacity(0.15) : AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? activeColor.withOpacity(0.6) : AppTheme.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? activeColor : AppTheme.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Subtask Entry (data model) ─────────────────────────────────────────────────

class _SubtaskEntry {
  final String id;
  final TextEditingController titleCtrl;
  int hours;

  _SubtaskEntry({required this.id, required this.titleCtrl, required this.hours});
}

// ── Subtask Editor Widget ─────────────────────────────────────────────────────

class _SubtaskEditor extends StatefulWidget {
  final _SubtaskEntry entry;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _SubtaskEditor({
    super.key,
    required this.entry,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_SubtaskEditor> createState() => _SubtaskEditorState();
}

class _SubtaskEditorState extends State<_SubtaskEditor> {
  @override
  Widget build(BuildContext context) {
    final h = widget.entry.hours;
    final Color hoursColor = h < 2 || h > 8
        ? Colors.red
        : h <= 4
            ? Colors.green
            : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.entry.titleCtrl,
                  onChanged: (_) => widget.onChanged(),
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Título da subtarefa',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onRemove,
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: AppTheme.textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Estimativa: ',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
              IconButton(
                onPressed: h > 1
                    ? () {
                        setState(() => widget.entry.hours--);
                        widget.onChanged();
                      }
                    : null,
                icon: const Icon(Icons.remove_circle_outline, size: 18),
                color: AppTheme.textSecondary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              Text(
                '${h}h',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: hoursColor,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: h < 16
                    ? () {
                        setState(() => widget.entry.hours++);
                        widget.onChanged();
                      }
                    : null,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                color: AppTheme.textSecondary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              if (h < 2)
                const Text('⚠️ Muito curta',
                    style: TextStyle(fontSize: 10, color: Colors.red))
              else if (h > 8)
                const Text('⚠️ Quebre em partes',
                    style: TextStyle(fontSize: 10, color: Colors.orange))
              else
                Text('✓ Dentro do ideal (2–8h)',
                    style: TextStyle(fontSize: 10, color: Colors.green[400])),
            ],
          ),
        ],
      ),
    );
  }
}
