import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/activity_model.dart';
import '../models/area_model.dart';
import '../models/checkin_model.dart';
import '../models/achievement_model.dart';

/// Serviço de acesso ao Cloud Firestore.
///
/// Estrutura: /users/{uid}/{profile|activities|areas|checkIns|achievements}
/// Todos os dados são isolados por uid — cada usuário acessa apenas os próprios.
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ── Referências ────────────────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> _profileRef(String uid) =>
      _db.collection('users').doc(uid).collection('profile').doc('data');

  CollectionReference<Map<String, dynamic>> _activitiesRef(String uid) =>
      _db.collection('users').doc(uid).collection('activities');

  CollectionReference<Map<String, dynamic>> _areasRef(String uid) =>
      _db.collection('users').doc(uid).collection('areas');

  CollectionReference<Map<String, dynamic>> _checkInsRef(String uid) =>
      _db.collection('users').doc(uid).collection('checkIns');

  CollectionReference<Map<String, dynamic>> _achievementsRef(String uid) =>
      _db.collection('users').doc(uid).collection('achievements');

  // ── Perfil ─────────────────────────────────────────────────────────────────

  Future<UserModel?> getProfile(String uid) async {
    try {
      final doc = await _profileRef(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromJson(doc.data()!);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProfile(String uid, UserModel user) async {
    try {
      await _profileRef(uid).set(user.toJson(), SetOptions(merge: true));
    } catch (_) {}
  }

  // ── Atividades ─────────────────────────────────────────────────────────────

  Future<List<ActivityModel>> getActivities(String uid) async {
    try {
      final snap = await _activitiesRef(uid)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map((d) => ActivityModel.fromJson(d.data())).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveActivity(String uid, ActivityModel activity) async {
    try {
      await _activitiesRef(uid).doc(activity.id).set(activity.toJson());
    } catch (_) {}
  }

  Future<void> deleteActivity(String uid, String activityId) async {
    try {
      await _activitiesRef(uid).doc(activityId).delete();
    } catch (_) {}
  }

  // ── Áreas da Vida ──────────────────────────────────────────────────────────

  Future<List<AreaModel>> getAreas(String uid) async {
    try {
      final snap = await _areasRef(uid).get();
      return snap.docs.map((d) => AreaModel.fromJson(d.data())).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveArea(String uid, AreaModel area) async {
    try {
      await _areasRef(uid).doc(area.id).set(area.toJson());
    } catch (_) {}
  }

  /// Salva todas as áreas em um único batch (eficiente no onboarding)
  Future<void> saveAllAreas(String uid, List<AreaModel> areas) async {
    try {
      final batch = _db.batch();
      for (final area in areas) {
        batch.set(_areasRef(uid).doc(area.id), area.toJson());
      }
      await batch.commit();
    } catch (_) {}
  }

  // ── Check-ins ──────────────────────────────────────────────────────────────

  /// Retorna os últimos 90 dias de check-ins
  Future<List<CheckInModel>> getCheckIns(String uid) async {
    try {
      final snap = await _checkInsRef(uid)
          .orderBy('date', descending: true)
          .limit(90)
          .get();
      return snap.docs.map((d) => CheckInModel.fromJson(d.data())).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCheckIn(String uid, CheckInModel checkIn) async {
    try {
      await _checkInsRef(uid).doc(checkIn.id).set(checkIn.toJson());
    } catch (_) {}
  }

  // ── Conquistas ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAchievements(String uid) async {
    try {
      final snap = await _achievementsRef(uid).get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAchievement(String uid, AchievementModel ach) async {
    if (!ach.isUnlocked) return;
    try {
      await _achievementsRef(uid).doc(ach.id).set(ach.toJson());
    } catch (_) {}
  }
}
