import 'package:flutter/material.dart';

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
import '../../utils/extensions.dart';

/// Live vehicle position for a child's current trip.
///
/// A real map needs a plugin (`google_maps_flutter` or `flutter_map`), so the
/// canvas below is a painted stand-in with the right shape: dark ground, green
/// route, endpoint pins. Swap [_RouteCanvas] for the map widget and keep the
/// sheet as-is.
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

  @override
  void initState() {
    super.initState();
    _load();
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
      final student = await _studentsRepo.getById(studentId);

      // The trip actually carrying this child today — not, as the previous
      // fixture-backed version did, whichever trip happened to load first.
      final trips = await _tripsRepo.list();
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
        try {
          driver = await _driversRepo.getById(trip.driverId);
        } on ApiException {
          driver = null;
        }
        try {
          vehicle = await _vehiclesRepo.getById(trip.vehicleId);
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
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
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

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _RouteCanvas()),

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

/// Painted placeholder standing in for the map.
class _RouteCanvas extends StatelessWidget {
  const _RouteCanvas();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF101216),
      child: CustomPaint(painter: _RoutePainter(), child: const SizedBox()),
    );
  }
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final streets = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 14;

    // Faint street grid.
    for (double x = -size.height; x < size.width; x += 78) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height),
          streets);
    }
    for (double y = 0; y < size.height + size.width; y += 92) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - size.width), streets);
    }

    // Route.
    final path = Path()
      ..moveTo(size.width * 0.22, size.height * 0.74)
      ..lineTo(size.width * 0.22, size.height * 0.52)
      ..lineTo(size.width * 0.48, size.height * 0.52)
      ..lineTo(size.width * 0.48, size.height * 0.3)
      ..lineTo(size.width * 0.78, size.height * 0.3);

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    _pin(canvas, Offset(size.width * 0.22, size.height * 0.74));
    _pin(canvas, Offset(size.width * 0.78, size.height * 0.3), filled: true);
  }

  void _pin(Canvas canvas, Offset centre, {bool filled = false}) {
    canvas.drawCircle(
      centre,
      12,
      Paint()..color = AppColors.accent.withValues(alpha: 0.2),
    );
    canvas.drawCircle(centre, 7, Paint()..color = AppColors.accent);
    if (!filled) {
      canvas.drawCircle(centre, 3, Paint()..color = const Color(0xFF101216));
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) => false;
}
