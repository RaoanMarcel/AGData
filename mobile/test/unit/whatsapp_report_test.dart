import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/diagnostico/data/models/leitura_model.dart';

/// Espelho da lógica de geração de texto do _enviarRelatorioWhatsApp
String gerarTextoRelatorio(List<LeituraModel> itens) {
  final sb = StringBuffer();
  sb.writeln('📊 *Relatório AGdata - Inspeção de Campo*');
  sb.writeln('⚠️ *Atenção:* ${itens.length} registro(s) selecionado(s).\n');

  for (int i = 0; i < itens.length; i++) {
    final item = itens[i];
    sb.writeln('*Foco ${i + 1} - ${item.resultadoIA}*');
    sb.writeln('Talhão: ${item.talhao}');
    sb.writeln('Precisão: ${(item.confianca * 100).toStringAsFixed(1)}%');
    if (item.observacao.trim().isNotEmpty) {
      sb.writeln('Obs.: ${item.observacao.trim()}');
    }
  }
  sb.writeln('Aguardando orientações de manejo. 🚜');
  return sb.toString();
}

LeituraModel _make({
  required String talhao,
  required String resultado,
  required double confianca,
  String obs = '',
}) {
  return LeituraModel()
    ..talhao = talhao
    ..resultadoIA = resultado
    ..confianca = confianca
    ..observacao = obs
    ..dataHora = DateTime(2024, 6, 15)
    ..caminhoImagem = '/fake/path.jpg'
    ..latitude = -22.0
    ..longitude = -47.0;
}

void main() {
  group('gerarTextoRelatorio', () {
    test('texto inclui cabeçalho padrão', () {
      final texto = gerarTextoRelatorio([]);
      expect(texto, contains('Relatório AGdata'));
      expect(texto, contains('Inspeção de Campo'));
    });

    test('texto inclui contagem correta de registros', () {
      final leituras = [
        _make(talhao: 'T1', resultado: 'FERRUGEM', confianca: 0.95),
        _make(talhao: 'T2', resultado: 'SAUDÁVEL', confianca: 0.88),
      ];
      final texto = gerarTextoRelatorio(leituras);
      expect(texto, contains('2 registro(s)'));
    });

    test('cada leitura tem número de foco sequencial', () {
      final leituras = [
        _make(talhao: 'T1', resultado: 'FERRUGEM', confianca: 0.9),
        _make(talhao: 'T2', resultado: 'OÍDIO', confianca: 0.8),
      ];
      final texto = gerarTextoRelatorio(leituras);
      expect(texto, contains('Foco 1 - FERRUGEM'));
      expect(texto, contains('Foco 2 - OÍDIO'));
    });

    test('precisão é formatada com 1 casa decimal', () {
      final leituras = [
        _make(talhao: 'T1', resultado: 'FERRUGEM', confianca: 0.956),
      ];
      final texto = gerarTextoRelatorio(leituras);
      expect(texto, contains('95.6%'));
    });

    test('observação é incluída quando não vazia', () {
      final leituras = [
        _make(talhao: 'T1', resultado: 'FERRUGEM', confianca: 0.9, obs: 'Urgente'),
      ];
      final texto = gerarTextoRelatorio(leituras);
      expect(texto, contains('Obs.: Urgente'));
    });

    test('observação é omitida quando vazia', () {
      final leituras = [
        _make(talhao: 'T1', resultado: 'SAUDÁVEL', confianca: 0.9),
      ];
      final texto = gerarTextoRelatorio(leituras);
      expect(texto, isNot(contains('Obs.:')));
    });

    test('lista vazia não quebra e inclui rodapé', () {
      final texto = gerarTextoRelatorio([]);
      expect(texto, contains('Aguardando orientações'));
    });
  });
}
