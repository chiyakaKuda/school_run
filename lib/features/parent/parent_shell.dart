import 'package:flutter/material.dart';

import '../../shared/widgets/app_shell.dart';
import '../profile/profile_page.dart';
import 'notifications_page.dart';
import 'parent_home.dart';

/// The parent's three top-level destinations: children, alerts, profile.
///
/// Live tracking for a specific child stays a pushed screen — it only makes
/// sense in the context of the child just tapped, not as a standing tab.
class ParentShell extends StatelessWidget {
  const ParentShell({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      destinations: [
        ShellDestination(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
          label: 'Home',
          builder: (_) => const ParentHome(),
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
