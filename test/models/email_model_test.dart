import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance_tracker/models/email_model.dart';

void main() {
  final testDate = DateTime.utc(2024, 6, 1, 10, 0);

  group('EmailMessage', () {
    test('fromName extrai nome de formato "Name <email>"', () {
      final msg = EmailMessage(
        id: 'abc123',
        subject: 'Reunião amanhã',
        from: 'João Silva <joao@empresa.com>',
        snippet: '',
        date: testDate,
      );
      expect(msg.fromName, 'João Silva');
    });

    test('fromName retorna o endereço quando sem display name', () {
      final msg = EmailMessage(
        id: 'x',
        subject: 'S',
        from: 'noreply@foo.com',
        snippet: '',
        date: testDate,
      );
      expect(msg.fromName, 'noreply@foo.com');
    });

    test('fromName retorna string vazia quando from está vazio', () {
      final msg = EmailMessage(
        id: 'x',
        subject: 'S',
        from: '',
        snippet: '',
        date: testDate,
      );
      expect(msg.fromName, '');
    });

    test('propriedades id, subject e snippet corretas', () {
      final msg = EmailMessage(
        id: 'id1',
        subject: 'Assunto',
        from: 'x@y.com',
        snippet: 'Resumo curto',
        date: testDate,
      );
      expect(msg.id, 'id1');
      expect(msg.subject, 'Assunto');
      expect(msg.snippet, 'Resumo curto');
      expect(msg.date, testDate);
    });
  });

  group('kEmailWindowOptions', () {
    test('contém exatamente 6 opções', () {
      expect(kEmailWindowOptions.length, 6);
    });

    test('primeira opção é 1 dia', () {
      expect(kEmailWindowOptions.first.days, 1);
      expect(kEmailWindowOptions.first.label, '1 dia');
    });

    test('última opção é 1 ano (365 dias)', () {
      expect(kEmailWindowOptions.last.days, 365);
      expect(kEmailWindowOptions.last.label, '1 ano');
    });

    test('cobre dias esperados: 1, 7, 30, 90, 180, 365', () {
      final days = kEmailWindowOptions.map((o) => o.days).toList();
      expect(days, containsAll([1, 7, 30, 90, 180, 365]));
    });
  });

  group('EmailAnalysisConfig', () {
    test('defaults: windowDays=7, senderEmails vazio', () {
      const c = EmailAnalysisConfig();
      expect(c.windowDays, 7);
      expect(c.senderEmails, isEmpty);
    });

    test('copyWith altera windowDays mantendo senderEmails', () {
      const base = EmailAnalysisConfig();
      final c = base.copyWith(windowDays: 30);
      expect(c.windowDays, 30);
      expect(c.senderEmails, isEmpty);
    });

    test('copyWith altera senderEmails mantendo windowDays', () {
      const base = EmailAnalysisConfig();
      final c = base.copyWith(senderEmails: ['a@b.com', 'c@d.com']);
      expect(c.senderEmails, hasLength(2));
      expect(c.windowDays, 7);
    });

    test('toJson / fromJson roundtrip preserva todos os campos', () {
      final config = EmailAnalysisConfig(
        senderEmails: ['foo@bar.com', 'baz@qux.com'],
        windowDays: 90,
      );
      final restored = EmailAnalysisConfig.fromJson(config.toJson());
      expect(restored.windowDays, 90);
      expect(restored.senderEmails, ['foo@bar.com', 'baz@qux.com']);
    });

    test('fromJson com json vazio usa defaults', () {
      final c = EmailAnalysisConfig.fromJson({});
      expect(c.windowDays, 7);
      expect(c.senderEmails, isEmpty);
    });

    test('fromJson com windowDays 180', () {
      final c = EmailAnalysisConfig.fromJson({
        'senderEmails': <String>[],
        'windowDays': 180,
      });
      expect(c.windowDays, 180);
      expect(c.senderEmails, isEmpty);
    });
  });
}
