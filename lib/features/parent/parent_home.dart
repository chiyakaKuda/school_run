import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/services/api_service.dart';
import '../../core/services/drivers_repository.dart';
import '../../core/services/students_repository.dart';
import '../../core/services/trips_repository.dart';
import '../../core/services/vehicles_repository.dart';
import '../../models/driver_profile.dart';
import '../../models/student.dart';
import '../../models/trip.dart';
import '../../models/vehicle.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../utils/extensions.dart';
import '../auth/auth_provider.dart';

/// Parent landing screen: their children and each one's current status.
class ParentHome extends StatefulWidget {
  const ParentHome({super.key});

  @override
  State<ParentHome> createState() => _ParentHomeState();
}

class _ParentHomeState extends State<ParentHome> {
  final StudentsRepository _studentsRepo = StudentsRepository.instance;
  final TripsRepository _tripsRepo = TripsRepository.instance;
  final DriversRepository _driversRepo = DriversRepository.instance;
  final VehiclesRepository _vehiclesRepo = VehiclesRepository.instance;

  List<Student> _children = const [];
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
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final children = await _studentsRepo.list();

      // "Today's driver" is whichever trip is carrying this parent's children
      // right now — running takes priority over merely scheduled, so a parent
      // mid-run sees the driver actually on the road rather than tomorrow's.
      final trips = await _tripsRepo.list();
      Trip? chosen;
      for (final trip in trips) {
        if (trip.isActive) {
          chosen = trip;
          break;
        }
        chosen ??= trip;
      }

      DriverProfile? driver;
      Vehicle? vehicle;
      if (chosen != null) {
        // Best-effort: a driver or vehicle lookup failing shouldn't blank the
        // whole screen when the children list loaded fine.
        try {
          driver = await _driversRepo.getById(chosen.driverId);
        } on ApiException {
          driver = null;
        }
        try {
          vehicle = await _vehiclesRepo.getById(chosen.vehicleId);
        } on ApiException {
          vehicle = null;
        }
      }

      if (!mounted) return;
      setState(() {
        _children = children;
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _TopBar(),
            Expanded(
              child: switch ((_loading, _error, _children.isEmpty)) {
                (true, _, _) => const LoadingWidget(),
                (false, String message, _) => EmptyState(
                    icon: Icons.wifi_off_rounded,
                    message: message,
                    onRetry: _load,
                  ),
                (false, null, true) => EmptyState(
                    icon: Icons.child_care_outlined,
                    message: 'No children linked to this account yet.',
                    onRetry: _load,
                  ),
                (false, null, false) => RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        Text(
                          'Where are\nyour kids?',
                          style: context.text.displaySmall,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Live updates from today\'s run.',
                          style: context.text.bodyLarge
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        if (_driver != null)
                          _DriverStrip(driver: _driver!, vehicle: _vehicle),
                        const SizedBox(height: 28),
                        Text('My children', style: context.text.titleLarge),
                        const SizedBox(height: 14),
                        for (final child in _children) ...[
                          _ChildCard(student: child),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context).user;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.grid_view_rounded, size: 20),
            onPressed: () {},
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, size: 20),
            // Alerts is a sibling tab inside ParentShell, not a pushed screen.
            onPressed: () => ShellScope.maybeOf(context)?.goTo(1),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => ShellScope.maybeOf(context)?.goTo(2),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.accent,
              child: Text(
                user?.name.initials ?? '?',
                style: context.text.labelLarge
                    ?.copyWith(color: AppColors.onAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Today's driver — the reference's rated-driver row.
///
/// There is no rating field on the backend; the reference's "4.9" was a bare
/// literal with no model behind it at all, so it is dropped rather than
/// carried forward as fake precision.
class _DriverStrip extends StatelessWidget {
  const _DriverStrip({required this.driver, required this.vehicle});

  final DriverProfile driver;
  final Vehicle? vehicle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.surfaceVariant,
            child: Text(driver.name.initials, style: context.text.labelLarge),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(driver.name, style: context.text.titleMedium),
                const SizedBox(height: 2),
                Text(
                  vehicle?.displayName ?? 'Vehicle not assigned',
                  style: context.text.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({required this.student});

  final Student student;

  Color get _statusColor => switch (student.status) {
        StudentStatus.onboard => AppColors.onboard,
        StudentStatus.waiting => AppColors.waiting,
        StudentStatus.droppedOff => AppColors.info,
        StudentStatus.absent => AppColors.absent,
      };

  @override
  Widget build(BuildContext context) {
    final onboard = student.status == StudentStatus.onboard;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: onboard ? AppColors.accentContainer : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: onboard ? AppColors.accent : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.surfaceVariant,
            child: Text(student.name.initials, style: context.text.titleMedium),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: context.text.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      height: 6,
                      width: 6,
                      decoration: BoxDecoration(
                        color: _statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${student.status.label} • ${student.grade}',
                        style: context.text.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: onboard ? AppColors.accent : null,
              foregroundColor: onboard ? AppColors.onAccent : null,
            ),
            icon: const Icon(Icons.navigation_rounded, size: 18),
            onPressed: () => Navigator.of(context).pushNamed(
              AppRoutes.liveTracking,
              arguments: student.id,
            ),
          ),
        ],
      ),
    );
  }
}
