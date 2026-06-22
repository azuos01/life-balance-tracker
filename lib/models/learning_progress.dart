// ── Chess.com ─────────────────────────────────────────────────────────────────

class ChessStats {
  final String username;
  final int? puzzleRating;
  final int? rapidRating;
  final int? blitzRating;
  final int? bulletRating;
  final int? puzzleRushBest;
  final DateTime fetchedAt;

  const ChessStats({
    required this.username,
    this.puzzleRating,
    this.rapidRating,
    this.blitzRating,
    this.bulletRating,
    this.puzzleRushBest,
    required this.fetchedAt,
  });

  factory ChessStats.fromApi(String username, Map<String, dynamic> json) {
    int? lastRating(dynamic section) {
      if (section is! Map) return null;
      return section['last']?['rating'] as int?;
    }

    return ChessStats(
      username: username,
      rapidRating: lastRating(json['chess_rapid']),
      blitzRating: lastRating(json['chess_blitz']),
      bulletRating: lastRating(json['chess_bullet']),
      puzzleRating: json['tactics']?['highest']?['rating'] as int?,
      puzzleRushBest: json['puzzle_rush']?['best']?['score'] as int?,
      fetchedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'username': username,
        'puzzleRating': puzzleRating,
        'rapidRating': rapidRating,
        'blitzRating': blitzRating,
        'bulletRating': bulletRating,
        'puzzleRushBest': puzzleRushBest,
        'fetchedAt': fetchedAt.toIso8601String(),
      };

  factory ChessStats.fromJson(Map<String, dynamic> json) => ChessStats(
        username: json['username'] as String? ?? '',
        puzzleRating: json['puzzleRating'] as int?,
        rapidRating: json['rapidRating'] as int?,
        blitzRating: json['blitzRating'] as int?,
        bulletRating: json['bulletRating'] as int?,
        puzzleRushBest: json['puzzleRushBest'] as int?,
        fetchedAt: DateTime.tryParse(json['fetchedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

// ── Duolingo (manual) ─────────────────────────────────────────────────────────

class DuolingoProgress {
  final String username;
  final int streak;
  final int totalXP;
  final int dailyGoalXP;
  final String activeLanguage;
  final int languageLevel;
  final int languageXP;

  const DuolingoProgress({
    required this.username,
    this.streak = 0,
    this.totalXP = 0,
    this.dailyGoalXP = 10,
    this.activeLanguage = '',
    this.languageLevel = 1,
    this.languageXP = 0,
  });

  DuolingoProgress copyWith({
    String? username,
    int? streak,
    int? totalXP,
    int? dailyGoalXP,
    String? activeLanguage,
    int? languageLevel,
    int? languageXP,
  }) =>
      DuolingoProgress(
        username: username ?? this.username,
        streak: streak ?? this.streak,
        totalXP: totalXP ?? this.totalXP,
        dailyGoalXP: dailyGoalXP ?? this.dailyGoalXP,
        activeLanguage: activeLanguage ?? this.activeLanguage,
        languageLevel: languageLevel ?? this.languageLevel,
        languageXP: languageXP ?? this.languageXP,
      );

  Map<String, dynamic> toJson() => {
        'username': username,
        'streak': streak,
        'totalXP': totalXP,
        'dailyGoalXP': dailyGoalXP,
        'activeLanguage': activeLanguage,
        'languageLevel': languageLevel,
        'languageXP': languageXP,
      };

  factory DuolingoProgress.fromJson(Map<String, dynamic> json) =>
      DuolingoProgress(
        username: json['username'] as String? ?? '',
        streak: json['streak'] as int? ?? 0,
        totalXP: json['totalXP'] as int? ?? 0,
        dailyGoalXP: json['dailyGoalXP'] as int? ?? 10,
        activeLanguage: json['activeLanguage'] as String? ?? '',
        languageLevel: json['languageLevel'] as int? ?? 1,
        languageXP: json['languageXP'] as int? ?? 0,
      );
}

// ── DataCamp (manual) ─────────────────────────────────────────────────────────

const kDataCampTechnologies = [
  'Python',
  'R',
  'SQL',
  'Power BI',
  'Tableau',
  'Excel',
  'Machine Learning',
  'Deep Learning',
  'Data Engineering',
  'Shell',
  'Outro',
];

class DataCampCourse {
  final String id;
  final String title;
  final String technology;
  final int totalChapters;
  final int completedChapters;

  const DataCampCourse({
    required this.id,
    required this.title,
    required this.technology,
    required this.totalChapters,
    required this.completedChapters,
  });

  double get progress =>
      totalChapters == 0 ? 0.0 : completedChapters / totalChapters;

  bool get isCompleted =>
      totalChapters > 0 && completedChapters >= totalChapters;

  DataCampCourse copyWith({
    String? title,
    String? technology,
    int? totalChapters,
    int? completedChapters,
  }) =>
      DataCampCourse(
        id: id,
        title: title ?? this.title,
        technology: technology ?? this.technology,
        totalChapters: totalChapters ?? this.totalChapters,
        completedChapters: completedChapters ?? this.completedChapters,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'technology': technology,
        'totalChapters': totalChapters,
        'completedChapters': completedChapters,
      };

  factory DataCampCourse.fromJson(Map<String, dynamic> json) => DataCampCourse(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        technology: json['technology'] as String? ?? 'Python',
        totalChapters: json['totalChapters'] as int? ?? 4,
        completedChapters: json['completedChapters'] as int? ?? 0,
      );
}
