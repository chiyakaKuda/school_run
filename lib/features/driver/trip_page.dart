import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../models/trip.dart';
import '../../shared/widgets/primary_button.dart';
import '../../utils/extensions.dart';

/// The active run: start/end the trip and jump to the student manifest.
class TripPage extends StatefulWidget {
  const TripPage({super.key, this.tripId});

  final String? tripId;

  @override
  State<TripPage> createState() => _TripPageState();
}

class _TripPageState extends State<TripPage> {
  // TODO: load via ApiService.get(ApiConstants.tripById(id)) and hold in a provider.
  Trip? _trip;
  bool _busy = false;

  bool get _isRunning => _trip?.isActive ?? false;

  Future<void> _toggleTrip() async {
    setState(() => _busy = true);
    // TODO: POST start/end to the backend and begin location streaming.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _trip = _trip?.copyWith(
        status: _isRunning ? TripStatus.completed : TripStatus.inProgress,
        startedAt: _isRunning ? null : DateTime.now(),
        endedAt: _isRunning ? DateTime.now() : null,
      );
    });
    context.showSnack(_isRunning ? 'Trip ended.' : 'Trip started.');
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;

    return Scaffold(
      appBar: AppBar(title: const Text('Trip')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        trip?.status.label ?? 'No active trip',
                        style: context.text.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (trip?.elapsed != null)
                        Text(
                          trip!.elapsed!.compact,
                          style: context.text.bodyMedium,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    trip == null
                        ? 'Pick a run from the home screen to begin.'
                        : '${trip.studentIds.length} students on this run',
                    style: context.text.bodyMedium
                        ?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.people_outline),
            label: const Text(AppStrings.students),
            onPressed: () => Navigator.of(context).pushNamed(
              AppRoutes.studentList,
              arguments: widget.tripId,
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: _isRunning ? AppStrings.endTrip : AppStrings.startTrip,
            icon: _isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
            busy: _busy,
            onPressed: _toggleTrip,
          ),
        ],
      ),
    );
  }
}
