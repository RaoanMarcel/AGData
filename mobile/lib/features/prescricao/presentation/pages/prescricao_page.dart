import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../auth/data/models/auth_model.dart';
import '../../../auth/presentation/controller/session_controller.dart';
import '../../../diagnostico/data/datasources/database_service.dart';
import '../../../diagnostico/data/models/leitura_model.dart';
import '../../../diagnostico/data/models/talhao_model.dart';
import '../../models/config_prescricao.dart';
import '../../models/zona_prescricao.dart';
import '../../services/grid_service.dart';
import '../../services/isobus_service.dart';
import '../widgets/prescricao_map_widget.dart';

class PrescricaoPage extends StatefulWidget {
  const PrescricaoPage({super.key});

  @override
  State<PrescricaoPage> createState() => _PrescricaoPageState();
}

class _PrescricaoPageState extends State<PrescricaoPage> {
  final _db = DatabaseService();

  List<TalhaoModel> _talhoes = [];
  List<LeituraModel> _todasLeituras = [];
  String? _talhaoSelected;
  DateTimeRange _periodo = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  ConfigPrescricao _config = const ConfigPrescricao(
    nomeProduto: 'Fungicida',
    taxaSem: 0.0,
    taxaPreventiva: 1.5,
    taxaCurativa: 3.0,
    tamanhoCelulaMetros: 20.0,
  );

