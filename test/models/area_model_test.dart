import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance_tracker/models/area_model.dart';

void main() {
  // ── GoalModel ─────────────────────────────────────────────────────────────

  group('GoalModel', () {
    test('toJson / fromJson round-trip preserva todos os campos', () {
      final goal = GoalModel(
        id: 'g1',
        areaId: 'career',
        title: 'Aprender Flutter',
        description: 'Dominar o framework',
        type: 'annual',
        status: 'in_progress',
        progress: 45.5,
        targetDate: DateTime(2024, 12, 31),
        createdAt: DateTime(2024, 1, 1),
      );
      final restored = GoalModel.fromJson(goal.toJson());
      expect(restored.id, goal.id);
      expect(restored.areaId, goal.areaId);
      expect(restored.title, goal.title);
      expect(restored.description, goal.description);
      expect(restored.type, goal.type);
      expect(restored.status, goal.status);
      expect(restored.progress, goal.progress);
      expect(restored.targetDate, goal.targetDate);
    });

    test('fromJson usa defaults quando campos opcionais ausentes', () {
      final g = GoalModel.fromJson({
        'id': 'g',
        'areaId': 'career',
        'title': 'Meta',
        'createdAt': DateTime(2024, 1, 1).toIso8601String(),
      });
      expect(g.description, '');
      expect(g.type, 'quarterly');
      expect(g.status, 'not_started');
      expect(g.progress, 0);
      expect(g.targetDate, null);
      expect(g.completedAt, null);
    });

    test('completedAt é serializado e desserializado corretamente', () {
      final completedAt = DateTime(2024, 6, 15);
      final g = GoalModel(
        id: 'g',
        areaId: 'career',
        title: 'Meta',
        completedAt: completedAt,
        createdAt: DateTime(2024, 1, 1),
      );
      final restored = GoalModel.fromJson(g.toJson());
      expect(restored.completedAt, completedAt);
    });

    test('status pode ser not_started / in_progress / completed', () {
      for (final status in ['not_started', 'in_progress', 'completed']) {
        final g = GoalModel(
          id: 'g',
          areaId: 'career',
          title: 'T',
          status: status,
          createdAt: DateTime(2024, 1, 1),
        );
        expect(GoalModel.fromJson(g.toJson()).status, status);
      }
    });
  });

  // ── AreaModel ─────────────────────────────────────────────────────────────

  group('AreaModel', () {
    test('currentScore padrão é 5', () {
      final a = AreaModel(id: 'x', name: 'Teste', icon: '⭐');
      expect(a.currentScore, 5);
    });

    test('goals é lista vazia por padrão', () {
      final a = AreaModel(id: 'x', name: 'Teste', icon: '⭐');
      expect(a.goals, isNotNull);
      expect(a.goals, isEmpty);
    });

    test('toJson / fromJson round-trip preserva campos principais', () {
      final area = AreaModel(
        id: 'career',
        name: 'Carreira',
        icon: '🚀',
        currentScore: 7.5,
        importance: 'high',
      );
      final restored = AreaModel.fromJson(area.toJson());
      expect(restored.id, area.id);
      expect(restored.name, area.name);
      expect(restored.icon, area.icon);
      expect(restored.currentScore, area.currentScore);
      expect(restored.importance, area.importance);
    });

    test('fromJson com goals aninhados', () {
      final json = {
        'id': 'career',
        'name': 'Carreira',
        'icon': '🚀',
        'currentScore': 8.0,
        'importance': '',
        'goals': [
          {
            'id': 'g1',
            'areaId': 'career',
            'title': 'Meta 1',
            'createdAt': DateTime(2024, 1, 1).toIso8601String(),
          },
          {
            'id': 'g2',
            'areaId': 'career',
            'title': 'Meta 2',
            'createdAt': DateTime(2024, 2, 1).toIso8601String(),
          },
        ],
      };
      final a = AreaModel.fromJson(json);
      expect(a.goals.length, 2);
      expect(a.goals.first.title, 'Meta 1');
      expect(a.goals.last.title, 'Meta 2');
    });

    test('goals podem ser adicionados mutavelmente', () {
      final area = AreaModel(id: 'career', name: 'Carreira', icon: '🚀');
      final goal = GoalModel(
        id: 'g1',
        areaId: 'career',
        title: 'Nova meta',
        createdAt: DateTime(2024, 1, 1),
      );
      area.goals.add(goal);
      expect(area.goals.length, 1);
      expect(area.goals.first.id, 'g1');
    });

    test('toJson serializa goals corretamente', () {
      final area = AreaModel(
        id: 'career',
        name: 'Carreira',
        icon: '🚀',
        goals: [
          GoalModel(
              id: 'g1',
              areaId: 'career',
              title: 'Meta',
              createdAt: DateTime(2024, 1, 1)),
        ],
      );
      final json = area.toJson();
      expect((json['goals'] as List).length, 1);
    });

    test('fromJson sem goals retorna lista vazia', () {
      final a = AreaModel.fromJson({
        'id': 'x',
        'name': 'T',
        'icon': '⭐',
      });
      expect(a.goals, isEmpty);
    });
  });
}
