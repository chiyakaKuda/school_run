import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/drivers_repository.dart';
import '../../core/services/students_repository.dart';
import '../../core/services/trips_repository.dart';
import '../../core/services/vehicles_repository.dart';
import '../../models/driver_profile.dart';
import '../../models/student.dart';
import '../../models/trip.dart';
import '../../models/vehicle.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/vehicle_map.dart';
import '../../utils/extensions.dart';

/// How often the trip is re-fetched while it is running, to move the marker.
/// The driver posts a position on ~15m of movement (see `LocationService`),
/// so polling much faster than this would just re-render the same point.
const Duration _pollInterval = Duration(seconds: 6);

/// Live vehicle position for a child's current trip.
class LiveTrackingPage extends StatefulWidget {
  const LiveTrackingPage({super.key, this.studentId});

  final String? studentId;

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  final StudentsRepository _studentsRepo = StudentsRepository.instance;
  final TripsRepository _tripsRepo = TripsRepository.instance;
  final DriversRepository _driversRepo = DriversRepository.instance;
  final VehiclesRepository _vehiclesRepo = VehiclesRepository.instance;

  Student? _student;
  Trip? _trip;
  DriverProfile? _driver;
  Vehicle? _vehicle;
  bool _loading = true;
  String? _error;

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final studentId = widget.studentId;
    if (studentId == null) {
      setState(() {
        _loading = false;
        _error = 'No child was selected.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Neither depends on the other's result, so both go out together — a
      // real device pays full round-trip latency to Neon (us-east-1) on every
      // request, not just the dev machine's near-zero LAN latency to it.
      final studentFuture = _studentsRepo.getById(studentId);
      final tripsFuture = _tripsRepo.list();
      final student = await studentFuture;

      // The trip actually carrying this child today — not, as the previous
      // fixture-backed version did, whichever trip happened to load first.
      final trips = await tripsFuture;
      Trip? trip;
      for (final t in trips) {
        if (t.studentIds.contains(studentId)) {
          trip = t;
          if (t.isActive) break; // prefer a live run over a scheduled one
        }
      }

      DriverProfile? driver;
      Vehicle? vehicle;
      if (trip != null) {
        final driverFuture = _driversRepo.getById(trip.driverId);
        final vehicleFuture = _vehiclesRepo.getById(trip.vehicleId);
        try {
          driver = await driverFuture;
        } on ApiException {
          driver = null;
        }
        try {
          vehicle = await vehicleFuture;
        } on ApiException {
          vehicle = null;
        }
      }

      if (!mounted) return;
      setState(() {
        _student = student;
        _trip = trip;
        _driver = driver;
        _vehicle = vehicle;
        _loading = false;
      });

      _pollTimer?.cancel();
      if (trip != null && trip.isActive) _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  /// Refreshes only the trip — the marker moves, nothing else re-fetches.
  /// [_load] re-resolves student/driver/vehicle too, which this deliberately
  /// skips: those don't change mid-trip, and re-requesting them every six
  /// seconds would just be load with nothing to show for it.
  Future<void> _poll() async {
    final trip = _trip;
    if (trip == null) return;

    try {
      final fresh = await _tripsRepo.getById(trip.id);
      if (!mounted) return;
      setState(() => _trip = fresh);

      // The run ended since the last poll — nothing left to follow.
      if (!fresh.isActive) _pollTimer?.cancel();
    } on ApiException {
      // A missed poll tick isn't worth surfacing; the next one, six seconds
      // on, tries again.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: LoadingWidget());
    }

    final error = _error;
    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
        body: EmptyState(
          icon: Icons.wifi_off_rounded,
          message: error,
          onRetry: widget.studentId == null ? null : _load,
        ),
      );
    }

    final location = _trip?.lastLocation;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: VehicleMap(
              position: location == null
                  ? null
                  : LatLng(location.latitude, location.longitude),
            ),
          ),

          // Floating back control, as in the reference.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                    ),
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  if (_student != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        _student!.name,
                        style: context.text.labelMedium,
                      ),
                    ),
                ],
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: _TrackingSheet(
              trip: _trip,
              driver: _driver,
              vehicle: _vehicle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet: status banner, driver card, contact action.
class _TrackingSheet extends StatelessWidget {
  const _TrackingSheet({
    required this.trip,
    required this.driver,
    required this.vehicle,
  });

  final Trip? trip;
  final DriverProfile? driver;
  final Vehicle? vehicle;

  @override
  Widget build(BuildContext context) {
    final running = trip?.isActive ?? false;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status banner. There is no ETA on the backend yet — the
            // reference's "6 min" was a bare literal, not derived from
            // anything — so this reports the trip's real state instead of a
            // number that would always read the same regardless of reality.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: running ? AppColors.accent : AppColors.surfaceVariant,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.sheet),
                ),
              ),
              child: Row(
                children: [
                  if (running)
                    Container(
                      height: 8,
                      width: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                        color: AppColors.onAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    trip == null
                        ? 'No run scheduled today'
                        : running
                            ? 'On the road now'
                            : trip!.status.label,
                    style: context.text.labelLarge?.copyWith(
                      color: running
                          ? AppColors.onAccent
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            if (driver != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.surfaceVariant,
                      child: Text(
                        driver!.name.initials,
                        style: context.text.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(driver!.name, style: context.text.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            vehicle?.model ?? '',
                            style: context.text.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (vehicle != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          vehicle!.plateNumber,
                          style: context.text.labelMedium,
                        ),
                      ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text(
                trip?.lastLocation == null
                    ? 'Waiting for the driver to start the trip…'
                    : 'Location updated ${trip!.lastLocation!.recordedAt.relative}',
                style: context.text.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.chat_bubble_outline_rounded,
                          size: 18),
                      label: const Text('Message driver'),
                      onPressed: driver == null
                          ? null
                          : () => context.showSnack(
                                'Messaging is not wired up yet.',
                              ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceVariant,
                      minimumSize: const Size.square(58),
                    ),
                    icon: const Icon(Icons.phone_rounded),
                    onPressed: driver?.phone == null
                        ? null
                        : () =>
                            context.showSnack('Calling is not wired up yet.'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
