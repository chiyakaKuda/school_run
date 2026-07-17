import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/services/api_service.dart';
import '../../core/services/trips_repository.dart';
import '../../core/services/vehicles_repository.dart';
import '../../models/trip.dart';
import '../../models/vehicle.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../utils/extensions.dart';
import '../auth/auth_provider.dart';

/// Driver landing screen: today's runs, with the next one selected.
class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  final TripsRepository _tripsRepo = TripsRepository.instance;
  final VehiclesRepository _vehiclesRepo = VehiclesRepository.instance;

  List<Trip> _trips = const [];
  Vehicle? _vehicle;
  int _selected = 0;
  bool _loading = true;
  String? _error;

  Trip? get _trip => _trips.isEmpty ? null : _trips[_selected.clamp(0, _trips.length - 1)];

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
      // A driver's fleet is a single vehicle in this schema — there is no
      // "my vehicle" endpoint, so the first (only) row is it.
      final results = await Future.wait([_tripsRepo.list(), _vehiclesRepo.list()]);
      if (!mounted) return;

      final trips = results[0] as List<Trip>;
      final vehicles = results[1] as List<Vehicle>;

      setState(() {
        _trips = trips;
        _vehicle = vehicles.isEmpty ? null : vehicles.first;
        _selected = 0;
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

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context).user;
    final firstName = user?.name.split(' ').first ?? 'there';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _TopBar(),
            Expanded(
              child: switch ((_loading, _error, _trips.isEmpty)) {
                (true, _, _) => const LoadingWidget(),
                (false, String message, _) => EmptyState(
                    icon: Icons.wifi_off_rounded,
                    message: message,
                    onRetry: _load,
                  ),
                (false, null, true) => EmptyState(
                    icon: Icons.event_busy_rounded,
                    message: 'No runs assigned to you today.',
                    onRetry: _load,
                  ),
                (false, null, false) => RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        Text(
                          '${_greeting()},\n$firstName.',
                          style: context.text.displaySmall,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${_trip!.studentIds.length} students on your next run.',
                          style: context.text.bodyLarge
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        if (_vehicle != null) _VehicleCard(vehicle: _vehicle!),
                        const SizedBox(height: 28),
                        Text('Today\'s runs', style: context.text.titleLarge),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 158,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            itemCount: _trips.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 12),
                            itemBuilder: (context, i) => _RunCard(
                              trip: _trips[i],
                              selected: i == _selected,
                              onTap: () => setState(() => _selected = i),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        _ManifestTile(
                          count: _trip!.studentIds.length,
                          onTap: () => Navigator.of(context).pushNamed(
                            AppRoutes.studentList,
                            arguments: _trip!.id,
                          ),
                        ),
                      ],
                    ),
                  ),
              },
            ),
            if (!_loading && _error == null && _trips.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: FilledButton(
                  onPressed: () => Navigator.of(context)
                      .pushNamed(AppRoutes.trip, arguments: _trip!.id)
                      // The trip screen may have started/ended/cancelled the
                      // run; reload so the card underneath reflects it rather
                      // than showing stale state when the driver comes back.
                      .then((_) => _load()),
                  child: Text(
                    _trip!.isActive ? 'Continue trip' : 'Start trip',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Circular controls and avatar, as in the reference.
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
            // Alerts is a sibling tab inside DriverShell, not a pushed screen.
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

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.directions_bus_rounded, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vehicle.model ?? 'Vehicle',
                    style: context.text.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '${vehicle.capacity} seats',
                  style: context.text.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(vehicle.plateNumber, style: context.text.labelMedium),
          ),
        ],
      ),
    );
  }
}

/// Horizontally scrolled run card. Selected state mirrors the reference's
/// green-filled tier card.
class _RunCard extends StatelessWidget {
  const _RunCard({
    required this.trip,
    required this.selected,
    required this.onTap,
  });

  final Trip trip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = trip.direction == TripDirection.pickup
        ? 'Pickup'
        : 'Drop-off';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 168,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentContainer : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: selected ? AppColors.accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: context.text.titleMedium?.copyWith(
                color: selected ? AppColors.accent : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              trip.scheduledAt?.hhmm ?? '--:--',
              style: context.text.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${trip.studentIds.length}',
                  style: context.text.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.accent : AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.directions_bus_rounded,
                    size: 18,
                    color: selected ? AppColors.onAccent : AppColors.textPrimary,
                  ),
                ),
                if (trip.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      'Live',
                      style: context.text.labelSmall
                          ?.copyWith(color: AppColors.onAccent),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ManifestTile extends StatelessWidget {
  const _ManifestTile({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_outline_rounded, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Student manifest', style: context.text.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    '$count on this run',
                    style: context.text.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
