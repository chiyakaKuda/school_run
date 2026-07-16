import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/primary_button.dart';
import '../../utils/extensions.dart';
import '../auth/auth_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.signOut),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text(AppStrings.signOut),
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
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        title: const Text(AppStrings.profile),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.accent,
                  child: Text(
                    user?.name.initials ?? '?',
                    style: context.text.headlineMedium
                        ?.copyWith(color: AppColors.onAccent),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? 'Not signed in',
                  style: context.text.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: context.text.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                if (user != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.accentContainer,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      user.role.name.capitalized,
                      style: context.text.labelMedium
                          ?.copyWith(color: AppColors.accent),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 32),
            _Group(
              children: [
                _Row(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: user?.phone ?? 'Not set',
                ),
                _Row(
                  icon: Icons.notifications_none_rounded,
                  label: AppStrings.notifications,
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.notifications),
                ),
                _Row(
                  icon: Icons.shield_outlined,
                  label: 'Privacy & safety',
                  onTap: () {},
                ),
                _Row(
                  icon: Icons.help_outline_rounded,
                  label: 'Help',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: AppStrings.signOut,
              icon: Icons.logout_rounded,
              danger: true,
              onPressed: () => _confirmLogout(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Divider(height: 1, indent: 58, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: context.text.bodyLarge)),
            if (value != null)
              Text(
                value!,
                style: context.text.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppColors.textSecondary),
            ],
          ],
        ),
      ),
    );
  }
}
