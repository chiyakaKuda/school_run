import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/router/app_router.dart';
import '../auth/auth_provider.dart';

/// Driver landing screen: today's runs and a way into the active trip.
class DriverHome extends StatelessWidget {
  const DriverHome({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.driverHome),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: AppStrings.profile,
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.profile),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Good morning${user == null ? '' : ', ${user.name.split(' ').first}'}.',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // TODO: replace with real trips from ApiService.get(ApiConstants.trips).
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: const CircleAvatar(
                child: Icon(Icons.directions_bus_rounded),
              ),
              title: const Text('Morning pickup'),
              subtitle: const Text('No trip loaded yet'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.trip),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: const CircleAvatar(child: Icon(Icons.people_outline)),
              title: const Text(AppStrings.students),
              subtitle: const Text('View the manifest for this run'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.studentList),
            ),
          ),
        ],
      ),
    );
  }
}
