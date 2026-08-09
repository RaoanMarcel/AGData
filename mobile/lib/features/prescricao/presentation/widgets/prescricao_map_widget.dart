import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:path_provider/path_provider.dart';
import 'package:latlong2/latlong.dart';
import '../../models/zona_prescricao.dart';

class PrescricaoMapWidget extends StatefulWidget {
  final GradePrescricao grade;
  final double height;

  const PrescricaoMapWidget({
    super.key,
    required this.grade,
    this.height = 320,
  });

  @override
  State<PrescricaoMapWidget> createState() => _PrescricaoMapWidgetState();
}

class _PrescricaoMapWidgetState extends State<PrescricaoMapWidget> {
  final MapController _mapController = MapController();

  Color _corPorNivel(int nivel) {
    switch (nivel) {
      case 1:
        return const Color(0xFFF9A825).withValues(alpha: 0.55); // amarelo
      case 2:
        return const Color(0xFFC62828).withValues(alpha: 0.55); // vermelho
      default:
        return const Color(0xFF2E7D32).withValues(alpha: 0.35); // verde
    }
  }

  Color _bordaPorNivel(int nivel) {
    switch (nivel) {
      case 1:
        return const Color(0xFFF9A825);
      case 2:
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  void _reenquadrar() {
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(widget.grade.minLat, widget.grade.minLng),
          LatLng(widget.grade.maxLat, widget.grade.maxLng),
        ),
        padding: const EdgeInsets.all(32),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final zonas = widget.grade.todasZonas;

    return SizedBox(
      height: widget.height,
      child: FutureBuilder<String>(
        future: getApplicationDocumentsDirectory().then((d) => d.path),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(
                      (widget.grade.minLat + widget.grade.maxLat) / 2,
                      (widget.grade.minLng + widget.grade.maxLng) / 2,
                    ),
                    initialZoom: 14,
                    onMapReady: _reenquadrar,
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
                    PolygonLayer(
                      polygons: zonas.map((z) {
                        return Polygon(
                          points: [
                            LatLng(z.latMin, z.lngMin),
                            LatLng(z.latMax, z.lngMin),
                            LatLng(z.latMax, z.lngMax),
                            LatLng(z.latMin, z.lngMax),
                          ],
                          color: _corPorNivel(z.nivel),
                          borderColor: _bordaPorNivel(z.nivel),
                          borderStrokeWidth: 0.8,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: _Legenda(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 4)
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _LegendaItem(color: Color(0xFF2E7D32), label: 'Sem aplicação'),
          SizedBox(height: 4),
          _LegendaItem(color: Color(0xFFF9A825), label: 'Preventivo'),
          SizedBox(height: 4),
          _LegendaItem(color: Color(0xFFC62828), label: 'Curativo'),
        ],
      ),
    );
  }
}

class _LegendaItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendaItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
