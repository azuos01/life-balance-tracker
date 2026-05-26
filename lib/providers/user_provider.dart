import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/achievement_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';
import '../constants/app_constants.dart';

const String _kUserKey      = 'user_data';
const String _kAchievementsKey = 'achievements_data';
const String _kAuthKey      = 'auth_state';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  List<AchievementModel> _achievements = [];
  bool _isInitialized  = false;
  bool _isAuthenticated = false;
  bool _isCloud = false;
  String? _authProvider;
  // UID persistido no auth_state para recuperar sessão corretamente
  String? _persistedUid;

  UserModel? get user             => _user;
  bool get isInitialized          => _isInitialized;
  bool get isAuthenticated        => _isAuthenticated;
  bool get isCloudUser            => _isCloud;
  bool get onboardingComplete     => _user?.onboardingComplete ?? false;
  String? get authProvider        => _authProvider;
  List<AchievementModel> get achievements => _achievements;
  List<AchievementModel> get unlockedAchievements =>
      _achievements.where((a) => a.isUnlocked).toList();

  // ── Inicialização ──────────────────────────────────────────────────────────

  Future<void> init() async {
    await StorageService.instance.init();
    _loadUser();
    _loadAchievements();
    _restoreAuthState();
    _isInitialized = true;

    // Se havia sessão cloud ativa, sincroniza perfil do Firestore em background.
    // Usa _persistedUid (Firebase UID) como fonte de verdade; se o _user.id
    // local for diferente (usuário antigo com UUID), o perfil correto é carregado.
    if (_isAuthenticated && _isCloud) {
      final uidToSync = _persistedUid ?? _user?.id;
      if (uidToSync != null) {
        _syncProfileFromCloud(uidToSync);
      }
    }

    notifyListeners();
  }

  // ── Auth state ─────────────────────────────────────────────────────────────

  void _restoreAuthState() {
    final saved = StorageService.instance.getJson(_kAuthKey);
    if (saved != null) {
      _isAuthenticated = saved['isAuthenticated'] as bool? ?? false;
      _authProvider    = saved['provider'] as String?;
      _isCloud         = _authProvider != null && _authProvider != 'demo';
      // Firebase UID persistido — garante que syncUser use o UID correto
      _persistedUid    = saved['uid'] as String?;
    }
  }

  Future<void> _persistAuthState() async {
    await StorageService.instance.setJson(_kAuthKey, {
      'isAuthenticated': _isAuthenticated,
      'provider':        _authProvider,
      // Persiste o Firebase UID para que o syncUser dos providers use o path
      // correto no Firestore mesmo após reinício do app ou troca de browser.
      'uid': _user?.id,
    });
  }

  // ── Login OAuth ────────────────────────────────────────────────────────────

  /// Chamado após login OAuth bem-sucedido
  Future<void> onAuthResult(AuthResult result) async {
    _isAuthenticated = true;
    _authProvider    = result.provider;
    _isCloud         = result.provider != 'demo';

    if (_isCloud) {
      // Usuário real — tenta carregar perfil existente do Firestore
      final cloudUser =
          await FirestoreService.instance.getProfile(result.uid);

      if (cloudUser != null) {
        // Usuário retornando: usa dados do Firestore
        _user = cloudUser;
        await _loadAchievementsFromCloud(result.uid);
      } else if (_user != null) {
        // Primeira vez com esta conta: migra dados locais para o Firestore.
        // IMPORTANTE: o user mantém o id que já possui (pode ser Firebase UID
        // criado antes do onboarding ou UUID antigo). O perfil é salvo em
        // users/{result.uid}/... para garantir que futuros logins encontrem
        // os dados pelo Firebase UID.
        _user = UserModel(
          id:                result.uid,   // normaliza para Firebase UID
          name:              _user!.name,
          avatar:            _user!.avatar ?? result.photoUrl,
          totalXP:           _user!.totalXP,
          currentStreak:     _user!.currentStreak,
          longestStreak:     _user!.longestStreak,
          lastCheckInDate:   _user!.lastCheckInDate,
          onboardingComplete: _user!.onboardingComplete,
          createdAt:         _user!.createdAt,
        );
        await FirestoreService.instance.saveProfile(result.uid, _user!);
        await _migrateAchievementsToCloud(result.uid);
      } else {
        // Conta nova sem dados locais
        _user = UserModel(
          id:                result.uid,
          name:              result.name ?? 'Usuário',
          avatar:            result.photoUrl,
          onboardingComplete: false,
          createdAt:         DateTime.now(),
        );
        await FirestoreService.instance.saveProfile(result.uid, _user!);
      }

      // Salva local e persiste auth state com o Firebase UID
      await StorageService.instance.setJson(_kUserKey, _user!.toJson());
    } else {
      // Demo mode: cria usuário local se necessário
      if (_user == null) {
        _user = UserModel(
          id:                const Uuid().v4(),
          name:              result.name ?? 'Usuário Demo',
          onboardingComplete: false,
          createdAt:         DateTime.now(),
        );
        await StorageService.instance.setJson(_kUserKey, _user!.toJson());
      }
    }

    await _persistAuthState();
    notifyListeners();
  }

  // ── Carregamento local ─────────────────────────────────────────────────────

  void _loadUser() {
    final json = StorageService.instance.getJson(_kUserKey);
    if (json != null) _user = UserModel.fromJson(json);
  }

  void _loadAchievements() {
    final saved    = StorageService.instance.getJsonList(_kAchievementsKey);
    final savedMap = {for (final item in saved) item['id'] as String: item};

    _achievements = kAchievements.map((a) {
      final savedData = savedMap[a.id];
      if (savedData != null && savedData['unlockedAt'] != null) {
        return a.withUnlock(
            DateTime.parse(savedData['unlockedAt'] as String));
      }
      return a;
    }).toList();
  }

  // ── Sincronização com Firestore ────────────────────────────────────────────

  Future<void> _syncProfileFromCloud(String uid) async {
    final cloudUser = await FirestoreService.instance.getProfile(uid);
    if (cloudUser != null) {
      _user = cloudUser;
      await StorageService.instance.setJson(_kUserKey, _user!.toJson());
      await _loadAchievementsFromCloud(uid);
      notifyListeners();
    }
  }

  Future<void> _loadAchievementsFromCloud(String uid) async {
    final cloudAchs = await FirestoreService.instance.getAchievements(uid);
    final cloudMap  = {for (final a in cloudAchs) a['id'] as String: a};
    _achievements = kAchievements.map((a) {
      final saved = cloudMap[a.id];
      if (saved != null && saved['unlockedAt'] != null) {
        return a.withUnlock(DateTime.parse(saved['unlockedAt'] as String));
      }
      return a;
    }).toList();
  }

  Future<void> _migrateAchievementsToCloud(String uid) async {
    for (final ach in _achievements.where((a) => a.isUnlocked)) {
      await FirestoreService.instance.saveAchievement(uid, ach);
    }
  }

  // ── Persistência ──────────────────────────────────────────────────────────

  Future<void> _saveUser() async {
    if (_user == null) return;
    await StorageService.instance.setJson(_kUserKey, _user!.toJson());
    if (_isCloud) {
      await FirestoreService.instance.saveProfile(_user!.id, _user!);
    }
  }

  Future<void> _saveAchievements() async {
    await StorageService.instance.setJsonList(
      _kAchievementsKey,
      _achievements.map((a) => a.toJson()).toList(),
    );
    if (_isCloud && _user != null) {
      for (final ach in _achievements.where((a) => a.isUnlocked)) {
        await FirestoreService.instance.saveAchievement(_user!.id, ach);
      }
    }
  }

  // ── Operações de usuário ──────────────────────────────────────────────────

  /// Cria / atualiza o perfil após o onboarding.
  ///
  /// CRÍTICO: preserva `_user?.id` (Firebase UID definido em onAuthResult).
  /// Se gerasse um novo UUID aqui, todos os dados seriam salvos em
  /// users/{uuid}/... em vez de users/{firebase_uid}/..., e o histórico
  /// desapareceria no próximo login.
  Future<void> createUser(String name, {String? avatar}) async {
    _user = UserModel(
      id:                _user?.id ?? const Uuid().v4(),
      name:              name,
      avatar:            avatar ?? _user?.avatar,
      totalXP:           _user?.totalXP ?? 0,
      currentStreak:     _user?.currentStreak ?? 0,
      longestStreak:     _user?.longestStreak ?? 0,
      lastCheckInDate:   _user?.lastCheckInDate,
      onboardingComplete: false,
      createdAt:         _user?.createdAt ?? DateTime.now(),
    );
    await _saveUser();
    // Mantém auth_state com UID correto após criação do perfil
    await _persistAuthState();
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
    if (newLevel > oldLevel) _checkLevelAchievements(newLevel);
    notifyListeners();
  }

  Future<void> updateStreak(bool checkedInToday) async {
    if (_user == null) return;
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (!checkedInToday) {
      final last = _user!.lastCheckInDate;
      if (last != null) {
        final lastDay = DateTime(last.year, last.month, last.day);
        final diff    = today.difference(lastDay).inDays;
        if (diff == 1) {
          _user!.currentStreak++;
          if (_user!.currentStreak > _user!.longestStreak) {
            _user!.longestStreak = _user!.currentStreak;
          }
          if (_user!.currentStreak % 7 == 0) await addXP(kXpStreakBonus);
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
    if (_user!.currentStreak >= 7)  _unlockAchievement('week_streak');
    if (_user!.currentStreak >= 30) _unlockAchievement('month_iron');
  }

  void _checkLevelAchievements(int level) {
    if (level >= 10) _unlockAchievement('level_10');
  }

  Future<void> unlockAchievement(String id) async => _unlockAchievement(id);

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
    _user          = null;
    _achievements  = kAchievements.toList();
    _isAuthenticated = false;
    _isCloud         = false;
    _authProvider    = null;
    _persistedUid    = null;
    _isInitialized   = false;
    notifyListeners();
    await init();
  }

  /// Desconecta e limpa estado de autenticação (mantém dados locais em cache)
  Future<void> signOut() async {
    await AuthService.instance.signOut();
    _isAuthenticated = false;
    _isCloud         = false;
    _authProvider    = null;
    _persistedUid    = null;
    await StorageService.instance.remove(_kAuthKey);
    notifyListeners();
  }
}
