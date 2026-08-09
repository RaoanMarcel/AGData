import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../auth/presentation/controller/session_controller.dart';
import '../../../diagnostico/data/datasources/database_service.dart';
import '../../../diagnostico/data/models/leitura_model.dart';
import '../../../diagnostico/data/models/talhao_model.dart';
import '../../services/map_capture_service.dart';
import '../../services/relatorio_service.dart';
import '../../widgets/mapa_mini_widget.dart';

class RelatorioPage extends StatefulWidget {
  const RelatorioPage({super.key});

  @override
  State<RelatorioPage> createState() => _RelatorioPageState();
}

class _RelatorioPageState extends State<RelatorioPage> {
  final _db = DatabaseService();
  final _mapKey = GlobalKey();

  List<TalhaoModel> _talhoes = [];
  List<LeituraModel> _todasLeituras = [];
  final Set<String> _talhoesSelected = {};
  DateTimeRange _periodo = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  bool _loading = true;
  bool _gerando = false;
  String _empresaNome = '';

  List<LeituraModel> get _leiturasFiltered {
    return _todasLeituras.where((l) {
      final noTalhao =
          _talhoesSelected.isEmpty || _talhoesSelected.contains(l.talhao);
      final noRange = !l.dataHora.isBefore(_periodo.start) &&
          !l.dataHora.isAfter(_periodo.end.add(const Duration(days: 1)));
      return noTalhao && noRange;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final session = sl<SessionController>();
    _talhoes = await _db.buscarTodosTalhoes();
    _todasLeituras = await _db.buscarTodasLeituras();

    final companyId = session.usuario?.companyId ?? '';
    if (companyId.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId)
            .get();
        _empresaNome =
            (doc.data()?['name'] as String?) ?? session.usuario?.name ?? '';
      } catch (_) {
        _empresaNome = session.usuario?.name ?? '';
      }
    } else {
      _empresaNome = session.usuario?.name ?? '';
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _gerarPdf() async {
    final leituras = _leiturasFiltered;
    if (leituras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma leitura no período selecionado.')),
      );
      return;
    }

    setState(() => _gerando = true);

    try {
      final mapaBytes = await MapCaptureService.capture(_mapKey);

      final session = sl<SessionController>();
      final tecnico = session.usuario?.name ?? 'Técnico';

      final pdfBytes = await RelatorioService.gerarPdf(
        leituras: leituras,
        empresaNome: _empresaNome,
        tecnicoNome: tecnico,
        periodoInicio: _periodo.start,
        periodoFim: _periodo.end,
        mapaImageBytes: mapaBytes,
        talhoesSelecionados: _talhoesSelected.isEmpty
            ? _talhoes.map((t) => t.nome).toList()
            : _talhoesSelected.toList(),
      );

      if (!mounted) return;
      final extDir = await getExternalStorageDirectory();
      final dir = extDir ?? await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'relatorio_${_empresaNome.replaceAll(' ', '_')}_$ts.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF salvo em: ${file.path}'),
          duration: const Duration(seconds: 6),
        ),
      );
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Relatório Fitossanitário — $_empresaNome',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar relatório: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }

  Future<void> _selecionarPeriodo() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _periodo,
      locale: const Locale('pt', 'BR'),
      helpText: 'Selecionar período',
      cancelText: 'CANCELAR',
      confirmText: 'CONFIRMAR',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primary,
              ),
        ),
        child: child!,
      ),
    );
    if (range != null) setState(() => _periodo = range);
  }

  String _fmtDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/${m.padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relatório Agronômico')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    children: [
                      _SecaoCard(
                        titulo: 'Período',
                        child: InkWell(
                          onTap: _selecionarPeriodo,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.outline),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.date_range_outlined,
                                    color: AppColors.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${_fmtDate(_periodo.start)}  →  ${_fmtDate(_periodo.end)}',
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    color: AppColors.textTertiary),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _SecaoCard(
                        titulo:
                            'Talhões (${_talhoesSelected.isEmpty ? 'todos' : _talhoesSelected.length} selecionado(s))',
                        child: _talhoes.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('Nenhum talhão cadastrado.'),
                              )
                            : Column(
                                children: _talhoes
                                    .map((t) => t.nome)
                                    .toSet()
                                    .map((nome) {
                                  final sel =
                                      _talhoesSelected.contains(nome);
                                  return CheckboxListTile(
                                    dense: true,
                                    title: Text(nome),
                                    value: sel,
                                    activeColor: AppColors.primary,
                                    onChanged: (v) {
                                      setState(() {
                                        if (v == true) {
                                          _talhoesSelected.add(nome);
                                        } else {
                                          _talhoesSelected.remove(nome);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _SecaoCard(
                        titulo: 'Prévia do Mapa',
                        child: _leiturasFiltered.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: Text(
                                    'Sem leituras no período.',
                                    style:
                                        TextStyle(color: AppColors.textTertiary),
                                  ),
                                ),
                              )
                            : MapaMiniWidget(
                                leituras: _leiturasFiltered,
                                repaintKey: _mapKey,
                              ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _ResumoCard(leituras: _leiturasFiltered),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
                _BotaoGerar(gerando: _gerando, onPressed: _gerarPdf),
              ],
            ),
    );
  }
}

// ── Widgets de suporte ────────────────────────────────────────────────────────

class _SecaoCard extends StatelessWidget {
  final String titulo;
  final Widget child;
  const _SecaoCard({required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Card(child: child),
      ],
    );
  }
}

class _ResumoCard extends StatelessWidget {
  final List<LeituraModel> leituras;
  const _ResumoCard({required this.leituras});

  @override
  Widget build(BuildContext context) {
    if (leituras.isEmpty) return const SizedBox.shrink();
    final focos = leituras
        .where((l) =>
            l.resultadoIA != 'SAUDÁVEL' &&
            l.resultadoIA != 'SAUDAVEL' &&
            l.confianca > 0.7)
        .length;
    final talhoes = leituras.map((l) => l.talhao).toSet().length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumo do Relatório',
                style: Theme.of(context).textTheme.titleSmall),
            const Divider(height: 16),
            _linha(context, Icons.analytics_outlined,
                '${leituras.length} análise(s) no período'),
            _linha(context, Icons.landscape_outlined, '$talhoes talhão(ões)'),
            _linha(
                context,
                Icons.warning_amber_outlined,
                '$focos foco(s) com confiança > 70%',
                focos > 0 ? AppColors.ferrugem : null),
          ],
        ),
      ),
    );
  }

  Widget _linha(BuildContext ctx, IconData icon, String text, [Color? cor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cor ?? AppColors.primary),
          const SizedBox(width: 10),
          Text(text,
              style: Theme.of(ctx)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cor)),
        ],
      ),
    );
  }
}

class _BotaoGerar extends StatelessWidget {
  final bool gerando;
  final VoidCallback onPressed;
  const _BotaoGerar({required this.gerando, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.lg),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: gerando ? null : onPressed,
            icon: gerando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            label: Text(gerando ? 'Gerando PDF...' : 'Gerar e Compartilhar PDF'),
          ),
        ),
      ),
    );
  }
}
