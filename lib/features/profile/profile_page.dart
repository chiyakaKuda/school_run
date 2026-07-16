import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../utils/extensions.dart';
import '../auth/auth_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.logout),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await AuthScope.read(context).logout();
    if (!context.mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context).user;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profile)),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  child: Text(
                    user?.name.initials ?? '?',
                    style: context.text.titleLarge,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Not signed in',
                        style: context.text.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: context.text.bodySmall
                            ?.copyWith(color: context.colors.onSurfaceVariant),
                      ),
                      if (user != null) ...[
                        const SizedBox(height: 6),
                        Chip(
                          label: Text(user.role.name.capitalized),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.phone_outlined),
            title: const Text('Phone'),
            subtitle: Text(user?.phone ?? 'Not set'),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_none),
            title: const Text(AppStrings.notifications),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.notifications),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: context.colors.error),
            title: Text(
              AppStrings.logout,
              style: TextStyle(color: context.colors.error),
            ),
            onTap: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }
}
