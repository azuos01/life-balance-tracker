class SubtaskModel {
  final String id;
  String title;
  int estimatedHours;
  bool isCompleted;
  DateTime? completedAt;

  SubtaskModel({
    required this.id,
    required this.title,
    this.estimatedHours = 2,
    this.isCompleted = false,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'estimatedHours': estimatedHours,
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory SubtaskModel.fromJson(Map<String, dynamic> j) => SubtaskModel(
        id: j['id'] as String,
        title: j['title'] as String,
        estimatedHours: j['estimatedHours'] as int? ?? 2,
        isCompleted: j['isCompleted'] as bool? ?? false,
        completedAt: j['completedAt'] != null
            ? DateTime.parse(j['completedAt'] as String)
            : null,
      );
}

/// Quadrantes Eisenhower (definição vigente):
///   Q1 = +Urgente +Importante  → Faça Agora  🔴
///   Q2 = +Urgente −Importante  → Delegue     🟡
///   Q3 = −Urgente +Importante  → Agende      🟢
///   Q4 = −Urgente −Importante  → Elimine     ⚫
///
/// Ambientes:
///   'indoor'       → não afetado por clima
///   'outdoor'      → afetado por condições climáticas
///   'unspecified'  → detecção automática por palavras-chave
///
/// Status Kanban:
///   'pending'     → Planejado
///   'in_progress' → Em Andamento
///   'completed'   → Feito
///   'blocked'     → Bloqueado
class TaskModel {
  final String id;         // Formato: YYYYMMDDHHMMSSXX (ex: 20260623145830AA)
  final String userId;
  String title;
  String description;
  String areaId;
  int eisenhowerQ;         // 1–4
  bool isMIT;
  int mitOrder;
  String status;           // 'pending' | 'in_progress' | 'completed' | 'blocked'
  DateTime? dueDate;
  double? estimatedHours;  // Horas estimadas de execução (nível tarefa)
  String environment;      // 'indoor' | 'outdoor' | 'unspecified'
  int progressPercent;     // 0–100 — progresso manual dentro do estágio atual
  List<SubtaskModel> subtasks;
  final DateTime createdAt;
  DateTime? completedAt;
  final bool isFromCalendar;
  final String? calendarEventId;
  final String? locationAddress;

  TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    required this.areaId,
    this.eisenhowerQ = 3,       // Padrão: Q3 = Importante, não urgente
    this.isMIT = false,
    this.mitOrder = 0,
    this.status = 'pending',
    this.dueDate,
    this.estimatedHours,
    this.environment = 'unspecified',
    this.progressPercent = 0,
    List<SubtaskModel>? subtasks,
    required this.createdAt,
    this.completedAt,
    this.isFromCalendar = false,
    this.calendarEventId,
    this.locationAddress,
  }) : subtasks = subtasks ?? [];

  // ── Computed ───────────────────────────────────────────────────────────────

  bool get hasLocation =>
      locationAddress != null && locationAddress!.trim().isNotEmpty;

  String? get googleMapsUrl {
    if (!hasLocation) return null;
    final encoded = Uri.encodeComponent(locationAddress!.trim());
    return 'https://www.google.com/maps/search/$encoded';
  }

  /// Tarefa ao ar livre — afetada por condições climáticas.
  bool get isOutdoor {
    if (environment == 'outdoor') return true;
    if (environment == 'indoor') return false;
    // Fallback: verificação por palavras-chave (importada de weather_model)
    return _kOutdoorKeywords.any(
      (kw) => title.toLowerCase().contains(kw) ||
          description.toLowerCase().contains(kw),
    );
  }

  /// Pontos concedidos ao concluir a tarefa.
  int get points {
    final base = switch (eisenhowerQ) {
      1 => 100,  // Urgente + Importante
      2 => 50,   // Urgente − Importante
      3 => 75,   // − Urgente + Importante
      _ => 25,   // Não urgente, não importante
    };
    return isMIT ? (base * 1.5).round() : base;
  }

  String get eisenhowerLabel => switch (eisenhowerQ) {
        1 => 'Faça Agora',
        2 => 'Delegue',
        3 => 'Agende',
        _ => 'Elimine',
      };

  String get eisenhowerDescription => switch (eisenhowerQ) {
        1 => '+Urgente +Importante',
        2 => '+Urgente −Importante',
        3 => '−Urgente +Importante',
        _ => '−Urgente −Importante',
      };

  String get eisenhowerEmoji => switch (eisenhowerQ) {
        1 => '🔴',
        2 => '🟡',
        3 => '🟢',
        _ => '⚫',
      };

  String get statusLabel => switch (status) {
        'in_progress' => 'Em Andamento',
        'completed'   => 'Feito',
        'blocked'     => 'Bloqueado',
        _             => 'Planejado',
      };

  String get environmentLabel => switch (environment) {
        'indoor'  => 'Indoor',
        'outdoor' => 'Outdoor',
        _         => 'Não definido',
      };

  /// Progresso por subtarefas (0.0–1.0). Usado se houver subtarefas.
  int get completedSubtasks => subtasks.where((s) => s.isCompleted).length;
  double get subtaskProgress =>
      subtasks.isEmpty ? 0 : completedSubtasks / subtasks.length;

  // ── Serialização ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'description': description,
        'areaId': areaId,
        'eisenhowerQ': eisenhowerQ,
        'isMIT': isMIT,
        'mitOrder': mitOrder,
        'status': status,
        'dueDate': dueDate?.toIso8601String(),
        'estimatedHours': estimatedHours,
        'environment': environment,
        'progressPercent': progressPercent,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'isFromCalendar': isFromCalendar,
        'calendarEventId': calendarEventId,
        'locationAddress': locationAddress,
      };

  factory TaskModel.fromJson(Map<String, dynamic> j) => TaskModel(
        id: j['id'] as String,
        userId: j['userId'] as String,
        title: j['title'] as String,
        description: j['description'] as String? ?? '',
        areaId: j['areaId'] as String,
        eisenhowerQ: j['eisenhowerQ'] as int? ?? 3,
        isMIT: j['isMIT'] as bool? ?? false,
        mitOrder: j['mitOrder'] as int? ?? 0,
        status: j['status'] as String? ?? 'pending',
        dueDate: j['dueDate'] != null
            ? DateTime.parse(j['dueDate'] as String)
            : null,
        estimatedHours: (j['estimatedHours'] as num?)?.toDouble(),
        environment: j['environment'] as String? ?? 'unspecified',
        progressPercent: j['progressPercent'] as int? ?? 0,
        subtasks: (j['subtasks'] as List<dynamic>?)
                ?.map((s) => SubtaskModel.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: DateTime.parse(j['createdAt'] as String),
        completedAt: j['completedAt'] != null
            ? DateTime.parse(j['completedAt'] as String)
            : null,
        isFromCalendar: j['isFromCalendar'] as bool? ?? false,
        calendarEventId: j['calendarEventId'] as String?,
        locationAddress: j['locationAddress'] as String?,
      );

  TaskModel copyWith({
    String? title,
    String? description,
    String? areaId,
    int? eisenhowerQ,
    bool? isMIT,
    int? mitOrder,
    String? status,
    DateTime? dueDate,
    double? estimatedHours,
    String? environment,
    int? progressPercent,
    List<SubtaskModel>? subtasks,
    DateTime? completedAt,
    bool? isFromCalendar,
    String? calendarEventId,
    String? locationAddress,
    bool clearLocation = false,
    bool clearDueDate = false,
  }) =>
      TaskModel(
        id: id,
        userId: userId,
        title: title ?? this.title,
        description: description ?? this.description,
        areaId: areaId ?? this.areaId,
        eisenhowerQ: eisenhowerQ ?? this.eisenhowerQ,
        isMIT: isMIT ?? this.isMIT,
        mitOrder: mitOrder ?? this.mitOrder,
        status: status ?? this.status,
        dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
        estimatedHours: estimatedHours ?? this.estimatedHours,
        environment: environment ?? this.environment,
        progressPercent: progressPercent ?? this.progressPercent,
        subtasks: subtasks ?? this.subtasks,
        createdAt: createdAt,
        completedAt: completedAt ?? this.completedAt,
        isFromCalendar: isFromCalendar ?? this.isFromCalendar,
        calendarEventId: calendarEventId ?? this.calendarEventId,
        locationAddress:
            clearLocation ? null : (locationAddress ?? this.locationAddress),
      );
}

// Palavras-chave para detecção de tarefas outdoor quando environment='unspecified'
const _kOutdoorKeywords = [
  'limpeza', 'solar', 'pintura', 'jardinagem', 'obra', 'lavagem',
  'telhado', 'calha', 'muro', 'terreno', 'quintal', 'jardim',
  'poda', 'externo', 'outdoor', 'campo', 'praça', 'rua',
  'corrida', 'caminhada', 'ciclismo', 'futebol', 'esporte',
];
