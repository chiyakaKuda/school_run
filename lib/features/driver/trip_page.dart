import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../core/services/api_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/trips_repository.dart';
import '../../core/services/vehicles_repository.dart';
import '../../models/trip.dart';
import '../../models/vehicle.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/primary_button.dart';
import '../../utils/extensions.dart';

/// The active run: start/end the trip and reach the manifest.
class TripPage extends StatefulWidget {
  const TripPage({super.key, this.tripId});

  final String? tripId;

  @override
  State<TripPage> createState() => _TripPageState();
}

class _TripPageState extends State<TripPage> {
  final TripsRepository _tripsRepo = TripsRepository.instance;
  final VehiclesRepository _vehiclesRepo = VehiclesRepository.instance;
  final LocationService _locationService = LocationService.instance;

  Trip? _trip;
  Vehicle? _vehicle;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  StreamSubscription<Position>? _positionSub;
  bool _sharingLocation = false;

  bool get _isRunning => _trip?.isActive ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    // Foreground-only tracking, deliberately: leaving the screen — or the
    // app — stops the stream. A background service that kept posting after
    // the driver moved on would need its own persistent notification and a
    // much heavier permission (ACCESS_BACKGROUND_LOCATION), which is a
    // separate feature, not a default to fall into silently.
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _beginSharingLocation() async {
    if (_positionSub != null) return; // already streaming

    final access = await _locationService.requestAccess();
    if (!mounted) return;

    switch (access) {
      case LocationAccessResult.granted:
        break;
      case LocationAccessResult.serviceDisabled:
        context.showSnack(
          'Turn on location services to share your position with parents.',
        );
        return;
      case LocationAccessResult.denied:
        context.showSnack(
          'Location permission is needed to share your position with parents.',
        );
        return;
      case LocationAccessResult.deniedForever:
        context.showSnack(
          'Location is blocked for School Run. Enable it in Settings to '
          'share your position with parents.',
        );
        return;
    }

    setState(() => _sharingLocation = true);

    _positionSub = _locationService.watchPosition().listen((position) async {
      final trip = _trip;
      if (trip == null) return;

      try {
        await _tripsRepo.postLocation(
          tripId: trip.id,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      } on ApiException {
        // One missed ping is not worth interrupting the driver over — the
        // next position update, ~15m on, tries again. A parent sees a stale
        // dot for a few seconds rather than a dropped trip.
      }
    });
  }

  void _stopSharingLocation() {
    _positionSub?.cancel();
    _positionSub = null;
    if (mounted) setState(() => _sharingLocation = false);
  }

  Future<void> _load() async {
    final tripId = widget.tripId;
    if (tripId == null) {
      setState(() {
        _loading = false;
        _error = 'No run was selected.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final trip = await _tripsRepo.getById(tripId);
      Vehicle? vehicle;
      try {
        vehicle = await _vehiclesRepo.getById(trip.vehicleId);
      } on ApiException {
        // The trip itself is what matters here; a vehicle lookup failure
        // shouldn't block the start/end action over a cosmetic detail.
        vehicle = null;
      }

      if (!mounted) return;
      setState(() {
        _trip = trip;
        _vehicle = vehicle;
        _loading = false;
      });

      // A driver can leave this screen and come back to a trip that is still
      // running — the manifest, say, then back — so sharing resumes on
      // arrival rather than only ever starting from a fresh "Start trip" tap.
      if (trip.isActive) unawaited(_beginSharingLocation());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _toggleTrip() async {
    final trip = _trip;
    if (trip == null || _busy) return;

    setState(() => _busy = true);
    final wasRunning = _isRunning;

    try {
      final updated =
          wasRunning ? await _tripsRepo.end(trip.id) : await _tripsRepo.start(trip.id);
      if (!mounted) return;

      if (wasRunning) {
        _stopSharingLocation();
      } else {
        unawaited(_beginSharingLocation());
      }

      setState(() {
        _trip = updated;
        _busy = false;
      });
      context.showSnack(wasRunning ? 'Trip ended.' : 'Trip started.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      // A transition the server rejected (already started by a stale screen,
      // say) is worth surfacing rather than silently reverting.
      context.showSnack(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        title: Text(
          trip == null
              ? 'Trip'
              : trip.direction == TripDirection.pickup
                  ? 'Pickup run'
                  : 'Drop-off run',
        ),
      ),
      body: switch ((_loading, _error, trip)) {
        (true, _, _) => const LoadingWidget(message: AppStrings.loading),
        (false, String message, _) => EmptyState(
            icon: Icons.wifi_off_rounded,
            message: message,
            onRetry: widget.tripId == null ? null : _load,
          ),
        (false, null, null) => const EmptyState(
            icon: Icons.error_outline_rounded,
            message: 'That run could not be found.',
          ),
        (false, null, Trip t) => SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      _StatusCard(
                        trip: t,
                        vehicle: _vehicle,
                        sharingLocation: _sharingLocation,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.people_outline_rounded,
                              value: '${t.studentIds.length}',
                              label: 'Students',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.schedule_rounded,
                              value: t.elapsed?.compact ?? '--',
                              label: 'Elapsed',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.people_outline_rounded, size: 20),
                        label: const Text(AppStrings.students),
                        onPressed: () => Navigator.of(context).pushNamed(
                          AppRoutes.studentList,
                          arguments: t.id,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: PrimaryButton(
                    label: _isRunning ? AppStrings.endTrip : AppStrings.startTrip,
                    icon:
                        _isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    busy: _busy,
                    danger: _isRunning,
                    onPressed: _toggleTrip,
                  ),
                ),
              ],
            ),
          ),
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.trip,
    required this.vehicle,
    required this.sharingLocation,
  });

  final Trip trip;
  final Vehicle? vehicle;
  final bool sharingLocation;

  @override
  Widget build(BuildContext context) {
    final live = trip.isActive;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: live ? AppColors.accentContainer : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: live ? AppColors.accent : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (live) ...[
                Container(
                  height: 8,
                  width: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                trip.status.label,
                style: context.text.labelLarge?.copyWith(
                  color: live ? AppColors.accent : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            trip.scheduledAt?.hhmm ?? '--:--',
            style: context.text.displayMedium,
          ),
          const SizedBox(height: 6),
          Text(
            vehicle?.displayName ?? 'Vehicle not assigned',
            style: context.text.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          if (live) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  sharingLocation
                      ? Icons.location_on_rounded
                      : Icons.location_off_rounded,
                  size: 14,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 6),
                Text(
                  sharingLocation
                      ? 'Sharing your location with parents'
                      : 'Location not shared — check permissions',
                  style: context.text.labelSmall
                      ?.copyWith(color: AppColors.accent),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(value, style: context.text.headlineSmall),
          const SizedBox(height: 2),
          Text(
            label,
            style: context.text.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
