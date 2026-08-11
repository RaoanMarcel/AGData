import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/diagnostico_visuals.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/diagnostico_badge.dart';
import '../../../../core/widgets/info_pill.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/datasources/database_service.dart';
import '../../data/models/leitura_model.dart';
import '../widgets/observacao_field.dart';

/// Detalhe de uma leitura salva: visualizar, editar observação e excluir.
class LeituraDetalheScreen extends StatefulWidget {
  final LeituraModel leitura;
  const LeituraDetalheScreen({super.key, required this.leitura});

  @override
  State<LeituraDetalheScreen> createState() => _LeituraDetalheScreenState();
}

class _LeituraDetalheScreenState extends State<LeituraDetalheScreen> {
  final DatabaseService _db = DatabaseService();
  late final TextEditingController _obsController =
      TextEditingController(text: widget.leitura.observacao);

  bool _editando = false;
  bool _salvando = false;

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _salvarObservacao() async {
    setState(() => _salvando = true);
    widget.leitura.observacao = _obsController.text.trim();
    await _db.guardarLeitura(widget.leitura); // put faz upsert pelo id
    if (!mounted) return;
    setState(() {
      _salvando = false;
      _editando = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Observação atualizada.'),
        backgroundColor: AppColors.syncSuccess,
      ),
    );
  }

  Future<void> _excluir() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir leitura'),
        content: const Text(
            'Esta leitura será removida deste dispositivo. Deseja continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    await _db.deletarLeitura(widget.leitura.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.leitura;
    final visual = DiagnosticoVisual.fromResultado(l.resultadoIA);
    final temGps = l.latitude != 0.0 || l.longitude != 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhe da leitura'),
        actions: [
          if (!_editando)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar observação',
              onPressed: () => setState(() => _editando = true),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Excluir leitura',
            onPressed: _excluir,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.file(
                    File(l.caminhoImagem),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.broken_image,
                          color: AppColors.textTertiary, size: 48),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: DiagnosticoBadge(resultado: l.resultadoIA)),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Precisão da análise',
                              style: Theme.of(context).textTheme.bodyMedium),
                          Text('${(l.confianca * 100).toStringAsFixed(1)}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                      color: visual.color,
                                      fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(
                          value: l.confianca.clamp(0.0, 1.0),
                          minHeight: 10,
                          backgroundColor: AppColors.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation(visual.color),
                        ),
                      ),
                      const Divider(height: AppSpacing.xl),
                      _MetaLinha(
                          icon: Icons.eco,
                          texto: l.talhao.isEmpty ? 'Sem talhão' : l.talhao),
                      const SizedBox(height: AppSpacing.sm),
                      _MetaLinha(
                          icon: Icons.event_outlined,
                          texto: formatarDataHora(l.dataHora)),
                      if (temGps) ...[
                        const SizedBox(height: AppSpacing.md),
                        _MiniMapa(
                          latitude: l.latitude,
                          longitude: l.longitude,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () async {
                              final url = Uri.parse(
                                  'https://www.google.com/maps/search/?api=1&query=${l.latitude},${l.longitude}');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url,
                                    mode: LaunchMode.externalApplication);
                              }
                            },
                            child: InfoPill(
                              icon: Icons.location_on_outlined,
                              text:
                                  '${l.latitude.toStringAsFixed(4)}, ${l.longitude.toStringAsFixed(4)}',
                              color: AppColors.info,
                              background: AppColors.infoContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _secaoObservacao(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _secaoObservacao() {
    if (_editando) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ObservacaoField(controller: _obsController),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Cancelar',
                  variant: AppButtonVariant.secondary,
                  onPressed: _salvando
                      ? null
                      : () {
                          _obsController.text = widget.leitura.observacao;
                          setState(() => _editando = false);
                        },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: 'Salvar',
                  icon: Icons.check,
                  loading: _salvando,
                  onPressed: _salvarObservacao,
                ),
              ),
            ],
          ),
        ],
      );
    }

    final obs = widget.leitura.observacao.trim();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Observações',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar'),
                  onPressed: () => setState(() => _editando = true),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              obs.isEmpty ? 'Nenhuma observação registrada.' : obs,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: obs.isEmpty
                        ? AppColors.textTertiary
                        : AppColors.textPrimary,
                  ),
            ),
          ],
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
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: Text(texto, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}

/// Mini-mapa não interativo exibindo o ponto GPS da leitura.
class _MiniMapa extends StatefulWidget {
  final double latitude;
  final double longitude;
  const _MiniMapa({required this.latitude, required this.longitude});

  @override
  State<_MiniMapa> createState() => _MiniMapaState();
}

class _MiniMapaState extends State<_MiniMapa> {
  late Future<String> _cachePath;

  @override
  void initState() {
    super.initState();
    _cachePath = getApplicationDocumentsDirectory().then((d) => d.path);
  }

  @override
  Widget build(BuildContext context) {
    final centro = LatLng(widget.latitude, widget.longitude);

    return FutureBuilder<String>(
      future: _cachePath,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: SizedBox(
            height: 160,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: centro,
                initialZoom: 17,
                interactionOptions:
                    const InteractionOptions(flags: InteractiveFlag.none),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.agdata.app',
                  maxNativeZoom: 19,
                  tileProvider: CachedTileProvider(
                    store: HiveCacheStore(
                      snapshot.data!,
                      hiveBoxName: 'agdata_tiles',
                    ),
                    maxStale: const Duration(days: 30),
                  ),
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: centro,
                      width: 32,
                      height: 32,
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.danger,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
