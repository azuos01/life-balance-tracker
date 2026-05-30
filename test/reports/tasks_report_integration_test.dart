// ── Testes de Integração — Relatório de Tarefas ───────────────────────────────
//
// Valida o fluxo completo de dados entre os métodos do TasksProvider:
// criação → movimentação de status → conclusão → reflexo nas métricas.
// Também testa combinações de filtros, mix de origens (usuário + calendário)
// e consistência após operações encadeadas.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:life_balance_tracker/providers/tasks_provider.dart';
import 'package:life_balance_tracker/models/task_model.dart';
import 'package:life_balance_tracker/models/calendar_event_model.dart';
import 'package:life_balance_tracker/services/storage_service.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Future<TasksProvider> _makeProvider() async {
  SharedPreferences.setMockInitialValues({});
  await StorageService.instance.init();
  final p = TasksProvider();
  p.initLocal();
  return p;
}

TaskModel _task({
  required String id,
  String areaId = 'career',
  int q = 2,
  String status = 'pending',
  DateTime? createdAt,
}) =>
    TaskModel(
      id: id,
      userId: 'u1',
      title: 'Tarefa $id',
      areaId: areaId,
      eisenhowerQ: q,
      status: status,
      createdAt: createdAt ?? DateTime(2024, 1, 1),
    );

CalendarEventModel _event({required String id, String title = 'Evento'}) =>
    CalendarEventModel(
      id: id,
      title: title,
      start: DateTime.now().add(const Duration(hours: 2)),
      end: DateTime.now().add(const Duration(hours: 3)),
    );

// ── Testes ────────────────────────────────────────────────────────────────────

