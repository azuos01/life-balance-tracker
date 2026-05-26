import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../models/calendar_event_model.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';
import '../constants/app_constants.dart';

const String _kTasksKey = 'tasks_data';
const String _kCalendarOverridesKey = 'calendar_task_overrides';

class TasksProvider extends ChangeNotifier {
  List<TaskModel> _tasks = [];

  /// Tarefas geradas automaticamente a partir de eventos do Google Calendar.
  /// Não são salvas no Firestore — reconstruídas a cada sync.
  List<TaskModel> _calendarTasks = [];

  /// Overrides mutáveis para tarefas de calendário (status, MIT, quadrante).
  /// Chave = calendarEventId (sem prefixo 'cal_'). Persistidos localmente.
  Map<String, Map<String, dynamic>> _calendarOverrides = {};

  String? _uid;
  bool _isCloud = false;
  String? _lastLoadedUid;

  // ── Lista combinada ───────────────────────────────────────────────────────

  List<TaskModel> get _allTasks => [..._tasks, ..._calendarTasks];

  List<TaskModel> get tasks => List.unmodifiable(_allTasks);

  // ── Queries ──────────────────────────────────────────────────────────────

  /// Tarefas MIT ativas ordenadas por mitOrder (1, 2, 3)
  List<TaskModel> get activeMITs => _allTasks
      .where((t) => t.isMIT && t.status != 'completed')
      .toList()
    ..sort((a, b) => a.mitOrder.compareTo(b.mitOrder));

  /// Número de MITs ativos (máx 3)
  int get mitCount => activeMITs.length;
  bool get canAddMIT => mitCount < 3;

  /// Tarefas ativas por quadrante Eisenhower
  List<TaskModel> byQuadrant(int q) => _allTasks
      .where((t) => t.eisenhowerQ == q && t.status != 'completed')
      .toList()
    ..sort((a, b) {
      if (a.isMIT != b.isMIT) return a.isMIT ? -1 : 1;
      return a.createdAt.compareTo(b.createdAt);
    });

  /// Todas as tarefas não concluídas (pending + in_progress)
  List<TaskModel> get pendingTasks =>
      _allTasks.where((t) => t.status != 'completed').toList();

  /// Tarefas planejadas (coluna Kanban "A Fazer")
  List<TaskModel> get plannedTasks => _allTasks
      .where((t) => t.status == 'pending')
      .toList()
    ..sort((a, b) {
      if (a.isMIT != b.isMIT) return a.isMIT ? -1 : 1;
      if (a.eisenhowerQ != b.eisenhowerQ) {
        return a.eisenhowerQ.compareTo(b.eisenhowerQ);
      }
      return a.createdAt.compareTo(b.createdAt);
    });

  /// Tarefas em execução (coluna Kanban "Em Progresso")
  List<TaskModel> get inProgressTasks => _allTasks
      .where((t) => t.status == 'in_progress')
      .toList()
    ..sort((a, b) {
      if (a.isMIT != b.isMIT) return a.isMIT ? -1 : 1;
      return a.createdAt.compareTo(b.createdAt);
    });

  /// Tarefas concluídas
  List<TaskModel> get completedTasks => _allTasks
      .where((t) => t.status == 'completed')
      .toList()
    ..sort((a, b) =>
        (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt));

  int get totalTasks => _allTasks.length;
  int get completedCount => completedTasks.length;

  // ── Inicialização ─────────────────────────────────────────────────────────

  void initLocal() {
    _loadLocal();
    _loadCalendarOverrides();
  }

  Future<void> init() async {
    initLocal();
  }

  /// Chamado pelo ProxyProvider toda vez que UserProvider notifica.
  void syncUser(String? uid, bool isCloud) {
    _uid = uid;
    _isCloud = isCloud;

    if (uid == null || !isCloud) {
      _lastLoadedUid = null;
      return;
    }

    if (uid != _lastLoadedUid) {
      _lastLoadedUid = uid;
      _loadFromCloud(uid);
    }
  }

  // ── Sincronização com calendário ──────────────────────────────────────────

