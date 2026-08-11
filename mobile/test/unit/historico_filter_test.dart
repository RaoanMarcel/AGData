import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/diagnostico/data/models/leitura_model.dart';

/// Espelho da lógica de filtro do HistoricoScreen — função pura testável
/// sem dependência de UI, Firebase ou Isar.
List<LeituraModel> filtrarLeituras(
  List<LeituraModel> todas, {
  String? doenca,
  double? confiancaMin,
  DateTime? dataInicio,
  DateTime? dataFim,
}) {
  return todas.where((l) {
    if (doenca != null && l.resultadoIA != doenca) return false;
    if (confiancaMin != null && l.confianca < confiancaMin) return false;
    if (dataInicio != null && l.dataHora.isBefore(dataInicio)) return false;
    if (dataFim != null && l.dataHora.isAfter(dataFim)) return false;
    return true;
  }).toList();
}

LeituraModel _make({
  String resultado = 'SAUDÁVEL',
  double confianca = 0.9,
  DateTime? dataHora,
}) {
  return LeituraModel()
    ..resultadoIA = resultado
    ..confianca = confianca
    ..dataHora = dataHora ?? DateTime(2024, 6, 15)
    ..caminhoImagem = '/fake/path.jpg'
    ..latitude = -22.0
    ..longitude = -47.0
    ..talhao = 'T1';
}

void main() {
  final leituras = [
    _make(resultado: 'FERRUGEM', confianca: 0.95, dataHora: DateTime(2024, 1, 5)),
    _make(resultado: 'FERRUGEM', confianca: 0.70, dataHora: DateTime(2024, 2, 10)),
    _make(resultado: 'SAUDÁVEL', confianca: 0.85, dataHora: DateTime(2024, 3, 1)),
    _make(resultado: 'SAUDÁVEL', confianca: 0.50, dataHora: DateTime(2024, 4, 20)),
    _make(resultado: 'INCONCLUSIVO', confianca: 0.60, dataHora: DateTime(2024, 5, 15)),
    _make(resultado: 'INCONCLUSIVO', confianca: 0.88, dataHora: DateTime(2024, 6, 30)),
  ];

  group('filtro por doença', () {
    test('retorna apenas leituras FERRUGEM', () {
      final result = filtrarLeituras(leituras, doenca: 'FERRUGEM');
      expect(result.length, 2);
      expect(result.every((l) => l.resultadoIA == 'FERRUGEM'), isTrue);
    });

    test('retorna apenas leituras SAUDÁVEL', () {
      final result = filtrarLeituras(leituras, doenca: 'SAUDÁVEL');
      expect(result.length, 2);
      expect(result.every((l) => l.resultadoIA == 'SAUDÁVEL'), isTrue);
    });

    test('retorna apenas leituras INCONCLUSIVO', () {
      final result = filtrarLeituras(leituras, doenca: 'INCONCLUSIVO');
      expect(result.length, 2);
      expect(result.every((l) => l.resultadoIA == 'INCONCLUSIVO'), isTrue);
    });

    test('doença inexistente retorna lista vazia', () {
      final result = filtrarLeituras(leituras, doenca: 'PRAGA_INEXISTENTE');
      expect(result, isEmpty);
    });
  });

  group('filtro por confiança mínima', () {
    test('confiança >= 0.8 exclui leituras abaixo do limiar', () {
      final result = filtrarLeituras(leituras, confiancaMin: 0.8);
      expect(result.length, 3);
      expect(result.every((l) => l.confianca >= 0.8), isTrue);
    });

    test('confiança >= 0.9 retorna apenas leituras de alta confiança', () {
      final result = filtrarLeituras(leituras, confiancaMin: 0.9);
      // somente a de confiança 0.95 e 0.9 (nenhuma é 0.9 aqui, só 0.95)
      expect(result.length, 1);
      expect(result.first.confianca, 0.95);
    });
  });

  group('filtro por data', () {
    test('exclui leituras antes da data de início', () {
      final result = filtrarLeituras(
        leituras,
        dataInicio: DateTime(2024, 3, 1),
      );
      expect(result.length, 4);
      expect(result.every((l) => !l.dataHora.isBefore(DateTime(2024, 3, 1))),
          isTrue);
    });

    test('exclui leituras depois da data de fim', () {
      final result = filtrarLeituras(
        leituras,
        dataFim: DateTime(2024, 3, 31),
      );
      expect(result.length, 3);
      expect(
          result.every((l) => !l.dataHora.isAfter(DateTime(2024, 3, 31))),
          isTrue);
    });

    test('intervalo de datas preciso retorna apenas leituras no período', () {
      final result = filtrarLeituras(
        leituras,
        dataInicio: DateTime(2024, 2, 1),
        dataFim: DateTime(2024, 4, 30),
      );
      expect(result.length, 3);
    });
  });

  group('combinação de filtros', () {
    test('doença + confiança mínima aplica interseção', () {
      final result = filtrarLeituras(
        leituras,
        doenca: 'FERRUGEM',
        confiancaMin: 0.80,
      );
      expect(result.length, 1);
      expect(result.first.confianca, 0.95);
    });

    test('doença + intervalo de datas aplica interseção', () {
      final result = filtrarLeituras(
        leituras,
        doenca: 'SAUDÁVEL',
        dataInicio: DateTime(2024, 3, 1),
        dataFim: DateTime(2024, 3, 31),
      );
      expect(result.length, 1);
      expect(result.first.resultadoIA, 'SAUDÁVEL');
    });
  });

  group('sem filtros', () {
    test('retorna todas as leituras quando nenhum filtro é aplicado', () {
      final result = filtrarLeituras(leituras);
      expect(result.length, leituras.length);
    });
  });

  group('lista vazia', () {
    test('lista vazia com filtros retorna lista vazia', () {
      final result = filtrarLeituras(
        [],
        doenca: 'FERRUGEM',
        confiancaMin: 0.9,
        dataInicio: DateTime(2024, 1, 1),
        dataFim: DateTime(2024, 12, 31),
      );
      expect(result, isEmpty);
    });
  });
}
