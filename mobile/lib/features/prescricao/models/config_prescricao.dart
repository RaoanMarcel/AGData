class ConfigPrescricao {
  final String nomeProduto;

  /// Taxas de aplicação em L/ha para cada nível de severidade.
  final double taxaSem;
  final double taxaPreventiva;
  final double taxaCurativa;

  /// Tamanho da célula da grade em metros (ex.: 10, 20, 50).
  final double tamanhoCelulaMetros;

  const ConfigPrescricao({
    required this.nomeProduto,
    required this.taxaSem,
    required this.taxaPreventiva,
    required this.taxaCurativa,
    required this.tamanhoCelulaMetros,
  });

  ConfigPrescricao copyWith({
    String? nomeProduto,
    double? taxaSem,
    double? taxaPreventiva,
    double? taxaCurativa,
    double? tamanhoCelulaMetros,
  }) {
    return ConfigPrescricao(
      nomeProduto: nomeProduto ?? this.nomeProduto,
      taxaSem: taxaSem ?? this.taxaSem,
      taxaPreventiva: taxaPreventiva ?? this.taxaPreventiva,
      taxaCurativa: taxaCurativa ?? this.taxaCurativa,
      tamanhoCelulaMetros: tamanhoCelulaMetros ?? this.tamanhoCelulaMetros,
    );
  }
}
