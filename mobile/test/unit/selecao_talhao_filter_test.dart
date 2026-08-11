import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/diagnostico/data/models/talhao_model.dart';

/// Espelho da lógica de _talhoesFiltrados de _SelecaoTalhaoScreenState.
/// Função pura que recebe os dados do controller e aplica os mesmos critérios.
enum OrdemTalhao { nome, recente, leituras }

List<TalhaoModel> talhoesFiltrados({
  required List<TalhaoModel> talhoes,
  required String busca,
  required OrdemTalhao ordem,
  required Map<String, DateTime> ultimaLeitura,
  required Map<String, int> totalLeituras,
}) {
  var lista = talhoes.where((t) {
    return busca.isEmpty || t.nome.toLowerCase().contains(busca.toLowerCase());
  }).toList();

  switch (ordem) {
    case OrdemTalhao.nome:
      lista.sort((a, b) => a.nome.compareTo(b.nome));
    case OrdemTalhao.recente:
      lista.sort((a, b) {
        final ua = ultimaLeitura[a.nome];
        final ub = ultimaLeitura[b.nome];
        if (ua == null && ub == null) return 0;
        if (ua == null) return 1;
        if (ub == null) return -1;
        return ub.compareTo(ua);
      });
    case OrdemTalhao.leituras:
      lista.sort((a, b) {
        final la = totalLeituras[a.nome] ?? 0;
        final lb = totalLeituras[b.nome] ?? 0;
        return lb.compareTo(la);
      });
  }
  return lista;
}

TalhaoModel _talhao(String nome) => TalhaoModel()..nome = nome;

void main() {
  final tA = _talhao('Arroz Sul');
  final tB = _talhao('Bravo Norte');
  final tC = _talhao('Central');
  final todos = [tA, tB, tC];

  final agora = DateTime.now();
  final ontem = agora.subtract(const Duration(days: 1));
  final semana = agora.subtract(const Duration(days: 7));

  final ultimaLeitura = {
    'Arroz Sul': semana,
    'Bravo Norte': ontem,
    // 'Central' sem leitura
  };

  final totalLeituras = {
    'Arroz Sul': 5,
    'Bravo Norte': 10,
    'Central': 0,
  };

  group('Filtro por busca', () {
    test('"arr" filtra só talhões com "arr" no nome (case-insensitive)', () {
      final result = talhoesFiltrados(
        talhoes: todos,
        busca: 'arr',
        ordem: OrdemTalhao.nome,
        ultimaLeitura: ultimaLeitura,
        totalLeituras: totalLeituras,
      );
      expect(result.length, 1);
      expect(result.first.nome, 'Arroz Sul');
    });

    test('"ARR" maiúsculo também filtra corretamente', () {
      final result = talhoesFiltrados(
        talhoes: todos,
        busca: 'ARR',
        ordem: OrdemTalhao.nome,
        ultimaLeitura: ultimaLeitura,
        totalLeituras: totalLeituras,
      );
      expect(result.length, 1);
    });

    test('busca vazia retorna todos', () {
      final result = talhoesFiltrados(
        talhoes: todos,
        busca: '',
        ordem: OrdemTalhao.nome,
        ultimaLeitura: ultimaLeitura,
        totalLeituras: totalLeituras,
      );
      expect(result.length, 3);
    });

    test('busca sem resultado retorna lista vazia', () {
      final result = talhoesFiltrados(
        talhoes: todos,
        busca: 'XYZ_INEXISTENTE',
        ordem: OrdemTalhao.nome,
        ultimaLeitura: ultimaLeitura,
        totalLeituras: totalLeituras,
      );
      expect(result, isEmpty);
    });
  });

  group('Ordenação por nome', () {
    test('ordena A→Z corretamente', () {
      final result = talhoesFiltrados(
        talhoes: [tC, tA, tB], // ordem embaralhada
        busca: '',
        ordem: OrdemTalhao.nome,
        ultimaLeitura: ultimaLeitura,
        totalLeituras: totalLeituras,
      );
      expect(result[0].nome, 'Arroz Sul');
      expect(result[1].nome, 'Bravo Norte');
      expect(result[2].nome, 'Central');
    });
  });

  group('Ordenação por recente', () {
    test('talhão com ultimaLeitura mais nova aparece primeiro', () {
      final result = talhoesFiltrados(
        talhoes: todos,
        busca: '',
        ordem: OrdemTalhao.recente,
        ultimaLeitura: ultimaLeitura,
        totalLeituras: totalLeituras,
      );
      // Bravo Norte tem leitura ontem (mais recente) → primeiro
      expect(result[0].nome, 'Bravo Norte');
      expect(result[1].nome, 'Arroz Sul');
      // Central sem leitura vai pro fim
      expect(result[2].nome, 'Central');
    });

    test('talhão sem leitura vai ao fim', () {
      final result = talhoesFiltrados(
        talhoes: todos,
        busca: '',
        ordem: OrdemTalhao.recente,
        ultimaLeitura: ultimaLeitura,
        totalLeituras: totalLeituras,
      );
      expect(result.last.nome, 'Central');
    });
  });

  group('Ordenação por número de leituras', () {
    test('talhão com mais leituras aparece primeiro', () {
      final result = talhoesFiltrados(
        talhoes: todos,
        busca: '',
        ordem: OrdemTalhao.leituras,
        ultimaLeitura: ultimaLeitura,
        totalLeituras: totalLeituras,
      );
      // Bravo Norte tem 10 → primeiro; Arroz Sul 5 → segundo; Central 0 → último
      expect(result[0].nome, 'Bravo Norte');
      expect(result[1].nome, 'Arroz Sul');
      expect(result[2].nome, 'Central');
    });
  });

  group('Busca vazia + ordenação recente', () {
    test('retorna todos, ordenados por data', () {
      final result = talhoesFiltrados(
        talhoes: todos,
        busca: '',
        ordem: OrdemTalhao.recente,
        ultimaLeitura: ultimaLeitura,
        totalLeituras: totalLeituras,
      );
      expect(result.length, 3);
      expect(result[0].nome, 'Bravo Norte');
    });
  });
}
