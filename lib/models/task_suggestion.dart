/// Sugestão de tarefa gerada por IA (Agente ou análise de e-mails).
///
/// Quadrantes:
///   Q1 = +Urgente +Importante  → Faça Agora  🔴
///   Q2 = +Urgente −Importante  → Delegue     🟡
///   Q3 = −Urgente +Importante  → Agende      🟢
///   Q4 = −Urgente −Importante  → Elimine     ⚫
class TaskSuggestion {
  final String id;
  final String title;
  final String description;
  final String areaId;
  final int eisenhowerQ;     // 1–4
  final bool isMIT;
  final String reasoning;
  final DateTime? dueDate;
  final double? estimatedHours;
  final String environment;  // 'indoor' | 'outdoor' | 'unspecified'

  const TaskSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.areaId,
    required this.eisenhowerQ,
    this.isMIT = false,
    required this.reasoning,
    this.dueDate,
    this.estimatedHours,
    this.environment = 'unspecified',
  });

  factory TaskSuggestion.fromJson(String id, Map<String, dynamic> json) {
    return TaskSuggestion(
      id: id,
      title: (json['title'] as String?)?.trim() ?? 'Tarefa sugerida',
      description: (json['description'] as String?)?.trim() ?? '',
      areaId: _validArea(json['areaId'] as String?),
      eisenhowerQ: ((json['eisenhowerQ'] as int?) ?? 3).clamp(1, 4),
      isMIT: json['isMIT'] as bool? ?? false,
      reasoning: (json['reasoning'] as String?)?.trim() ?? '',
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'] as String)
          : null,
      estimatedHours: (json['estimatedHours'] as num?)?.toDouble(),
      environment: _validEnv(json['environment'] as String?),
    );
  }

  static const _validAreas = {
    'health_physical', 'health_mental', 'career', 'finances',
    'relationships', 'family', 'intellectual', 'spirituality',
    'leisure', 'contribution',
  };

  static String _validArea(String? id) =>
      (_validAreas.contains(id) ? id : 'career')!;

  static String _validEnv(String? v) =>
      (v == 'indoor' || v == 'outdoor') ? v! : 'unspecified';

  String get eisenhowerLabel => switch (eisenhowerQ) {
        1 => 'Faça Agora',
        2 => 'Delegue',
        3 => 'Agende',
        _ => 'Elimine',
      };

  String get eisenhowerEmoji => switch (eisenhowerQ) {
        1 => '🔴',
        2 => '🟡',
        3 => '🟢',
        _ => '⚫',
      };

  String get eisenhowerDescription => switch (eisenhowerQ) {
        1 => '+Urgente +Importante',
        2 => '+Urgente −Importante',
        3 => '−Urgente +Importante',
        _ => '−Urgente −Importante',
      };
}
