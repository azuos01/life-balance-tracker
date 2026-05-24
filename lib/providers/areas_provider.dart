import 'package:flutter/foundation.dart';
import '../models/area_model.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';
import '../constants/app_constants.dart';

const String _kAreasKey = 'areas_data';

class AreasProvider extends ChangeNotifier {
  List<AreaModel> _areas = [];

  String? _uid;
  bool _isCloud = false;

  List<AreaModel> get areas => _areas;

  double get overallBalance {
    if (_areas.isEmpty) return 0;
    final sum = _areas.fold(0.0, (acc, a) => acc + a.currentScore);
    return (sum / _areas.length / 10 * 100).roundToDouble();
  }

  AreaModel? areaById(String id) {
    try {
      return _areas.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Inicialização ─────────────────────────────────────────────────────────

  /// Carrega dados locais — chamado uma vez na criação do provider
  void initLocal() {
    _loadAreasLocal();
  }

  /// Compatibilidade retroativa
  Future<void> init() async {
    initLocal();
  }

  /// Chamado pelo ProxyProvider quando o usuário autenticado muda.
  void syncUser(String? uid, bool isCloud) {
    if (_uid == uid && _isCloud == isCloud) return;
    _uid = uid;
    _isCloud = isCloud;
    if (uid != null && isCloud) {
      _loadFromCloud(uid);
    }
  }

  // ── Sincronização com Firestore ───────────────────────────────────────────

  Future<void> _loadFromCloud(String uid) async {
    final cloudAreas = await FirestoreService.instance.getAreas(uid);

    if (cloudAreas.isNotEmpty) {
      _areas = cloudAreas;
      // Garante que todas as áreas do sistema existam (novos releases)
      for (final config in kAreas) {
        if (!_areas.any((a) => a.id == config.id)) {
          final newArea =
              AreaModel(id: config.id, name: config.name, icon: config.icon);
          _areas.add(newArea);
          await FirestoreService.instance.saveArea(uid, newArea);
        }
      }
    } else {
      // Primeira vez no Firestore: migra dados locais
      await FirestoreService.instance.saveAllAreas(uid, _areas);
    }

    notifyListeners();
  }

  // ── Carregamento local ─────────────────────────────────────────────────────

  void _loadAreasLocal() {
    final saved = StorageService.instance.getJsonList(_kAreasKey);
    if (saved.isEmpty) {
      _areas = kAreas
          .map((c) => AreaModel(id: c.id, name: c.name, icon: c.icon))
          .toList();
    } else {
      _areas = saved.map((j) => AreaModel.fromJson(j)).toList();
      for (final config in kAreas) {
        if (!_areas.any((a) => a.id == config.id)) {
          _areas.add(
              AreaModel(id: config.id, name: config.name, icon: config.icon));
        }
      }
    }
    notifyListeners();
  }

  // ── Persistência (local + cloud) ──────────────────────────────────────────

  Future<void> _saveAreasLocal() async {
    await StorageService.instance.setJsonList(
      _kAreasKey,
      _areas.map((a) => a.toJson()).toList(),
    );
  }

  Future<void> _saveArea(AreaModel area) async {
    await _saveAreasLocal();
    if (_isCloud && _uid != null) {
      await FirestoreService.instance.saveArea(_uid!, area);
    }
  }

  Future<void> _saveAllAreas() async {
    await _saveAreasLocal();
    if (_isCloud && _uid != null) {
      await FirestoreService.instance.saveAllAreas(_uid!, _areas);
    }
  }

  // ── Operações ─────────────────────────────────────────────────────────────

  Future<void> updateAreaScore(String areaId, double score) async {
    final index = _areas.indexWhere((a) => a.id == areaId);
    if (index == -1) return;
    _areas[index].currentScore = score.clamp(1, 10);
    await _saveArea(_areas[index]);
    notifyListeners();
  }

  Future<void> updateAreaImportance(String areaId, String importance) async {
    final index = _areas.indexWhere((a) => a.id == areaId);
    if (index == -1) return;
    _areas[index].importance = importance;
    await _saveArea(_areas[index]);
    notifyListeners();
  }

  Future<void> addGoal(String areaId, GoalModel goal) async {
    final index = _areas.indexWhere((a) => a.id == areaId);
    if (index == -1) return;
    _areas[index].goals.add(goal);
    await _saveArea(_areas[index]);
    notifyListeners();
  }

  Future<void> updateGoal(String areaId, GoalModel goal) async {
    final areaIndex = _areas.indexWhere((a) => a.id == areaId);
    if (areaIndex == -1) return;
    final goalIndex =
        _areas[areaIndex].goals.indexWhere((g) => g.id == goal.id);
    if (goalIndex == -1) return;
    _areas[areaIndex].goals[goalIndex] = goal;
    await _saveArea(_areas[areaIndex]);
    notifyListeners();
  }

  Future<void> deleteGoal(String areaId, String goalId) async {
    final areaIndex = _areas.indexWhere((a) => a.id == areaId);
    if (areaIndex == -1) return;
    _areas[areaIndex].goals.removeWhere((g) => g.id == goalId);
    await _saveArea(_areas[areaIndex]);
    notifyListeners();
  }

  Future<void> updateAllScores(Map<String, double> scores) async {
    for (final entry in scores.entries) {
      final index = _areas.indexWhere((a) => a.id == entry.key);
      if (index != -1) {
        _areas[index].currentScore = entry.value.clamp(1, 10);
      }
    }
    await _saveAllAreas();
    notifyListeners();
  }

  List<GoalModel> get allGoals =>
      _areas.expand((a) => a.goals).toList();

  List<GoalModel> get activeGoals =>
      allGoals.where((g) => g.status != 'completed').toList();
}
