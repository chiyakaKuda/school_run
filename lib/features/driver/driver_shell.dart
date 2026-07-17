import 'package:flutter/material.dart';

import '../../shared/widgets/app_shell.dart';
import '../parent/notifications_page.dart';
import '../profile/profile_page.dart';
import 'driver_home.dart';

/// The driver's three top-level destinations: today's runs, alerts, profile.
///
/// Trip detail and the manifest stay pushed screens reached from a run card —
/// they are contextual to a selected trip, not a permanent section of the app,
/// so they do not get a tab of their own.
class DriverShell extends StatelessWidget {
  const DriverShell({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      destinations: [
        ShellDestination(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
          label: 'Home',
          builder: (_) => const DriverHome(),
        ),
        ShellDestination(
          icon: Icons.notifications_none_rounded,
          selectedIcon: Icons.notifications_rounded,
          label: 'Alerts',
          builder: (_) => const NotificationsPage(embedded: true),
        ),
        ShellDestination(
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
          label: 'Profile',
          builder: (_) => const ProfilePage(embedded: true),
        ),
      ],
    );
  }
}
