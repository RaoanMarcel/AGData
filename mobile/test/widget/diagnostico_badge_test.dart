import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/widgets/diagnostico_badge.dart';
import 'package:mobile/core/theme/app_colors.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('DiagnosticoBadge', () {
    testWidgets('renderiza rótulo "Saudável" para resultado SAUDÁVEL',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const DiagnosticoBadge(resultado: 'SAUDÁVEL'),
      ));
      expect(find.text('Saudável'), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('renderiza rótulo "Ferrugem" para resultado FERRUGEM',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const DiagnosticoBadge(resultado: 'FERRUGEM'),
      ));
      expect(find.text('Ferrugem'), findsOneWidget);
    });

    testWidgets('FERRUGEM e SAUDÁVEL têm cores diferentes', (tester) async {
      await tester.pumpWidget(_wrap(
        const Column(
          children: [
            DiagnosticoBadge(resultado: 'SAUDÁVEL'),
            DiagnosticoBadge(resultado: 'FERRUGEM'),
          ],
        ),
      ));

      final containers = tester.widgetList<Container>(find.byType(Container));
      final cores = containers
          .map((c) => (c.decoration as BoxDecoration?)?.color)
          .whereType<Color>()
          .toList();

      // Deve haver pelo menos 2 cores distintas (container saudavel ≠ ferrugem)
      expect(cores.contains(AppColors.saudavelContainer), isTrue);
      expect(cores.contains(AppColors.ferrugemContainer), isTrue);
    });

    testWidgets('não crasha com string desconhecida', (tester) async {
      await tester.pumpWidget(_wrap(
        const DiagnosticoBadge(resultado: 'DOENÇA_INEXISTENTE'),
      ));
      expect(find.byType(DiagnosticoBadge), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('modo dense renderiza badge sem erro', (tester) async {
      await tester.pumpWidget(_wrap(
        const DiagnosticoBadge(resultado: 'INCONCLUSIVO', dense: true),
      ));
      expect(find.text('Inconclusivo'), findsOneWidget);
    });
  });
}