  bool _loading = true;
  bool _exportando = false;
  GradePrescricao? _grade;
  String _empresaNome = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _talhoes = await _db.buscarTodosTalhoes();
    _todasLeituras = await _db.buscarTodasLeituras();
    final session = sl<SessionController>();
    _empresaNome = session.usuario?.name ?? 'AGData';
    if (_talhoes.isNotEmpty) {
      _talhaoSelected = _talhoes.first.nome;
      _recalcularGrade();
    }
    if (mounted) setState(() => _loading = false);
  }

  void _recalcularGrade() {
    final leituras = _leiturasFiltered;
    setState(() => _grade = GridService.gerarGrade(leituras, _config));
  }

  List<LeituraModel> get _leiturasFiltered {
    return _todasLeituras.where((l) {
      final noTalhao =
          _talhaoSelected == null || l.talhao == _talhaoSelected;
      final noRange = !l.dataHora.isBefore(_periodo.start) &&
          !l.dataHora
              .isAfter(_periodo.end.add(const Duration(days: 1)));
      return noTalhao && noRange;
    }).toList();
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
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      setState(() => _periodo = range);
      _recalcularGrade();
    }
  }

  Future<void> _exportar() async {
    if (_grade == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Sem dados para exportar no período selecionado.')),
      );
      return;
    }
    setState(() => _exportando = true);
    try {
      final zipBytes = await IsobusService.gerarZip(
        grade: _grade!,
        config: _config,
        talhaoNome: _talhaoSelected ?? 'Talhao',
        empresaNome: _empresaNome,
      );

      final dir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/prescricao_$ts.zip');
      await file.writeAsBytes(zipBytes);

      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/zip')],
        subject: 'Prescrição ISOBUS — ${_talhaoSelected ?? ''}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  String _fmtDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final session = sl<SessionController>();
    final isAdmin = session.usuario?.role == UserRole.admin ||
        session.usuario?.role == UserRole.superAdmin;

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Prescrição de Máquina')),
        body: const Center(
          child: Text('Acesso restrito a administradores.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Prescrição de Máquina')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    children: [
                      _InfoCard(),
                      const SizedBox(height: AppSpacing.lg),

                      // ── Talhão ───────────────────────────────────────────
                      _labelSecao('Talhão'),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: DropdownButton<String>(
                            isExpanded: true,
                            underline: const SizedBox(),
                            value: _talhaoSelected,
                            hint: const Text('Selecionar talhão'),
                            items: _talhoes
                                .map((t) => DropdownMenuItem(
                                    value: t.nome, child: Text(t.nome)))
                                .toList(),
                            onChanged: (v) {
                              setState(() => _talhaoSelected = v);
                              _recalcularGrade();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // ── Período ──────────────────────────────────────────
                      _labelSecao('Período'),
                      Card(
                        child: InkWell(
                          onTap: _selecionarPeriodo,
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Icon(Icons.date_range_outlined,
                                    color: AppColors.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${_fmtDate(_periodo.start)}  →  ${_fmtDate(_periodo.end)}',
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

                      // ── Produto e taxas ──────────────────────────────────
                      _labelSecao('Produto e Taxas (L/ha)'),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: _ConfigForm(
                            config: _config,
                            onChanged: (c) {
                              setState(() => _config = c);
                              _recalcularGrade();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // ── Tamanho de célula ────────────────────────────────
                      _labelSecao('Tamanho da Célula'),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: DropdownButton<double>(
                            isExpanded: true,
                            underline: const SizedBox(),
                            value: _config.tamanhoCelulaMetros,
                            items: const [
                              DropdownMenuItem(
                                  value: 10.0, child: Text('10 m × 10 m')),
                              DropdownMenuItem(
                                  value: 20.0, child: Text('20 m × 20 m')),
                              DropdownMenuItem(
                                  value: 50.0, child: Text('50 m × 50 m')),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setState(
                                () => _config =
                                    _config.copyWith(tamanhoCelulaMetros: v),
                              );
                              _recalcularGrade();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // ── Preview mapa ─────────────────────────────────────
                      _labelSecao('Prévia da Grade de Prescrição'),
                      if (_grade == null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                'Sem leituras com GPS no período selecionado.',
                                style: TextStyle(
                                    color: AppColors.textTertiary),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        )
                      else ...[
                        PrescricaoMapWidget(grade: _grade!),
                        const SizedBox(height: AppSpacing.md),
                        _EstatisticasGrade(grade: _grade!, config: _config),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),

                // ── Botão exportar ────────────────────────────────────────
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.md,
                        AppSpacing.xl,
                        AppSpacing.lg),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed:
                            _exportando || _grade == null ? null : _exportar,
                        icon: _exportando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.agriculture),
                        label: Text(_exportando
                            ? 'Gerando arquivo...'
                            : 'Exportar ZIP (ISOBUS)'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _labelSecao(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        titulo,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

// ── Widgets de suporte ────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFE8F5E9),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Gera um arquivo ZIP com TaskData.xml + GRD00001.bin no formato '
                'ISO 11783-10 (ISOBUS) — compatível com John Deere Operations '
                'Center e Jacto Hydra. Importe no software da máquina e '
                'transfira via USB ou cartão CF.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfigForm extends StatefulWidget {
  final ConfigPrescricao config;
  final ValueChanged<ConfigPrescricao> onChanged;
  const _ConfigForm({required this.config, required this.onChanged});

  @override
  State<_ConfigForm> createState() => _ConfigFormState();
}

class _ConfigFormState extends State<_ConfigForm> {
  late final TextEditingController _produto;
  late final TextEditingController _sem;
  late final TextEditingController _prev;
  late final TextEditingController _curat;

  @override
  void initState() {
    super.initState();
    _produto =
        TextEditingController(text: widget.config.nomeProduto);
    _sem = TextEditingController(
        text: widget.config.taxaSem.toStringAsFixed(1));
    _prev = TextEditingController(
        text: widget.config.taxaPreventiva.toStringAsFixed(1));
    _curat = TextEditingController(
        text: widget.config.taxaCurativa.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _produto.dispose();
    _sem.dispose();
    _prev.dispose();
    _curat.dispose();
    super.dispose();
  }

  void _notificar() {
    widget.onChanged(widget.config.copyWith(
      nomeProduto: _produto.text,
      taxaSem: double.tryParse(_sem.text) ?? widget.config.taxaSem,
      taxaPreventiva:
          double.tryParse(_prev.text) ?? widget.config.taxaPreventiva,
      taxaCurativa:
          double.tryParse(_curat.text) ?? widget.config.taxaCurativa,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.outline),
    );
    final dec = InputDecoration(
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    );

    return Column(
      children: [
        TextField(
          controller: _produto,
          decoration: dec.copyWith(labelText: 'Nome do produto'),
          onChanged: (_) => _notificar(),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _sem,
                decoration:
                    dec.copyWith(labelText: 'Sem doença', suffixText: 'L/ha'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _notificar(),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextField(
                controller: _prev,
                decoration: dec.copyWith(
                    labelText: 'Preventivo', suffixText: 'L/ha'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _notificar(),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextField(
                controller: _curat,
                decoration: dec.copyWith(
                    labelText: 'Curativo', suffixText: 'L/ha'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _notificar(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EstatisticasGrade extends StatelessWidget {
  final GradePrescricao grade;
  final ConfigPrescricao config;
  const _EstatisticasGrade({required this.grade, required this.config});

  @override
  Widget build(BuildContext context) {
    final zonas = grade.todasZonas;
    final sem = zonas.where((z) => z.nivel == 0).length;
    final prev = zonas.where((z) => z.nivel == 1).length;
    final curat = zonas.where((z) => z.nivel == 2).length;
    final total = zonas.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Grade: ${grade.nRows} × ${grade.nCols} células ($total total)',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            _linha(context, AppColors.saudavel, 'Sem aplicação',
                sem, total, config.taxaSem),
            _linha(context, AppColors.syncPending, 'Preventivo',
                prev, total, config.taxaPreventiva),
            _linha(context, AppColors.ferrugem, 'Curativo',
                curat, total, config.taxaCurativa),
          ],
        ),
      ),
    );
  }

  Widget _linha(BuildContext ctx, Color cor, String label, int n,
      int total, double taxa) {
    final perc = total > 0 ? (n / total * 100).toStringAsFixed(0) : '0';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          Text('$n cél. ($perc%)',
              style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          const SizedBox(width: 8),
          Text('${taxa.toStringAsFixed(1)} L/ha',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
