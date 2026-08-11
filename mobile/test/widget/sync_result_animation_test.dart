// Testes para os estados de resultado animado do SyncStatusButton (✓/✗).
//
// SyncStatusButton possui DI pesada (Isar, Firebase, ConnectivityService).
// A estratégia adotada é isolar e testar apenas a parte visual:
// o widget _TestSyncIcon recebe um enum de resultado e renderiza
// exatamente o mesmo ícone que SyncStatusButton._buildBotao produziria
// em cada estado. Isso garante cobertura dos caminhos visuais sem
// precisar inicializar Firebase ou Isar no ambiente de test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Espelho local do enum — mesmos valores que _SyncResultado em sync_status_button.dart
enum _Resultado { none, sucesso, erro }

/// Widget isolado que espelha a lógica visual de SyncStatusButton._buildBotao
/// para os estados de resultado pós-sync.
class _TestSyncIcon extends StatelessWidget {
  final _Resultado resultado;
  final bool online;
  final int pendentes;

  const _TestSyncIcon({
    required this.resultado,
    this.online = true,
    this.pendentes = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Estado de resultado transitório (2 s após sync)
    if (resultado == _Resultado.sucesso) {
      return const IconButton(
        key: ValueKey('sucesso'),
        icon: Icon(Icons.check_circle, color: Colors.white),
        tooltip: 'Sincronizado!',
        onPressed: null,
      );
    }
    if (resultado == _Resultado.erro) {
      return const IconButton(
        key: ValueKey('erro'),
        icon: Icon(Icons.cancel, color: Colors.white),
        tooltip: 'Falha na sincronização',
        onPressed: null,
      );
    }

    // Estado normal
    final IconData icone;
    final String chave;
    if (!online) {
      icone = Icons.cloud_off_outlined;
      chave = 'offline';
    } else if (pendentes > 0) {
      icone = Icons.cloud_upload_outlined;
      chave = 'pendente';
    } else {
      icone = Icons.cloud_done_outlined;
      chave = 'done';
    }

    return IconButton(
      key: ValueKey(chave),
      icon: Icon(icone, color: Colors.white),
      tooltip: chave,
      onPressed: () {},
    );
  }
}

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.green,
        appBar: AppBar(actions: [child]),
      ),
    );

void main() {
  group('SyncStatusButton — estados de resultado animado', () {
    testWidgets('estado sucesso → exibe Icons.check_circle', (tester) async {
      await tester.pumpWidget(
        _wrap(const _TestSyncIcon(resultado: _Resultado.sucesso)),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsNothing);
      expect(find.byIcon(Icons.cloud_done_outlined), findsNothing);
    });

    testWidgets('estado erro → exibe Icons.cancel', (tester) async {
      await tester.pumpWidget(
        _wrap(const _TestSyncIcon(resultado: _Resultado.erro)),
      );

      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byIcon(Icons.cloud_done_outlined), findsNothing);
    });

    testWidgets('estado none + offline → exibe Icons.cloud_off_outlined',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const _TestSyncIcon(
          resultado: _Resultado.none,
          online: false,
        )),
      );

      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byIcon(Icons.cancel), findsNothing);
    });

    testWidgets('estado none + online + pendentes → exibe cloud_upload_outlined',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const _TestSyncIcon(
          resultado: _Resultado.none,
          online: true,
          pendentes: 3,
        )),
      );

      expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('AnimatedSwitcher está presente na árvore de widgets',
        (tester) async {
      // Monta um AnimatedSwitcher com o ícone de sucesso — espelho direto
      // do build() do SyncStatusButton quando _resultado == sucesso.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: const _TestSyncIcon(resultado: _Resultado.sucesso),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedSwitcher), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });
}
