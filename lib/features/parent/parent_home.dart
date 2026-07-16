import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/services/demo_data.dart';
import '../../models/student.dart';
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
  // TODO: load via ApiService.get(ApiConstants.students, query: {'parentId': ...}).
  final List<Student> _children = DemoData.myChildren;
  final bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context).user;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(initials: user?.name.initials ?? '?'),
            Expanded(
              child: switch ((_loading, _children.isEmpty)) {
                (true, _) => const LoadingWidget(),
                (false, true) => const EmptyState(
                    icon: Icons.child_care_outlined,
                    message: 'No children linked to this account yet.',
                  ),
                (false, false) => ListView(
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
                      const _DriverStrip(),
                      const SizedBox(height: 28),
                      Text('My children', style: context.text.titleLarge),
                      const SizedBox(height: 14),
                      for (final child in _children) ...[
                        _ChildCard(student: child),
                        const SizedBox(height: 10),
                      ],
                    ],
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
  const _TopBar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
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
                initials,
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
class _DriverStrip extends StatelessWidget {
  const _DriverStrip();

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
            child: Text(
              DemoData.driver.name.initials,
              style: context.text.labelLarge,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DemoData.driver.name, style: context.text.titleMedium),
                const SizedBox(height: 2),
                Text(
                  DemoData.vehicle.displayName,
                  style: context.text.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded,
                    size: 14, color: AppColors.warning),
                const SizedBox(width: 4),
                Text('4.9', style: context.text.labelSmall),
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
