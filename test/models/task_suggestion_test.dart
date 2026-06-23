import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance_tracker/models/task_suggestion.dart';

void main() {
  group('TaskSuggestion — fromJson', () {
    test('parseia campos corretamente', () {
      final s = TaskSuggestion.fromJson('sug_1', {
        'title': 'Meditar 10 minutos',
        'description': 'Prática diária de mindfulness',
        'areaId': 'health_mental',
        'eisenhowerQ': 2,
        'isMIT': true,
        'reasoning': 'Score baixo em saúde mental',
      });
      expect(s.id, 'sug_1');
      expect(s.title, 'Meditar 10 minutos');
      expect(s.description, 'Prática diária de mindfulness');
      expect(s.areaId, 'health_mental');
      expect(s.eisenhowerQ, 2);
      expect(s.isMIT, true);
      expect(s.reasoning, 'Score baixo em saúde mental');
    });

    test('usa defaults para campos ausentes', () {
      final s = TaskSuggestion.fromJson('sug_2', {
        'title': 'Tarefa mínima',
        'areaId': 'career',
      });
      expect(s.description, '');
      expect(s.eisenhowerQ, 3); // Q3 = padrão (−Urgente +Importante)
      expect(s.isMIT, false);
      expect(s.reasoning, '');
    });

    test('clamp eisenhowerQ para intervalo 1-4', () {
      final s0 = TaskSuggestion.fromJson('x', {'title': 'T', 'areaId': 'career', 'eisenhowerQ': 0});
      expect(s0.eisenhowerQ, 1);

      final s5 = TaskSuggestion.fromJson('y', {'title': 'T', 'areaId': 'career', 'eisenhowerQ': 5});
      expect(s5.eisenhowerQ, 4);
    });

    test('areaId inválida usa fallback career', () {
      final s = TaskSuggestion.fromJson('x', {
        'title': 'T',
        'areaId': 'area_inexistente',
      });
      expect(s.areaId, 'career');
    });

    test('areaId null usa fallback career', () {
      final s = TaskSuggestion.fromJson('x', {'title': 'T'});
      expect(s.areaId, 'career');
    });
  });

  group('TaskSuggestion — labels', () {
    TaskSuggestion make(int q) => TaskSuggestion(
          id: 'x',
          title: 'T',
          description: '',
          areaId: 'career',
          eisenhowerQ: q,
          reasoning: '',
        );

    test('eisenhowerLabel correto para cada quadrante', () {
      expect(make(1).eisenhowerLabel, 'Faça Agora');
      expect(make(2).eisenhowerLabel, 'Delegue');
      expect(make(3).eisenhowerLabel, 'Agende');
      expect(make(4).eisenhowerLabel, 'Elimine');
    });

    test('eisenhowerEmoji correto para cada quadrante', () {
      expect(make(1).eisenhowerEmoji, '🔴');
      expect(make(2).eisenhowerEmoji, '🟡');
      expect(make(3).eisenhowerEmoji, '🟢');
      expect(make(4).eisenhowerEmoji, '⚫');
    });
  });

  group('TaskSuggestion — trim', () {
    test('title e reasoning são trimados', () {
      final s = TaskSuggestion.fromJson('x', {
        'title': '  Título com espaços  ',
        'areaId': 'career',
        'reasoning': '  Motivo com espaços  ',
      });
      expect(s.title, 'Título com espaços');
      expect(s.reasoning, 'Motivo com espaços');
    });
  });
}
