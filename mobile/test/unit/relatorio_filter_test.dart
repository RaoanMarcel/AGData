import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/diagnostico/data/models/leitura_model.dart';

/// Espelho da lógica de _leiturasFiltered de RelatorioPage —
/// função pura para testar sem Firebase ou Isar.
List<LeituraModel> filtrar({
  required List<LeituraModel> todas,
  required Set<String> talhoesSelected,
  required DateTimeRange periodo,
}) {
  return todas.where((l) {
    final noTalhao =
        talhoesSelected.isEmpty || talhoesSelected.contains(l.talhao);
    final noRange = !l.dataHora.isBefore(periodo.start) &&
        !l.dataHora.isAfter(periodo.end.add(const Duration(days: 1)));
    return noTalhao && noRange;
  }).toList();
}

LeituraModel _make({
  required String talhao,
  required DateTime dataHora,
  String resultado = 'SAUDÁVEL',
}) {
  return LeituraModel()
    ..talhao = talhao
    ..dataHora = dataHora
    ..resultadoIA = resultado
    ..confianca = 0.9
    ..caminhoImagem = '/fake/path.jpg'
    ..latitude = 0.0
    ..longitude = 0.0;
}

void main() {
  final jan10 = DateTime(2024, 1, 10);
  final jan20 = DateTime(2024, 1, 20);
  final feb05 = DateTime(2024, 2, 5);

  final leituras = [
    _make(talhao: 'A', dataHora: jan10),
    _make(talhao: 'B', dataHora: jan20),
    _make(talhao: 'A', dataHora: feb05),
  ];

  final periodo30dias = DateTimeRange(
    start: DateTime(2024, 1, 1),
    end: DateTime(2024, 1, 31),
  );

  final periodoTotal = DateTimeRange(
    start: DateTime(2024, 1, 1),
    end: DateTime(2024, 12, 31),
  );

  group('filtrar por período', () {
    test('retorna só leituras dentro do intervalo', () {
      final result =
          filtrar(todas: leituras, talhoesSelected: {}, periodo: periodo30dias);
      expect(result.length, 2);
      expect(result.any((l) => l.dataHora == feb05), isFalse);
    });

    test('retorna todas quando o período cobre tudo', () {
      final result =
          filtrar(todas: leituras, talhoesSelected: {}, periodo: periodoTotal);
      expect(result.length, 3);
    });
  });

  group('filtrar por talhão', () {
    test('retorna só leituras do talhão selecionado', () {
      final result = filtrar(
          todas: leituras, talhoesSelected: {'A'}, periodo: periodoTotal);
      expect(result.length, 2);
      expect(result.every((l) => l.talhao == 'A'), isTrue);
    });

    test('talhão vazio não filtra (retorna todos)', () {
      final result =
          filtrar(todas: leituras, talhoesSelected: {}, periodo: periodoTotal);
      expect(result.length, 3);
    });

    test('múltiplos talhões selecionados', () {
      final result = filtrar(
          todas: leituras,
          talhoesSelected: {'A', 'B'},
          periodo: periodoTotal);
      expect(result.length, 3);
    });
  });

  group('filtrar por talhão + período combinados', () {
    test('talhão A dentro de janeiro retorna 1 leitura', () {
      final result = filtrar(
          todas: leituras,
          talhoesSelected: {'A'},
          periodo: periodo30dias);
      expect(result.length, 1);
      expect(result.first.dataHora, jan10);
    });
  });

  group('sem leituras', () {
    test('lista vazia retorna vazia', () {
      final result =
          filtrar(todas: [], talhoesSelected: {}, periodo: periodoTotal);
      expect(result, isEmpty);
    });
  });
}
