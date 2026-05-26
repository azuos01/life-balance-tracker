import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';

const String _kTasksKey = 'tasks_data';

class TasksProvider extends ChangeNotifier {
  List<TaskModel> _tasks = [];
  String? _uid;
  bool _isCloud = false;
  // Último UID carregado do Firestore. Quando null, força recarga no próximo login.
  String? _lastLoadedUid;

  List<TaskModel> get tasks => List.unmodifiable(_tasks);

  // ── Queries ──────────────────────────────────────────────────────────────

  /// Tarefas MIT ativas ordenadas por mitOrder (1, 2, 3)
  List<TaskModel> get activeMITs => _tasks
      .where((t) => t.isMIT && t.status != 'completed')
      .toList()
    ..sort((a, b) => a.mitOrder.compareTo(b.mitOrder));

  /// Número de MITs ativos (máx 3)
  int get mitCount => activeMITs.length;
  bool get canAddMIT => mitCount < 3;

  /// Tarefas ativas por quadrante Eisenhower
  List<TaskModel> byQuadrant(int q) => _tasks
      .where((t) => t.eisenhowerQ == q && t.status != 'completed')
      .toList()
    ..sort((a, b) {
      // MIT primeiro
      if (a.isMIT != b.isMIT) return a.isMIT ? -1 : 1;
      return a.createdAt.compareTo(b.createdAt);
    });

  /// Todas as tarefas não concluídas (pending + in_progress)
  List<TaskModel> get pendingTasks =>
      _tasks.where((t) => t.status != 'completed').toList();

  /// Tarefas planejadas (coluna Kanban "A Fazer")
  List<TaskModel> get plannedTasks => _tasks
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
  List<TaskModel> get inProgressTasks => _tasks
      .where((t) => t.status == 'in_progress')
      .toList()
    ..sort((a, b) {
      if (a.isMIT != b.isMIT) return a.isMIT ? -1 : 1;
      return a.createdAt.compareTo(b.createdAt);
    });

  /// Tarefas concluídas
  List<TaskModel> get completedTasks => _tasks
      .where((t) => t.status == 'completed')
      .toList()
    ..sort((a, b) =>
        (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt));

  int get totalTasks => _tasks.length;
  int get completedCount => completedTasks.length;

  // ── Inicialização ─────────────────────────────────────────────────────────

  void initLocal() {
    _loadLocal();
  }

  Future<void> init() async {
    initLocal();
  }

  /// Chamado pelo ProxyProvider toda vez que UserProvider notifica.
  ///
  /// Estratégia de recarga:
  /// • Ao fazer logout (isCloud=false): reseta _lastLoadedUid → garante que o
  ///   próximo login sempre busque dados frescos do Firestore.
  /// • Ao fazer login (isCloud=true, uid≠_lastLoadedUid): dispara _loadFromCloud.
  /// • Rebuilds intermediários com mesmo uid+isCloud: ignorados.
  void syncUser(String? uid, bool isCloud) {
    _uid      = uid;
    _isCloud  = isCloud;

    if (uid == null || !isCloud) {
      // Deslogou ou modo demo — reseta o marcador de última carga
      _lastLoadedUid = null;
      return;
    }

    // Login ou troca de conta: carrega dados do Firestore
    if (uid != _lastLoadedUid) {
      _lastLoadedUid = uid;
      _loadFromCloud(uid);
    }
  }

  // ── Sincronização com Firestore ───────────────────────────────────────────

  Future<void> _loadFromCloud(String uid) async {
    final cloudTasks = await FirestoreService.instance.getTasks(uid);

    if (cloudTasks.isNotEmpty) {
      // Dados encontrados no Firestore → substitui tudo (local + memória)
      _tasks = cloudTasks;
      await _saveLocal();
    } else if (_tasks.isNotEmpty) {
      // Firestore vazio mas há dados locais em memória.
      // Cenário típico: usuário antigo cujos dados foram salvos com UUID em vez
      // do Firebase UID. Migra para o path correto no Firestore agora.
      for (final task in _tasks) {
        await FirestoreService.instance.saveTask(uid, task);
      }
      // Mantém _tasks como está (já são os dados corretos)
    }
    // Se ambos estiverem vazios: usuário novo sem tarefas → lista vazia ✓

    notifyListeners();
  }

