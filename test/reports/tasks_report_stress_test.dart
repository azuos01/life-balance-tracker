// ── Testes de Stress — Relatório de Tarefas ───────────────────────────────────
//
// Valida estabilidade, correção e consistência das métricas de relatório
// sob carga elevada (100–1000 tarefas) e distribuições extremas.
// Também mede que os cálculos terminam em tempo razoável.

import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:life_balance_tracker/providers/tasks_provider.dart';
import 'package:life_balance_tracker/models/task_model.dart';
import 'package:life_balance_tracker/models/calendar_event_model.dart';
import 'package:life_balance_tracker/services/storage_service.dart';
import 'package:life_balance_tracker/constants/app_constants.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Future<TasksProvider> _makeProvider() async {
  SharedPreferences.setMockInitialValues({});
  await StorageService.instance.init();
  final p = TasksProvider();
  p.initLocal();
  return p;
}

/// Cria N tarefas com distribuição determinística:
///   área rotativa entre as 10 disponíveis,
///   quadrante rotativo entre 1-4,
///   status conforme [completedEvery] (concluída a cada N tarefas).
Future<TasksProvider> _providerWith(
  int n, {
  int completedEvery = 0,   // 0 = nenhuma concluída
  int inProgressEvery = 0,  // 0 = nenhuma in_progress
}) async {
  final p = await _makeProvider();
  for (var i = 0; i < n; i++) {
    final area = kAreas[i % kAreas.length].id;
    final q    = (i % 4) + 1;
    await p.addTask(TaskModel(
      id: 't$i',
      userId: 'u1',
      title: 'Tarefa $i',
      areaId: area,
      eisenhowerQ: q,
      createdAt: DateTime.now().subtract(Duration(minutes: n - i)),
    ));
    if (completedEvery > 0 && i % completedEvery == 0) {
      await p.completeTask('t$i');
    } else if (inProgressEvery > 0 && i % inProgressEvery == 0) {
      await p.moveToInProgress('t$i');
    }
  }
  return p;
}

CalendarEventModel _event(String id) => CalendarEventModel(
      id: id,
      title: 'Evento $id',
      start: DateTime.now().add(const Duration(hours: 1)),
      end: DateTime.now().add(const Duration(hours: 2)),
    );

// ── Testes ────────────────────────────────────────────────────────────────────

