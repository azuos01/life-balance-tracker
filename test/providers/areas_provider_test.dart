import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:life_balance_tracker/providers/areas_provider.dart';
import 'package:life_balance_tracker/models/area_model.dart';
import 'package:life_balance_tracker/services/storage_service.dart';
import 'package:life_balance_tracker/constants/app_constants.dart';

Future<AreasProvider> _makeProvider() async {
  SharedPreferences.setMockInitialValues({});
  await StorageService.instance.init();
  final p = AreasProvider();
  p.initLocal();
  return p;
}

void main() {
  group('AreasProvider — inicialização', () {
    test('initLocal carrega as 10 áreas padrão', () async {
      final p = await _makeProvider();
      expect(p.areas.length, kAreas.length);
    });

    test('todas as áreas padrão têm id, name e icon não-vazios', () async {
      final p = await _makeProvider();
      for (final area in p.areas) {
        expect(area.id, isNotEmpty);
        expect(area.name, isNotEmpty);
        expect(area.icon, isNotEmpty);
      }
    });

    test('score padrão de todas as áreas é 5', () async {
      final p = await _makeProvider();
      for (final area in p.areas) {
        expect(area.currentScore, 5);
      }
    });
  });

  group('AreasProvider — consultas', () {
    test('areaById retorna a área correta', () async {
      final p = await _makeProvider();
      final area = p.areaById('career');
      expect(area, isNotNull);
      expect(area!.id, 'career');
    });

    test('areaById retorna null para ID inexistente', () async {
      final p = await _makeProvider();
      expect(p.areaById('area_inexistente'), null);
    });

    test('overallBalance com score 5 está entre 0 e 100', () async {
      final p = await _makeProvider();
      expect(p.overallBalance, greaterThan(0));
      expect(p.overallBalance, lessThanOrEqualTo(100));
    });

    test('overallBalance = 100 quando todos os scores são 10', () async {
      final p = await _makeProvider();
      for (final area in p.areas) {
        await p.updateAreaScore(area.id, 10.0);
      }
      expect(p.overallBalance, 100.0);
    });

    test('overallBalance aumenta quando scores aumentam', () async {
      final p = await _makeProvider();
      final balanceBefore = p.overallBalance;
      await p.updateAreaScore('career', 10.0);
      expect(p.overallBalance, greaterThan(balanceBefore));
    });
  });

  group('AreasProvider — atualização de score', () {
    test('updateAreaScore atualiza o score dentro do intervalo válido', () async {
      final p = await _makeProvider();
      await p.updateAreaScore('career', 7.5);
      expect(p.areaById('career')!.currentScore, 7.5);
    });

    test('updateAreaScore clamps para 10 quando acima do máximo', () async {
      final p = await _makeProvider();
      await p.updateAreaScore('career', 15.0);
      expect(p.areaById('career')!.currentScore, 10.0);
    });

    test('updateAreaScore clamps para 1 quando abaixo do mínimo', () async {
      final p = await _makeProvider();
      await p.updateAreaScore('career', -5.0);
      expect(p.areaById('career')!.currentScore, 1.0);
    });

    test('updateAreaScore não afeta outras áreas', () async {
      final p = await _makeProvider();
      await p.updateAreaScore('career', 9.0);
      final health = p.areaById('health_physical');
      expect(health!.currentScore, 5.0); // inalterado
    });

    test('updateAllScores atualiza múltiplas áreas de uma vez', () async {
      final p = await _makeProvider();
      await p.updateAllScores({
        'career': 8.0,
        'finances': 6.0,
        'health_physical': 9.0,
      });
      expect(p.areaById('career')!.currentScore, 8.0);
      expect(p.areaById('finances')!.currentScore, 6.0);
      expect(p.areaById('health_physical')!.currentScore, 9.0);
    });
  });

  group('AreasProvider — metas', () {
    test('addGoal adiciona à área correta', () async {
      final p = await _makeProvider();
      final goal = GoalModel(
        id: 'g1',
        areaId: 'career',
        title: 'Meta de Carreira',
        createdAt: DateTime(2024, 1, 1),
      );
      await p.addGoal('career', goal);
      expect(p.areaById('career')!.goals.length, 1);
      expect(p.areaById('career')!.goals.first.title, 'Meta de Carreira');
    });

    test('addGoal não afeta outras áreas', () async {
      final p = await _makeProvider();
      await p.addGoal('career', GoalModel(
        id: 'g1',
        areaId: 'career',
        title: 'Meta',
        createdAt: DateTime(2024, 1, 1),
      ));
      expect(p.areaById('finances')!.goals, isEmpty);
    });

    test('deleteGoal remove a meta correta', () async {
      final p = await _makeProvider();
      await p.addGoal('career', GoalModel(
        id: 'g1', areaId: 'career', title: 'Meta',
        createdAt: DateTime(2024, 1, 1),
      ));
      await p.deleteGoal('career', 'g1');
      expect(p.areaById('career')!.goals, isEmpty);
    });

    test('updateGoal atualiza a meta existente', () async {
      final p = await _makeProvider();
      final goal = GoalModel(
        id: 'g1',
        areaId: 'career',
        title: 'Meta Original',
        createdAt: DateTime(2024, 1, 1),
      );
      await p.addGoal('career', goal);
      final updated = GoalModel(
        id: 'g1',
        areaId: 'career',
        title: 'Meta Atualizada',
        status: 'in_progress',
        progress: 50,
        createdAt: DateTime(2024, 1, 1),
      );
      await p.updateGoal('career', updated);
      final found = p.areaById('career')!.goals.first;
      expect(found.title, 'Meta Atualizada');
      expect(found.status, 'in_progress');
      expect(found.progress, 50);
    });

    test('allGoals retorna metas de todas as áreas', () async {
      final p = await _makeProvider();
      await p.addGoal('career', GoalModel(
        id: 'g1', areaId: 'career', title: 'G1',
        createdAt: DateTime(2024, 1, 1),
      ));
      await p.addGoal('finances', GoalModel(
        id: 'g2', areaId: 'finances', title: 'G2',
        createdAt: DateTime(2024, 1, 1),
      ));
      expect(p.allGoals.length, 2);
    });

    test('activeGoals exclui metas com status completed', () async {
      final p = await _makeProvider();
      await p.addGoal('career', GoalModel(
        id: 'g1', areaId: 'career', title: 'Ativa',
        status: 'in_progress', createdAt: DateTime(2024, 1, 1),
      ));
      await p.addGoal('career', GoalModel(
        id: 'g2', areaId: 'career', title: 'Concluída',
        status: 'completed', createdAt: DateTime(2024, 1, 1),
      ));
      expect(p.activeGoals.length, 1);
      expect(p.activeGoals.first.id, 'g1');
    });

    test('updateAreaImportance persiste a importância', () async {
      final p = await _makeProvider();
      await p.updateAreaImportance('career', 'high');
      expect(p.areaById('career')!.importance, 'high');
    });
  });
}
