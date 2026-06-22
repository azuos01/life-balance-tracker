import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance_tracker/models/learning_progress.dart';

void main() {
  // ── ChessStats ────────────────────────────────────────────────────────────

  group('ChessStats — fromApi', () {
    Map<String, dynamic> apiJson({
      int? rapidRating,
      int? blitzRating,
      int? bulletRating,
      int? puzzleRating,
      int? rushBest,
    }) =>
        {
          if (rapidRating != null)
            'chess_rapid': {
              'last': {'rating': rapidRating}
            },
          if (blitzRating != null)
            'chess_blitz': {
              'last': {'rating': blitzRating}
            },
          if (bulletRating != null)
            'chess_bullet': {
              'last': {'rating': bulletRating}
            },
          if (puzzleRating != null)
            'tactics': {
              'highest': {'rating': puzzleRating}
            },
          if (rushBest != null)
            'puzzle_rush': {
              'best': {'score': rushBest}
            },
        };

    test('parseia todos os ratings', () {
      final s = ChessStats.fromApi(
          'user1',
          apiJson(
              rapidRating: 1200,
              blitzRating: 900,
              bulletRating: 800,
              puzzleRating: 1400,
              rushBest: 22));
      expect(s.username, 'user1');
      expect(s.rapidRating, 1200);
      expect(s.blitzRating, 900);
      expect(s.bulletRating, 800);
      expect(s.puzzleRating, 1400);
      expect(s.puzzleRushBest, 22);
    });

    test('campos ausentes resultam em null', () {
      final s = ChessStats.fromApi('user2', {});
      expect(s.rapidRating, null);
      expect(s.blitzRating, null);
      expect(s.puzzleRating, null);
      expect(s.puzzleRushBest, null);
    });

    test('toJson / fromJson round-trip', () {
      final original = ChessStats(
        username: 'playerX',
        rapidRating: 1100,
        blitzRating: 950,
        bulletRating: null,
        puzzleRating: 1300,
        puzzleRushBest: 15,
        fetchedAt: DateTime(2026, 6, 22),
      );
      final restored = ChessStats.fromJson(original.toJson());
      expect(restored.username, original.username);
      expect(restored.rapidRating, original.rapidRating);
      expect(restored.blitzRating, original.blitzRating);
      expect(restored.bulletRating, original.bulletRating);
      expect(restored.puzzleRating, original.puzzleRating);
      expect(restored.puzzleRushBest, original.puzzleRushBest);
      expect(restored.fetchedAt, original.fetchedAt);
    });

    test('fromJson com campos ausentes usa null', () {
      final s = ChessStats.fromJson({'username': 'u', 'fetchedAt': DateTime(2026, 1, 1).toIso8601String()});
      expect(s.rapidRating, null);
      expect(s.puzzleRating, null);
    });
  });

  // ── DuolingoProgress ──────────────────────────────────────────────────────

  group('DuolingoProgress', () {
    test('valores padrão corretos', () {
      const d = DuolingoProgress(username: 'user');
      expect(d.streak, 0);
      expect(d.totalXP, 0);
      expect(d.dailyGoalXP, 10);
      expect(d.activeLanguage, '');
      expect(d.languageLevel, 1);
    });

    test('toJson / fromJson round-trip', () {
      const original = DuolingoProgress(
        username: 'marcos',
        streak: 42,
        totalXP: 15000,
        dailyGoalXP: 50,
        activeLanguage: 'Inglês',
        languageLevel: 12,
        languageXP: 3000,
      );
      final restored = DuolingoProgress.fromJson(original.toJson());
      expect(restored.username, original.username);
      expect(restored.streak, original.streak);
      expect(restored.totalXP, original.totalXP);
      expect(restored.activeLanguage, original.activeLanguage);
      expect(restored.languageLevel, original.languageLevel);
      expect(restored.languageXP, original.languageXP);
    });

    test('copyWith preserva campos não alterados', () {
      const d = DuolingoProgress(username: 'u', streak: 10, totalXP: 500);
      final copy = d.copyWith(streak: 15);
      expect(copy.streak, 15);
      expect(copy.totalXP, 500);
      expect(copy.username, 'u');
    });

    test('fromJson com campos ausentes usa defaults', () {
      final d = DuolingoProgress.fromJson({'username': 'x'});
      expect(d.streak, 0);
      expect(d.totalXP, 0);
      expect(d.languageLevel, 1);
    });
  });

  // ── DataCampCourse ────────────────────────────────────────────────────────

  group('DataCampCourse', () {
    const base = DataCampCourse(
      id: 'dc_1',
      title: 'Intro to Python',
      technology: 'Python',
      totalChapters: 4,
      completedChapters: 0,
    );

    test('progress = 0 quando nenhum capítulo concluído', () {
      expect(base.progress, 0.0);
      expect(base.isCompleted, false);
    });

    test('progress = 0.5 com metade concluída', () {
      final c = base.copyWith(completedChapters: 2);
      expect(c.progress, 0.5);
      expect(c.isCompleted, false);
    });

    test('progress = 1.0 e isCompleted quando todos concluídos', () {
      final c = base.copyWith(completedChapters: 4);
      expect(c.progress, 1.0);
      expect(c.isCompleted, true);
    });

    test('progress = 0 quando totalChapters = 0', () {
      const c = DataCampCourse(
          id: 'x', title: 'T', technology: 'SQL',
          totalChapters: 0, completedChapters: 0);
      expect(c.progress, 0.0);
      expect(c.isCompleted, false);
    });

    test('toJson / fromJson round-trip', () {
      const original = DataCampCourse(
        id: 'dc_42',
        title: 'Machine Learning Fundamentals',
        technology: 'Machine Learning',
        totalChapters: 5,
        completedChapters: 3,
      );
      final restored = DataCampCourse.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.technology, original.technology);
      expect(restored.totalChapters, original.totalChapters);
      expect(restored.completedChapters, original.completedChapters);
    });

    test('copyWith atualiza apenas campos especificados', () {
      final c = base.copyWith(completedChapters: 3, title: 'Novo Título');
      expect(c.completedChapters, 3);
      expect(c.title, 'Novo Título');
      expect(c.technology, base.technology);
      expect(c.totalChapters, base.totalChapters);
    });

    test('fromJson usa defaults para campos ausentes', () {
      final c = DataCampCourse.fromJson({'id': 'x', 'title': 'T'});
      expect(c.technology, 'Python');
      expect(c.totalChapters, 4);
      expect(c.completedChapters, 0);
    });
  });

  // ── kDataCampTechnologies ─────────────────────────────────────────────────

  group('kDataCampTechnologies', () {
    test('lista contém pelo menos 10 tecnologias', () {
      expect(kDataCampTechnologies.length, greaterThanOrEqualTo(10));
    });

    test('Python está na lista', () {
      expect(kDataCampTechnologies.contains('Python'), true);
    });
  });
}
