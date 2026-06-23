import 'package:flutter/foundation.dart';
import '../models/learning_progress.dart';
import '../services/learning_service.dart';
import '../services/storage_service.dart';

const _kChessUsername = 'learning_chess_username';
const _kChessStats = 'learning_chess_stats';
const _kDuolingoData = 'learning_duolingo_data';
const _kDatacampCourses = 'learning_datacamp_courses';
const _kGoodreadsData = 'learning_goodreads_data';
const _kNotebookLMData = 'learning_notebooklm_data';
const _kMecLivrosData = 'learning_meclivros_data';
const _kMecIdiomasData = 'learning_mecidiomas_data';

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
    final totalChapters = _courses.fold(0, (s, c) => s + c.totalChapters);
    if (totalChapters == 0) return 0.0;
    final completedChapters =
        _courses.fold(0, (s, c) => s + c.completedChapters);
    return completedChapters / totalChapters;
  }

  // ── Goodreads ──────────────────────────────────────────────────────────────
  GoodreadsProgress _goodreads = const GoodreadsProgress();
  GoodreadsProgress get goodreads => _goodreads;

  // ── NotebookLM ─────────────────────────────────────────────────────────────
  NotebookLMProgress _notebookLM = const NotebookLMProgress();
  NotebookLMProgress get notebookLM => _notebookLM;

  // ── MEC Livros ─────────────────────────────────────────────────────────────
  MecLivrosProgress _mecLivros = const MecLivrosProgress();
  MecLivrosProgress get mecLivros => _mecLivros;

  // ── MEC Idiomas ────────────────────────────────────────────────────────────
  MecIdiomasProgress _mecIdiomas = const MecIdiomasProgress();
  MecIdiomasProgress get mecIdiomas => _mecIdiomas;

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

    final grJson = StorageService.instance.getJson(_kGoodreadsData);
    if (grJson != null) {
      try {
        _goodreads = GoodreadsProgress.fromJson(grJson);
      } catch (_) {}
    }

    final nlmJson = StorageService.instance.getJson(_kNotebookLMData);
    if (nlmJson != null) {
      try {
        _notebookLM = NotebookLMProgress.fromJson(nlmJson);
      } catch (_) {}
    }

    final mlJson = StorageService.instance.getJson(_kMecLivrosData);
    if (mlJson != null) {
      try {
        _mecLivros = MecLivrosProgress.fromJson(mlJson);
      } catch (_) {}
    }

    final miJson = StorageService.instance.getJson(_kMecIdiomasData);
    if (miJson != null) {
      try {
        _mecIdiomas = MecIdiomasProgress.fromJson(miJson);
      } catch (_) {}
    }
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

  // ── Goodreads ──────────────────────────────────────────────────────────────

  Future<void> saveGoodreads(GoodreadsProgress progress) async {
    _goodreads = progress;
    await StorageService.instance
        .setJson(_kGoodreadsData, progress.toJson());
    notifyListeners();
  }

  // ── NotebookLM ─────────────────────────────────────────────────────────────

  Future<void> saveNotebookLM(NotebookLMProgress progress) async {
    _notebookLM = progress;
    await StorageService.instance
        .setJson(_kNotebookLMData, progress.toJson());
    notifyListeners();
  }

  // ── MEC Livros ─────────────────────────────────────────────────────────────

  Future<void> saveMecLivros(MecLivrosProgress progress) async {
    _mecLivros = progress;
    await StorageService.instance
        .setJson(_kMecLivrosData, progress.toJson());
    notifyListeners();
  }

  // ── MEC Idiomas ────────────────────────────────────────────────────────────

  Future<void> saveMecIdiomas(MecIdiomasProgress progress) async {
    _mecIdiomas = progress;
    await StorageService.instance
        .setJson(_kMecIdiomasData, progress.toJson());
    notifyListeners();
  }
}
