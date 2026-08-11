import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/widgets/empty_state.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('EmptyState', () {
    testWidgets('renderiza title e icon', (tester) async {
      await tester.pumpWidget(_wrap(
        const EmptyState(
          icon: Icons.search_off,
          title: 'Nenhum item',
        ),
      ));
      expect(find.text('Nenhum item'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets('renderiza message quando fornecida', (tester) async {
      await tester.pumpWidget(_wrap(
        const EmptyState(
          icon: Icons.inbox,
          title: 'Vazio',
          message: 'Adicione itens para começar.',
        ),
      ));
      expect(find.text('Adicione itens para começar.'), findsOneWidget);
    });

    testWidgets('não renderiza message quando null', (tester) async {
      await tester.pumpWidget(_wrap(
        const EmptyState(
          icon: Icons.inbox,
          title: 'Vazio',
        ),
      ));
      // Nenhum segundo Text além do title
      expect(find.text('Vazio'), findsOneWidget);
      expect(find.textContaining('Adicione'), findsNothing);
    });

    testWidgets('renderiza action quando fornecida', (tester) async {
      await tester.pumpWidget(_wrap(
        EmptyState(
          icon: Icons.add,
          title: 'Sem dados',
          action: ElevatedButton(
            onPressed: () {},
            child: const Text('Criar'),
          ),
        ),
      ));
      expect(find.text('Criar'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('não renderiza action quando null', (tester) async {
      await tester.pumpWidget(_wrap(
        const EmptyState(
          icon: Icons.add,
          title: 'Sem dados',
        ),
      ));
      expect(find.byType(ElevatedButton), findsNothing);
    });
  });
}
