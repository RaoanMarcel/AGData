import 'package:flutter_test/flutter_test.dart';

final _emailRegex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');

String? validarEmail(String? v) {
  if (v == null || v.isEmpty) return 'E-mail obrigatório';
  if (!_emailRegex.hasMatch(v.trim())) return 'E-mail inválido';
  return null;
}

String? validarSenha(String? v, {int minChars = 8}) {
  if (v == null || v.isEmpty) return 'Senha obrigatória';
  if (v.trim().length < minChars) return 'Mínimo $minChars caracteres';
  return null;
}

void main() {
  group('validarEmail', () {
    test('formato padrão é válido', () => expect(validarEmail('usuario@empresa.com'), isNull));
    test('subdomínio é válido', () => expect(validarEmail('user@mail.empresa.com.br'), isNull));
    test('TLD de 1 char é inválido', () => expect(validarEmail('a@b.c'), isNotNull));
    test('sem @ é inválido', () => expect(validarEmail('usuarioempresa.com'), isNotNull));
    test('sem domínio é inválido', () => expect(validarEmail('usuario@'), isNotNull));
    test('vazio retorna obrigatório', () => expect(validarEmail(''), 'E-mail obrigatório'));
    test('null retorna obrigatório', () => expect(validarEmail(null), 'E-mail obrigatório'));
    test('com ponto no local-part é válido', () => expect(validarEmail('nome.sobrenome@empresa.com'), isNull));
  });

  group('validarSenha', () {
    test('null retorna erro', () => expect(validarSenha(null), isNotNull));
    test('vazia retorna erro', () => expect(validarSenha(''), isNotNull));
    test('menos de 8 chars retorna erro', () => expect(validarSenha('1234567'), isNotNull));
    test('exatamente 8 chars é válido', () => expect(validarSenha('12345678'), isNull));
    test('mais de 8 chars é válido', () => expect(validarSenha('senha_longa_123'), isNull));
    test('limite customizável', () => expect(validarSenha('123456', minChars: 6), isNull));
  });
}
