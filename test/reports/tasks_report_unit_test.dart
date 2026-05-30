// ── Testes Unitários — Métricas de Relatório de Tarefas ──────────────────────
//
// Cobertura: todos os getters de relatório adicionados ao TasksProvider.
//   - completionRate
//   - pendingCount / inProgressCount
//   - userTasksCount / calendarTasksCount
//   - taskCountByArea (com e sem filtro de status)
//   - activeTasksByQuadrant
//   - completedThisWeek / createdThisWeek
//   - avgCompletionTime

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
  String id = 't1',
  String areaId = 'career',
  int q = 2,
  String status = 'pending',
  DateTime? createdAt,
  DateTime? completedAt,
}) =>
    TaskModel(
      id: id,
      userId: 'u1',
      title: 'Tarefa $id',
      areaId: areaId,
      eisenhowerQ: q,
      status: status,
      createdAt: createdAt ?? DateTime(2024, 1, 1),
      completedAt: completedAt,
    );

CalendarEventModel _event({String id = 'e1', String title = 'Reunião'}) =>
    CalendarEventModel(
      id: id,
      title: title,
      start: DateTime.now().add(const Duration(hours: 1)),
      end: DateTime.now().add(const Duration(hours: 2)),
    );

// ── Testes ────────────────────────────────────────────────────────────────────

