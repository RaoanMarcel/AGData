import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/diagnostico_visuals.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/section_header.dart';
import '../controllers/mapa_controller.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final MapaController _controller = MapaController();

  static const List<String> _tiposDoenca = [
    "SAUDÁVEL",
    "FERRUGEM",
    "OÍDIO",
    "MANCHA ALVO",
    "INCONCLUSIVO"
  ];

  Future<String> _getPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  void _abrirFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        String? tempTalhao = _controller.filtroTalhao;
        String? tempDoenca = _controller.filtroDoenca;
        DateTime? tempInicio = _controller.dataInicio;
        DateTime? tempFim = _controller.dataFim;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Filtrar mapa",
                          style: Theme.of(context).textTheme.titleLarge),
                      IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const Divider(),
                  const SectionHeader(title: "Talhão"),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: tempTalhao,
                    hint: const Text("Todos os talhões"),
                    items: [
                      const DropdownMenuItem(value: null, child: Text("Todos")),
                      ..._controller.talhoes.map((t) =>
                          DropdownMenuItem(value: t.nome, child: Text(t.nome)))
                    ],
                    onChanged: (val) => setModalState(() => tempTalhao = val),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const SectionHeader(title: "Diagnóstico"),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _tiposDoenca.map((tipo) {
                      final v = DiagnosticoVisual.fromResultado(tipo);
                      final selecionado = tempDoenca == tipo;
                      return ChoiceChip(
                        avatar: Icon(v.icon,
                            size: 18,
                            color: selecionado
                                ? v.color
                                : AppColors.textTertiary),
                        label: Text(v.label),
                        selected: selecionado,
                        selectedColor: v.container,
                        onSelected: (selected) => setModalState(
                            () => tempDoenca = selected ? tipo : null),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: "Limpar",
                          variant: AppButtonVariant.secondary,
                          onPressed: () {
                            _controller.aplicarFiltros();
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppButton(
                          label: "Filtrar",
                          onPressed: () {
                            _controller.aplicarFiltros(
                                talhao: tempTalhao,
                                doenca: tempDoenca,
                                inicio: tempInicio,
                                fim: tempFim);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de ocorrências'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar mapa',
            onPressed: _abrirFiltros,
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _getPath(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final cachePath = snapshot.data!;

          return ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              if (_controller.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              return FlutterMap(
                options: MapOptions(
                  initialCenter: _controller.centroMapa,
                  initialZoom: 16.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.agdata.app',
                    tileProvider: CachedTileProvider(
                      store: HiveCacheStore(
                        cachePath,
                        hiveBoxName: 'agdata_tiles',
                      ),
                      // Expira o visual do mapa após 30 dias.
                      maxStale: const Duration(days: 30),
                    ),
                  ),
                  CircleLayer(circles: _controller.circles),
                  MarkerLayer(markers: _controller.markers),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
