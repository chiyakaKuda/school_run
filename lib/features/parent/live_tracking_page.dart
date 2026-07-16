import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../models/trip.dart';
import '../../utils/extensions.dart';

/// Live vehicle position for a child's current trip.
///
/// The map itself needs a plugin (`google_maps_flutter` or `flutter_map`), so
/// the map area is a placeholder for now. [_location] is the value a real
/// location stream would push into this screen.
class LiveTrackingPage extends StatefulWidget {
  const LiveTrackingPage({super.key, this.studentId});

  final String? studentId;

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  // TODO: subscribe to the trip's location stream (WebSocket or polling).
  TripLocation? _location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.liveTracking)),
      body: Column(
        children: [
          Expanded(child: _MapPlaceholder(location: _location)),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        child: Icon(Icons.directions_bus_rounded),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vehicle location',
                              style: context.text.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _location == null
                                  ? 'Waiting for the driver to start the trip…'
                                  : 'Updated ${_location!.recordedAt.relative}',
                              style: context.text.bodySmall?.copyWith(
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({this.location});

  final TripLocation? location;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: context.colors.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 48, color: context.colors.outline),
          const SizedBox(height: 12),
          Text(
            'Map goes here',
            style: context.text.bodyMedium
                ?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          if (location != null) ...[
            const SizedBox(height: 4),
            Text(
              '${location!.latitude.toStringAsFixed(5)}, '
              '${location!.longitude.toStringAsFixed(5)}',
              style: context.text.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
