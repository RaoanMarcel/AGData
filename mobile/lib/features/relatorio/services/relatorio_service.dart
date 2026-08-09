import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../diagnostico/data/models/leitura_model.dart';
import '../../../core/theme/diagnostico_visuals.dart';

class RelatorioService {
  static String _fmt(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$d/$m/$y';
  }

  static String _fmtDt(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$d/$mo/$y $h:$mi';
  }

  static const _verde = PdfColor(0.18, 0.49, 0.20);
  static const _verdeEscuro = PdfColor(0.11, 0.37, 0.13);
  static const _vermelho = PdfColor(0.78, 0.16, 0.16);
  static const _cinza = PdfColor(0.42, 0.42, 0.42);
  static const _cinzaClaro = PdfColor(0.92, 0.92, 0.92);

  static Future<Uint8List> gerarPdf({
    required List<LeituraModel> leituras,
    required String empresaNome,
    required String tecnicoNome,
    required DateTime periodoInicio,
    required DateTime periodoFim,
    Uint8List? mapaImageBytes,
    List<String>? talhoesSelecionados,
  }) async {
    final doc = pw.Document();
    final periodStr = '${_fmt(periodoInicio)} – ${_fmt(periodoFim)}';
    final hoje = _fmt(DateTime.now());

    final Map<String, List<LeituraModel>> porTalhao = {};
    for (final l in leituras) {
      porTalhao.putIfAbsent(l.talhao, () => []).add(l);
    }

    final Map<String, int> contagem = {};
    final Map<String, List<double>> confiancasPorDoenca = {};
    for (final l in leituras) {
      contagem[l.resultadoIA] = (contagem[l.resultadoIA] ?? 0) + 1;
      confiancasPorDoenca.putIfAbsent(l.resultadoIA, () => []).add(l.confianca);
    }

    // ── Capa ──────────────────────────────────────────────────────────────────
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Container(
                width: 80,
                height: 80,
                decoration: const pw.BoxDecoration(
                  color: _verde,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Center(
                  child: pw.Text(
                    'AG',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 34,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Text(
                empresaNome,
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: _verdeEscuro,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Relatório Fitossanitário — Soja',
                style: pw.TextStyle(fontSize: 15, color: _cinza),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Período: $periodStr',
                style: pw.TextStyle(fontSize: 12, color: _cinza),
              ),
              pw.SizedBox(height: 28),
              pw.Divider(color: _verde),
              pw.SizedBox(height: 12),
              pw.Text('Técnico: $tecnicoNome',
                  style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 4),
              pw.Text('Gerado em: $hoje',
                  style: pw.TextStyle(fontSize: 11, color: _cinza)),
              if (talhoesSelecionados != null &&
                  talhoesSelecionados.isNotEmpty) ...[
                pw.SizedBox(height: 6),
                pw.Text(
                  'Talhões: ${talhoesSelecionados.join(', ')}',
                  style: pw.TextStyle(fontSize: 10, color: _cinza),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    // ── Resumo Executivo ───────────────────────────────────────────────────────
    final maisAfetado = porTalhao.entries
        .where((e) => e.value.any(_isFoco))
        .fold<MapEntry<String, int>?>(null, (prev, e) {
      final n = e.value.where(_isFoco).length;
      return prev == null || n > prev.value ? MapEntry(e.key, n) : prev;
    });

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (_) => [
          _cabecalho('Resumo Executivo'),
          pw.SizedBox(height: 14),
          _infoLinha('Total de análises:', '${leituras.length}'),
          _infoLinha('Talhões analisados:', '${porTalhao.length}'),
          _infoLinha('Período:', periodStr),
          if (maisAfetado != null)
            _infoLinha(
              'Talhão mais afetado:',
              '${maisAfetado.key} (${maisAfetado.value} foco(s))',
            ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Distribuição por Diagnóstico',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(
                color: PdfColor(0.82, 0.82, 0.82), width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(2),
            },
            children: [
              _linhaTabela(
                ['Diagnóstico', 'Qtd.', '%', 'Conf. Média'],
                cabecalho: true,
              ),
              ...contagem.entries.map((e) {
                final v = DiagnosticoVisual.fromResultado(e.key);
                final perc =
                    (e.value / leituras.length * 100).toStringAsFixed(1);
                final cfList = confiancasPorDoenca[e.key]!;
                final media =
                    cfList.reduce((a, b) => a + b) / cfList.length * 100;
                return _linhaTabela([
                  v.label,
                  '${e.value}',
                  '$perc%',
                  '${media.toStringAsFixed(1)}%',
                ]);
              }),
            ],
          ),
          if (mapaImageBytes != null) ...[
            pw.SizedBox(height: 20),
            pw.Text(
              'Mapa de Ocorrências',
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
            pw.SizedBox(height: 8),
            pw.ClipRRect(
              horizontalRadius: 8,
              verticalRadius: 8,
              child: pw.Image(
                pw.MemoryImage(mapaImageBytes),
                fit: pw.BoxFit.contain,
                height: 250,
              ),
            ),
          ],
        ],
      ),
    );

    // ── Seção por Talhão ───────────────────────────────────────────────────────
    for (final entry in porTalhao.entries) {
      final talhao = entry.key;
      final lts = entry.value;
      final focos = lts.where(_isFoco).toList();

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          build: (_) => [
            _cabecalho('Talhão: $talhao'),
            pw.SizedBox(height: 10),
            _infoLinha('Total de leituras:', '${lts.length}'),
            _infoLinha(
                'Focos (confiança > 70%):', '${focos.length}'),
            pw.SizedBox(height: 14),
            if (focos.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: const pw.BoxDecoration(
                  color: PdfColor(0.98, 0.92, 0.92),
                  border:
                      pw.Border(left: pw.BorderSide(color: _vermelho, width: 3)),
                ),
                child: pw.Text(
                  '⚠  Pontos de Foco Identificados',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                    color: _vermelho,
                  ),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(
                    color: PdfColor(0.82, 0.82, 0.82), width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2.2),
                  1: const pw.FlexColumnWidth(1.8),
                  2: const pw.FlexColumnWidth(1.4),
                  3: const pw.FlexColumnWidth(1.8),
                  4: const pw.FlexColumnWidth(1.8),
                },
                children: [
                  _linhaTabela(
                    ['Data/Hora', 'Diagnóstico', 'Conf.', 'Latitude', 'Longitude'],
                    cabecalho: true,
                    corFundo: _vermelho,
                  ),
                  ...focos.map((l) {
                    final v = DiagnosticoVisual.fromResultado(l.resultadoIA);
                    return _linhaTabela([
                      _fmtDt(l.dataHora),
                      v.label,
                      '${(l.confianca * 100).toStringAsFixed(1)}%',
                      l.latitude.toStringAsFixed(5),
                      l.longitude.toStringAsFixed(5),
                    ]);
                  }),
                ],
              ),
              pw.SizedBox(height: 14),
            ],
            pw.Text(
              'Todas as Leituras',
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(
                  color: PdfColor(0.82, 0.82, 0.82), width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.2),
                1: const pw.FlexColumnWidth(1.8),
                2: const pw.FlexColumnWidth(1.2),
                3: const pw.FlexColumnWidth(1.6),
                4: const pw.FlexColumnWidth(1.6),
                5: const pw.FlexColumnWidth(3),
              },
              children: [
                _linhaTabela(
                  ['Data/Hora', 'Diagnóstico', 'Conf.', 'Lat.', 'Lng.', 'Observação'],
                  cabecalho: true,
                ),
                ...lts.map((l) {
                  final v = DiagnosticoVisual.fromResultado(l.resultadoIA);
                  return _linhaTabela([
                    _fmtDt(l.dataHora),
                    v.label,
                    '${(l.confianca * 100).toStringAsFixed(1)}%',
                    l.latitude.toStringAsFixed(4),
                    l.longitude.toStringAsFixed(4),
                    l.observacao.isEmpty ? '-' : l.observacao,
                  ]);
                }),
              ],
            ),
          ],
        ),
      );
    }

