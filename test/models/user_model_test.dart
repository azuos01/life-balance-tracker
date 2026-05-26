import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance_tracker/models/user_model.dart';
import 'package:life_balance_tracker/constants/app_constants.dart';

void main() {
  group('UserModel', () {
    late UserModel user;

    setUp(() {
      user = UserModel(
        id: 'u1',
        name: 'João Silva',
        totalXP: 0,
        currentStreak: 0,
        longestStreak: 0,
        onboardingComplete: false,
        createdAt: DateTime(2024, 1, 1),
      );
    });

    test('toJson / fromJson round-trip preserva todos os campos', () {
      final full = UserModel(
        id: 'u2',
        name: 'Maria',
        avatar: 'https://avatar.example.com/u2.jpg',
        totalXP: 1500,
        currentStreak: 7,
        longestStreak: 14,
        lastCheckInDate: DateTime(2024, 6, 15),
        onboardingComplete: true,
        createdAt: DateTime(2024, 1, 1),
      );
      final restored = UserModel.fromJson(full.toJson());
      expect(restored.id, full.id);
      expect(restored.name, full.name);
      expect(restored.avatar, full.avatar);
      expect(restored.totalXP, full.totalXP);
      expect(restored.currentStreak, full.currentStreak);
      expect(restored.longestStreak, full.longestStreak);
      expect(restored.lastCheckInDate, full.lastCheckInDate);
      expect(restored.onboardingComplete, full.onboardingComplete);
      expect(restored.createdAt, full.createdAt);
    });

    test('fromJson usa defaults quando campos opcionais ausentes', () {
      final u = UserModel.fromJson({
        'id': 'x',
        'name': 'Teste',
        'createdAt': DateTime(2024, 1, 1).toIso8601String(),
      });
      expect(u.totalXP, 0);
      expect(u.currentStreak, 0);
      expect(u.longestStreak, 0);
      expect(u.onboardingComplete, false);
      expect(u.avatar, null);
      expect(u.lastCheckInDate, null);
    });

    test('level começa em 1 com 0 XP', () {
      expect(user.level, 1);
    });

    test('level aumenta com XP crescente', () {
      final low = user.copyWith(totalXP: 100);
      final mid = user.copyWith(totalXP: 1500);
      final high = user.copyWith(totalXP: 10000);
      expect(mid.level, greaterThan(low.level));
      expect(high.level, greaterThan(mid.level));
    });

    test('tier muda conforme o XP', () {
      // 0-1000: Iniciante
      expect(user.tier, 'Iniciante');
      // 1001-5000: Praticante
      expect(user.copyWith(totalXP: 2000).tier, 'Praticante');
      // 5001-15000: Guerreiro
      expect(user.copyWith(totalXP: 8000).tier, 'Guerreiro');
    });

    test('avatar é null por padrão', () {
      expect(user.avatar, null);
    });

    test('onboardingComplete padrão é false', () {
      expect(user.onboardingComplete, false);
    });

    test('copyWith preserva id e createdAt', () {
      final copy = user.copyWith(name: 'Maria', totalXP: 500);
      expect(copy.id, user.id);
      expect(copy.createdAt, user.createdAt);
      expect(copy.name, 'Maria');
      expect(copy.totalXP, 500);
    });

    test('copyWith(onboardingComplete: true) funciona', () {
      final completed = user.copyWith(onboardingComplete: true);
      expect(completed.onboardingComplete, true);
    });

    test('copyWith sem argumentos cria cópia idêntica', () {
      final copy = user.copyWith();
      expect(copy.id, user.id);
      expect(copy.name, user.name);
      expect(copy.totalXP, user.totalXP);
    });

    test('lastCheckInDate null é serializado corretamente', () {
      final json = user.toJson();
      expect(json['lastCheckInDate'], null);
      final restored = UserModel.fromJson(json);
      expect(restored.lastCheckInDate, null);
    });

    test('nextLevelXP retorna valor positivo', () {
      expect(user.nextLevelXP, greaterThanOrEqualTo(0));
    });
  });

  group('UserModel — constantes de XP', () {
    test('kXpEasy < kXpMedium < kXpHard', () {
      expect(kXpEasy, lessThan(kXpMedium));
      expect(kXpMedium, lessThan(kXpHard));
    });

    test('kXpStreakBonus é positivo', () {
      expect(kXpStreakBonus, greaterThan(0));
    });

    test('kAreas tem exatamente 10 áreas', () {
      expect(kAreas.length, 10);
    });

    test('todas as áreas têm id, name e icon não-vazios', () {
      for (final area in kAreas) {
        expect(area.id, isNotEmpty);
        expect(area.name, isNotEmpty);
        expect(area.icon, isNotEmpty);
      }
    });

    test('IDs das áreas são únicos', () {
      final ids = kAreas.map((a) => a.id).toSet();
      expect(ids.length, kAreas.length);
    });
  });
}
