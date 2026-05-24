import '../constants/app_constants.dart';

class UserModel {
  final String id;
  final String name;
  final String? avatar;
  int totalXP;
  int currentStreak;
  int longestStreak;
  DateTime? lastCheckInDate;
  bool onboardingComplete;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    this.avatar,
    this.totalXP = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCheckInDate,
    this.onboardingComplete = false,
    required this.createdAt,
  });

  int get level => levelFromXP(totalXP);
  String get tier => tierFromXP(totalXP);
  int get nextLevelXP => xpForNextLevel(totalXP);

  UserModel copyWith({
    String? name,
    String? avatar,
    int? totalXP,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastCheckInDate,
    bool? onboardingComplete,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      totalXP: totalXP ?? this.totalXP,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCheckInDate: lastCheckInDate ?? this.lastCheckInDate,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar': avatar,
        'totalXP': totalXP,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastCheckInDate': lastCheckInDate?.toIso8601String(),
        'onboardingComplete': onboardingComplete,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        avatar: json['avatar'] as String?,
        totalXP: json['totalXP'] as int? ?? 0,
        currentStreak: json['currentStreak'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
        lastCheckInDate: json['lastCheckInDate'] != null
            ? DateTime.parse(json['lastCheckInDate'] as String)
            : null,
        onboardingComplete: json['onboardingComplete'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
