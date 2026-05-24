import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/achievement_model.dart';
import '../services/storage_service.dart';
import '../constants/app_constants.dart';

const String _kUserKey = 'user_data';
const String _kAchievementsKey = 'achievements_data';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  List<AchievementModel> _achievements = [];
  bool _isInitialized = false;

  UserModel? get user => _user;
  bool get isInitialized => _isInitialized;
  bool get onboardingComplete => _user?.onboardingComplete ?? false;
  List<AchievementModel> get achievements => _achievements;
  List<AchievementModel> get unlockedAchievements =>
      _achievements.where((a) => a.isUnlocked).toList();

  Future<void> init() async {
    await StorageService.instance.init();
    _loadUser();
    _loadAchievements();
    _isInitialized = true;
    notifyListeners();
  }

  void _loadUser() {
    final json = StorageService.instance.getJson(_kUserKey);
    if (json != null) {
      _user = UserModel.fromJson(json);
    }
  }

  void _loadAchievements() {
    final saved = StorageService.instance.getJsonList(_kAchievementsKey);
    final savedMap = {
      for (final item in saved) item['id'] as String: item,
    };

    _achievements = kAchievements.map((a) {
      final savedData = savedMap[a.id];
      if (savedData != null && savedData['unlockedAt'] != null) {
        return a.withUnlock(DateTime.parse(savedData['unlockedAt'] as String));
      }
      return a;
    }).toList();
  }

  Future<void> _saveUser() async {
    if (_user == null) return;
    await StorageService.instance.setJson(_kUserKey, _user!.toJson());
  }

  Future<void> _saveAchievements() async {
    await StorageService.instance.setJsonList(
      _kAchievementsKey,
      _achievements.map((a) => a.toJson()).toList(),
    );
  }

  Future<void> createUser(String name, {String? avatar}) async {
    _user = UserModel(
      id: const Uuid().v4(),
      name: name,
      avatar: avatar,
      createdAt: DateTime.now(),
    );
    await _saveUser();
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    if (_user == null) return;
    _user = _user!.copyWith(onboardingComplete: true);
    await _saveUser();
    notifyListeners();
  }

  Future<void> addXP(int xp) async {
    if (_user == null) return;
    final oldLevel = _user!.level;
    _user!.totalXP += xp;
    final newLevel = _user!.level;
    await _saveUser();

    if (newLevel > oldLevel) {
      _checkLevelAchievements(newLevel);
    }
    notifyListeners();
  }

  Future<void> updateStreak(bool checkedInToday) async {
    if (_user == null) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (!checkedInToday) {
      final last = _user!.lastCheckInDate;
      if (last != null) {
        final lastDay = DateTime(last.year, last.month, last.day);
        final diff = today.difference(lastDay).inDays;
        if (diff == 1) {
          // consecutive day
          _user!.currentStreak++;
          if (_user!.currentStreak > _user!.longestStreak) {
            _user!.longestStreak = _user!.currentStreak;
          }
          if (_user!.currentStreak % 7 == 0) {
            await addXP(kXpStreakBonus);
          }
        } else if (diff > 1) {
          _user!.currentStreak = 1;
        }
      } else {
        _user!.currentStreak = 1;
      }
      _user = _user!.copyWith(lastCheckInDate: today);
    }
    await _saveUser();
    _checkStreakAchievements();
    notifyListeners();
  }

  void _checkStreakAchievements() {
    if (_user == null) return;
    if (_user!.currentStreak >= 7) _unlockAchievement('week_streak');
    if (_user!.currentStreak >= 30) _unlockAchievement('month_iron');
  }

  void _checkLevelAchievements(int level) {
    if (level >= 10) _unlockAchievement('level_10');
  }

  Future<void> unlockAchievement(String id) async {
    await _unlockAchievement(id);
  }

  Future<void> _unlockAchievement(String id) async {
    final index = _achievements.indexWhere((a) => a.id == id);
    if (index == -1) return;
    if (_achievements[index].isUnlocked) return;

    _achievements[index] = _achievements[index].withUnlock(DateTime.now());
    final xp = _achievements[index].xpReward;
    await _saveAchievements();
    await addXP(xp);
    notifyListeners();
  }

  Future<void> checkFirstActivityAchievement(int activityCount) async {
    if (activityCount == 1) await _unlockAchievement('first_step');
  }

  Future<void> checkEveningCheckInsAchievement(int eveningCount) async {
    if (eveningCount >= 10) await _unlockAchievement('reflective');
  }

  Future<void> resetAll() async {
    await StorageService.instance.clear();
    _user = null;
    _achievements = kAchievements.toList();
    _isInitialized = false;
    notifyListeners();
    await init();
  }
}
