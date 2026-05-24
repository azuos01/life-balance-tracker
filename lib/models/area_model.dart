class GoalModel {
  final String id;
  final String areaId;
  String title;
  String description;
  String type; // 'annual' | 'quarterly' | 'monthly'
  String status; // 'not_started' | 'in_progress' | 'completed'
  double progress; // 0-100
  DateTime? targetDate;
  DateTime? completedAt;
  final DateTime createdAt;

  GoalModel({
    required this.id,
    required this.areaId,
    required this.title,
    this.description = '',
    this.type = 'quarterly',
    this.status = 'not_started',
    this.progress = 0,
    this.targetDate,
    this.completedAt,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'areaId': areaId,
        'title': title,
        'description': description,
        'type': type,
        'status': status,
        'progress': progress,
        'targetDate': targetDate?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory GoalModel.fromJson(Map<String, dynamic> json) => GoalModel(
        id: json['id'] as String,
        areaId: json['areaId'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        type: json['type'] as String? ?? 'quarterly',
        status: json['status'] as String? ?? 'not_started',
        progress: (json['progress'] as num?)?.toDouble() ?? 0,
        targetDate: json['targetDate'] != null
            ? DateTime.parse(json['targetDate'] as String)
            : null,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class AreaModel {
  final String id;
  String name;
  String icon;
  double currentScore; // 1-10
  String importance;
  List<GoalModel> goals;

  AreaModel({
    required this.id,
    required this.name,
    required this.icon,
    this.currentScore = 5,
    this.importance = '',
    List<GoalModel>? goals,
  }) : goals = goals ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'currentScore': currentScore,
        'importance': importance,
        'goals': goals.map((g) => g.toJson()).toList(),
      };

  factory AreaModel.fromJson(Map<String, dynamic> json) => AreaModel(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String,
        currentScore: (json['currentScore'] as num?)?.toDouble() ?? 5,
        importance: json['importance'] as String? ?? '',
        goals: (json['goals'] as List<dynamic>?)
                ?.map((g) => GoalModel.fromJson(g as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
