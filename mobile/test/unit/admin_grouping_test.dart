import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/models/auth_model.dart';

/// Funções puras que espelham a lógica de agrupamento do AdminPage.

List<UserModel> filtrarPorRole(List<UserModel> lista, UserRole role) =>
    lista.where((u) => u.role == role).toList();

List<UserModel> filtrarPorBusca(List<UserModel> lista, String busca) =>
    busca.isEmpty
        ? lista
        : lista
            .where((u) =>
                u.name.toLowerCase().contains(busca.toLowerCase()) ||
                u.email.toLowerCase().contains(busca.toLowerCase()))
            .toList();

// Helpers para criar usuários de teste rapidamente.
UserModel _admin(String name, String email) => UserModel(
      uid: name,
      email: email,
      companyId: 'emp1',
      name: name,
      role: UserRole.admin,
    );

UserModel _operador(String name, String email) => UserModel(
      uid: name,
      email: email,
      companyId: 'emp1',
      name: name,
      role: UserRole.operador,
    );

void main() {
  final lista = [
    _admin('João Admin', 'joao@empresa.com'),
    _admin('Maria Admin', 'maria@empresa.com'),
    _operador('Pedro Operador', 'pedro@empresa.com'),
    _operador('Ana Operadora', 'ana@empresa.com'),
    _operador('Carlos Campo', 'carlos@empresa.com'),
  ];

  group('filtrarPorRole', () {
    test('lista mista → admins separados corretamente', () {
      final admins = filtrarPorRole(lista, UserRole.admin);
      expect(admins.length, 2);
      expect(admins.every((u) => u.role == UserRole.admin), isTrue);
    });

    test('lista mista → operadores separados corretamente', () {
      final operadores = filtrarPorRole(lista, UserRole.operador);
      expect(operadores.length, 3);
      expect(operadores.every((u) => u.role == UserRole.operador), isTrue);
    });

    test('lista só de operadores → seção admins vazia', () {
      final soOperadores = [
        _operador('X', 'x@e.com'),
        _operador('Y', 'y@e.com'),
      ];
      final admins = filtrarPorRole(soOperadores, UserRole.admin);
      expect(admins, isEmpty);
    });

    test('lista vazia → ambas as seções vazias', () {
      expect(filtrarPorRole([], UserRole.admin), isEmpty);
      expect(filtrarPorRole([], UserRole.operador), isEmpty);
    });
  });

  group('filtrarPorBusca', () {
    test('busca por nome parcial (case-insensitive) retorna correspondências', () {
      final resultado = filtrarPorBusca(lista, 'joao');
      expect(resultado.length, 1);
      expect(resultado.first.name, 'João Admin');
    });

    test('busca por email retorna correspondências', () {
      final resultado = filtrarPorBusca(lista, 'pedro@');
      expect(resultado.length, 1);
      expect(resultado.first.name, 'Pedro Operador');
    });

    test('busca vazia retorna toda a lista', () {
      final resultado = filtrarPorBusca(lista, '');
      expect(resultado.length, lista.length);
    });

    test('busca sem correspondência retorna lista vazia', () {
      final resultado = filtrarPorBusca(lista, 'zzzinexistente');
      expect(resultado, isEmpty);
    });

    test('filtro de busca combinado com filtro de role', () {
      final admins = filtrarPorRole(lista, UserRole.admin);
      final resultado = filtrarPorBusca(admins, 'maria');
      expect(resultado.length, 1);
      expect(resultado.first.email, 'maria@empresa.com');
    });

    test('busca case-insensitive funciona com maiúsculas', () {
      final resultado = filtrarPorBusca(lista, 'CARLOS');
      expect(resultado.length, 1);
      expect(resultado.first.name, 'Carlos Campo');
    });
  });
}
