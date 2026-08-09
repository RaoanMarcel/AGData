class ZonaPrescricao {
  final int row;
  final int col;
  final double latMin;
  final double latMax;
  final double lngMin;
  final double lngMax;

  /// Taxa de aplicação calculada, em L/ha.
  final double taxa;

  /// 0 = sem aplicação, 1 = preventivo, 2 = curativo.
  final int nivel;

  const ZonaPrescricao({
    required this.row,
    required this.col,
    required this.latMin,
    required this.latMax,
    required this.lngMin,
    required this.lngMax,
    required this.taxa,
    required this.nivel,
  });
}

class GradePrescricao {
  /// [row][col] onde row 0 é a mais ao sul (latitude mínima).
  final List<List<ZonaPrescricao>> celulas;
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;
  final double cellHeightDeg;
  final double cellWidthDeg;
  final int nRows;
  final int nCols;

  const GradePrescricao({
    required this.celulas,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
    required this.cellHeightDeg,
    required this.cellWidthDeg,
    required this.nRows,
    required this.nCols,
  });

  List<ZonaPrescricao> get todasZonas =>
      celulas.expand((row) => row).toList();
}
