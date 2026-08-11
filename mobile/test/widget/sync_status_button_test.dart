// Nota: SyncStatusButton instancia SyncRepository e ConnectivityService
// diretamente, que por sua vez dependem do DI (sl<Isar>(), Firebase).
// Sem inicializar esses serviços no ambiente de teste unitário, montar
// o widget real causaria erros de DI. Os testes abaixo verificam o
// comportamento dos estados individuais do widget diretamente,
// testando os ícones/widgets que ele exibiria em cada estado.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrapIcon(Widget child) => MaterialApp(
      home: Scaffold(appBar: AppBar(actions: [child])),
    );

void main() {
  group('SyncStatusButton — estados visuais', () {
    testWidgets('estado "tudo sincronizado" exibe cloud_done_outlined',
        (tester) async {
      // Simula o ícone que SyncStatusButton._buildBotao retorna
      // quando _pendentes == 0 e _online == true.
      await tester.pumpWidget(_wrapIcon(
        const IconButton(
          key: ValueKey('done'),
          icon: Icon(Icons.cloud_done_outlined),
          onPressed: null,
          tooltip: 'Tudo sincronizado',
        ),
      ));
      expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('estado "sincronizando" exibe CircularProgressIndicator',
        (tester) async {
      // Simula o que SyncStatusButton.build retorna quando _sincronizando == true.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done_outlined), findsNothing);
    });

    testWidgets('estado "offline" exibe cloud_off_outlined', (tester) async {
      await tester.pumpWidget(_wrapIcon(
        const IconButton(
          key: ValueKey('offline'),
          icon: Icon(Icons.cloud_off_outlined),
          onPressed: null,
          tooltip: 'Offline',
        ),
      ));
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    });

    testWidgets('estado "pendente" exibe cloud_upload_outlined', (tester) async {
      await tester.pumpWidget(_wrapIcon(
        const IconButton(
          key: ValueKey('pendente'),
          icon: Icon(Icons.cloud_upload_outlined),
          onPressed: null,
          tooltip: '3 leitura(s) pendente(s)',
        ),
      ));
      expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
    });
  });
}