void main() {
  // ── Ciclo de vida completo de uma tarefa ──────────────────────────────────

  group('Integração — ciclo de vida completo', () {
    test('pending → in_progress → completed reflete nas métricas', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));

      // Estado inicial
      expect(p.pendingCount, 1);
      expect(p.inProgressCount, 0);
      expect(p.completedCount, 0);
      expect(p.completionRate, 0.0);

      // Mover para in_progress
      await p.moveToInProgress('t1');
      expect(p.pendingCount, 0);
      expect(p.inProgressCount, 1);
      expect(p.completedCount, 0);

      // Concluir
      await p.completeTask('t1');
      expect(p.pendingCount, 0);
      expect(p.inProgressCount, 0);
      expect(p.completedCount, 1);
      expect(p.completionRate, 1.0);
    });

    test('reabrir tarefa reduz completedCount e aumenta pendingCount', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      await p.completeTask('t1');
      expect(p.completedCount, 1);
      await p.moveToPending('t1');
      expect(p.completedCount, 0);
      expect(p.pendingCount, 1);
    });

    test('conclusão de tarefa remove dela MIT e atualiza activeMITs', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      await p.toggleMIT('t1');
      expect(p.activeMITs.length, 1);
      await p.completeTask('t1');
      expect(p.activeMITs, isEmpty);
      expect(p.activeTasksByQuadrant.values.every((v) => v == 0), isTrue);
    });
  });

  // ── Mix de origens (usuário + calendário) ─────────────────────────────────

  group('Integração — mix usuário + calendário', () {
    test('métricas somam tarefas de ambas as origens', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1', areaId: 'career'));
      await p.addTask(_task(id: 't2', areaId: 'finances'));
      p.syncCalendarTasks([
        _event(id: 'e1'),
        _event(id: 'e2'),
      ], 'u1');

      expect(p.totalTasks, 4);
      expect(p.userTasksCount, 2);
      expect(p.calendarTasksCount, 2);
    });

    test('completionRate engloba tarefas de calendário concluídas', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      p.syncCalendarTasks([_event(id: 'e1')], 'u1');
      await p.completeTask('t1');
      await p.completeTask('cal_e1');
      expect(p.completionRate, 1.0);
      expect(p.completedCount, 2);
    });

    test(
        're-sync de calendário preserva tarefas de usuário intactas', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1', areaId: 'finances'));
      p.syncCalendarTasks([_event(id: 'e1')], 'u1');
      expect(p.userTasksCount, 1);
      // Novo sync com eventos diferentes
      p.syncCalendarTasks(
          [_event(id: 'e2'), _event(id: 'e3')], 'u1');
      expect(p.userTasksCount, 1);       // inalterado
      expect(p.calendarTasksCount, 2);   // atualizado
    });

    test('taskCountByArea combina área de user + calendário', () async {
      final p = await _makeProvider();
      // Calendário usa kAreas.first.id como área default
      p.syncCalendarTasks([_event(id: 'e1')], 'u1');
      await p.addTask(_task(id: 't1', areaId: 'career'));
      final counts = p.taskCountByArea();
      final total = counts.values.fold(0, (a, b) => a + b);
      expect(total, 2);
    });
  });

  // ── Consistência dos filtros por status ───────────────────────────────────

  group('Integração — filtros taskCountByArea por status', () {
    test('sem statusFilter retorna todas as tarefas', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1', areaId: 'career'));
      await p.addTask(_task(id: 't2', areaId: 'career'));
      await p.addTask(_task(id: 't3', areaId: 'finances'));
      await p.completeTask('t1');
      await p.moveToInProgress('t2');

      final all = p.taskCountByArea();
      expect(all['career'], 2);
      expect(all['finances'], 1);
    });

    test('filtro pending exclui in_progress e completed', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1', areaId: 'career'));
      await p.addTask(_task(id: 't2', areaId: 'career'));
      await p.addTask(_task(id: 't3', areaId: 'career'));
      await p.moveToInProgress('t1');
      await p.completeTask('t2');

      final pending = p.taskCountByArea(statusFilter: 'pending');
      expect(pending['career'], 1); // apenas t3
    });

    test('todos os status somam ao total de tarefas da área', () async {
      final p = await _makeProvider();
      for (var i = 1; i <= 6; i++) {
        await p.addTask(_task(id: 't$i', areaId: 'career'));
      }
      await p.moveToInProgress('t1');
      await p.moveToInProgress('t2');
      await p.completeTask('t3');
      await p.completeTask('t4');

      final pending   = p.taskCountByArea(statusFilter: 'pending')['career'] ?? 0;
      final inProg    = p.taskCountByArea(statusFilter: 'in_progress')['career'] ?? 0;
      final completed = p.taskCountByArea(statusFilter: 'completed')['career'] ?? 0;
      expect(pending + inProg + completed, p.taskCountByArea()['career']);
    });
  });

  // ── Distribuição por quadrante ─────────────────────────────────────────────

  group('Integração — distribuição por quadrante', () {
    test('activeTasksByQuadrant atualiza após conclusão', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1', q: 1));
      await p.addTask(_task(id: 't2', q: 1));
      expect(p.activeTasksByQuadrant[1], 2);
      await p.completeTask('t1');
      expect(p.activeTasksByQuadrant[1], 1);
      await p.completeTask('t2');
      expect(p.activeTasksByQuadrant[1], 0);
    });

    test('tarefa movida para in_progress permanece ativa no quadrante', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1', q: 2));
      await p.moveToInProgress('t1');
      expect(p.activeTasksByQuadrant[2], 1);
    });

    test('atualização de quadrante via updateTask reflete na distribuição', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1', q: 4));
      expect(p.activeTasksByQuadrant[4], 1);
      await p.updateTask(_task(id: 't1', q: 1));
      expect(p.activeTasksByQuadrant[4], 0);
      expect(p.activeTasksByQuadrant[1], 1);
    });
  });

  // ── Métricas semanais ─────────────────────────────────────────────────────

  group('Integração — métricas semanais', () {
    test('createdThisWeek sobe com cada addTask recente', () async {
      final p = await _makeProvider();
      for (var i = 1; i <= 5; i++) {
        await p.addTask(TaskModel(
          id: 't$i',
          userId: 'u1',
          title: 'T$i',
          areaId: 'career',
          createdAt: DateTime.now(),
        ));
      }
      expect(p.createdThisWeek, 5);
    });

    test('completedThisWeek sobe a cada completeTask', () async {
      final p = await _makeProvider();
      for (var i = 1; i <= 3; i++) {
        await p.addTask(_task(id: 't$i'));
        await p.completeTask('t$i');
      }
      expect(p.completedThisWeek, 3);
    });

    test('tarefas antigas não entram em createdThisWeek', () async {
      final p = await _makeProvider();
      // 1 recente + 1 antiga
      await p.addTask(TaskModel(
        id: 't1', userId: 'u1', title: 'Recente',
        areaId: 'career', createdAt: DateTime.now(),
      ));
      await p.addTask(TaskModel(
        id: 't2', userId: 'u1', title: 'Antiga',
        areaId: 'career',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ));
      expect(p.createdThisWeek, 1);
    });
  });

  // ── Invariantes gerais ────────────────────────────────────────────────────

  group('Integração — invariantes', () {
    test('totalTasks = userTasksCount + calendarTasksCount', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      await p.addTask(_task(id: 't2'));
      p.syncCalendarTasks([_event(id: 'e1')], 'u1');
      expect(p.totalTasks, p.userTasksCount + p.calendarTasksCount);
    });

    test('pendingCount = plannedTasks.length em qualquer estado', () async {
      final p = await _makeProvider();
      for (var i = 1; i <= 5; i++) {
        await p.addTask(_task(id: 't$i'));
      }
      await p.moveToInProgress('t1');
      await p.completeTask('t2');
      expect(p.pendingCount, p.plannedTasks.length);
    });

    test('inProgressCount = inProgressTasks.length em qualquer estado', () async {
      final p = await _makeProvider();
      for (var i = 1; i <= 5; i++) {
        await p.addTask(_task(id: 't$i'));
        if (i % 2 == 0) await p.moveToInProgress('t$i');
      }
      expect(p.inProgressCount, p.inProgressTasks.length);
    });

    test('completionRate está sempre entre 0.0 e 1.0', () async {
      final p = await _makeProvider();
      for (var i = 1; i <= 10; i++) {
        await p.addTask(_task(id: 't$i'));
      }
      for (var i = 1; i <= 10; i++) {
        expect(p.completionRate, inInclusiveRange(0.0, 1.0));
        await p.completeTask('t$i');
      }
      expect(p.completionRate, 1.0);
    });
  });
}
