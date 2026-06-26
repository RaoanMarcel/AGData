import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/diagnostico_badge.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/section_header.dart';
import '../../data/models/leitura_model.dart';
import '../../data/datasources/database_service.dart';
import 'package:url_launcher/url_launcher.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  final DatabaseService _databaseService = DatabaseService();

  List<LeituraModel> _todasLeituras = []; // Guarda TUDO que vem do banco
  List<LeituraModel> _leiturasFiltradas = []; // Guarda só o que passa no filtro

  final List<int> _selecionados = [];
  bool _loading = true;

  // --- VARIÁVEIS DOS FILTROS ---
  DateTime? _dataFiltro;
  String _doencaFiltro = 'Todas';
  double _confiancaFiltro = 0.0;
  final List<String> _opcoesDoenca = [
    'Todas',
    'FERRUGEM',
    'OÍDIO',
    'SAUDÁVEL',
    'MANCHA ALVO',
    'INCONCLUSIVO'
  ];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final dados = await _databaseService.buscarTodasLeituras();
    if (mounted) {
      setState(() {
        _todasLeituras = dados.reversed.toList();
        _leiturasFiltradas = List.from(_todasLeituras);
        _loading = false;
      });
    }
  }

  // --- LÓGICA DE FILTRAGEM ---
  void _aplicarFiltros() {
    setState(() {
      _selecionados.clear();
      _leiturasFiltradas = _todasLeituras.where((leitura) {
        bool passaData = true;
        if (_dataFiltro != null) {
          passaData = leitura.dataHora.year == _dataFiltro!.year &&
              leitura.dataHora.month == _dataFiltro!.month &&
              leitura.dataHora.day == _dataFiltro!.day;
        }

        bool passaDoenca = true;
        if (_doencaFiltro != 'Todas') {
          passaDoenca = leitura.resultadoIA == _doencaFiltro;
        }

        bool passaConfianca = leitura.confianca >= _confiancaFiltro;

        return passaData && passaDoenca && passaConfianca;
      }).toList();
    });
  }

  // --- MENU INFERIOR DE FILTROS ---
  void _abrirMenuDeFiltros() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Filtrar leituras",
                          style: Theme.of(context).textTheme.titleLarge),
                      IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context))
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),
                  const SectionHeader(title: "Filtrar por dia"),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _dataFiltro == null
                          ? "Todas as datas"
                          : "Dia: ${_dataFiltro!.day.toString().padLeft(2, '0')}/${_dataFiltro!.month.toString().padLeft(2, '0')}/${_dataFiltro!.year}",
                      style: TextStyle(
                          color: _dataFiltro == null
                              ? AppColors.textTertiary
                              : AppColors.textPrimary),
                    ),
                    trailing: const Icon(Icons.calendar_month,
                        color: AppColors.primary),
                    onTap: () async {
                      final DateTime? escolhida = await showDatePicker(
                        context: context,
                        initialDate: _dataFiltro ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (escolhida != null) {
                        setModalState(() => _dataFiltro = escolhida);
                        _aplicarFiltros();
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const SectionHeader(title: "Tipo de análise"),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: _doencaFiltro,
                    items: _opcoesDoenca.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (novoValor) {
                      setModalState(() => _doencaFiltro = novoValor!);
                      _aplicarFiltros();
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SectionHeader(
                    title: "Grau de certeza mínimo",
                    trailing: Text("${(_confiancaFiltro * 100).toInt()}%",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                  ),
                  Slider(
                    value: _confiancaFiltro,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    onChanged: (valor) {
                      setModalState(() => _confiancaFiltro = valor);
                      _aplicarFiltros();
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: "Limpar filtros",
                    icon: Icons.clear_all,
                    variant: AppButtonVariant.secondary,
                    onPressed: () {
                      setModalState(() {
                        _dataFiltro = null;
                        _doencaFiltro = 'Todas';
                        _confiancaFiltro = 0.0;
                      });
                      _aplicarFiltros();
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            );
          });
        });
  }

  // --- FUNÇÕES DE APOIO ---
  String _formatarData(DateTime data) {
    return "${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} às ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}";
  }

  void _alternarSelecao(int id) {
    setState(() {
      if (_selecionados.contains(id)) {
        _selecionados.remove(id);
      } else {
        _selecionados.add(id);
      }
    });
  }

  Future<void> _enviarRelatorioWhatsApp() async {
    final itensMarcados =
        _leiturasFiltradas.where((l) => _selecionados.contains(l.id)).toList();
    if (itensMarcados.isEmpty) return;

    StringBuffer sb = StringBuffer();
    sb.writeln("📊 *Relatório AGdata - Inspeção de Campo*");
    sb.writeln("📅 *Data do Envio:* ${_formatarData(DateTime.now())}\n");
    sb.writeln("⚠️ *Atenção:* ${itensMarcados.length} registro(s) selecionado(s).\n");

    for (int i = 0; i < itensMarcados.length; i++) {
      final item = itensMarcados[i];
      sb.writeln("*Foco ${i + 1} - ${item.resultadoIA}*");
      sb.writeln("Precisão: ${(item.confianca * 100).toStringAsFixed(1)}%");
      final linkMapa =
          "https://www.google.com/maps/search/?api=1&query=${item.latitude},${item.longitude}";
      sb.writeln("📍 Localização: $linkMapa\n");
    }
    sb.writeln("Aguardando orientações de manejo. 🚜");

    final textoCodificado = Uri.encodeComponent(sb.toString());
    final url = Uri.parse("https://wa.me/?text=$textoCodificado");

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Não foi possível abrir o link');
      }
      setState(() => _selecionados.clear());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao abrir o WhatsApp.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios de campo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar análises',
            onPressed: _abrirMenuDeFiltros,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Enviar via WhatsApp',
            onPressed: _selecionados.isEmpty ? null : _enviarRelatorioWhatsApp,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _leiturasFiltradas.isEmpty
              ? const EmptyState(
                  icon: Icons.search_off,
                  title: 'Nenhuma análise encontrada',
                  message:
                      'Ajuste os filtros ou realize novas leituras no campo.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: _leiturasFiltradas.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final leitura = _leiturasFiltradas[index];
                    return _LeituraCard(
                      leitura: leitura,
                      selecionado: _selecionados.contains(leitura.id),
                      data: _formatarData(leitura.dataHora),
                      onTap: () => _alternarSelecao(leitura.id),
                    );
                  },
                ),
    );
  }
}

/// Cartão de uma leitura no histórico (miniatura + diagnóstico + seleção).
class _LeituraCard extends StatelessWidget {
  final LeituraModel leitura;
  final bool selecionado;
  final String data;
  final VoidCallback onTap;

  const _LeituraCard({
    required this.leitura,
    required this.selecionado,
    required this.data,
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
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              _Thumb(caminho: leitura.caminhoImagem),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DiagnosticoBadge(resultado: leitura.resultadoIA, dense: true),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      "Confiança: ${(leitura.confianca * 100).toStringAsFixed(1)}%",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(data, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Checkbox(
                value: selecionado,
                onChanged: (_) => onTap(),
              )
            ],
          ),
        ),
      ),
    );
  }
}

/// Miniatura da imagem da leitura, com fallback para imagem quebrada.
class _Thumb extends StatelessWidget {
  final String caminho;
  const _Thumb({required this.caminho});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Image.file(
        File(caminho),
        height: 72,
        width: 72,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 72,
          width: 72,
          color: AppColors.surfaceVariant,
          child: const Icon(Icons.broken_image, color: AppColors.textTertiary),
        ),
      ),
    );
  }
}
