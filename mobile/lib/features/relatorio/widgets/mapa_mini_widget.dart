import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:path_provider/path_provider.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/diagnostico_visuals.dart';
import '../../diagnostico/data/models/leitura_model.dart';

class MapaMiniWidget extends StatefulWidget {
  final List<LeituraModel> leituras;
  final GlobalKey repaintKey;
  final double height;

  const MapaMiniWidget({
    super.key,
    required this.leituras,
    required this.repaintKey,
    this.height = 280,
  });

  @override
  State<MapaMiniWidget> createState() => _MapaMiniWidgetState();
}

class _MapaMiniWidgetState extends State<MapaMiniWidget> {
  final MapController _mapController = MapController();
  late List<CircleMarker> _circles;
  late List<Marker> _markers;
  late LatLng _center;
  late double _zoom;

  @override
  void initState() {
    super.initState();
    _buildLayers();
  }

  @override
  void didUpdateWidget(MapaMiniWidget old) {
    super.didUpdateWidget(old);
    if (old.leituras != widget.leituras) {
      _buildLayers();
    }
  }

  void _buildLayers() {
    _circles = [];
    _markers = [];
    final pontos = <LatLng>[];

    for (final l in widget.leituras) {
      if (l.latitude == 0.0) continue;
      final pos = LatLng(l.latitude, l.longitude);
      final v = DiagnosticoVisual.fromResultado(l.resultadoIA);
      pontos.add(pos);

      _circles.add(CircleMarker(
        point: pos,
        color: v.color.withValues(alpha: 0.3),
        borderColor: v.color,
        borderStrokeWidth: 2,
        radius: 10,
      ));

      _markers.add(Marker(
        point: pos,
        width: 28,
        height: 28,
        alignment: Alignment.topCenter,
        child: _PinMini(color: v.color, icon: v.icon),
      ));
    }

    if (pontos.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(pontos);
      _center = bounds.center;
      _zoom = pontos.length == 1 ? 16.0 : 14.0;
    } else {
      _center = const LatLng(-15.0, -50.0);
      _zoom = 4.0;
    }
  }

  void _reenquadrar() {
    if (_markers.isEmpty) return;
    if (_markers.length == 1) {
      _mapController.move(_center, 16.0);
    } else {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(_markers.map((m) => m.point).toList()),
          padding: const EdgeInsets.all(40),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: FutureBuilder<String>(
        future: getApplicationDocumentsDirectory().then((d) => d.path),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return RepaintBoundary(
            key: widget.repaintKey,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: _zoom,
                  onMapReady: _reenquadrar,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                  CircleLayer(circles: _circles),
                  MarkerLayer(markers: _markers),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PinMini extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _PinMini({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        const Icon(Icons.location_on, size: 28, color: Colors.white),
        Icon(Icons.location_on, size: 24, color: color),
        Positioned(top: 4, child: Icon(icon, size: 9, color: Colors.white)),
      ],
    );
  }
}
