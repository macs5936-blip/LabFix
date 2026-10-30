import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../config/theme/app_theme.dart';

/// Coordenadas y límites del campus ESPOCH
const _espochCenter = LatLng(-1.6582, -78.6783);
const _espochSW = LatLng(-1.6620, -78.6830);
const _espochNE = LatLng(-1.6540, -78.6730);
const _defaultZoom = 17.0;
const _minZoom = 15.5;
const _maxZoom = 19.0;

/// Modal de selección de ubicación con OpenStreetMap (flutter_map).
///
/// Abre una pantalla completa con las baldosas gratuitas de OSM centradas
/// en el campus ESPOCH. El usuario toca el mapa para colocar un marcador;
/// al confirmar, el widget hace pop devolviendo el [LatLng] seleccionado.
///
/// Uso:
/// ```dart
/// final LatLng? result = await showLocationPickerModal(context);
/// if (result != null) { /* usar lat/lng */ }
/// ```
Future<LatLng?> showLocationPickerModal(
  BuildContext context, {
  LatLng? initialSelection,
}) {
  return Navigator.of(context).push<LatLng>(
    MaterialPageRoute<LatLng>(
      fullscreenDialog: true,
      builder: (_) => LocationPickerModal(initialSelection: initialSelection),
    ),
  );
}

/// Widget modal de selección de ubicación (OpenStreetMap / flutter_map).
class LocationPickerModal extends StatefulWidget {
  const LocationPickerModal({
    super.key,
    this.initialSelection,
  });

  final LatLng? initialSelection;

  @override
  State<LocationPickerModal> createState() => _LocationPickerModalState();
}

class _LocationPickerModalState extends State<LocationPickerModal> {
  final MapController _mapController = MapController();
  LatLng? _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.initialSelection;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _recenter() {
    _mapController.move(_espochCenter, _defaultZoom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.fieBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancelar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Seleccionar ubicación',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_picked != null)
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(_picked),
              icon: const Icon(Icons.check, color: Colors.white, size: 18),
              label: const Text(
                'Confirmar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // ── FlutterMap con baldosas gratuitas de OpenStreetMap ────────────
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter:
                    widget.initialSelection ?? _espochCenter,
                initialZoom: _defaultZoom,
                minZoom: _minZoom,
                maxZoom: _maxZoom,
                cameraConstraint: CameraConstraint.containCenter(
                  bounds: LatLngBounds(_espochSW, _espochNE),
                ),
                onTap: (tapPosition, latLng) {
                  setState(() => _picked = latLng);
                },
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                // Capa de baldosas OSM (gratuita, sin API Key)
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'ec.espoch.labfix',
                  maxZoom: _maxZoom,
                  minZoom: _minZoom,
                  tileBuilder: (context, child, tile) => child,
                ),
                // Marcador del punto seleccionado
                if (_picked != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _picked!,
                        width: 54,
                        height: 64,
                        alignment: Alignment.topCenter,
                        child: _MapPin(),
                      ),
                    ],
                  ),
                // Atribución requerida por OpenStreetMap
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                  ],
                  alignment: AttributionAlignment.bottomLeft,
                  popupBackgroundColor: Colors.white,
                ),
              ],
            ),
          ),

          // ── Pista contextual en la parte superior ─────────────────────────
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Center(
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    _picked == null
                        ? '📍 Toca el mapa para marcar el incidente'
                        : '✅ Ubicación seleccionada — pulsa "Confirmar Ubicación"',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: _picked == null
                          ? AppColors.muted
                          : AppColors.fieBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Coordenadas del marcador actual ───────────────────────────────
          if (_picked != null)
            Positioned(
              right: 12,
              top: 70,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.fieBlue.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_picked!.latitude.toStringAsFixed(5)}, '
                  '${_picked!.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),

          // ── Botón recentrar en ESPOCH ─────────────────────────────────────
          Positioned(
            right: 16,
            bottom: 104,
            child: FloatingActionButton.small(
              heroTag: 'recenter-espoch-osm',
              tooltip: 'Recentrar en la ESPOCH',
              backgroundColor: Colors.white,
              foregroundColor: AppColors.fieBlue,
              elevation: 4,
              onPressed: _recenter,
              child: const Icon(Icons.my_location),
            ),
          ),

          // ── Barra inferior: Cancelar / Confirmar ─────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('map-cancel'),
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.line),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      key: const Key('map-confirm'),
                      onPressed: _picked == null
                          ? null
                          : () => Navigator.of(context).pop(_picked),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Confirmar Ubicación'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.fieBlue,
                        disabledBackgroundColor:
                            AppColors.fieBlue.withValues(alpha: 0.35),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Icono de pin personalizado para el marcador seleccionado
class _MapPin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.fieBlue,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.location_pin,
            color: Colors.white,
            size: 22,
          ),
        ),
        CustomPaint(
          size: const Size(12, 10),
          painter: _PinTailPainter(),
        ),
      ],
    );
  }
}

class _PinTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.fieBlue
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTailPainter oldDelegate) => false;
}
