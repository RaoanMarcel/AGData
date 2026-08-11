import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/diagnostico_visuals.dart';
import 'package:mobile/core/theme/app_colors.dart';

void main() {
  group('DiagnosticoVisual.fromResultado', () {
    test('"SAUDÁVEL" retorna cor saudavel', () {
      final v = DiagnosticoVisual.fromResultado('SAUDÁVEL');
      expect(v.color, AppColors.saudavel);
      expect(v.container, AppColors.saudavelContainer);
    });

    test('"SAUDAVEL" (sem acento) retorna cor saudavel', () {
      final v = DiagnosticoVisual.fromResultado('SAUDAVEL');
      expect(v.color, AppColors.saudavel);
    });

    test('"FERRUGEM" retorna cor ferrugem', () {
      final v = DiagnosticoVisual.fromResultado('FERRUGEM');
      expect(v.color, AppColors.ferrugem);
      expect(v.container, AppColors.ferrugemContainer);
    });

    test('"ferrugem" (minúsculo) retorna cor ferrugem', () {
      final v = DiagnosticoVisual.fromResultado('ferrugem');
      expect(v.color, AppColors.ferrugem);
    });

    test('"INCONCLUSIVO" retorna cor inconclusivo', () {
      final v = DiagnosticoVisual.fromResultado('INCONCLUSIVO');
      expect(v.color, AppColors.inconclusivo);
      expect(v.container, AppColors.inconclusivoContainer);
    });

    test('"OÍDIO" retorna cor oidio', () {
      final v = DiagnosticoVisual.fromResultado('OÍDIO');
      expect(v.color, AppColors.oidio);
    });

    test('"MANCHA ALVO" retorna cor manchaAlvo', () {
      final v = DiagnosticoVisual.fromResultado('MANCHA ALVO');
      expect(v.color, AppColors.manchaAlvo);
    });

    test('string inválida cai no fallback sem crash', () {
      final v = DiagnosticoVisual.fromResultado('STRING_DESCONHECIDA_XYZ');
      expect(v, isNotNull);
      expect(v.color, AppColors.inconclusivo);
      expect(v.label, 'STRING_DESCONHECIDA_XYZ');
    });

    test('string vazia cai no fallback sem crash', () {
      final v = DiagnosticoVisual.fromResultado('');
      expect(v, isNotNull);
    });
  });

  group('DiagnosticoVisual.isConhecido', () {
    test('reconhece diagnósticos válidos', () {
      expect(DiagnosticoVisual.isConhecido('SAUDÁVEL'), isTrue);
      expect(DiagnosticoVisual.isConhecido('FERRUGEM'), isTrue);
      expect(DiagnosticoVisual.isConhecido('INCONCLUSIVO'), isTrue);
    });

    test('rejeita strings desconhecidas', () {
      expect(DiagnosticoVisual.isConhecido('NADA'), isFalse);
    });
  });
}
