class ActivityModel {
  final String id;
  final String userId;
  final String areaId;
  String description;
  int durationMinutes;
  String difficulty; // 'easy' | 'medium' | 'hard'
  int xpEarned;
  List<String> tags;
  final DateTime createdAt;
  String? relatedGoalId;

  ActivityModel({
    required this.id,
    required this.userId,
    required this.areaId,
    required this.description,
    this.durationMinutes = 30,
    this.difficulty = 'medium',
    this.xpEarned = 0,
    List<String>? tags,
    required this.createdAt,
    this.relatedGoalId,
  }) : tags = tags ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'areaId': areaId,
        'description': description,
        'durationMinutes': durationMinutes,
        'difficulty': difficulty,
        'xpEarned': xpEarned,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'relatedGoalId': relatedGoalId,
      };

  factory ActivityModel.fromJson(Map<String, dynamic> json) => ActivityModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        areaId: json['areaId'] as String,
        description: json['description'] as String,
        durationMinutes: json['durationMinutes'] as int? ?? 30,
        difficulty: json['difficulty'] as String? ?? 'medium',
        xpEarned: json['xpEarned'] as int? ?? 0,
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        createdAt: DateTime.parse(json['createdAt'] as String),
        relatedGoalId: json['relatedGoalId'] as String?,
      );
}
