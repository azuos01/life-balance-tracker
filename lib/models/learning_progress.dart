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

// ── Goodreads (manual) ────────────────────────────────────────────────────────

class GoodreadsProgress {
  final String username;
  final int booksReadYear;
  final int booksReading;
  final int booksWantToRead;
  final int pagesYear;
  final String currentBook;

  const GoodreadsProgress({
    this.username = '',
    this.booksReadYear = 0,
    this.booksReading = 0,
    this.booksWantToRead = 0,
    this.pagesYear = 0,
    this.currentBook = '',
  });

  GoodreadsProgress copyWith({
    String? username,
    int? booksReadYear,
    int? booksReading,
    int? booksWantToRead,
    int? pagesYear,
    String? currentBook,
  }) =>
      GoodreadsProgress(
        username: username ?? this.username,
        booksReadYear: booksReadYear ?? this.booksReadYear,
        booksReading: booksReading ?? this.booksReading,
        booksWantToRead: booksWantToRead ?? this.booksWantToRead,
        pagesYear: pagesYear ?? this.pagesYear,
        currentBook: currentBook ?? this.currentBook,
      );

  Map<String, dynamic> toJson() => {
        'username': username,
        'booksReadYear': booksReadYear,
        'booksReading': booksReading,
        'booksWantToRead': booksWantToRead,
        'pagesYear': pagesYear,
        'currentBook': currentBook,
      };

  factory GoodreadsProgress.fromJson(Map<String, dynamic> json) =>
      GoodreadsProgress(
        username: json['username'] as String? ?? '',
        booksReadYear: json['booksReadYear'] as int? ?? 0,
        booksReading: json['booksReading'] as int? ?? 0,
        booksWantToRead: json['booksWantToRead'] as int? ?? 0,
        pagesYear: json['pagesYear'] as int? ?? 0,
        currentBook: json['currentBook'] as String? ?? '',
      );
}

// ── NotebookLM (manual) ───────────────────────────────────────────────────────

class NotebookLMProgress {
  final int notebooksCount;
  final int sourcesCount;
  final int notesCount;
  final String latestTopic;

  const NotebookLMProgress({
    this.notebooksCount = 0,
    this.sourcesCount = 0,
    this.notesCount = 0,
    this.latestTopic = '',
  });

  NotebookLMProgress copyWith({
    int? notebooksCount,
    int? sourcesCount,
    int? notesCount,
    String? latestTopic,
  }) =>
      NotebookLMProgress(
        notebooksCount: notebooksCount ?? this.notebooksCount,
        sourcesCount: sourcesCount ?? this.sourcesCount,
        notesCount: notesCount ?? this.notesCount,
        latestTopic: latestTopic ?? this.latestTopic,
      );

  Map<String, dynamic> toJson() => {
        'notebooksCount': notebooksCount,
        'sourcesCount': sourcesCount,
        'notesCount': notesCount,
        'latestTopic': latestTopic,
      };

  factory NotebookLMProgress.fromJson(Map<String, dynamic> json) =>
      NotebookLMProgress(
        notebooksCount: json['notebooksCount'] as int? ?? 0,
        sourcesCount: json['sourcesCount'] as int? ?? 0,
        notesCount: json['notesCount'] as int? ?? 0,
        latestTopic: json['latestTopic'] as String? ?? '',
      );
}

// ── MEC Livros (manual) ───────────────────────────────────────────────────────

class MecLivrosProgress {
  final int booksRead;
  final int booksReading;
  final String currentBook;
  final String favoriteGenre;

  const MecLivrosProgress({
    this.booksRead = 0,
    this.booksReading = 0,
    this.currentBook = '',
    this.favoriteGenre = '',
  });

  MecLivrosProgress copyWith({
    int? booksRead,
    int? booksReading,
    String? currentBook,
    String? favoriteGenre,
  }) =>
      MecLivrosProgress(
        booksRead: booksRead ?? this.booksRead,
        booksReading: booksReading ?? this.booksReading,
        currentBook: currentBook ?? this.currentBook,
        favoriteGenre: favoriteGenre ?? this.favoriteGenre,
      );

  Map<String, dynamic> toJson() => {
        'booksRead': booksRead,
        'booksReading': booksReading,
        'currentBook': currentBook,
        'favoriteGenre': favoriteGenre,
      };

  factory MecLivrosProgress.fromJson(Map<String, dynamic> json) =>
      MecLivrosProgress(
        booksRead: json['booksRead'] as int? ?? 0,
        booksReading: json['booksReading'] as int? ?? 0,
        currentBook: json['currentBook'] as String? ?? '',
        favoriteGenre: json['favoriteGenre'] as String? ?? '',
      );
}

// ── MEC Idiomas (manual) ──────────────────────────────────────────────────────

class MecIdiomasProgress {
  final String activeCourse;
  final String activeLanguage;
  final int lessonsCompleted;
  final int totalLessons;
  final int streak;

  const MecIdiomasProgress({
    this.activeCourse = '',
    this.activeLanguage = '',
    this.lessonsCompleted = 0,
    this.totalLessons = 0,
    this.streak = 0,
  });

  double get progress =>
      totalLessons == 0 ? 0.0 : lessonsCompleted / totalLessons;

  MecIdiomasProgress copyWith({
    String? activeCourse,
    String? activeLanguage,
    int? lessonsCompleted,
    int? totalLessons,
    int? streak,
  }) =>
      MecIdiomasProgress(
        activeCourse: activeCourse ?? this.activeCourse,
        activeLanguage: activeLanguage ?? this.activeLanguage,
        lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
        totalLessons: totalLessons ?? this.totalLessons,
        streak: streak ?? this.streak,
      );

  Map<String, dynamic> toJson() => {
        'activeCourse': activeCourse,
        'activeLanguage': activeLanguage,
        'lessonsCompleted': lessonsCompleted,
        'totalLessons': totalLessons,
        'streak': streak,
      };

  factory MecIdiomasProgress.fromJson(Map<String, dynamic> json) =>
      MecIdiomasProgress(
        activeCourse: json['activeCourse'] as String? ?? '',
        activeLanguage: json['activeLanguage'] as String? ?? '',
        lessonsCompleted: json['lessonsCompleted'] as int? ?? 0,
        totalLessons: json['totalLessons'] as int? ?? 0,
        streak: json['streak'] as int? ?? 0,
      );
}
