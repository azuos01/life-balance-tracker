import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:life_balance_tracker/providers/tasks_provider.dart';
import 'package:life_balance_tracker/models/task_model.dart';
import 'package:life_balance_tracker/models/calendar_event_model.dart';
import 'package:life_balance_tracker/services/storage_service.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

Future<TasksProvider> _makeProvider() async {
  SharedPreferences.setMockInitialValues({});
  await StorageService.instance.init();
  final p = TasksProvider();
  p.initLocal();
  return p;
}

TaskModel _task({
  String id = 't1',
  String title = 'Tarefa',
  int q = 2,
  bool isMIT = false,
  String status = 'pending',
}) =>
    TaskModel(
      id: id,
      userId: 'u1',
      title: title,
      areaId: 'career',
      eisenhowerQ: q,
      isMIT: isMIT,
      status: status,
      createdAt: DateTime(2024, 1, 1),
    );

CalendarEventModel _event({
  String id = 'evt1',
  String title = 'Reunião',
}) =>
    CalendarEventModel(
      id: id,
      title: title,
      start: DateTime.now().add(const Duration(hours: 1)),
      end: DateTime.now().add(const Duration(hours: 2)),
    );

// ── Testes ────────────────────────────────────────────────────────────────────

void main() {
  // ── CRUD básico ──────────────────────────────────────────────────────────

  group('TasksProvider — CRUD básico', () {
    test('addTask insere na lista', () async {
      final p = await _makeProvider();
      await p.addTask(_task());
      expect(p.tasks.length, 1);
      expect(p.tasks.first.title, 'Tarefa');
    });

    test('addTask múltiplas tarefas', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      await p.addTask(_task(id: 't2', title: 'T2'));
      await p.addTask(_task(id: 't3', title: 'T3'));
      expect(p.tasks.length, 3);
    });

    test('deleteTask remove a tarefa correta', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      await p.addTask(_task(id: 't2', title: 'Outra'));
      await p.deleteTask('t1');
      expect(p.tasks.length, 1);
      expect(p.tasks.first.id, 't2');
    });

    test('deleteTask ignora IDs com prefixo cal_ (tarefas de calendário)', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      await p.deleteTask('cal_event123'); // deve ser ignorado
      expect(p.tasks.length, 1);
    });

    test('updateTask atualiza campos corretamente', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1', q: 2));
      await p.updateTask(_task(id: 't1', q: 1, status: 'in_progress'));
      final t = p.tasks.firstWhere((t) => t.id == 't1');
      expect(t.eisenhowerQ, 1);
      expect(t.status, 'in_progress');
    });

    test('updateTask não afeta outras tarefas', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      await p.addTask(_task(id: 't2', title: 'T2'));
      await p.updateTask(_task(id: 't1', q: 3));
      expect(p.tasks.firstWhere((t) => t.id == 't2').eisenhowerQ, 2); // inalterado
    });
  });

  // ── Transições de status ──────────────────────────────────────────────────

  group('TasksProvider — transições de status', () {
    test('completeTask define status e completedAt', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      await p.completeTask('t1');
      final t = p.tasks.firstWhere((t) => t.id == 't1');
      expect(t.status, 'completed');
      expect(t.completedAt, isNotNull);
    });

    test('completeTask remove MIT da tarefa', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      await p.toggleMIT('t1');
      await p.completeTask('t1');
      expect(p.activeMITs, isEmpty);
    });

    test('moveToInProgress altera status para in_progress', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      await p.moveToInProgress('t1');
      expect(p.tasks.firstWhere((t) => t.id == 't1').status, 'in_progress');
    });

    test('moveToPending reseta status e completedAt para null', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1', status: 'completed'));
      await p.moveToPending('t1');
      final t = p.tasks.firstWhere((t) => t.id == 't1');
      expect(t.status, 'pending');
      expect(t.completedAt, null);
      expect(t.isMIT, false);
      expect(t.mitOrder, 0);
    });

    test('sequência pendente → em progresso → concluída → pendente', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      expect(p.tasks.first.status, 'pending');
      await p.moveToInProgress('t1');
      expect(p.tasks.first.status, 'in_progress');
      await p.completeTask('t1');
      expect(p.tasks.first.status, 'completed');
      await p.moveToPending('t1');
      expect(p.tasks.first.status, 'pending');
    });
  });

  // ── MIT ───────────────────────────────────────────────────────────────────

  group('TasksProvider — MIT', () {
    test('toggleMIT marca tarefa como MIT', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      final result = await p.toggleMIT('t1');
      expect(result, true);
      expect(p.activeMITs.length, 1);
      expect(p.activeMITs.first.mitOrder, 1);
    });

    test('toggleMIT desmarca MIT existente', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      await p.toggleMIT('t1'); // marca
      final result = await p.toggleMIT('t1'); // desmarca
      expect(result, true);
      expect(p.activeMITs, isEmpty);
    });

    test('toggleMIT respeita limite de 3 MITs', () async {
      final p = await _makeProvider();
      for (var i = 1; i <= 4; i++) {
        await p.addTask(_task(id: 't$i', title: 'T$i'));
      }
      await p.toggleMIT('t1');
      await p.toggleMIT('t2');
      await p.toggleMIT('t3');
      final result = await p.toggleMIT('t4'); // 4° MIT — deve falhar
      expect(result, false);
      expect(p.mitCount, 3);
    });

    test('canAddMIT retorna false com 3 MITs ativos', () async {
      final p = await _makeProvider();
      for (var i = 1; i <= 3; i++) {
        await p.addTask(_task(id: 't$i', title: 'T$i'));
        await p.toggleMIT('t$i');
      }
      expect(p.canAddMIT, false);
    });

    test('canAddMIT retorna true com menos de 3 MITs', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      await p.toggleMIT('t1');
      expect(p.canAddMIT, true);
    });

    test('activeMITs ordenados por mitOrder', () async {
      final p = await _makeProvider();
      for (var i = 1; i <= 3; i++) {
        await p.addTask(_task(id: 't$i', title: 'T$i'));
      }
      await p.toggleMIT('t1');
      await p.toggleMIT('t2');
      await p.toggleMIT('t3');
      final mits = p.activeMITs;
      expect(mits[0].mitOrder, 1);
      expect(mits[1].mitOrder, 2);
      expect(mits[2].mitOrder, 3);
    });

    test('MIT é removido dos activeMITs ao concluir a tarefa', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      await p.toggleMIT('t1');
      expect(p.activeMITs.length, 1);
      await p.completeTask('t1');
      expect(p.activeMITs, isEmpty);
    });
  });

  // ── Queries de filtragem ──────────────────────────────────────────────────

  group('TasksProvider — queries', () {
    test('byQuadrant filtra por quadrante Eisenhower', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1', q: 1));
      await p.addTask(_task(id: 't2', q: 2, title: 'T2'));
      await p.addTask(_task(id: 't3', q: 1, title: 'T3'));
      expect(p.byQuadrant(1).length, 2);
      expect(p.byQuadrant(2).length, 1);
      expect(p.byQuadrant(3), isEmpty);
    });

    test('byQuadrant exclui tarefas concluídas', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1', q: 1));
      await p.completeTask('t1');
      expect(p.byQuadrant(1), isEmpty);
    });

    test('plannedTasks retorna apenas pending', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      await p.addTask(_task(id: 't2', title: 'T2'));
      await p.moveToInProgress('t2');
      expect(p.plannedTasks.length, 1);
      expect(p.plannedTasks.first.id, 't1');
    });

    test('inProgressTasks retorna apenas in_progress', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      await p.addTask(_task(id: 't2', title: 'T2'));
      await p.moveToInProgress('t1');
      expect(p.inProgressTasks.length, 1);
      expect(p.inProgressTasks.first.id, 't1');
    });

    test('completedTasks retorna apenas completed', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      await p.addTask(_task(id: 't2', title: 'T2'));
      await p.completeTask('t1');
      expect(p.completedTasks.length, 1);
      expect(p.completedTasks.first.id, 't1');
    });

    test('totalTasks conta tarefas do usuário', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      await p.addTask(_task(id: 't2', title: 'T2'));
      expect(p.totalTasks, 2);
    });

    test('completedCount conta apenas concluídas', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      await p.addTask(_task(id: 't2', title: 'T2'));
      await p.completeTask('t1');
      expect(p.completedCount, 1);
    });
  });

  // ── Subtarefas ────────────────────────────────────────────────────────────

  group('TasksProvider — subtarefas', () {
    test('toggleSubtask conclui subtarefa específica', () async {
      final p = await _makeProvider();
      await p.addTask(TaskModel(
        id: 't1',
        userId: 'u1',
        title: 'T',
        areaId: 'career',
        createdAt: DateTime(2024, 1, 1),
        subtasks: [
          SubtaskModel(id: 's1', title: 'Sub A'),
          SubtaskModel(id: 's2', title: 'Sub B'),
        ],
      ));
      await p.toggleSubtask('t1', 's1');
      final t = p.tasks.firstWhere((t) => t.id == 't1');
      expect(t.subtasks.firstWhere((s) => s.id == 's1').isCompleted, true);
      expect(t.subtasks.firstWhere((s) => s.id == 's2').isCompleted, false);
    });

    test('toggleSubtask conclui tarefa quando todas as subtarefas estão prontas', () async {
      final p = await _makeProvider();
      await p.addTask(TaskModel(
        id: 't1',
        userId: 'u1',
        title: 'T',
        areaId: 'career',
        createdAt: DateTime(2024, 1, 1),
        subtasks: [SubtaskModel(id: 's1', title: 'Sub')],
      ));
      await p.toggleSubtask('t1', 's1');
      expect(p.tasks.firstWhere((t) => t.id == 't1').status, 'completed');
    });

    test('toggleSubtask em tarefa de calendário não faz nada', () async {
      final p = await _makeProvider();
      p.syncCalendarTasks([_event(id: 'e1')], 'u1');
      // Não deve lançar exceção
      await p.toggleSubtask('cal_e1', 'any_sub');
      expect(p.tasks.firstWhere((t) => t.id == 'cal_e1').subtasks, isEmpty);
    });
  });

  // ── Sincronização de calendário ───────────────────────────────────────────

  group('TasksProvider — Calendar sync', () {
    test('syncCalendarTasks cria tarefas de calendário', () async {
      final p = await _makeProvider();
      p.syncCalendarTasks([_event()], 'u1');
      expect(p.tasks.where((t) => t.isFromCalendar).length, 1);
    });

    test('id da tarefa de calendário tem prefixo cal_', () async {
      final p = await _makeProvider();
      p.syncCalendarTasks([_event(id: 'abc')], 'u1');
      final calTask = p.tasks.firstWhere((t) => t.isFromCalendar);
      expect(calTask.id, 'cal_abc');
      expect(calTask.calendarEventId, 'abc');
    });

    test('tarefa de calendário padrão: Q2 (Agende), status pending', () async {
      final p = await _makeProvider();
      p.syncCalendarTasks([_event()], 'u1');
      final calTask = p.tasks.firstWhere((t) => t.isFromCalendar);
      expect(calTask.eisenhowerQ, 2);
      expect(calTask.status, 'pending');
      expect(calTask.isMIT, false);
    });

    test('syncCalendarTasks com lista vazia remove tarefas de calendário', () async {
      final p = await _makeProvider();
      p.syncCalendarTasks([_event()], 'u1');
      expect(p.tasks.where((t) => t.isFromCalendar).length, 1);
      p.syncCalendarTasks([], 'u1');
      expect(p.tasks.where((t) => t.isFromCalendar), isEmpty);
    });

    test('tarefas do usuário e de calendário coexistem na lista', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 'user_task'));
      p.syncCalendarTasks([_event(id: 'cal_event')], 'u1');
      expect(p.tasks.length, 2);
      expect(p.tasks.any((t) => t.id == 'user_task'), true);
      expect(p.tasks.any((t) => t.id == 'cal_cal_event'), true);
    });

    test('completeTask funciona em tarefa de calendário', () async {
      final p = await _makeProvider();
      p.syncCalendarTasks([_event(id: 'e1')], 'u1');
      await p.completeTask('cal_e1');
      final t = p.tasks.firstWhere((t) => t.id == 'cal_e1');
      expect(t.status, 'completed');
      expect(t.completedAt, isNotNull);
    });

    test('moveToInProgress funciona em tarefa de calendário', () async {
      final p = await _makeProvider();
      p.syncCalendarTasks([_event(id: 'e1')], 'u1');
      await p.moveToInProgress('cal_e1');
      final t = p.tasks.firstWhere((t) => t.id == 'cal_e1');
      expect(t.status, 'in_progress');
      expect(p.inProgressTasks.any((t) => t.id == 'cal_e1'), true);
    });

    test('deleteTask NÃO remove tarefa de calendário', () async {
      final p = await _makeProvider();
      p.syncCalendarTasks([_event(id: 'e1')], 'u1');
      await p.deleteTask('cal_e1');
      expect(p.tasks.any((t) => t.id == 'cal_e1'), true); // ainda presente
    });

    test('tarefas de calendário aparecem em plannedTasks', () async {
      final p = await _makeProvider();
      p.syncCalendarTasks([_event(id: 'e1')], 'u1');
      expect(p.plannedTasks.any((t) => t.isFromCalendar), true);
    });

    test('limite de 3 MITs conta user + calendar tasks combinados', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      await p.addTask(_task(id: 't2', title: 'T2'));
      await p.toggleMIT('t1');
      await p.toggleMIT('t2');
      p.syncCalendarTasks([
        _event(id: 'e1'),
        _event(id: 'e2', title: 'E2'),
      ], 'u1');
      await p.toggleMIT('cal_e1'); // 3° MIT
      final result = await p.toggleMIT('cal_e2'); // 4° MIT — deve falhar
      expect(result, false);
      expect(p.mitCount, 3);
    });

    test('toggleMIT funciona em tarefa de calendário', () async {
      final p = await _makeProvider();
      p.syncCalendarTasks([_event(id: 'e1')], 'u1');
      final result = await p.toggleMIT('cal_e1');
      expect(result, true);
      expect(p.activeMITs.any((t) => t.id == 'cal_e1'), true);
    });

    test('moveToPending em calendário reseta status e MIT', () async {
      final p = await _makeProvider();
      p.syncCalendarTasks([_event(id: 'e1')], 'u1');
      await p.moveToInProgress('cal_e1');
      await p.moveToPending('cal_e1');
      final t = p.tasks.firstWhere((t) => t.id == 'cal_e1');
      expect(t.status, 'pending');
    });

    test('re-sync com mesmos eventos mantém overrides de status', () async {
      final p = await _makeProvider();
      p.syncCalendarTasks([_event(id: 'e1')], 'u1');
      await p.completeTask('cal_e1');
      // Re-sync com o mesmo evento
      p.syncCalendarTasks([_event(id: 'e1')], 'u1');
      final t = p.tasks.firstWhere((t) => t.id == 'cal_e1');
      expect(t.status, 'completed'); // override deve ser mantido
    });
  });
}
