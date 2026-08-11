import 'package:flutter_test/flutter_test.dart';

/// Função pura espelho da lógica do _Avatar widget
String computarIniciais(String nome) {
  final partes = nome.trim().split(' ').where((p) => p.isNotEmpty).toList();
  if (partes.isEmpty) return '?';
  if (partes.length == 1) return partes[0][0].toUpperCase();
  return '${partes[0][0]}${partes.last[0]}'.toUpperCase();
}

void main() {
  group('computarIniciais', () {
    test('nome completo retorna primeira e última inicial', () {
      expect(computarIniciais('João Silva'), 'JS');
    });
    test('nome único retorna primeira letra maiúscula', () {
      expect(computarIniciais('Maria'), 'M');
    });
    test('string vazia retorna ?', () {
      expect(computarIniciais(''), '?');
    });
    test('apenas espaços retorna ?', () {
      expect(computarIniciais('   '), '?');
    });
    test('três partes usa primeira e última', () {
      expect(computarIniciais('Ana Paula Souza'), 'AS');
    });
    test('nome minúsculo é convertido para maiúsculo', () {
      expect(computarIniciais('carlos'), 'C');
    });
    test('espaços extras entre palavras são ignorados', () {
      expect(computarIniciais('  João   Silva  '), 'JS');
    });
  });
}