  /// Reconstrói [_calendarTasks] a partir dos eventos próximos.
  /// Chamado pelo ProxyProvider2 quando CalendarProvider notifica.
  void syncCalendarTasks(
      List<CalendarEventModel> upcomingEvents, String userId) {
    final newCalendarTasks = <TaskModel>[];

    for (final event in upcomingEvents) {
      if (event.id == null) continue;

      final eventId = event.id!;
      final taskId = 'cal_$eventId';
      final ov = _calendarOverrides[eventId];

      final task = TaskModel(
        id: taskId,
        userId: userId,
        title: event.title,
        description: event.description.isNotEmpty
            ? event.description
            : (event.location.isNotEmpty ? '📍 ${event.location}' : ''),
        areaId: kAreas.first.id,
        eisenhowerQ: ov?['eisenhowerQ'] as int? ?? 2,
        isMIT: ov?['isMIT'] as bool? ?? false,
        mitOrder: ov?['mitOrder'] as int? ?? 0,
        status: ov?['status'] as String? ?? 'pending',
        dueDate: event.start,
        createdAt: event.start,
        completedAt: ov?['completedAt'] != null
            ? DateTime.tryParse(ov!['completedAt'] as String)
            : null,
        isFromCalendar: true,
        calendarEventId: eventId,
      );

      newCalendarTasks.add(task);
    }

    _calendarTasks = newCalendarTasks;
    _normalizeMITs();
    notifyListeners();
  }

  // ── Sincronização com Firestore ───────────────────────────────────────────

  Future<void> _loadFromCloud(String uid) async {
    final cloudTasks = await FirestoreService.instance.getTasks(uid);

    if (cloudTasks.isNotEmpty) {
      // Dados encontrados no Firestore → substitui tudo (local + memória)
      // Filtra tarefas de calendário que possam ter escapado para o Firestore
      _tasks = cloudTasks.where((t) => !t.isFromCalendar).toList();
      await _saveLocal();
    } else if (_tasks.isNotEmpty) {
      // Firestore vazio mas há dados locais em memória — migração.
      for (final task in _tasks) {
        await FirestoreService.instance.saveTask(uid, task);
      }
    }

    notifyListeners();
  }

  // ── Persistência ──────────────────────────────────────────────────────────

