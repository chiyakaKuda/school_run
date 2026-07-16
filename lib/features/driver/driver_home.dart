import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/services/demo_data.dart';
import '../../models/trip.dart';
import '../../utils/extensions.dart';
import '../auth/auth_provider.dart';

/// Driver landing screen: today's runs, with the next one selected.
class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  // TODO: replace with ApiService.get(ApiConstants.trips).
  final List<Trip> _trips = DemoData.trips;
  int _selected = 0;

  Trip get _trip => _trips[_selected];

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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Text(
                    '${_greeting()},\n$firstName.',
                    style: context.text.displaySmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${_trip.studentIds.length} students on your next run.',
                    style: context.text.bodyLarge
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  const _VehicleCard(),
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
                    count: _trip.studentIds.length,
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.studentList,
                      arguments: _trip.id,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: FilledButton(
                onPressed: () => Navigator.of(context)
                    .pushNamed(AppRoutes.trip, arguments: _trip.id),
                child: Text(
                  _trip.isActive ? 'Continue trip' : 'Start trip',
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
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.notifications),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
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
  const _VehicleCard();

  @override
  Widget build(BuildContext context) {
    const vehicle = DemoData.vehicle;

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
