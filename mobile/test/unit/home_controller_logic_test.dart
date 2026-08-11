import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/diagnostico/presentation/controllers/home_controller.dart';

/// Funções puras que espelham decisões do HomeController
bool deveHabilitarSalvar(DiagnosticoStatus status, bool salvando) {
  return status == DiagnosticoStatus.revisao && !salvando;
}

bool deveExibirBotoesCaptura(DiagnosticoStatus status) {
  return status == DiagnosticoStatus.inicial || status == DiagnosticoStatus.erro;
}

void main() {
  group('DiagnosticoStatus enum', () {
    test('todos os valores estão presentes', () {
      expect(DiagnosticoStatus.values.length, 4);
      expect(DiagnosticoStatus.values, contains(DiagnosticoStatus.inicial));
      expect(DiagnosticoStatus.values, contains(DiagnosticoStatus.processando));
      expect(DiagnosticoStatus.values, contains(DiagnosticoStatus.revisao));
      expect(DiagnosticoStatus.values, contains(DiagnosticoStatus.erro));
    });
  });

  group('deveHabilitarSalvar', () {
    test('habilitado apenas em revisão sem salvamento em curso', () {
      expect(deveHabilitarSalvar(DiagnosticoStatus.revisao, false), isTrue);
    });
    test('desabilitado durante salvamento', () {
      expect(deveHabilitarSalvar(DiagnosticoStatus.revisao, true), isFalse);
    });
    test('desabilitado em estado inicial', () {
      expect(deveHabilitarSalvar(DiagnosticoStatus.inicial, false), isFalse);
    });
    test('desabilitado em processamento', () {
      expect(deveHabilitarSalvar(DiagnosticoStatus.processando, false), isFalse);
    });
    test('desabilitado em erro', () {
      expect(deveHabilitarSalvar(DiagnosticoStatus.erro, false), isFalse);
    });
  });

  group('deveExibirBotoesCaptura', () {
    test('exibe botões no estado inicial', () {
      expect(deveExibirBotoesCaptura(DiagnosticoStatus.inicial), isTrue);
    });
    test('exibe botões no estado de erro (retry)', () {
      expect(deveExibirBotoesCaptura(DiagnosticoStatus.erro), isTrue);
    });
    test('oculta botões durante processamento', () {
      expect(deveExibirBotoesCaptura(DiagnosticoStatus.processando), isFalse);
    });
    test('oculta botões em revisão', () {
      expect(deveExibirBotoesCaptura(DiagnosticoStatus.revisao), isFalse);
    });
  });
}
