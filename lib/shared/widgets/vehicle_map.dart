import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';

/// Falls back to central Harare — where every seeded trip actually runs —
/// rather than (0, 0), so an unstarted trip still centres on something
/// meaningful instead of the middle of the Atlantic.
const LatLng _defaultCentre = LatLng(-17.8252, 31.0335);

/// A single vehicle's position on a dark basemap.
///
/// Tiles are CartoDB's free "Dark Matter" set — no API key, which
/// `google_maps_flutter` and Mapbox both require and neither project has
/// provisioned. It is also the one basemap that does not fight the app's
/// dark-only theme; the default OSM tiles are daylight-bright and would sit
/// on this screen like a hole cut in the UI.
///
/// [position] is null before a trip has posted its first location — the map
/// still renders, centred on the school's home city, so the screen never
/// shows a blank rectangle while waiting.
class VehicleMap extends StatefulWidget {
  const VehicleMap({super.key, this.position});

  final LatLng? position;

  @override
  State<VehicleMap> createState() => _VehicleMapState();
}

class _VehicleMapState extends State<VehicleMap> {
  final MapController _controller = MapController();

  @override
  void didUpdateWidget(VehicleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.position;
    // Follow the vehicle as new positions arrive, without resetting the zoom
    // level a parent may have pinched out to.
    if (next != null && next != oldWidget.position) {
      _controller.move(next, _controller.camera.zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: widget.position ?? _defaultCentre,
        initialZoom: widget.position == null ? 12 : 15,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'co.zw.schoolrun.school_run',
          maxZoom: 19,
        ),
        if (widget.position != null)
          MarkerLayer(
            markers: [
              Marker(
                point: widget.position!,
                width: 44,
                height: 44,
                child: const _VehicleMarker(),
              ),
            ],
          ),
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution('OpenStreetMap contributors'),
            TextSourceAttribution('CARTO'),
          ],
        ),
      ],
    );
  }
}

class _VehicleMarker extends StatelessWidget {
  const _VehicleMarker();

  @override
  Widget build(BuildContext context) {
    // No shadow — AppTheme sets elevation: 0 throughout, and a marker sitting
    // on a map tile is not the one sanctioned exception (AppLogo's glow).
    // Contrast against the tile comes from the white ring instead.
    return Container(
      decoration: BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.onAccent, width: 2),
      ),
      child: const Icon(
        Icons.directions_bus_rounded,
        color: AppColors.onAccent,
        size: 22,
      ),
    );
  }
}
