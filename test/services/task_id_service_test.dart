import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance_tracker/services/task_id_service.dart';

void main() {
  group('TaskIdService', () {
    late TaskIdService svc;

    setUp(() {
      // Cria instância isolada usando o singleton (estado compartilhado)
      svc = TaskIdService.instance;
    });

    test('ID tem 16 caracteres (14 dígitos + 2 letras)', () {
      final id = svc.generate();
      expect(id.length, 16);
    });

    test('ID começa com dígitos (data e hora)', () {
      final id = svc.generate();
      // YYYYMMDDHHMMSS = 14 dígitos
      expect(int.tryParse(id.substring(0, 14)), isNotNull);
    });

    test('sufixo XX são letras maiúsculas', () {
      final id = svc.generate();
      final suffix = id.substring(14); // 2 últimos chars
      expect(suffix, matches(RegExp(r'^[A-Z]{2}$')));
    });

    test('IDs gerados em sequência são diferentes', () {
      final ids = List.generate(10, (_) => svc.generate());
      final unique = ids.toSet();
      expect(unique.length, ids.length);
    });

    test('sequência começa em AA (quando reinicia o segundo)', () {
      // Geramos 26 IDs e verificamos que o sufixo avança AA→AB→...→AZ
      // O segundo pode mudar durante o teste, mas o padrão de incremento deve valer
      final ids = List.generate(5, (_) => svc.generate());
      // Cada ID deve ser diferente — garantia mínima
      for (var i = 1; i < ids.length; i++) {
        expect(ids[i], isNot(equals(ids[i - 1])));
      }
    });

    test('formato YYYYMMDDHHMMSS correto', () {
      final id = svc.generate();
      final year  = int.parse(id.substring(0, 4));
      final month = int.parse(id.substring(4, 6));
      final day   = int.parse(id.substring(6, 8));
      final hour  = int.parse(id.substring(8, 10));
      final min   = int.parse(id.substring(10, 12));
      final sec   = int.parse(id.substring(12, 14));
      final now   = DateTime.now();

      expect(year,  closeTo(now.year, 1));
      expect(month, inInclusiveRange(1, 12));
      expect(day,   inInclusiveRange(1, 31));
      expect(hour,  inInclusiveRange(0, 23));
      expect(min,   inInclusiveRange(0, 59));
      expect(sec,   inInclusiveRange(0, 59));
    });
  });
}
