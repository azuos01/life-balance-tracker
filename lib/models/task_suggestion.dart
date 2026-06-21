class TaskSuggestion {
  final String id;
  final String title;
  final String description;
  final String areaId;
  final int eisenhowerQ;
  final bool isMIT;
  final String reasoning;

  const TaskSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.areaId,
    required this.eisenhowerQ,
    this.isMIT = false,
    required this.reasoning,
  });

  factory TaskSuggestion.fromJson(String id, Map<String, dynamic> json) {
    return TaskSuggestion(
      id: id,
      title: (json['title'] as String?)?.trim() ?? 'Tarefa sugerida',
      description: (json['description'] as String?)?.trim() ?? '',
      areaId: _validArea(json['areaId'] as String?),
      eisenhowerQ: ((json['eisenhowerQ'] as int?) ?? 2).clamp(1, 4),
      isMIT: json['isMIT'] as bool? ?? false,
      reasoning: (json['reasoning'] as String?)?.trim() ?? '',
    );
  }

  static const _validAreas = {
    'health_physical', 'health_mental', 'career', 'finances',
    'relationships', 'family', 'intellectual', 'spirituality',
    'leisure', 'contribution',
  };

  static String _validArea(String? id) =>
      (_validAreas.contains(id) ? id : 'career')!;

  String get eisenhowerLabel => switch (eisenhowerQ) {
    1 => 'Faça Agora',
    2 => 'Agende',
    3 => 'Delegue',
    _ => 'Elimine',
  };

  String get eisenhowerEmoji => switch (eisenhowerQ) {
    1 => '🔴',
    2 => '🟢',
    3 => '🟡',
    _ => '⚫',
  };
}