  // ── Persistência ──────────────────────────────────────────────────────────

  void _loadLocal() {
    final saved = StorageService.instance.getJsonList(_kTasksKey);
    _tasks = saved.map((j) => TaskModel.fromJson(j)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _saveLocal() async {
    await StorageService.instance.setJsonList(
      _kTasksKey,
      _tasks.map((t) => t.toJson()).toList(),
    );
  }

  Future<void> _persist(TaskModel task) async {
    await _saveLocal();
    if (_isCloud && _uid != null) {
      await FirestoreService.instance.saveTask(_uid!, task);
    }
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<void> addTask(TaskModel task) async {
    _tasks.insert(0, task);
    if (task.isMIT) _normalizeMITs();
    await _persist(task);
    notifyListeners();
  }

  Future<void> updateTask(TaskModel task) async {
    final i = _tasks.indexWhere((t) => t.id == task.id);
    if (i == -1) return;
    _tasks[i] = task;
    _normalizeMITs();
    await _persist(task);
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    _normalizeMITs();
    await _saveLocal();
    if (_isCloud && _uid != null) {
      await FirestoreService.instance.deleteTask(_uid!, id);
    }
    notifyListeners();
  }

  /// Marca/desmarca uma tarefa como MIT.
  /// Respeita o limite de 3 MITs simultâneos.
  Future<bool> toggleMIT(String taskId) async {
    final i = _tasks.indexWhere((t) => t.id == taskId);
    if (i == -1) return false;

    final task = _tasks[i];

    if (task.isMIT) {
      // Remove MIT
      _tasks[i] = task.copyWith(isMIT: false, mitOrder: 0);
    } else {
      if (!canAddMIT) return false; // limite atingido
      _tasks[i] = task.copyWith(isMIT: true, mitOrder: mitCount + 1);
    }

    _normalizeMITs();
    await _persist(_tasks[i]);
    notifyListeners();
    return true;
  }

  /// Alterna o estado de uma subtarefa. Completa a tarefa pai se todas prontas.
  Future<void> toggleSubtask(String taskId, String subtaskId) async {
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
    final i = _tasks.indexWhere((t) => t.id == taskId);
    if (i == -1) return;
    _tasks[i] = _tasks[i].copyWith(status: 'in_progress');
    await _persist(_tasks[i]);
    notifyListeners();
  }

  /// Retorna tarefa para 'pending' (Kanban: Em Execução → Planejada ou reabertura)
  Future<void> moveToPending(String taskId) async {
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
    );
    _normalizeMITs();
    await _persist(_tasks[i]);
    notifyListeners();
  }

  /// Marca uma tarefa como concluída diretamente (sem subtarefas)
  Future<void> completeTask(String taskId) async {
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Garante que mitOrder está correto e que não há mais de 3 MITs ativos
  void _normalizeMITs() {
    final mits = _tasks
        .where((t) => t.isMIT && t.status != 'completed')
        .toList()
      ..sort((a, b) => a.mitOrder.compareTo(b.mitOrder));

    // Remover MIT de tarefas concluídas
    for (var i = 0; i < _tasks.length; i++) {
      if (_tasks[i].isMIT && _tasks[i].status == 'completed') {
        _tasks[i] = _tasks[i].copyWith(isMIT: false, mitOrder: 0);
      }
    }

    // Se mais de 3, remove os extras (os de maior mitOrder)
    if (mits.length > 3) {
      for (var i = 3; i < mits.length; i++) {
        final idx = _tasks.indexWhere((t) => t.id == mits[i].id);
        if (idx != -1) {
          _tasks[idx] = _tasks[idx].copyWith(isMIT: false, mitOrder: 0);
        }
      }
    }

    // Renumera mitOrder (1, 2, 3)
    final validMits = _tasks
        .where((t) => t.isMIT && t.status != 'completed')
        .toList()
      ..sort((a, b) => a.mitOrder.compareTo(b.mitOrder));

    for (var i = 0; i < validMits.length; i++) {
      final idx = _tasks.indexWhere((t) => t.id == validMits[i].id);
      if (idx != -1 && _tasks[idx].mitOrder != i + 1) {
        _tasks[idx] = _tasks[idx].copyWith(mitOrder: i + 1);
      }
    }
  }
}
