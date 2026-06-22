import 'package:flutter/foundation.dart';
import '../models/learning_progress.dart';
import '../services/learning_service.dart';
import '../services/storage_service.dart';

const _kChessUsername = 'learning_chess_username';
const _kChessStats = 'learning_chess_stats';
const _kDuolingoData = 'learning_duolingo_data';
const _kDatacampCourses = 'learning_datacamp_courses';

class LearningProvider extends ChangeNotifier {
  final _service = LearningService();

  // ── Chess.com ──────────────────────────────────────────────────────────────
  String _chessUsername = '';
  ChessStats? _chessStats;
  bool _chessLoading = false;
  String? _chessError;

  String get chessUsername => _chessUsername;
  ChessStats? get chessStats => _chessStats;
  bool get chessLoading => _chessLoading;
  String? get chessError => _chessError;

  // ── Duolingo ───────────────────────────────────────────────────────────────
  DuolingoProgress _duolingo = const DuolingoProgress(username: '');

  DuolingoProgress get duolingo => _duolingo;

  // ── DataCamp ───────────────────────────────────────────────────────────────
  List<DataCampCourse> _courses = [];

  List<DataCampCourse> get courses => List.unmodifiable(_courses);

  int get completedCourses => _courses.where((c) => c.isCompleted).length;

  double get overallProgress {
    if (_courses.isEmpty) return 0.0;
    final totalChapters =
        _courses.fold(0, (s, c) => s + c.totalChapters);
    if (totalChapters == 0) return 0.0;
    final completedChapters =
        _courses.fold(0, (s, c) => s + c.completedChapters);
    return completedChapters / totalChapters;
  }

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> init() async {
    _chessUsername =
        StorageService.instance.getString(_kChessUsername) ?? '';
    final chessJson = StorageService.instance.getJson(_kChessStats);
    if (chessJson != null) {
      try {
        _chessStats = ChessStats.fromJson(chessJson);
      } catch (_) {}
    }

    final duoJson = StorageService.instance.getJson(_kDuolingoData);
    if (duoJson != null) {
      try {
        _duolingo = DuolingoProgress.fromJson(duoJson);
      } catch (_) {}
    }

    final rawCourses = StorageService.instance.getJsonList(_kDatacampCourses);
    _courses = rawCourses.map(DataCampCourse.fromJson).toList();
  }

  // ── Chess.com ──────────────────────────────────────────────────────────────

  Future<void> fetchChess(String username) async {
    _chessUsername = username.trim();
    _chessLoading = true;
    _chessError = null;
    notifyListeners();

    await StorageService.instance.setString(_kChessUsername, _chessUsername);

    try {
      _chessStats = await _service.fetchChessStats(_chessUsername);
      await StorageService.instance
          .setJson(_kChessStats, _chessStats!.toJson());
    } catch (e) {
      _chessError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _chessLoading = false;
      notifyListeners();
    }
  }

  void clearChessError() {
    _chessError = null;
    notifyListeners();
  }

  // ── Duolingo ───────────────────────────────────────────────────────────────

  Future<void> saveDuolingo(DuolingoProgress progress) async {
    _duolingo = progress;
    await StorageService.instance.setJson(_kDuolingoData, progress.toJson());
    notifyListeners();
  }

  // ── DataCamp ───────────────────────────────────────────────────────────────

  Future<void> addCourse(DataCampCourse course) async {
    _courses = [..._courses, course];
    await _saveCourses();
    notifyListeners();
  }

  Future<void> updateProgress(String id, int completedChapters) async {
    _courses = _courses.map((c) {
      if (c.id != id) return c;
      return c.copyWith(
        completedChapters: completedChapters.clamp(0, c.totalChapters),
      );
    }).toList();
    await _saveCourses();
    notifyListeners();
  }

  Future<void> deleteCourse(String id) async {
    _courses = _courses.where((c) => c.id != id).toList();
    await _saveCourses();
    notifyListeners();
  }

  Future<void> _saveCourses() async {
    await StorageService.instance.setJsonList(
      _kDatacampCourses,
      _courses.map((c) => c.toJson()).toList(),
    );
  }
}
