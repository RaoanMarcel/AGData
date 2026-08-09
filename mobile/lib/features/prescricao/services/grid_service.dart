import 'dart:math' as math;
import '../../diagnostico/data/models/leitura_model.dart';
import '../models/config_prescricao.dart';
import '../models/zona_prescricao.dart';

class GridService {
  static const double _mPorGrauLat = 111000.0;

  /// Gera a grade de prescrição a partir de [leituras] com as configurações dadas.
  ///
  /// Retorna null se não houver leituras com GPS válido.
  static GradePrescricao? gerarGrade(
    List<LeituraModel> leituras,
    ConfigPrescricao config,
  ) {
    final validas = leituras.where((l) => l.latitude != 0.0).toList();
    if (validas.isEmpty) return null;

    // Bounding box das leituras
    double minLat = validas.first.latitude;
    double maxLat = validas.first.latitude;
    double minLng = validas.first.longitude;
    double maxLng = validas.first.longitude;

    for (final l in validas) {
      if (l.latitude < minLat) minLat = l.latitude;
      if (l.latitude > maxLat) maxLat = l.latitude;
      if (l.longitude < minLng) minLng = l.longitude;
      if (l.longitude > maxLng) maxLng = l.longitude;
    }

    // Tamanho da célula em graus
    final latCenter = (minLat + maxLat) / 2;
    final mPorGrauLng =
        _mPorGrauLat * math.cos(latCenter * math.pi / 180);

    final cellH = config.tamanhoCelulaMetros / _mPorGrauLat;
    final cellW = config.tamanhoCelulaMetros / mPorGrauLng;

    // Buffer de meia célula em cada lado para não cortar pontos nas bordas
    final bufH = cellH * 0.5;
    final bufW = cellW * 0.5;

    final gridMinLat = minLat - bufH;
    final gridMinLng = minLng - bufW;
    final gridMaxLat = maxLat + bufH;
    final gridMaxLng = maxLng + bufW;

    final nRows =
        ((gridMaxLat - gridMinLat) / cellH).ceil().clamp(1, 500);
    final nCols =
        ((gridMaxLng - gridMinLng) / cellW).ceil().clamp(1, 500);

    // Constrói a grade (row 0 = mais ao sul)
    final celulas = List.generate(nRows, (row) {
      return List.generate(nCols, (col) {
        final cellLatMin = gridMinLat + row * cellH;
        final cellLatMax = cellLatMin + cellH;
        final cellLngMin = gridMinLng + col * cellW;
        final cellLngMax = cellLngMin + cellW;

        // Leituras dentro desta célula
        final dentroCell = validas.where((l) =>
            l.latitude >= cellLatMin &&
            l.latitude < cellLatMax &&
            l.longitude >= cellLngMin &&
            l.longitude < cellLngMax);

        // Leituras com doença detectada
        final comDoenca = dentroCell
            .where((l) =>
                l.resultadoIA != 'SAUDÁVEL' &&
                l.resultadoIA != 'SAUDAVEL' &&
                l.resultadoIA != 'INCONCLUSIVO')
            .toList();

        int nivel;
        if (comDoenca.isEmpty) {
          nivel = 0;
        } else {
          final avgConf =
              comDoenca.map((l) => l.confianca).reduce((a, b) => a + b) /
                  comDoenca.length;
          nivel = (comDoenca.length >= 3 || avgConf > 0.70) ? 2 : 1;
        }

        final taxa = _taxaPorNivel(nivel, config);

        return ZonaPrescricao(
          row: row,
          col: col,
          latMin: cellLatMin,
          latMax: cellLatMax,
          lngMin: cellLngMin,
          lngMax: cellLngMax,
          taxa: taxa,
          nivel: nivel,
        );
      });
    });

    return GradePrescricao(
      celulas: celulas,
      minLat: gridMinLat,
      maxLat: gridMinLat + nRows * cellH,
      minLng: gridMinLng,
      maxLng: gridMinLng + nCols * cellW,
      cellHeightDeg: cellH,
      cellWidthDeg: cellW,
      nRows: nRows,
      nCols: nCols,
    );
  }

  static double _taxaPorNivel(int nivel, ConfigPrescricao config) {
    switch (nivel) {
      case 1:
        return config.taxaPreventiva;
      case 2:
        return config.taxaCurativa;
      default:
        return config.taxaSem;
    }
  }
}
