import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../controllers/selecao_talhao_controller.dart';
import 'home_screen.dart';
import '/../infra/repositories/sync_repository.dart';
import '/../infra/services/connectivity_service.dart';

class SelecaoTalhaoScreen extends StatefulWidget {
  const SelecaoTalhaoScreen({super.key});

  @override
  State<SelecaoTalhaoScreen> createState() => _SelecaoTalhaoScreenState();
}

class _SelecaoTalhaoScreenState extends State<SelecaoTalhaoScreen> {
  final SelecaoTalhaoController _controller = SelecaoTalhaoController();
  final SyncRepository _syncRepo = SyncRepository();
  final ConnectivityService _connectivity = ConnectivityService();
  bool _isSyncing = false;

  Future<void> _handleManualSync() async {
    setState(() => _isSyncing = true);

    final isStable = await _connectivity.triplePingCheck();

    if (isStable) {
      try {
        await _syncRepo.sincronizarLeituras();
        _mostrarSnack('Dados sincronizados com a nuvem!', AppColors.syncSuccess);
      } catch (e) {
        _mostrarSnack('Erro na sincronização: $e', AppColors.syncError);
      }
    } else {
      _mostrarSnack(
          'Conexão instável ou inexistente. Tente mais tarde.',
          AppColors.syncPending);
    }

    if (mounted) setState(() => _isSyncing = false);
  }

  void _mostrarSnack(String mensagem, Color cor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: cor),
    );
  }

  Future<void> _mostrarDialogoNovoTalhao() async {
    final textController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cadastrar novo talhão'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Ex: Lote Sul, Gleba 03...',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nome = textController.text.trim();
                if (nome.isNotEmpty) {
                  await _controller.salvarTalhao(nome);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar área'),
        actions: [
          _isSyncing
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.cloud_upload_outlined),
                  onPressed: _handleManualSync,
                  tooltip: 'Sincronizar com a nuvem',
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoNovoTalhao,
        icon: const Icon(Icons.add),
        label: const Text('Novo talhão'),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.talhoes.isEmpty) {
            return EmptyState(
              icon: Icons.agriculture_outlined,
              title: 'Nenhum talhão cadastrado',
              message: 'Crie a primeira área para iniciar o monitoramento.',
              action: AppButton(
                label: 'Cadastrar talhão',
                icon: Icons.add,
                expand: false,
                onPressed: _mostrarDialogoNovoTalhao,
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Onde você vai realizar o monitoramento?',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: ListView.separated(
                    itemCount: _controller.talhoes.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final talhao = _controller.talhoes[index].nome;
                      final isSelected =
                          _controller.talhaoSelecionado == talhao;
                      return _TalhaoTile(
                        nome: talhao,
                        selecionado: isSelected,
                        onTap: () => _controller.selecionarTalhao(talhao),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Iniciar análises',
                  icon: Icons.arrow_forward,
                  onPressed: _controller.talhaoSelecionado == null
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomeScreen(
                                  talhaoAtual: _controller.talhaoSelecionado!),
                            ),
                          ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Cartão de um talhão na lista de seleção.
class _TalhaoTile extends StatelessWidget {
  final String nome;
  final bool selecionado;
  final VoidCallback onTap;

  const _TalhaoTile({
    required this.nome,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selecionado ? AppColors.primaryContainer : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: selecionado ? AppColors.primary : AppColors.outlineVariant,
          width: selecionado ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
        leading: Icon(
          Icons.eco,
          color: selecionado ? AppColors.primary : AppColors.textTertiary,
        ),
        title: Text(
          nome,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight:
                    selecionado ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
        trailing: selecionado
            ? const Icon(Icons.check_circle, color: AppColors.primary)
            : null,
        onTap: onTap,
      ),
    );
  }
}