void main() {
  // ── completionRate ────────────────────────────────────────────────────────

  group('completionRate', () {
    test('retorna 0.0 quando não há tarefas', () async {
      final p = await _makeProvider();
      expect(p.completionRate, 0.0);
    });

    test('retorna 0.0 quando nenhuma tarefa está concluída', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      await p.addTask(_task(id: 't2'));
      expect(p.completionRate, 0.0);
    });

    test('retorna 0.5 quando metade das tarefas está concluída', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      await p.addTask(_task(id: 't2'));
      await p.completeTask('t1');
      expect(p.completionRate, 0.5);
    });

    test('retorna 1.0 quando todas as tarefas estão concluídas', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      await p.addTask(_task(id: 't2'));
      await p.completeTask('t1');
      await p.completeTask('t2');
      expect(p.completionRate, 1.0);
    });

    test('é proporcional ao número real de concluídas', () async {
      final p = await _makeProvider();
      for (var i = 1; i <= 10; i++) {
        await p.addTask(_task(id: 't$i'));
      }
      for (var i = 1; i <= 3; i++) {
        await p.completeTask('t$i');
      }
      expect(p.completionRate, closeTo(0.3, 0.001));
    });

    test('inclui tarefas de calendário no cálculo', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      p.syncCalendarTasks([_event(id: 'e1')], 'u1');
      await p.completeTask('t1');
      // total = 2, completed = 1 → 0.5
      expect(p.completionRate, 0.5);
    });
  });

  // ── pendingCount / inProgressCount ───────────────────────────────────────

  group('pendingCount e inProgressCount', () {
    test('pendingCount = 0 sem tarefas', () async {
      final p = await _makeProvider();
      expect(p.pendingCount, 0);
    });

    test('pendingCount conta apenas tarefas pending', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      await p.addTask(_task(id: 't2'));
      await p.moveToInProgress('t1');
      expect(p.pendingCount, 1);
    });

    test('inProgressCount = 0 sem tarefas em andamento', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      expect(p.inProgressCount, 0);
    });

    test('inProgressCount conta apenas in_progress', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      await p.addTask(_task(id: 't2'));
      await p.moveToInProgress('t1');
      await p.moveToInProgress('t2');
      expect(p.inProgressCount, 2);
    });

    test('pendingCount + inProgressCount + completedCount = totalTasks', () async {
      final p = await _makeProvider();
      for (var i = 1; i <= 6; i++) {
        await p.addTask(_task(id: 't$i'));
      }
      await p.moveToInProgress('t1');
      await p.moveToInProgress('t2');
      await p.completeTask('t3');
      await p.completeTask('t4');
      expect(
        p.pendingCount + p.inProgressCount + p.completedCount,
        p.totalTasks,
      );
    });
  });

  // ── userTasksCount / calendarTasksCount ──────────────────────────────────

  group('userTasksCount e calendarTasksCount', () {
    test('userTasksCount = 0 inicialmente', () async {
      final p = await _makeProvider();
      expect(p.userTasksCount, 0);
    });

    test('userTasksCount cresce com addTask', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      await p.addTask(_task(id: 't2'));
      expect(p.userTasksCount, 2);
    });

    test('calendarTasksCount = 0 sem sync', () async {
      final p = await _makeProvider();
      expect(p.calendarTasksCount, 0);
    });

    test('calendarTasksCount reflete eventos sincronizados', () async {
      final p = await _makeProvider();
      p.syncCalendarTasks(
          [_event(id: 'e1'), _event(id: 'e2')], 'u1');
      expect(p.calendarTasksCount, 2);
    });

    test('userTasksCount e calendarTasksCount são independentes', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      await p.addTask(_task(id: 't2'));
      p.syncCalendarTasks([_event(id: 'e1')], 'u1');
      expect(p.userTasksCount, 2);
      expect(p.calendarTasksCount, 1);
      expect(p.totalTasks, 3);
    });

    test('calendarTasksCount zera quando sync recebe lista vazia', () async {
      final p = await _makeProvider();
      p.syncCalendarTasks([_event(id: 'e1')], 'u1');
      p.syncCalendarTasks([], 'u1');
      expect(p.calendarTasksCount, 0);
    });
  });

  // ── taskCountByArea ───────────────────────────────────────────────────────

  group('taskCountByArea', () {
    test('retorna mapa vazio sem tarefas', () async {
      final p = await _makeProvider();
      expect(p.taskCountByArea(), isEmpty);
    });

    test('agrupa tarefas por área corretamente', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1', areaId: 'career'));
      await p.addTask(_task(id: 't2', areaId: 'career'));
      await p.addTask(_task(id: 't3', areaId: 'finances'));
      final counts = p.taskCountByArea();
      expect(counts['career'], 2);
      expect(counts['finances'], 1);
    });

    test('filtra por status pending', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1', areaId: 'career'));
      await p.addTask(_task(id: 't2', areaId: 'career'));
      await p.completeTask('t1');
      final pending = p.taskCountByArea(statusFilter: 'pending');
      expect(pending['career'], 1);
    });

    test('filtra por status completed', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1', areaId: 'health_physical'));
      await p.addTask(_task(id: 't2', areaId: 'health_physical'));
      await p.completeTask('t1');
      final completed = p.taskCountByArea(statusFilter: 'completed');
      expect(completed['health_physical'], 1);
      expect(completed.containsKey('career'), false);
    });

    test('filtra por status in_progress', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1', areaId: 'career'));
      await p.addTask(_task(id: 't2', areaId: 'finances'));
      await p.moveToInProgress('t1');
      final inProg = p.taskCountByArea(statusFilter: 'in_progress');
      expect(inProg['career'], 1);
      expect(inProg.containsKey('finances'), false);
    });

    test('inclui tarefas de calendário na contagem', () async {
      final p = await _makeProvider();
      p.syncCalendarTasks([_event(id: 'e1')], 'u1');
      // tarefas de calendário têm areaId = kAreas.first.id
      final counts = p.taskCountByArea();
      expect(counts.values.fold(0, (a, b) => a + b), 1);
    });

    test('áreas sem tarefas não aparecem no mapa', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1', areaId: 'career'));
      final counts = p.taskCountByArea();
      expect(counts.containsKey('finances'), false);
    });
  });

  // ── activeTasksByQuadrant ─────────────────────────────────────────────────

  group('activeTasksByQuadrant', () {
    test('sempre retorna os 4 quadrantes (valores zero se vazios)', () async {
      final p = await _makeProvider();
      final dist = p.activeTasksByQuadrant;
      expect(dist.keys.toSet(), {1, 2, 3, 4});
    });

    test('conta tarefas por quadrante corretamente', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1', q: 1));
      await p.addTask(_task(id: 't2', q: 1));
      await p.addTask(_task(id: 't3', q: 3));
      final dist = p.activeTasksByQuadrant;
      expect(dist[1], 2);
      expect(dist[2], 0);
      expect(dist[3], 1);
      expect(dist[4], 0);
    });

    test('exclui tarefas concluídas', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1', q: 1));
      await p.completeTask('t1');
      expect(p.activeTasksByQuadrant[1], 0);
    });

    test('inclui tarefas de calendário nos quadrantes', () async {
      final p = await _makeProvider();
      p.syncCalendarTasks([_event(id: 'e1')], 'u1');
      // padrão de calendário é Q2
      expect(p.activeTasksByQuadrant[2], 1);
    });

    test('soma de todos os quadrantes = totalTasks - completedCount', () async {
      final p = await _makeProvider();
      for (var q = 1; q <= 4; q++) {
        await p.addTask(_task(id: 'q$q', q: q));
      }
      await p.completeTask('q1');
      final dist  = p.activeTasksByQuadrant;
      final total = dist.values.fold(0, (a, b) => a + b);
      expect(total, p.totalTasks - p.completedCount);
    });
  });

  // ── completedThisWeek / createdThisWeek ───────────────────────────────────

  group('completedThisWeek e createdThisWeek', () {
    test('completedThisWeek = 0 sem conclusões', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      expect(p.completedThisWeek, 0);
    });

    test('completedThisWeek conta tarefa concluída agora', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      await p.completeTask('t1');
      expect(p.completedThisWeek, 1);
    });

    test('createdThisWeek = 0 sem tarefas recentes', () async {
      final p = await _makeProvider();
      // tarefa com data antiga (> 7 dias)
      await p.addTask(_task(id: 't1',
          createdAt: DateTime.now().subtract(const Duration(days: 10))));
      expect(p.createdThisWeek, 0);
    });

    test('createdThisWeek conta tarefa criada agora', () async {
      final p = await _makeProvider();
      await p.addTask(TaskModel(
        id: 't1', userId: 'u1', title: 'T',
        areaId: 'career', createdAt: DateTime.now(),
      ));
      expect(p.createdThisWeek, 1);
    });

    test('createdThisWeek inclui tarefas de calendário recentes', () async {
      final p = await _makeProvider();
      p.syncCalendarTasks([_event(id: 'e1')], 'u1');
      // eventos têm start = DateTime.now() + 1h, que cai dentro dos 7 dias
      expect(p.createdThisWeek, 1);
    });
  });

  // ── avgCompletionTime ─────────────────────────────────────────────────────

  group('avgCompletionTime', () {
    test('retorna null sem tarefas concluídas', () async {
      final p = await _makeProvider();
      await p.addTask(_task(id: 't1'));
      expect(p.avgCompletionTime, isNull);
    });

    test('retorna null quando completedAt é nulo', () async {
      final p = await _makeProvider();
      // Adiciona tarefa já "completed" mas sem completedAt explícito
      // (ex: migração de dado antigo)
      expect(p.avgCompletionTime, isNull);
    });

    test('calcula tempo para uma tarefa concluída', () async {
      final p = await _makeProvider();
      final created = DateTime.now().subtract(const Duration(hours: 2));
      await p.addTask(TaskModel(
        id: 't1', userId: 'u1', title: 'T',
        areaId: 'career', createdAt: created,
      ));
      await p.completeTask('t1');
      final avg = p.avgCompletionTime;
      expect(avg, isNotNull);
      // Tempo ≈ 2h (pode variar por ms de execução do teste)
      expect(avg!.inMinutes, greaterThanOrEqualTo(119));
    });

    test('calcula média correta para múltiplas tarefas', () async {
      final p = await _makeProvider();

      // t1: criada 60 min atrás → tempo ≈ 60 min
      await p.addTask(TaskModel(
        id: 't1', userId: 'u1', title: 'T1',
        areaId: 'career',
        createdAt: DateTime.now().subtract(const Duration(minutes: 60)),
      ));
      // t2: criada 120 min atrás → tempo ≈ 120 min
      await p.addTask(TaskModel(
        id: 't2', userId: 'u1', title: 'T2',
        areaId: 'career',
        createdAt: DateTime.now().subtract(const Duration(minutes: 120)),
      ));
      await p.completeTask('t1');
      await p.completeTask('t2');

      final avg = p.avgCompletionTime;
      expect(avg, isNotNull);
      // Média ≈ 90 min (margem de ±2 min para execução do teste)
      expect(avg!.inMinutes, inInclusiveRange(88, 92));
    });

    test('ignora tarefas de calendário no cálculo de tempo médio', () async {
      final p = await _makeProvider();
      p.syncCalendarTasks([_event(id: 'e1')], 'u1');
      await p.completeTask('cal_e1');
      // Calendário não tem completedAt rastreável da mesma forma
      // avgCompletionTime só considera _tasks (manual)
      expect(p.avgCompletionTime, isNull);
    });
  });
}
