import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/diagnostico/data/models/leitura_model.dart';

List<LeituraModel> filtrarParaRelatorio(
  List<LeituraModel> todas, {
  required DateTime inicio,
  required DateTime fim,
  Set<String>? talhoesSelecionados,
}) {
  final fimDia = fim.add(const Duration(days: 1));
  return todas.where((l) {
    final noTalhao = talhoesSelecionados == null ||
        talhoesSelecionados.isEmpty ||
        talhoesSelecionados.contains(l.talhao);
    final noRange =
        !l.dataHora.isBefore(inicio) && !l.dataHora.isAfter(fimDia);
    return noTalhao && noRange;
  }).toList();
}

LeituraModel _make({required String talhao, required DateTime dataHora}) {
  return LeituraModel()
    ..talhao = talhao
    ..dataHora = dataHora
    ..resultadoIA = 'SAUDÁVEL'
    ..confianca = 0.9
    ..caminhoImagem = '/fake/path.jpg'
    ..latitude = -22.0
    ..longitude = -47.0;
}

void main() {
  final leituras = [
    _make(talhao: 'T1', dataHora: DateTime(2024, 5, 15)),
    _make(talhao: 'T1', dataHora: DateTime(2024, 6, 10)),
    _make(talhao: 'T2', dataHora: DateTime(2024, 6, 20)),
    _make(talhao: 'T3', dataHora: DateTime(2024, 7, 5)),
  ];

  group('filtrar por período', () {
    test('retorna apenas leituras dentro do período', () {
      final result = filtrarParaRelatorio(
        leituras,
        inicio: DateTime(2024, 6, 1),
        fim: DateTime(2024, 6, 30),
      );
      expect(result.length, 2);
    });

    test('exclui leituras fora do período', () {
      final result = filtrarParaRelatorio(
        leituras,
        inicio: DateTime(2024, 7, 1),
        fim: DateTime(2024, 7, 31),
      );
      expect(result.length, 1);
      expect(result.first.talhao, 'T3');
    });

    test('período de 1 dia inclui leituras desse dia', () {
      final result = filtrarParaRelatorio(
        leituras,
        inicio: DateTime(2024, 6, 10),
        fim: DateTime(2024, 6, 10),
      );
      expect(result.length, 1);
      expect(result.first.talhao, 'T1');
    });
  });

  group('filtrar por talhão', () {
    test('sem seleção retorna todos dentro do período', () {
      final result = filtrarParaRelatorio(
        leituras,
        inicio: DateTime(2024, 1, 1),
        fim: DateTime(2024, 12, 31),
        talhoesSelecionados: {},
      );
      expect(result.length, 4);
    });

    test('com seleção retorna apenas talhões escolhidos', () {
      final result = filtrarParaRelatorio(
        leituras,
        inicio: DateTime(2024, 1, 1),
        fim: DateTime(2024, 12, 31),
        talhoesSelecionados: {'T1'},
      );
      expect(result.length, 2);
      expect(result.every((l) => l.talhao == 'T1'), isTrue);
    });
  });

  group('combinação período + talhão', () {
    test('aplica interseção correta', () {
      final result = filtrarParaRelatorio(
        leituras,
        inicio: DateTime(2024, 6, 1),
        fim: DateTime(2024, 6, 30),
        talhoesSelecionados: {'T2'},
      );
      expect(result.length, 1);
      expect(result.first.talhao, 'T2');
    });

    test('talhão fora do período retorna vazio', () {
      final result = filtrarParaRelatorio(
        leituras,
        inicio: DateTime(2024, 6, 1),
        fim: DateTime(2024, 6, 30),
        talhoesSelecionados: {'T3'},
      );
      expect(result, isEmpty);
    });
  });
}
