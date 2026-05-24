class CheckInModel {
  final String id;
  final String userId;
  final DateTime date;

  // Morning
  int morningMood; // 1-5
  int morningEnergy; // 1-5
  List<String> intentions;
  String gratitude;

  // Evening
  String eveningReflection;
  String tomorrowPlan;
  int? overallDayScore; // 1-10

  final DateTime createdAt;

  CheckInModel({
    required this.id,
    required this.userId,
    required this.date,
    this.morningMood = 3,
    this.morningEnergy = 3,
    List<String>? intentions,
    this.gratitude = '',
    this.eveningReflection = '',
    this.tomorrowPlan = '',
    this.overallDayScore,
    required this.createdAt,
  }) : intentions = intentions ?? [];

  bool get hasMorning => morningMood > 0;
  bool get hasEvening => overallDayScore != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'date': date.toIso8601String(),
        'morningMood': morningMood,
        'morningEnergy': morningEnergy,
        'intentions': intentions,
        'gratitude': gratitude,
        'eveningReflection': eveningReflection,
        'tomorrowPlan': tomorrowPlan,
        'overallDayScore': overallDayScore,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CheckInModel.fromJson(Map<String, dynamic> json) => CheckInModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        date: DateTime.parse(json['date'] as String),
        morningMood: json['morningMood'] as int? ?? 3,
        morningEnergy: json['morningEnergy'] as int? ?? 3,
        intentions: (json['intentions'] as List<dynamic>?)?.cast<String>() ?? [],
        gratitude: json['gratitude'] as String? ?? '',
        eveningReflection: json['eveningReflection'] as String? ?? '',
        tomorrowPlan: json['tomorrowPlan'] as String? ?? '',
        overallDayScore: json['overallDayScore'] as int?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
