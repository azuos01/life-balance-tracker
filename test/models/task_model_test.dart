import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance_tracker/models/task_model.dart';

void main() {
  // ── SubtaskModel ──────────────────────────────────────────────────────────

  group('SubtaskModel', () {
    test('toJson / fromJson round-trip completo', () {
      final sub = SubtaskModel(
        id: 'sub1',
        title: 'Subtarefa A',
        estimatedHours: 3,
        isCompleted: true,
        completedAt: DateTime(2024, 6, 1, 10),
      );
      final restored = SubtaskModel.fromJson(sub.toJson());
      expect(restored.id, sub.id);
      expect(restored.title, sub.title);
      expect(restored.estimatedHours, sub.estimatedHours);
      expect(restored.isCompleted, sub.isCompleted);
      expect(restored.completedAt, sub.completedAt);
    });

    test('fromJson usa defaults quando campos opcionais ausentes', () {
      final sub = SubtaskModel.fromJson({'id': 'x', 'title': 'Test'});
      expect(sub.estimatedHours, 2);
      expect(sub.isCompleted, false);
      expect(sub.completedAt, null);
    });

    test('completedAt null é serializado e desserializado corretamente', () {
      final sub = SubtaskModel(id: 's', title: 'T');
      final json = sub.toJson();
      expect(json['completedAt'], null);
      final restored = SubtaskModel.fromJson(json);
      expect(restored.completedAt, null);
    });
  });

  // ── TaskModel ─────────────────────────────────────────────────────────────

  group('TaskModel — valores padrão', () {
    late TaskModel task;

    setUp(() {
      task = TaskModel(
        id: 'task1',
        userId: 'user1',
        title: 'Tarefa Teste',
        description: 'Descrição',
        areaId: 'career',
        eisenhowerQ: 2,
        createdAt: DateTime(2024, 1, 1),
      );
    });

    test('valores padrão estão corretos', () {
      expect(task.eisenhowerQ, 2);
      expect(task.isMIT, false);
      expect(task.mitOrder, 0);
      expect(task.status, 'pending');
      expect(task.subtasks, isEmpty);
      expect(task.isFromCalendar, false);
      expect(task.calendarEventId, null);
      expect(task.completedAt, null);
      expect(task.dueDate, null);
    });
  });

  group('TaskModel — serialização', () {
    test('toJson / fromJson round-trip preserva todos os campos', () {
      final full = TaskModel(
        id: 't1',
        userId: 'u1',
        title: 'Reunião de equipe',
        description: 'Discutir sprint',
        areaId: 'career',
        eisenhowerQ: 1,
        isMIT: true,
        mitOrder: 2,
        status: 'in_progress',
        dueDate: DateTime(2024, 6, 15),
        createdAt: DateTime(2024, 6, 1),
        completedAt: null,
        isFromCalendar: false,
        subtasks: [SubtaskModel(id: 's1', title: 'Preparar pauta')],
      );
      final restored = TaskModel.fromJson(full.toJson());
      expect(restored.id, full.id);
      expect(restored.userId, full.userId);
      expect(restored.title, full.title);
      expect(restored.description, full.description);
      expect(restored.areaId, full.areaId);
      expect(restored.eisenhowerQ, full.eisenhowerQ);
      expect(restored.isMIT, full.isMIT);
      expect(restored.mitOrder, full.mitOrder);
      expect(restored.status, full.status);
      expect(restored.dueDate, full.dueDate);
      expect(restored.subtasks.length, 1);
      expect(restored.subtasks.first.title, 'Preparar pauta');
    });

    test('isFromCalendar e calendarEventId são preservados no round-trip', () {
      final calTask = TaskModel(
        id: 'cal_abc123',
        userId: 'user1',
        title: 'Reunião',
        areaId: 'career',
        createdAt: DateTime(2024, 6, 1),
        isFromCalendar: true,
        calendarEventId: 'abc123',
      );
      final restored = TaskModel.fromJson(calTask.toJson());
      expect(restored.isFromCalendar, true);
      expect(restored.calendarEventId, 'abc123');
    });

    test('fromJson usa defaults quando campos opcionais ausentes', () {
      final t = TaskModel.fromJson({
        'id': 'x',
        'userId': 'u',
        'title': 'Mínimo',
        'areaId': 'career',
        'createdAt': DateTime(2024, 1, 1).toIso8601String(),
      });
      expect(t.eisenhowerQ, 2);
      expect(t.isMIT, false);
      expect(t.mitOrder, 0);
      expect(t.status, 'pending');
      expect(t.isFromCalendar, false);
      expect(t.calendarEventId, null);
      expect(t.subtasks, isEmpty);
    });
  });

  group('TaskModel — eisenhower labels', () {
    late TaskModel base;
    setUp(() {
      base = TaskModel(
        id: 't',
        userId: 'u',
        title: 'T',
        areaId: 'career',
        createdAt: DateTime(2024, 1, 1),
      );
    });

    test('eisenhowerLabel retorna labels corretos', () {
      expect(base.copyWith(eisenhowerQ: 1).eisenhowerLabel, 'Faça Agora');
      expect(base.copyWith(eisenhowerQ: 2).eisenhowerLabel, 'Agende');
      expect(base.copyWith(eisenhowerQ: 3).eisenhowerLabel, 'Delegue');
      expect(base.copyWith(eisenhowerQ: 4).eisenhowerLabel, 'Elimine');
    });

    test('eisenhowerEmoji retorna emojis corretos', () {
      expect(base.copyWith(eisenhowerQ: 1).eisenhowerEmoji, '🔴');
      expect(base.copyWith(eisenhowerQ: 2).eisenhowerEmoji, '🟢');
      expect(base.copyWith(eisenhowerQ: 3).eisenhowerEmoji, '🟡');
      expect(base.copyWith(eisenhowerQ: 4).eisenhowerEmoji, '⚫');
    });
  });

  group('TaskModel — progresso e horas', () {
    late TaskModel base;
    setUp(() {
      base = TaskModel(
        id: 't',
        userId: 'u',
        title: 'T',
        areaId: 'career',
        createdAt: DateTime(2024, 1, 1),
      );
    });

    test('progress = 0 sem subtarefas', () {
      expect(base.progress, 0);
      expect(base.totalEstimatedHours, 0);
    });

    test('progress = 0.5 com metade das subtarefas concluídas', () {
      final t = base.copyWith(subtasks: [
        SubtaskModel(id: 's1', title: 'A', isCompleted: true),
        SubtaskModel(id: 's2', title: 'B', isCompleted: false),
      ]);
      expect(t.progress, 0.5);
    });

    test('progress = 1.0 com todas as subtarefas concluídas', () {
      final t = base.copyWith(subtasks: [
        SubtaskModel(id: 's1', title: 'A', isCompleted: true),
        SubtaskModel(id: 's2', title: 'B', isCompleted: true),
      ]);
      expect(t.progress, 1.0);
    });

    test('completedSubtasks conta corretamente', () {
      final t = base.copyWith(subtasks: [
        SubtaskModel(id: 's1', title: 'A', isCompleted: true),
        SubtaskModel(id: 's2', title: 'B', isCompleted: true),
        SubtaskModel(id: 's3', title: 'C', isCompleted: false),
      ]);
      expect(t.completedSubtasks, 2);
    });

    test('totalEstimatedHours soma horas de todas as subtarefas', () {
      final t = base.copyWith(subtasks: [
        SubtaskModel(id: 's1', title: 'A', estimatedHours: 3),
        SubtaskModel(id: 's2', title: 'B', estimatedHours: 5),
      ]);
      expect(t.totalEstimatedHours, 8);
    });
  });

  group('TaskModel — copyWith', () {
    late TaskModel task;
    setUp(() {
      task = TaskModel(
        id: 'task1',
        userId: 'user1',
        title: 'Original',
        areaId: 'career',
        eisenhowerQ: 2,
        createdAt: DateTime(2024, 1, 1),
        isFromCalendar: true,
        calendarEventId: 'cal_evt',
      );
    });

    test('copyWith preserva campos imutáveis (id, userId, createdAt, isFromCalendar)', () {
      final copy = task.copyWith(title: 'Novo', isMIT: true);
      expect(copy.id, task.id);
      expect(copy.userId, task.userId);
      expect(copy.createdAt, task.createdAt);
      expect(copy.isFromCalendar, task.isFromCalendar);
      expect(copy.calendarEventId, task.calendarEventId);
    });

    test('copyWith atualiza apenas os campos especificados', () {
      final copy = task.copyWith(eisenhowerQ: 1, status: 'completed');
      expect(copy.eisenhowerQ, 1);
      expect(copy.status, 'completed');
      expect(copy.title, task.title); // não alterado
      expect(copy.description, task.description); // não alterado
    });

    test('copyWith sem argumentos cria cópia idêntica', () {
      final copy = task.copyWith();
      expect(copy.id, task.id);
      expect(copy.title, task.title);
      expect(copy.status, task.status);
      expect(copy.eisenhowerQ, task.eisenhowerQ);
    });
  });

  // ── LocationAddress ───────────────────────────────────────────────────────

  group('TaskModel — locationAddress', () {
    TaskModel taskWithLocation(String address) => TaskModel(
          id: 't1',
          userId: 'u1',
          title: 'Reunião',
          areaId: 'career',
          createdAt: DateTime(2024, 1, 1),
          locationAddress: address,
        );

    test('hasLocation é false quando locationAddress é null', () {
      final t = TaskModel(
        id: 't1', userId: 'u1', title: 'T',
        areaId: 'career', createdAt: DateTime(2024, 1, 1),
      );
      expect(t.hasLocation, false);
    });

    test('hasLocation é false quando locationAddress é string vazia', () {
      final t = taskWithLocation('');
      expect(t.hasLocation, false);
    });

    test('hasLocation é false quando locationAddress é só espaços', () {
      final t = taskWithLocation('   ');
      expect(t.hasLocation, false);
    });

    test('hasLocation é true quando locationAddress tem conteúdo', () {
      final t = taskWithLocation('Av. Paulista, 1578 — São Paulo');
      expect(t.hasLocation, true);
    });

    test('googleMapsUrl retorna null quando não há localização', () {
      final t = TaskModel(
        id: 't1', userId: 'u1', title: 'T',
        areaId: 'career', createdAt: DateTime(2024, 1, 1),
      );
      expect(t.googleMapsUrl, null);
    });

    test('googleMapsUrl contém o endereço codificado', () {
      final t = taskWithLocation('Av. Paulista, São Paulo');
      expect(t.googleMapsUrl, isNotNull);
      expect(t.googleMapsUrl!.contains('maps.google.com') ||
             t.googleMapsUrl!.contains('google.com/maps'), true);
    });

    test('toJson / fromJson preserva locationAddress', () {
      final t = taskWithLocation('Rua das Flores, 42, Rio de Janeiro');
      final restored = TaskModel.fromJson(t.toJson());
      expect(restored.locationAddress, t.locationAddress);
    });

    test('fromJson com locationAddress ausente retorna null', () {
      final json = {
        'id': 't1', 'userId': 'u1', 'title': 'T',
        'areaId': 'career',
        'createdAt': DateTime(2024, 1, 1).toIso8601String(),
      };
      final t = TaskModel.fromJson(json);
      expect(t.locationAddress, null);
      expect(t.hasLocation, false);
    });

    test('copyWith com novo locationAddress atualiza o campo', () {
      final t = taskWithLocation('Endereço A');
      final copy = t.copyWith(locationAddress: 'Endereço B');
      expect(copy.locationAddress, 'Endereço B');
    });

    test('copyWith clearLocation: true remove o endereço', () {
      final t = taskWithLocation('Endereço A');
      final copy = t.copyWith(clearLocation: true);
      expect(copy.locationAddress, null);
      expect(copy.hasLocation, false);
    });

    test('copyWith sem locationAddress preserva o endereço existente', () {
      final t = taskWithLocation('Av. Brasil, 100');
      final copy = t.copyWith(title: 'Novo título');
      expect(copy.locationAddress, 'Av. Brasil, 100');
    });
  });
}