    // ── Recomendações Agronômicas ──────────────────────────────────────────────
    final doencasDetectadas = contagem.keys
        .where((d) =>
            d != 'SAUDÁVEL' &&
            d != 'SAUDAVEL' &&
            d != 'INCONCLUSIVO')
        .toList();

    if (doencasDetectadas.isNotEmpty) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          build: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _cabecalho('Recomendações Agronômicas'),
              pw.SizedBox(height: 14),
              ...doencasDetectadas.map(_boxRecomendacao),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: const pw.BoxDecoration(
                  color: _cinzaClaro,
                  borderRadius:
                      pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Text(
                  'Este relatório foi gerado automaticamente pelo sistema HectarIA. '
                  'As recomendações têm caráter orientativo. Consulte sempre um '
                  'engenheiro agrônomo habilitado antes de aplicar qualquer produto.',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: _cinza,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return doc.save();
  }

  static bool _isFoco(LeituraModel l) =>
      l.resultadoIA != 'SAUDÁVEL' &&
      l.resultadoIA != 'SAUDAVEL' &&
      l.confianca > 0.70;

  static pw.Widget _cabecalho(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: const pw.BoxDecoration(
        color: _verde,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  static pw.Widget _infoLinha(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 11)),
          pw.SizedBox(width: 8),
          pw.Text(value,
              style: pw.TextStyle(fontSize: 11, color: _cinza)),
        ],
      ),
    );
  }

  static pw.TableRow _linhaTabela(
    List<String> cells, {
    bool cabecalho = false,
    PdfColor corFundo = _verde,
  }) {
    return pw.TableRow(
      decoration: cabecalho ? pw.BoxDecoration(color: corFundo) : null,
      children: cells
          .map(
            (c) => pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                c,
                style: pw.TextStyle(
                  fontSize: 8,
                  color: cabecalho ? PdfColors.white : null,
                  fontWeight:
                      cabecalho ? pw.FontWeight.bold : null,
                ),
                maxLines: 3,
              ),
            ),
          )
          .toList(),
    );
  }

  static pw.Widget _boxRecomendacao(String doenca) {
    const recs = {
      'FERRUGEM': (
        'Ferrugem-da-Soja (Phakopsora pachyrhizi)',
        'Aplicar fungicida triazol + estrobilurina em mistura. Monitorar a evolução e reavaliar em 10–14 dias. Em casos severos, considerar segunda aplicação. Registrar data, produto e dosagem utilizados.',
      ),
      'OÍDIO': (
        'Oídio (Erysiphe diffusa)',
        'Aplicar fungicida à base de enxofre ou carboxamidas. Evitar excesso de nitrogênio. Monitorar umidade relativa — condições secas favorecem o oídio. Reavaliar em 7–10 dias.',
      ),
      'OIDIO': (
        'Oídio (Erysiphe diffusa)',
        'Aplicar fungicida à base de enxofre ou carboxamidas. Evitar excesso de nitrogênio. Monitorar umidade relativa — condições secas favorecem o oídio. Reavaliar em 7–10 dias.',
      ),
      'MANCHA ALVO': (
        'Mancha-Alvo (Corynespora cassiicola)',
        'Utilizar fungicida sistêmico preventivo ou curativo (triazóis/estrobilurinas). Atentar para resistência — variar grupos químicos a cada safra. Evitar estresse hídrico. Monitorar temperatura.',
      ),
    };

    final rec = recs[doenca.toUpperCase()];
    if (rec == null) return pw.SizedBox();

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
              left: pw.BorderSide(color: _verde, width: 3)),
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              rec.$1,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 11,
                color: _verdeEscuro,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              rec.$2,
              style: pw.TextStyle(fontSize: 10, color: _cinza),
            ),
          ],
        ),
      ),
    );
  }
}
