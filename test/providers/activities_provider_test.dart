import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:life_balance_tracker/providers/activities_provider.dart';
import 'package:life_balance_tracker/models/activity_model.dart';
import 'package:life_balance_tracker/services/storage_service.dart';
import 'package:life_balance_tracker/constants/app_constants.dart';

Future<ActivitiesProvider> _makeProvider() async {
  SharedPreferences.setMockInitialValues({});
  await StorageService.instance.init();
  final p = ActivitiesProvider();
  p.initLocal();
  return p;
}

ActivityModel _activity({
  String id = 'act1',
  String areaId = 'career',
  String difficulty = 'medium',
}) =>
    ActivityModel(
      id: id,
      userId: 'u1',
      areaId: areaId,
      description: 'Atividade $id',
      difficulty: difficulty,
      createdAt: DateTime.now(),
    );

void main() {
  group('ActivitiesProvider — CRUD', () {
    test('addActivity adiciona à lista', () async {
      final p = await _makeProvider();
      await p.addActivity(_activity());
      expect(p.totalActivities, 1);
    });

    test('addActivity retorna XP positivo', () async {
      final p = await _makeProvider();
      final xp = await p.addActivity(_activity());
      expect(xp, greaterThan(0));
    });

    test('addActivity retorna XP correto por dificuldade', () async {
      final p = await _makeProvider();
      final easyXP = await p.addActivity(_activity(id: 'a1', difficulty: 'easy'));
      final mediumXP = await p.addActivity(_activity(id: 'a2', difficulty: 'medium'));
      final hardXP = await p.addActivity(_activity(id: 'a3', difficulty: 'hard'));
      expect(easyXP, kXpEasy);
      expect(mediumXP, kXpMedium);
      expect(hardXP, kXpHard);
    });

    test('addActivity com dificuldade desconhecida usa XP de medium', () async {
      final p = await _makeProvider();
      final xp = await p.addActivity(_activity(difficulty: 'unknown'));
      expect(xp, kXpMedium);
    });

    test('deleteActivity remove a atividade correta', () async {
      final p = await _makeProvider();
      await p.addActivity(_activity(id: 'a1'));
      await p.addActivity(_activity(id: 'a2'));
      await p.deleteActivity('a1');
      expect(p.totalActivities, 1);
      expect(p.activities.any((a) => a.id == 'a1'), false);
      expect(p.activities.any((a) => a.id == 'a2'), true);
    });

    test('múltiplas atividades são adicionadas corretamente', () async {
      final p = await _makeProvider();
      for (var i = 1; i <= 5; i++) {
        await p.addActivity(_activity(id: 'a$i'));
      }
      expect(p.totalActivities, 5);
    });
  });

  group('ActivitiesProvider — XP e agrupamentos', () {
    test('xpByArea agrupa XP por área', () async {
      final p = await _makeProvider();
      await p.addActivity(_activity(id: 'a1', areaId: 'career', difficulty: 'medium'));
      await p.addActivity(_activity(id: 'a2', areaId: 'career', difficulty: 'medium'));
      await p.addActivity(_activity(id: 'a3', areaId: 'health_physical', difficulty: 'easy'));
      final byArea = p.xpByArea;
      expect(byArea.containsKey('career'), true);
      expect(byArea.containsKey('health_physical'), true);
      // 2x medium > 1x easy
      expect(byArea['career']!, greaterThan(byArea['health_physical']!));
    });

    test('xpByArea retorna mapa vazio quando não há atividades', () async {
      final p = await _makeProvider();
      expect(p.xpByArea, isEmpty);
    });

    test('activitiesByArea filtra por área corretamente', () async {
      final p = await _makeProvider();
      await p.addActivity(_activity(id: 'a1', areaId: 'career'));
      await p.addActivity(_activity(id: 'a2', areaId: 'health_physical'));
      await p.addActivity(_activity(id: 'a3', areaId: 'career'));
      expect(p.activitiesByArea('career').length, 2);
      expect(p.activitiesByArea('health_physical').length, 1);
      expect(p.activitiesByArea('finances'), isEmpty);
    });

    test('activityHeatmap agrupa atividades por dia', () async {
      final p = await _makeProvider();
      // Todas as atividades são criadas com DateTime.now() no mesmo dia
      await p.addActivity(_activity(id: 'a1'));
      await p.addActivity(_activity(id: 'a2'));
      final heatmap = p.activityHeatmap;
      expect(heatmap.isNotEmpty, true);
      // Soma de todas as atividades no heatmap deve ser 2
      final total = heatmap.values.fold(0, (sum, v) => sum + v);
      expect(total, 2);
    });

    test('areasActiveThisWeek retorna áreas com atividades recentes', () async {
      final p = await _makeProvider();
      await p.addActivity(_activity(id: 'a1', areaId: 'career'));
      final active = p.areasActiveThisWeek();
      expect(active.contains('career'), true);
    });
  });

  group('ActivitiesProvider — check-in matinal', () {
    test('hasMorningCheckIn é false sem check-in do dia', () async {
      final p = await _makeProvider();
      expect(p.hasMorningCheckIn, false);
    });

    test('saveMorningCheckIn cria check-in', () async {
      final p = await _makeProvider();
      await p.saveMorningCheckIn(
        userId: 'u1',
        mood: 4,
        energy: 3,
        intentions: ['Estudar', 'Exercitar'],
        gratitude: 'Família',
      );
      expect(p.hasMorningCheckIn, true);
    });

    test('saveMorningCheckIn salva os dados corretos', () async {
      final p = await _makeProvider();
      await p.saveMorningCheckIn(
        userId: 'u1',
        mood: 5,
        energy: 4,
        intentions: ['Meta A', 'Meta B'],
        gratitude: 'Saúde',
      );
      expect(p.todayCheckIn?.morningMood, 5);
      expect(p.todayCheckIn?.morningEnergy, 4);
      expect(p.todayCheckIn?.intentions, contains('Meta A'));
      expect(p.todayCheckIn?.gratitude, 'Saúde');
    });

    test('saveMorningCheckIn em check-in existente atualiza em vez de criar novo', () async {
      final p = await _makeProvider();
      await p.saveMorningCheckIn(
        userId: 'u1',
        mood: 3, energy: 2, intentions: ['A'], gratitude: 'G',
      );
      await p.saveMorningCheckIn(
        userId: 'u1',
        mood: 5, energy: 5, intentions: ['B'], gratitude: 'GG',
      );
      expect(p.checkIns.length, 1); // apenas 1 check-in por dia
      expect(p.todayCheckIn?.morningMood, 5);
    });
  });

  group('ActivitiesProvider — check-in noturno', () {
    test('hasEveningCheckIn é false sem check-in noturno', () async {
      final p = await _makeProvider();
      expect(p.hasEveningCheckIn, false);
    });

    test('saveEveningCheckIn atualiza check-in existente', () async {
      final p = await _makeProvider();
      await p.saveMorningCheckIn(
        userId: 'u1', mood: 5, energy: 4,
        intentions: ['Meta'], gratitude: 'Saúde',
      );
      await p.saveEveningCheckIn(
        userId: 'u1',
        reflection: 'Dia produtivo',
        tomorrowPlan: 'Continuar estudos',
        dayScore: 8,
      );
      expect(p.hasEveningCheckIn, true);
      expect(p.todayCheckIn?.eveningReflection, 'Dia produtivo');
      expect(p.todayCheckIn?.overallDayScore, 8);
    });

    test('saveEveningCheckIn sem check-in matinal cria novo', () async {
      final p = await _makeProvider();
      await p.saveEveningCheckIn(
        userId: 'u1',
        reflection: 'Reflexão',
        tomorrowPlan: 'Plano',
        dayScore: 7,
      );
      expect(p.hasEveningCheckIn, true);
      expect(p.checkIns.length, 1);
    });

    test('eveningCheckInsCount conta check-ins noturnos', () async {
      final p = await _makeProvider();
      expect(p.eveningCheckInsCount, 0);
      await p.saveEveningCheckIn(
        userId: 'u1',
        reflection: 'Teste',
        tomorrowPlan: 'Plano',
        dayScore: 6,
      );
      expect(p.eveningCheckInsCount, 1);
    });

    test('todayCheckIn retorna null sem nenhum check-in', () async {
      final p = await _makeProvider();
      expect(p.todayCheckIn, null);
    });
  });
}
