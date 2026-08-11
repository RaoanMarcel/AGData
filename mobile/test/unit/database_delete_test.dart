import 'package:flutter_test/flutter_test.dart';

List<int> idsAExcluir(List<int> selecionados) => List<int>.from(selecionados);

bool idFoiExcluido(int id, List<int> idsExcluidos) =>
    idsExcluidos.contains(id);

void main() {
  group('lógica de exclusão de leituras', () {
    test('idsAExcluir retorna cópia dos selecionados', () {
      final sel = [1, 2, 3];
      final ids = idsAExcluir(sel);
      expect(ids, equals([1, 2, 3]));
      sel.add(4);
      expect(ids.length, 3);
    });

    test('idFoiExcluido retorna true para ids excluídos', () {
      expect(idFoiExcluido(2, [1, 2, 3]), isTrue);
    });

    test('idFoiExcluido retorna false para ids não excluídos', () {
      expect(idFoiExcluido(5, [1, 2, 3]), isFalse);
    });

    test('exclusão de lista vazia', () {
      final ids = idsAExcluir([]);
      expect(ids, isEmpty);
    });

    test('lista de exclusão preserva todos os ids selecionados', () {
      final sel = [10, 20, 30, 40];
      final ids = idsAExcluir(sel);
      expect(ids.length, 4);
      expect(ids, containsAll([10, 20, 30, 40]));
    });
  });
}