  void _loadLocal() {
    final saved = StorageService.instance.getJsonList(_kTasksKey);
    _tasks = saved
        .map((j) => TaskModel.fromJson(j))
        .where((t) => !t.isFromCalendar) // garante que não há tarefas de cal
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _loadCalendarOverrides() {
    final saved =
        StorageService.instance.getJsonList(_kCalendarOverridesKey);
    _calendarOverrides = {};
    for (final item in saved) {
      final key = item['calendarEventId'] as String?;
      if (key != null) {
        _calendarOverrides[key] = Map<String, dynamic>.from(item)
          ..remove('calendarEventId');
      }
    }
  }

  Future<void> _saveLocal() async {
    await StorageService.instance.setJsonList(
      _kTasksKey,
      _tasks.map((t) => t.toJson()).toList(),
    );
  }

  Future<void> _saveCalendarOverrides() async {
    final list = _calendarOverrides.entries
        .map((e) => {'calendarEventId': e.key, ...e.value})
        .toList();
    await StorageService.instance.setJsonList(_kCalendarOverridesKey, list);
  }

  Future<void> _persist(TaskModel task) async {
    await _saveLocal();
    if (_isCloud && _uid != null) {
      await FirestoreService.instance.saveTask(_uid!, task);
    }
  }

  // ── CRUD — tarefas do usuário ─────────────────────────────────────────────

  Future<void> addTask(TaskModel task) async {
    _tasks.insert(0, task);
    if (task.isMIT) _normalizeMITs();
    await _persist(task);
    notifyListeners();
  }

  Future<void> updateTask(TaskModel task) async {
    if (task.isFromCalendar) {
      _updateCalendarTaskOverride(task);
      return;
    }
    final i = _tasks.indexWhere((t) => t.id == task.id);
    if (i == -1) return;
    _tasks[i] = task;
    _normalizeMITs();
    await _persist(task);
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    // Tarefas de calendário não podem ser excluídas
    if (id.startsWith('cal_')) return;

    _tasks.removeWhere((t) => t.id == id);
    _normalizeMITs();
    await _saveLocal();
    if (_isCloud && _uid != null) {
      await FirestoreService.instance.deleteTask(_uid!, id);
    }
    notifyListeners();
  }

  /// Marca/desmarca uma tarefa como MIT.
  /// Respeita o limite de 3 MITs simultâneos (user + calendar).
  Future<bool> toggleMIT(String taskId) async {
    if (taskId.startsWith('cal_')) {
      return _toggleCalendarMIT(taskId);
    }

    final i = _tasks.indexWhere((t) => t.id == taskId);
    if (i == -1) return false;

    final task = _tasks[i];

    if (task.isMIT) {
      _tasks[i] = task.copyWith(isMIT: false, mitOrder: 0);
    } else {
      if (!canAddMIT) return false;
      _tasks[i] = task.copyWith(isMIT: true, mitOrder: mitCount + 1);
    }

    _normalizeMITs();
    await _persist(_tasks[i]);
    notifyListeners();
    return true;
  }

  /// Alterna o estado de uma subtarefa. Completa a tarefa pai se todas prontas.
  Future<void> toggleSubtask(String taskId, String subtaskId) async {
    if (taskId.startsWith('cal_')) return; // Tarefas de calendário não têm subtarefas

    final i = _tasks.indexWhere((t) => t.id == taskId);
    if (i == -1) return;

    final task = _tasks[i];
    final subtasks = task.subtasks.map((s) {
      if (s.id == subtaskId) {
        return SubtaskModel(
          id: s.id,
          title: s.title,
          estimatedHours: s.estimatedHours,
          isCompleted: !s.isCompleted,
          completedAt: !s.isCompleted ? DateTime.now() : null,
        );
      }
      return s;
    }).toList();

    final allDone =
        subtasks.isNotEmpty && subtasks.every((s) => s.isCompleted);

    _tasks[i] = task.copyWith(
      subtasks: subtasks,
      status: allDone ? 'completed' : task.status,
      completedAt: allDone ? DateTime.now() : task.completedAt,
    );

    if (allDone) _normalizeMITs();
    await _persist(_tasks[i]);
    notifyListeners();
  }

  /// Move tarefa de 'pending' para 'in_progress' (Kanban: Planejada → Em Execução)
  Future<void> moveToInProgress(String taskId) async {
    if (taskId.startsWith('cal_')) {
      return _updateCalendarStatus(taskId, 'in_progress');
    }
    final i = _tasks.indexWhere((t) => t.id == taskId);
    if (i == -1) return;
    _tasks[i] = _tasks[i].copyWith(status: 'in_progress');
    await _persist(_tasks[i]);
    notifyListeners();
  }

  /// Retorna tarefa para 'pending' (Kanban: Em Execução → Planejada ou reabertura)
  Future<void> moveToPending(String taskId) async {
    if (taskId.startsWith('cal_')) {
      return _updateCalendarStatus(taskId, 'pending', clearCompleted: true);
    }
    final i = _tasks.indexWhere((t) => t.id == taskId);
    if (i == -1) return;
    final t = _tasks[i];
    // Cria nova instância explicitamente para resetar completedAt → null
    _tasks[i] = TaskModel(
      id: t.id,
      userId: t.userId,
      title: t.title,
      description: t.description,
      areaId: t.areaId,
      eisenhowerQ: t.eisenhowerQ,
      isMIT: false,
      mitOrder: 0,
      status: 'pending',
      dueDate: t.dueDate,
      subtasks: t.subtasks,
      createdAt: t.createdAt,
      completedAt: null,
      isFromCalendar: t.isFromCalendar,
      calendarEventId: t.calendarEventId,
    );
    _normalizeMITs();
    await _persist(_tasks[i]);
    notifyListeners();
  }

  /// Marca uma tarefa como concluída diretamente (sem subtarefas)
  Future<void> completeTask(String taskId) async {
    if (taskId.startsWith('cal_')) {
      return _updateCalendarStatus(taskId, 'completed');
    }
    final i = _tasks.indexWhere((t) => t.id == taskId);
    if (i == -1) return;

    _tasks[i] = _tasks[i].copyWith(
      status: 'completed',
      completedAt: DateTime.now(),
      isMIT: false,
      mitOrder: 0,
    );

    _normalizeMITs();
    await _persist(_tasks[i]);
    notifyListeners();
  }

  // ── CRUD — tarefas de calendário (via overrides) ──────────────────────────

  Future<void> _updateCalendarStatus(
    String taskId,
    String newStatus, {
    bool clearCompleted = false,
  }) async {
    final i = _calendarTasks.indexWhere((t) => t.id == taskId);
    if (i == -1) return;

    final task = _calendarTasks[i];
    final eventId = task.calendarEventId!;

    final now = DateTime.now();
    final completedAt =
        newStatus == 'completed' ? now : null;

    // Atualiza instância em memória
    _calendarTasks[i] = TaskModel(
      id: task.id,
      userId: task.userId,
      title: task.title,
      description: task.description,
      areaId: task.areaId,
      eisenhowerQ: task.eisenhowerQ,
      isMIT: newStatus == 'completed' ? false : task.isMIT,
      mitOrder: newStatus == 'completed' ? 0 : task.mitOrder,
      status: newStatus,
      dueDate: task.dueDate,
      createdAt: task.createdAt,
      completedAt: completedAt,
      isFromCalendar: true,
      calendarEventId: eventId,
    );

    // Persiste override
    _calendarOverrides[eventId] = {
      ..._calendarOverrides[eventId] ?? {},
      'status': newStatus,
      'isMIT': _calendarTasks[i].isMIT,
      'mitOrder': _calendarTasks[i].mitOrder,
      'completedAt':
          completedAt != null ? completedAt.toIso8601String() : null,
    };

    if (newStatus == 'completed' || clearCompleted) _normalizeMITs();
    await _saveCalendarOverrides();
    notifyListeners();
  }

  Future<bool> _toggleCalendarMIT(String taskId) async {
    final i = _calendarTasks.indexWhere((t) => t.id == taskId);
    if (i == -1) return false;

    final task = _calendarTasks[i];
    final eventId = task.calendarEventId!;

    if (task.isMIT) {
      _calendarTasks[i] = task.copyWith(isMIT: false, mitOrder: 0);
    } else {
      if (!canAddMIT) return false;
      _calendarTasks[i] =
          task.copyWith(isMIT: true, mitOrder: mitCount + 1);
    }

    _calendarOverrides[eventId] = {
      ..._calendarOverrides[eventId] ?? {},
      'isMIT': _calendarTasks[i].isMIT,
      'mitOrder': _calendarTasks[i].mitOrder,
    };

    _normalizeMITs();
    await _saveCalendarOverrides();
    notifyListeners();
    return true;
  }

  void _updateCalendarTaskOverride(TaskModel task) {
    final eventId = task.calendarEventId;
    if (eventId == null) return;

    final i = _calendarTasks.indexWhere((t) => t.id == task.id);
    if (i != -1) _calendarTasks[i] = task;

    _calendarOverrides[eventId] = {
      ..._calendarOverrides[eventId] ?? {},
      'eisenhowerQ': task.eisenhowerQ,
      'isMIT': task.isMIT,
      'mitOrder': task.mitOrder,
      'status': task.status,
      if (task.completedAt != null)
        'completedAt': task.completedAt!.toIso8601String(),
    };

    _normalizeMITs();
    _saveCalendarOverrides();
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Garante que mitOrder está correto e que não há mais de 3 MITs ativos.
  /// Opera sobre _tasks e _calendarTasks combinados.
  void _normalizeMITs() {
    // 1. Remove MIT de tarefas concluídas
    for (var i = 0; i < _tasks.length; i++) {
      if (_tasks[i].isMIT && _tasks[i].status == 'completed') {
        _tasks[i] = _tasks[i].copyWith(isMIT: false, mitOrder: 0);
      }
    }
    for (var i = 0; i < _calendarTasks.length; i++) {
      if (_calendarTasks[i].isMIT &&
          _calendarTasks[i].status == 'completed') {
        _calendarTasks[i] =
            _calendarTasks[i].copyWith(isMIT: false, mitOrder: 0);
      }
    }

    // 2. Coleta todos os MITs ativos em ordem
    final allActive = _allTasks
        .where((t) => t.isMIT && t.status != 'completed')
        .toList()
      ..sort((a, b) => a.mitOrder.compareTo(b.mitOrder));

    // 3. Se mais de 3, remove os extras (maiores mitOrder)
    if (allActive.length > 3) {
      for (var i = 3; i < allActive.length; i++) {
        _clearMITById(allActive[i].id);
      }
    }

    // 4. Renumera mitOrder (1, 2, 3)
    final validMits = _allTasks
        .where((t) => t.isMIT && t.status != 'completed')
        .toList()
      ..sort((a, b) => a.mitOrder.compareTo(b.mitOrder));

    for (var i = 0; i < validMits.length; i++) {
      final id = validMits[i].id;
      if (id.startsWith('cal_')) {
        final idx = _calendarTasks.indexWhere((t) => t.id == id);
        if (idx != -1 && _calendarTasks[idx].mitOrder != i + 1) {
          _calendarTasks[idx] =
              _calendarTasks[idx].copyWith(mitOrder: i + 1);
        }
      } else {
        final idx = _tasks.indexWhere((t) => t.id == id);
        if (idx != -1 && _tasks[idx].mitOrder != i + 1) {
          _tasks[idx] = _tasks[idx].copyWith(mitOrder: i + 1);
        }
      }
    }
  }

  void _clearMITById(String id) {
    if (id.startsWith('cal_')) {
      final idx = _calendarTasks.indexWhere((t) => t.id == id);
      if (idx != -1) {
        _calendarTasks[idx] =
            _calendarTasks[idx].copyWith(isMIT: false, mitOrder: 0);
      }
    } else {
      final idx = _tasks.indexWhere((t) => t.id == id);
      if (idx != -1) {
        _tasks[idx] = _tasks[idx].copyWith(isMIT: false, mitOrder: 0);
      }
    }
  }
}
