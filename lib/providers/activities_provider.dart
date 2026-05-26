import 'package:flutter/foundation.dart';
import '../models/activity_model.dart';
import '../models/checkin_model.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';
import '../constants/app_constants.dart';

const String _kActivitiesKey = 'activities_data';
const String _kCheckInsKey = 'checkins_data';

class ActivitiesProvider extends ChangeNotifier {
  List<ActivityModel> _activities = [];
  List<CheckInModel> _checkIns = [];

  String? _uid;
  bool _isCloud = false;
  String? _lastLoadedUid;

  List<ActivityModel> get activities => _activities;
  List<CheckInModel> get checkIns => _checkIns;

  List<ActivityModel> get todayActivities {
    final today = _today();
    return _activities
        .where((a) => _sameDay(a.createdAt, today))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  CheckInModel? get todayCheckIn {
    final today = _today();
    try {
      return _checkIns.firstWhere((c) => _sameDay(c.date, today));
    } catch (_) {
      return null;
    }
  }

  bool get hasMorningCheckIn => todayCheckIn?.hasMorning ?? false;
  bool get hasEveningCheckIn => todayCheckIn?.hasEvening ?? false;

  int get totalActivities => _activities.length;

  int get eveningCheckInsCount =>
      _checkIns.where((c) => c.hasEvening).length;

  // ── Inicialização ─────────────────────────────────────────────────────────

  /// Carrega dados locais (SharedPreferences) — chamado uma vez na criação
  void initLocal() {
    _loadActivitiesLocal();
    _loadCheckInsLocal();
  }

  /// Compatibilidade retroativa com o init() async original
  Future<void> init() async {
    initLocal();
  }

  /// Chamado pelo ProxyProvider quando o usuário autenticado muda.
  void syncUser(String? uid, bool isCloud) {
    _uid     = uid;
    _isCloud = isCloud;

    if (uid == null || !isCloud) {
      _lastLoadedUid = null;
      return;
    }

    if (uid != _lastLoadedUid) {
      _lastLoadedUid = uid;
      _loadFromCloud(uid);
    }
  }

  // ── Sincronização com Firestore ───────────────────────────────────────────

  Future<void> _loadFromCloud(String uid) async {
    // ── Atividades ──────────────────────────────────────────────────────────
    final acts = await FirestoreService.instance.getActivities(uid);
    if (acts.isNotEmpty) {
      _activities = acts;
      await _saveActivitiesLocal();
    } else if (_activities.isNotEmpty) {
      // Migração: atividades locais existem mas não estão neste UID no Firestore
      for (final act in _activities) {
        await FirestoreService.instance.saveActivity(uid, act);
      }
    }

    // ── Check-ins ───────────────────────────────────────────────────────────
    final checks = await FirestoreService.instance.getCheckIns(uid);
    if (checks.isNotEmpty) {
      _checkIns = checks;
      await _saveCheckInsLocal();
    } else if (_checkIns.isNotEmpty) {
      for (final checkIn in _checkIns) {
        await FirestoreService.instance.saveCheckIn(uid, checkIn);
      }
    }

    notifyListeners();
  }

  // ── Carregamento local ─────────────────────────────────────────────────────

  void _loadActivitiesLocal() {
    final saved = StorageService.instance.getJsonList(_kActivitiesKey);
    _activities = saved.map((j) => ActivityModel.fromJson(j)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _loadCheckInsLocal() {
    final saved = StorageService.instance.getJsonList(_kCheckInsKey);
    _checkIns = saved.map((j) => CheckInModel.fromJson(j)).toList();
  }

  // ── Persistência (local + cloud) ──────────────────────────────────────────

  Future<void> _saveActivitiesLocal() async {
    await StorageService.instance.setJsonList(
      _kActivitiesKey,
      _activities.map((a) => a.toJson()).toList(),
    );
  }

  Future<void> _saveCheckInsLocal() async {
    await StorageService.instance.setJsonList(
      _kCheckInsKey,
      _checkIns.map((c) => c.toJson()).toList(),
    );
  }

  // ── Operações de atividade ────────────────────────────────────────────────

  Future<int> addActivity(ActivityModel activity) async {
    int xp;
    switch (activity.difficulty) {
      case 'easy':
        xp = kXpEasy;
        break;
      case 'hard':
        xp = kXpHard;
        break;
      default:
        xp = kXpMedium;
    }
    activity.xpEarned = xp;
    _activities.insert(0, activity);

    // Salva localmente (cache)
    await _saveActivitiesLocal();
    // Se cloud, salva no Firestore
    if (_isCloud && _uid != null) {
      await FirestoreService.instance.saveActivity(_uid!, activity);
    }

    notifyListeners();
    return xp;
  }

  Future<void> deleteActivity(String id) async {
    _activities.removeWhere((a) => a.id == id);

    await _saveActivitiesLocal();
    if (_isCloud && _uid != null) {
      await FirestoreService.instance.deleteActivity(_uid!, id);
    }

    notifyListeners();
  }

  // ── Operações de check-in ─────────────────────────────────────────────────

  Future<CheckInModel> saveMorningCheckIn({
    required String userId,
    required int mood,
    required int energy,
    required List<String> intentions,
    required String gratitude,
  }) async {
    final today = _today();
    CheckInModel checkIn;

    final existing = todayCheckIn;
    if (existing != null) {
      existing.morningMood = mood;
      existing.morningEnergy = energy;
      existing.intentions = intentions;
      existing.gratitude = gratitude;
      checkIn = existing;
    } else {
      checkIn = CheckInModel(
        id: '${userId}_${today.toIso8601String()}',
        userId: userId,
        date: today,
        morningMood: mood,
        morningEnergy: energy,
        intentions: intentions,
        gratitude: gratitude,
        createdAt: DateTime.now(),
      );
      _checkIns.add(checkIn);
    }

    await _saveCheckInsLocal();
    if (_isCloud && _uid != null) {
      await FirestoreService.instance.saveCheckIn(_uid!, checkIn);
    }

    notifyListeners();
    return checkIn;
  }

  Future<void> saveEveningCheckIn({
    required String userId,
    required String reflection,
    required String tomorrowPlan,
    required int dayScore,
  }) async {
    final today = _today();
    final existing = todayCheckIn;

    if (existing != null) {
      existing.eveningReflection = reflection;
      existing.tomorrowPlan = tomorrowPlan;
      existing.overallDayScore = dayScore;

      await _saveCheckInsLocal();
      if (_isCloud && _uid != null) {
        await FirestoreService.instance.saveCheckIn(_uid!, existing);
      }
    } else {
      final newCheckIn = CheckInModel(
        id: '${userId}_eve_${today.toIso8601String()}',
        userId: userId,
        date: today,
        eveningReflection: reflection,
        tomorrowPlan: tomorrowPlan,
        overallDayScore: dayScore,
        createdAt: DateTime.now(),
      );
      _checkIns.add(newCheckIn);

      await _saveCheckInsLocal();
      if (_isCloud && _uid != null) {
        await FirestoreService.instance.saveCheckIn(_uid!, newCheckIn);
      }
    }

    notifyListeners();
  }

  // ── Queries ───────────────────────────────────────────────────────────────

  List<ActivityModel> activitiesByArea(String areaId) =>
      _activities.where((a) => a.areaId == areaId).toList();

  Map<String, int> get xpByArea {
    final map = <String, int>{};
    for (final a in _activities) {
      map[a.areaId] = (map[a.areaId] ?? 0) + a.xpEarned;
    }
    return map;
  }

  Map<DateTime, int> get activityHeatmap {
    final map = <DateTime, int>{};
    for (final a in _activities) {
      final day =
          DateTime(a.createdAt.year, a.createdAt.month, a.createdAt.day);
      map[day] = (map[day] ?? 0) + 1;
    }
    return map;
  }

  Set<String> areasActiveThisWeek() {
    final monday = _today().subtract(Duration(days: _today().weekday - 1));
    return _activities
        .where((a) => a.createdAt.isAfter(monday))
        .map((a) => a.areaId)
        .toSet();
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
