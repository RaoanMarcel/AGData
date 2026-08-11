import 'package:flutter_test/flutter_test.dart';

/// Espelho da lógica de paginação do HistoricoScreen
bool calcularTemMais(int registrosRetornados, {int limite = 50}) {
  return registrosRetornados == limite;
}

void main() {
  group('calcularTemMais', () {
    test('retorna true quando recebe página cheia (50 registros)', () {
      expect(calcularTemMais(50), isTrue);
    });
    test('retorna false quando recebe página incompleta (< 50)', () {
      expect(calcularTemMais(30), isFalse);
    });
    test('retorna false quando não há mais registros (0)', () {
      expect(calcularTemMais(0), isFalse);
    });
    test('retorna false quando recebe 49 registros', () {
      expect(calcularTemMais(49), isFalse);
    });
    test('funciona com limite personalizado', () {
      expect(calcularTemMais(20, limite: 20), isTrue);
      expect(calcularTemMais(19, limite: 20), isFalse);
    });
  });
}
