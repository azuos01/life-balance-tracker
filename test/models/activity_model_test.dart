import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance_tracker/models/activity_model.dart';

void main() {
  group('ActivityModel', () {
    late ActivityModel activity;

    setUp(() {
      activity = ActivityModel(
        id: 'act1',
        userId: 'user1',
        areaId: 'career',
        description: 'Estudo de Flutter',
        durationMinutes: 60,
        difficulty: 'medium',
        xpEarned: 50,
        tags: ['flutter', 'dart'],
        createdAt: DateTime(2024, 6, 1, 9),
      );
    });

    test('toJson / fromJson round-trip preserva todos os campos', () {
      final restored = ActivityModel.fromJson(activity.toJson());
      expect(restored.id, activity.id);
      expect(restored.userId, activity.userId);
      expect(restored.areaId, activity.areaId);
      expect(restored.description, activity.description);
      expect(restored.durationMinutes, activity.durationMinutes);
      expect(restored.difficulty, activity.difficulty);
      expect(restored.xpEarned, activity.xpEarned);
      expect(restored.tags, activity.tags);
      expect(restored.createdAt, activity.createdAt);
    });

    test('fromJson usa defaults quando campos opcionais ausentes', () {
      final a = ActivityModel.fromJson({
        'id': 'x',
        'userId': 'u',
        'areaId': 'career',
        'description': 'Teste',
        'createdAt': DateTime(2024, 1, 1).toIso8601String(),
      });
      expect(a.durationMinutes, 30);
      expect(a.difficulty, 'medium');
      expect(a.xpEarned, 0);
      expect(a.tags, isEmpty);
      expect(a.relatedGoalId, null);
    });

    test('tags são preservadas corretamente no round-trip', () {
      final restored = ActivityModel.fromJson(activity.toJson());
      expect(restored.tags, containsAll(['flutter', 'dart']));
      expect(restored.tags.length, 2);
    });

    test('tags list não é null por padrão (lista vazia)', () {
      final a = ActivityModel(
        id: 'x',
        userId: 'u',
        areaId: 'career',
        description: 'D',
        createdAt: DateTime(2024, 1, 1),
      );
      expect(a.tags, isNotNull);
      expect(a.tags, isEmpty);
    });

    test('relatedGoalId pode ser null ou preenchido', () {
      expect(activity.relatedGoalId, null);

      final withGoal = ActivityModel(
        id: 'act2',
        userId: 'u',
        areaId: 'career',
        description: 'Com meta',
        createdAt: DateTime(2024, 1, 1),
        relatedGoalId: 'goal1',
      );
      expect(withGoal.relatedGoalId, 'goal1');

      final restored = ActivityModel.fromJson(withGoal.toJson());
      expect(restored.relatedGoalId, 'goal1');
    });

    test('difficulty easy/medium/hard são preservados corretamente', () {
      for (final diff in ['easy', 'medium', 'hard']) {
        final a = ActivityModel(
          id: diff,
          userId: 'u',
          areaId: 'career',
          description: 'D',
          difficulty: diff,
          createdAt: DateTime(2024, 1, 1),
        );
        expect(ActivityModel.fromJson(a.toJson()).difficulty, diff);
      }
    });

    test('createdAt é serializado e desserializado corretamente', () {
      final now = DateTime(2024, 6, 15, 14, 30, 0);
      final a = ActivityModel(
        id: 'x',
        userId: 'u',
        areaId: 'career',
        description: 'D',
        createdAt: now,
      );
      final restored = ActivityModel.fromJson(a.toJson());
      expect(restored.createdAt, now);
    });
  });
}
