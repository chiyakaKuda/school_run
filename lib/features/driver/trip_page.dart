import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../core/services/demo_data.dart';
import '../../models/trip.dart';
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
  // TODO: load via ApiService.get(ApiConstants.tripById(id)).
  late Trip _trip = DemoData.trips.firstWhere(
    (t) => t.id == widget.tripId,
    orElse: () => DemoData.trips.first,
  );
  bool _busy = false;

  bool get _isRunning => _trip.isActive;

  Future<void> _toggleTrip() async {
    setState(() => _busy = true);
    // TODO: POST start/end to the backend and begin location streaming.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final wasRunning = _isRunning;
    setState(() {
      _busy = false;
      _trip = _trip.copyWith(
        status: wasRunning ? TripStatus.completed : TripStatus.inProgress,
        startedAt: wasRunning ? null : DateTime.now(),
        endedAt: wasRunning ? DateTime.now() : null,
      );
    });
    context.showSnack(wasRunning ? 'Trip ended.' : 'Trip started.');
  }

  @override
  Widget build(BuildContext context) {
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
          _trip.direction == TripDirection.pickup ? 'Pickup run' : 'Drop-off run',
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  _StatusCard(trip: _trip),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.people_outline_rounded,
                          value: '${_trip.studentIds.length}',
                          label: 'Students',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.schedule_rounded,
                          value: _trip.elapsed?.compact ?? '--',
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
                      arguments: _trip.id,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: PrimaryButton(
                label: _isRunning ? AppStrings.endTrip : AppStrings.startTrip,
                icon: _isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
                busy: _busy,
                danger: _isRunning,
                onPressed: _toggleTrip,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.trip});

  final Trip trip;

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
            DemoData.vehicle.displayName,
            style: context.text.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
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