void main() {
  // ── Escala: 100 tarefas ──────────────────────────────────────────────────

  group('Stress — 100 tarefas', () {
    test('totalTasks = 100 após inserção em lote', () async {
      final p = await _providerWith(100);
      expect(p.totalTasks, 100);
    });

    test('taskCountByArea distribui 100 tarefas nas 10 áreas (10 cada)', () async {
      final p = await _providerWith(100);
      final counts = p.taskCountByArea();
      for (final area in kAreas) {
        expect(counts[area.id], 10,
            reason: 'Área ${area.id} deveria ter 10 tarefas');
      }
    });

    test('activeTasksByQuadrant distribui 100 tarefas (25 por quadrante)', () async {
      final p = await _providerWith(100);
      final dist = p.activeTasksByQuadrant;
      for (var q = 1; q <= 4; q++) {
        expect(dist[q], 25,
            reason: 'Quadrante $q deveria ter 25 tarefas');
      }
    });

    test('completionRate = 0.5 com metade concluída (100 tarefas)', () async {
      final p = await _providerWith(100, completedEvery: 2);
      expect(p.completionRate, closeTo(0.5, 0.01));
    });

    test('pendingCount + inProgressCount + completedCount = 100', () async {
      final p = await _providerWith(100,
          completedEvery: 3, inProgressEvery: 5);
      expect(
        p.pendingCount + p.inProgressCount + p.completedCount,
        100,
      );
    });
  });

  // ── Escala: 500 tarefas ──────────────────────────────────────────────────

  group('Stress — 500 tarefas', () {
    test('totalTasks = 500 após inserção em lote', () async {
      final p = await _providerWith(500);
      expect(p.totalTasks, 500);
    });

    test('completionRate preciso com 500 tarefas (25% concluídas)', () async {
      final p = await _providerWith(500, completedEvery: 4);
      expect(p.completionRate, closeTo(0.25, 0.01));
    });

    test('taskCountByArea soma sempre = totalTasks', () async {
      final p = await _providerWith(500);
      final counts = p.taskCountByArea();
      final sum = counts.values.fold(0, (a, b) => a + b);
      expect(sum, p.totalTasks);
    });

    test('activeTasksByQuadrant soma = total - completed', () async {
      final p = await _providerWith(500, completedEvery: 4);
      final dist  = p.activeTasksByQuadrant;
      final total = dist.values.fold(0, (a, b) => a + b);
      expect(total, p.totalTasks - p.completedCount);
    });

    test('taskCountByArea com filtro pending + completed = total por área', () async {
      final p = await _providerWith(500, completedEvery: 2);
      for (final area in kAreas) {
        final all        = p.taskCountByArea()[area.id] ?? 0;
        final pending    = p.taskCountByArea(statusFilter: 'pending')[area.id] ?? 0;
        final inProgress = p.taskCountByArea(statusFilter: 'in_progress')[area.id] ?? 0;
        final completed  = p.taskCountByArea(statusFilter: 'completed')[area.id] ?? 0;
        expect(pending + inProgress + completed, all,
            reason: 'Área ${area.id}: soma dos status ≠ total');
      }
    });
  });

  // ── Escala: 1000 tarefas ─────────────────────────────────────────────────

  group('Stress — 1000 tarefas', () {
    test('totalTasks = 1000 após inserção em lote', () async {
      final p = await _providerWith(1000);
      expect(p.totalTasks, 1000);
    }, timeout: const Timeout(Duration(seconds: 120)));

    test('sem duplicatas em tasks após 1000 inserções', () async {
      final p = await _providerWith(1000);
      final ids = p.tasks.map((t) => t.id).toSet();
      expect(ids.length, p.totalTasks);
    }, timeout: const Timeout(Duration(seconds: 120)));

    test('completionRate entre 0 e 1 com 1000 tarefas mistas', () async {
      final p = await _providerWith(1000, completedEvery: 5);
      expect(p.completionRate, greaterThanOrEqualTo(0.0));
      expect(p.completionRate, lessThanOrEqualTo(1.0));
    }, timeout: const Timeout(Duration(seconds: 120)));

    test('activeTasksByQuadrant sempre tem exatamente 4 chaves', () async {
      final p = await _providerWith(1000, completedEvery: 3);
      expect(p.activeTasksByQuadrant.keys.toSet(), {1, 2, 3, 4});
    }, timeout: const Timeout(Duration(seconds: 120)));
  });

  // ── Mix calendário + usuário em escala ───────────────────────────────────

  group('Stress — mix usuário + calendário (50/50)', () {
    test('100 user + 100 calendar: totalTasks = 200', () async {
      final p = await _providerWith(100);
      final events = List.generate(
          100, (i) => _event('ce$i'));
      p.syncCalendarTasks(events, 'u1');
      expect(p.totalTasks, 200);
      expect(p.userTasksCount, 100);
      expect(p.calendarTasksCount, 100);
    });

    test('completionRate com mix: concluir todas as de usuário = 0.5', () async {
      final p = await _providerWith(50);
      p.syncCalendarTasks(
          List.generate(50, (i) => _event('ce$i')), 'u1');
      for (var i = 0; i < 50; i++) {
        await p.completeTask('t$i');
      }
      expect(p.completionRate, closeTo(0.5, 0.01));
    });

    test('re-sync substitui calendário sem afetar tarefas de usuário', () async {
      final p = await _providerWith(50);
      p.syncCalendarTasks(
          List.generate(50, (i) => _event('ce$i')), 'u1');
      // Segundo sync com eventos completamente diferentes
      p.syncCalendarTasks(
          List.generate(30, (i) => _event('cx$i')), 'u1');
      expect(p.userTasksCount, 50);
      expect(p.calendarTasksCount, 30);
      expect(p.totalTasks, 80);
    });

    test('activeTasksByQuadrant soma correta com mix 100+100', () async {
      final p = await _providerWith(100);
      p.syncCalendarTasks(
          List.generate(100, (i) => _event('e$i')), 'u1');
      final dist  = p.activeTasksByQuadrant;
      final total = dist.values.fold(0, (a, b) => a + b);
      // Nenhuma concluída → total ativo = totalTasks
      expect(total, p.totalTasks);
    });
  });

  // ── Distribuições extremas ───────────────────────────────────────────────

  group('Stress — distribuições extremas', () {
    test('todas as tarefas no mesmo quadrante', () async {
      final p = await _makeProvider();
      for (var i = 0; i < 200; i++) {
        await p.addTask(TaskModel(
          id: 't$i',
          userId: 'u1',
          title: 'T$i',
          areaId: 'career',
          eisenhowerQ: 1, // todas no Q1
          createdAt: DateTime.now(),
        ));
      }
      final dist = p.activeTasksByQuadrant;
      expect(dist[1], 200);
      expect(dist[2], 0);
      expect(dist[3], 0);
      expect(dist[4], 0);
    });

    test('todas as tarefas na mesma área', () async {
      final p = await _makeProvider();
      for (var i = 0; i < 150; i++) {
        await p.addTask(TaskModel(
          id: 't$i',
          userId: 'u1',
          title: 'T$i',
          areaId: 'finances', // todas em finances
          eisenhowerQ: 2,
          createdAt: DateTime.now(),
        ));
      }
      final counts = p.taskCountByArea();
      expect(counts['finances'], 150);
      expect(counts.length, 1); // só 1 área
    });

    test('1 tarefa: completionRate = 0 e depois 1.0', () async {
      final p = await _makeProvider();
      await p.addTask(_makeTask('single'));
      expect(p.completionRate, 0.0);
      await p.completeTask('single');
      expect(p.completionRate, 1.0);
    });

    test('avgCompletionTime com 200 tarefas concluídas — valor não nulo e positivo', () async {
      final p = await _makeProvider();
      for (var i = 0; i < 200; i++) {
        final created =
            DateTime.now().subtract(Duration(hours: 1 + i % 24));
        await p.addTask(TaskModel(
          id: 't$i',
          userId: 'u1',
          title: 'T$i',
          areaId: 'career',
          createdAt: created,
        ));
        await p.completeTask('t$i');
      }
      final avg = p.avgCompletionTime;
      expect(avg, isNotNull);
      expect(avg!.inMinutes, greaterThan(0));
    });

    test('operações encadeadas: add→complete→reopen×50 mantém consistência', () async {
      final p = await _makeProvider();
      for (var i = 0; i < 50; i++) {
        await p.addTask(_makeTask('t$i'));
        await p.completeTask('t$i');
        await p.moveToPending('t$i');
      }
      expect(p.pendingCount, 50);
      expect(p.completedCount, 0);
      expect(p.completionRate, 0.0);
      expect(p.totalTasks, p.pendingCount + p.inProgressCount + p.completedCount);
    });

    test('deleteTask em lote: métricas corretas após 100 exclusões', () async {
      final p = await _makeProvider();
      for (var i = 0; i < 200; i++) {
        await p.addTask(_makeTask('t$i'));
      }
      for (var i = 0; i < 100; i++) {
        await p.deleteTask('t$i');
      }
      expect(p.totalTasks, 100);
      expect(p.pendingCount, 100);
      expect(p.completionRate, 0.0);
    });

    test('PRNG: 300 tarefas aleatórias — invariantes mantidas', () async {
      final rng = math.Random(42); // semente fixa para reprodutibilidade
      final p   = await _makeProvider();
      for (var i = 0; i < 300; i++) {
        final area = kAreas[rng.nextInt(kAreas.length)].id;
        final q    = rng.nextInt(4) + 1;
        await p.addTask(TaskModel(
          id: 't$i',
          userId: 'u1',
          title: 'T$i',
          areaId: area,
          eisenhowerQ: q,
          createdAt: DateTime.now()
              .subtract(Duration(minutes: rng.nextInt(10080))),
        ));
        // Concluir aleatoriamente ≈ 30% das tarefas
        if (rng.nextDouble() < 0.3) await p.completeTask('t$i');
      }

      // Invariante: soma dos status = totalTasks
      expect(
        p.pendingCount + p.inProgressCount + p.completedCount,
        p.totalTasks,
      );
      // Invariante: activeTasksByQuadrant soma = total - completed
      final quadSum =
          p.activeTasksByQuadrant.values.fold(0, (a, b) => a + b);
      expect(quadSum, p.totalTasks - p.completedCount);
      // Invariante: taskCountByArea soma = totalTasks
      final areaSum =
          p.taskCountByArea().values.fold(0, (a, b) => a + b);
      expect(areaSum, p.totalTasks);
      // Invariante: completionRate em [0, 1]
      expect(p.completionRate, inInclusiveRange(0.0, 1.0));
    });
  });
}

// ── Factory auxiliar ──────────────────────────────────────────────────────────

TaskModel _makeTask(String id) => TaskModel(
      id: id,
      userId: 'u1',
      title: 'T$id',
      areaId: 'career',
      eisenhowerQ: 2,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    );
