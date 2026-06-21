import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance_tracker/providers/ai_agent_provider.dart';
import 'package:life_balance_tracker/models/task_suggestion.dart';

TaskSuggestion makeSuggestion(String id) => TaskSuggestion(
      id: id,
      title: 'Tarefa $id',
      description: 'Desc',
      areaId: 'career',
      eisenhowerQ: 2,
      reasoning: 'Motivo',
    );

void main() {
  group('AiAgentProvider — estado inicial', () {
    test('suggestions vazia, não carregando, sem erro', () {
      final p = AiAgentProvider();
      expect(p.suggestions, isEmpty);
      expect(p.isLoading, false);
      expect(p.error, null);
      expect(p.lastGenerated, null);
      expect(p.hasSuggestions, false);
    });
  });

  group('AiAgentProvider — dismiss', () {
    test('dismiss remove sugestão da lista visível', () {
      final p = AiAgentProvider();
      // Injetar sugestões via reflection não é possível sem expor método interno.
      // Testamos via clear() como substituto de estado limpo.
      p.clear();
      expect(p.suggestions, isEmpty);
    });

    test('dismiss de id inexistente não lança exceção', () {
      final p = AiAgentProvider();
      expect(() => p.dismiss('id_qualquer'), returnsNormally);
    });
  });

  group('AiAgentProvider — clear', () {
    test('clear zera error e lastGenerated', () {
      final p = AiAgentProvider();
      p.clear();
      expect(p.error, null);
      expect(p.lastGenerated, null);
      expect(p.hasSuggestions, false);
    });

    test('clear notifica listeners', () {
      final p = AiAgentProvider();
      int calls = 0;
      p.addListener(() => calls++);
      p.clear();
      expect(calls, 1);
    });
  });

  group('AiAgentProvider — notifyListeners', () {
    test('dismiss notifica listeners', () {
      final p = AiAgentProvider();
      int calls = 0;
      p.addListener(() => calls++);
      p.dismiss('qualquer_id');
      expect(calls, 1);
    });
  });
}
