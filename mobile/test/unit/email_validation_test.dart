import 'package:flutter_test/flutter_test.dart';

void main() {
  // Mesma regex implementada nas telas de auth (TASK-003)
  final emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');

  group('Validação de e-mail', () {
    test('e-mail simples válido', () {
      expect(emailRegex.hasMatch('usuario@empresa.com'), isTrue);
    });

    test('e-mail com subdomínio válido', () {
      expect(emailRegex.hasMatch('usuario@empresa.com.br'), isTrue);
    });

    test('e-mail com pontos no local-part válido', () {
      expect(emailRegex.hasMatch('nome.sobrenome@empresa.org'), isTrue);
    });

    test('e-mail com + no local-part válido', () {
      expect(emailRegex.hasMatch('usuario+tag@gmail.com'), isTrue);
    });

    test('TLD com 1 char é inválido (a@b.c)', () {
      expect(emailRegex.hasMatch('a@b.c'), isFalse);
    });

    test('sem arroba é inválido', () {
      expect(emailRegex.hasMatch('semAroba'), isFalse);
    });

    test('arroba no início é inválido', () {
      expect(emailRegex.hasMatch('@dominio.com'), isFalse);
    });

    test('domínio com ponto inicial é inválido', () {
      expect(emailRegex.hasMatch('usuario@.com'), isFalse);
    });

    test('sem TLD é inválido', () {
      expect(emailRegex.hasMatch('usuario@empresa'), isFalse);
    });

    test('string vazia é inválida', () {
      expect(emailRegex.hasMatch(''), isFalse);
    });
  });
}
