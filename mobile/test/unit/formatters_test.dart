import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/formatters.dart';

void main() {
  group('formatarData', () {
    test('formata data normal corretamente', () {
      final dt = DateTime(2024, 6, 15);
      expect(formatarData(dt), '15/06/2024');
    });

    test('preenche dia e mês com zero à esquerda', () {
      final dt = DateTime(2024, 1, 5);
      expect(formatarData(dt), '05/01/2024');
    });

    test('formata início do dia (meia-noite)', () {
      final dt = DateTime(2024, 12, 31, 0, 0);
      expect(formatarData(dt), '31/12/2024');
    });

    test('formata fim do ano', () {
      final dt = DateTime(2023, 12, 31);
      expect(formatarData(dt), '31/12/2023');
    });
  });

  group('formatarDataHora', () {
    test('formata data e hora normais', () {
      final dt = DateTime(2024, 6, 15, 14, 30);
      expect(formatarDataHora(dt), '15/06/2024 às 14:30');
    });

    test('preenche hora e minuto com zero à esquerda', () {
      final dt = DateTime(2024, 3, 7, 9, 5);
      expect(formatarDataHora(dt), '07/03/2024 às 09:05');
    });

    test('formata meia-noite corretamente', () {
      final dt = DateTime(2024, 1, 1, 0, 0);
      expect(formatarDataHora(dt), '01/01/2024 às 00:00');
    });

    test('formata fim do dia corretamente', () {
      final dt = DateTime(2024, 11, 30, 23, 59);
      expect(formatarDataHora(dt), '30/11/2024 às 23:59');
    });
  });
}
