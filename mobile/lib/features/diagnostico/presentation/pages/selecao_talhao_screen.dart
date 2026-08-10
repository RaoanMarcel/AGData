import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/models/talhao_model.dart';
import '../controllers/selecao_talhao_controller.dart';
import '../widgets/sync_status_button.dart';
import 'home_screen.dart';

class SelecaoTalhaoScreen extends StatefulWidget {
  const SelecaoTalhaoScreen({super.key});

  @override
  State<SelecaoTalhaoScreen> createState() => _SelecaoTalhaoScreenState();
}

enum _OrdemTalhao { nome, recente, leituras }

class _SelecaoTalhaoScreenState extends State<SelecaoTalhaoScreen> {
  final SelecaoTalhaoController _controller = SelecaoTalhaoController();
  final _buscaController = TextEditingController();
  String _busca = '';
  _OrdemTalhao _ordem = _OrdemTalhao.recente;

  @override
  void dispose() {
    _controller.dispose();
    _buscaController.dispose();
    super.dispose();
  }

  List<TalhaoModel> get _talhoesFiltrados {
    var lista = _controller.talhoes.where((t) {
      return _busca.isEmpty ||
          t.nome.toLowerCase().contains(_busca.toLowerCase());
    }).toList();

    switch (_ordem) {
      case _OrdemTalhao.nome:
        lista.sort((a, b) => a.nome.compareTo(b.nome));
      case _OrdemTalhao.recente:
        lista.sort((a, b) {
          final ua = _controller.ultimaLeitura[a.nome];
          final ub = _controller.ultimaLeitura[b.nome];
          if (ua == null && ub == null) return 0;
          if (ua == null) return 1;
          if (ub == null) return -1;
          return ub.compareTo(ua);
        });
      case _OrdemTalhao.leituras:
        lista.sort((a, b) {
          final la = _controller.totalLeituras[a.nome] ?? 0;
          final lb = _controller.totalLeituras[b.nome] ?? 0;
          return lb.compareTo(la);
        });
    }
    return lista;
  }

  Future<void> _iniciarAnalise(String talhao) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen(talhaoAtual: talhao)),
    );
    await _controller.recarregar();
  }

  Future<void> _abrirFormNovoTalhao() async {
    final textController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              final podeSalvar = textController.text.trim().isNotEmpty;
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(Icons.agriculture_outlined,
                              color: AppColors.primary),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Novo talhão',
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              Text('Cadastre uma área de monitoramento',
                                  style:
                                      Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Nome do talhão',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: textController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Ex: Lote Sul, Gleba 03...',
                        prefixIcon: Icon(Icons.eco_outlined),
                      ),
                      onChanged: (_) => setSheetState(() {}),
                      onSubmitted: (_) {
                        if (podeSalvar) _salvarTalhao(textController.text);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Cancelar',
                            variant: AppButtonVariant.secondary,
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppButton(
                            label: 'Salvar',
                            icon: Icons.check,
                            onPressed: podeSalvar
                                ? () => _salvarTalhao(textController.text)
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _salvarTalhao(String nome) async {
    final limpo = nome.trim();
    if (limpo.isEmpty) return;
    await _controller.salvarTalhao(limpo);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar área'),
        actions: [
          PopupMenuButton<_OrdemTalhao>(
            icon: const Icon(Icons.sort),
            tooltip: 'Ordenar',
            initialValue: _ordem,
            onSelected: (v) => setState(() => _ordem = v),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _OrdemTalhao.recente,
                child: Text('Mais recente'),
              ),
              PopupMenuItem(
                value: _OrdemTalhao.nome,
                child: Text('Nome A–Z'),
              ),
              PopupMenuItem(
                value: _OrdemTalhao.leituras,
                child: Text('Mais leituras'),
              ),
            ],
          ),
          const SyncStatusButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormNovoTalhao,
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
                onPressed: _abrirFormNovoTalhao,
              ),
            );
          }

          final lista = _talhoesFiltrados;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: TextField(
                  controller: _buscaController,
                  decoration: InputDecoration(
                    hintText: 'Buscar talhão...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _busca.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _buscaController.clear();
                              setState(() => _busca = '');
                            },
                          )
                        : null,
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _busca = v),
                ),
              ),
              Expanded(
                child: lista.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off,
                        title: 'Nenhum resultado',
                        message: 'Tente outro nome de talhão.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 96),
                        itemCount: lista.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final talhao = lista[index];
                          return _TalhaoCard(
                            nome: talhao.nome,
                            dataCriacao: talhao.dataCriacao,
                            ultimaLeitura:
                                _controller.ultimaLeitura[talhao.nome],
                            totalLeituras:
                                _controller.totalLeituras[talhao.nome] ?? 0,
                            onTap: () => _iniciarAnalise(talhao.nome),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TalhaoCard extends StatelessWidget {
  final String nome;
  final DateTime dataCriacao;
  final DateTime? ultimaLeitura;
  final int totalLeituras;
  final VoidCallback onTap;

  const _TalhaoCard({
    required this.nome,
    required this.dataCriacao,
    required this.ultimaLeitura,
    required this.totalLeituras,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.eco, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nome, style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    _MetaLinha(
                      icon: Icons.event_outlined,
                      texto: 'Criado em ${formatarData(dataCriacao)}',
                    ),
                    const SizedBox(height: 2),
                    _MetaLinha(
                      icon: Icons.history,
                      texto: ultimaLeitura == null
                          ? 'Nenhuma leitura ainda'
                          : 'Última leitura: ${formatarDataHora(ultimaLeitura!)}',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text('$totalLeituras',
                        style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary)),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: AppColors.textTertiary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaLinha extends StatelessWidget {
  final IconData icon;
  final String texto;
  const _MetaLinha({required this.icon, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(texto,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
