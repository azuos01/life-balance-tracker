class SubtaskModel {
  final String id;
  String title;
  int estimatedHours; // 2–8 horas por subtarefa
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

/// Representa uma tarefa gerenciável com classificação Eisenhower e MIT.
///
/// Quadrantes Eisenhower:
///   1 = Urgente  + Importante  → Faça Agora
///   2 = Não Urgente + Importante → Agende
///   3 = Urgente  + Não Importante → Delegue
///   4 = Não Urgente + Não Importante → Elimine
class TaskModel {
  final String id;
  final String userId;
  String title;
  String description;
  String areaId; // ID de uma das 10 áreas da Roda da Vida
  int eisenhowerQ; // 1–4
  bool isMIT; // Most Important Task (máx 3 simultâneas)
  int mitOrder; // 0 = não MIT; 1, 2 ou 3 = posição no bloco MIT
  String status; // 'pending' | 'in_progress' | 'completed'
  DateTime? dueDate;
  List<SubtaskModel> subtasks;
  final DateTime createdAt;
  DateTime? completedAt;

  /// Indica que esta tarefa foi importada do Google Calendar.
  /// Tarefas de calendário não são enviadas ao Firestore e não podem
  /// ser excluídas — apenas seu status/quadrante/MIT podem ser alterados.
  final bool isFromCalendar;

  /// ID do evento no Google Calendar (sem prefixo 'cal_').
  /// Usado como chave para persistir overrides locais.
  final String? calendarEventId;

  TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    required this.areaId,
    this.eisenhowerQ = 2,
    this.isMIT = false,
    this.mitOrder = 0,
    this.status = 'pending',
    this.dueDate,
    List<SubtaskModel>? subtasks,
    required this.createdAt,
    this.completedAt,
    this.isFromCalendar = false,
    this.calendarEventId,
  }) : subtasks = subtasks ?? [];

  /// Horas estimadas totais = soma das subtarefas (ou 0 se não houver)
  int get totalEstimatedHours =>
      subtasks.fold(0, (sum, s) => sum + s.estimatedHours);

  int get completedSubtasks => subtasks.where((s) => s.isCompleted).length;
  double get progress =>
      subtasks.isEmpty ? 0 : completedSubtasks / subtasks.length;

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
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'isFromCalendar': isFromCalendar,
        'calendarEventId': calendarEventId,
      };

  factory TaskModel.fromJson(Map<String, dynamic> j) => TaskModel(
        id: j['id'] as String,
        userId: j['userId'] as String,
        title: j['title'] as String,
        description: j['description'] as String? ?? '',
        areaId: j['areaId'] as String,
        eisenhowerQ: j['eisenhowerQ'] as int? ?? 2,
        isMIT: j['isMIT'] as bool? ?? false,
        mitOrder: j['mitOrder'] as int? ?? 0,
        status: j['status'] as String? ?? 'pending',
        dueDate:
            j['dueDate'] != null ? DateTime.parse(j['dueDate'] as String) : null,
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
    List<SubtaskModel>? subtasks,
    DateTime? completedAt,
    bool? isFromCalendar,
    String? calendarEventId,
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
        dueDate: dueDate ?? this.dueDate,
        subtasks: subtasks ?? this.subtasks,
        createdAt: createdAt,
        completedAt: completedAt ?? this.completedAt,
        isFromCalendar: isFromCalendar ?? this.isFromCalendar,
        calendarEventId: calendarEventId ?? this.calendarEventId,
      );
}
