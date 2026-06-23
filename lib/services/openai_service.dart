import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task_model.dart';
import '../models/task_suggestion.dart';
import '../constants/app_constants.dart';

class OpenAIService {
  static const _endpoint = 'https://api.openai.com/v1/chat/completions';
  static const _model = 'gpt-4o-mini';
  static const _timeout = Duration(seconds: 45);

  Future<List<TaskSuggestion>> generateTaskSuggestions({
    required String apiKey,
    required List<TaskModel> currentTasks,
    required Map<String, double> areaScores,
  }) async {
    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': _model,
            'messages': [
              {'role': 'system', 'content': _systemPrompt},
              {
                'role': 'user',
                'content': _buildUserMessage(currentTasks, areaScores)
              },
            ],
            'temperature': 0.7,
            'max_tokens': 2000,
            'response_format': {'type': 'json_object'},
          }),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final msg = (body['error']?['message'] as String?) ??
          'Erro HTTP ${response.statusCode}';
      throw Exception(msg);
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    final content = body['choices'][0]['message']['content'] as String;
    final parsed = jsonDecode(content) as Map<String, dynamic>;
    final list = (parsed['suggestions'] as List?) ?? [];
    final now = DateTime.now().millisecondsSinceEpoch;
    return list.asMap().entries.map((e) {
      return TaskSuggestion.fromJson(
        'sug_${now}_${e.key}',
        e.value as Map<String, dynamic>,
      );
    }).toList();
  }

  static const _systemPrompt = '''
Você é um coach de produtividade especializado em equilíbrio de vida e Matriz de Eisenhower.
Analise as tarefas e os scores das áreas de vida do usuário e sugira tarefas para maximizar produtividade e equilíbrio.

REGRAS:
- Quadrantes: Q1=+Urgente+Importante(FaçaAgora), Q2=+Urgente−Importante(Delegue), Q3=−Urgente+Importante(Agende), Q4=−Urgente−Importante(Elimine)
- 80% das sugestões devem ser Q1 ou Q3
- Priorize áreas com scores baixos (abaixo de 5)
- Não duplique tarefas existentes
- Tarefas específicas e acionáveis (verbos no imperativo)
- isMIT=true em no máximo 2 tarefas absolutamente críticas
- Sugira entre 6 e 8 tarefas no total

ÁREAS VÁLIDAS: health_physical, health_mental, career, finances, relationships, family, intellectual, spirituality, leisure, contribution

Retorne SOMENTE JSON neste formato exato:
{"suggestions":[{"title":"string","description":"string","areaId":"string","eisenhowerQ":2,"isMIT":false,"reasoning":"string"}]}
''';

  String _buildUserMessage(
      List<TaskModel> tasks, Map<String, double> areaScores) {
    final pending =
        tasks.where((t) => t.status != 'completed').take(15).toList();
    final taskLines = pending.isEmpty
        ? '(nenhuma tarefa ativa)'
        : pending
            .map((t) =>
                '- [Q${t.eisenhowerQ}] ${t.title} (${_statusLabel(t.status)})')
            .join('\n');

    final scoreLines = areaScores.entries.map((e) {
      final area = kAreas.firstWhere(
        (a) => a.id == e.key,
        orElse: () => kAreas.first,
      );
      final bar = '█' * e.value.round() + '░' * (10 - e.value.round());
      return '${area.name}: $bar ${e.value.toStringAsFixed(1)}/10';
    }).join('\n');

    return '''
TAREFAS ATIVAS (${pending.length}):
$taskLines

SCORES DAS ÁREAS DE VIDA:
$scoreLines

Sugira novas tarefas prioritárias para maximizar minha produtividade e melhorar o equilíbrio nas áreas com menor score.
''';
  }

  static String _statusLabel(String s) => switch (s) {
    'pending' => 'A fazer',
    'in_progress' => 'Em andamento',
    'completed' => 'Concluída',
    _ => s,
  };
}
