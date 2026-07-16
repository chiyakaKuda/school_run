import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../models/student.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../utils/extensions.dart';
import '../auth/auth_provider.dart';

/// Parent landing screen: the parent's children and their current status.
class ParentHome extends StatefulWidget {
  const ParentHome({super.key});

  @override
  State<ParentHome> createState() => _ParentHomeState();
}

class _ParentHomeState extends State<ParentHome> {
  // TODO: load via ApiService.get(ApiConstants.students, query: {'parentId': ...}).
  final List<Student> _children = <Student>[];
  final bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.parentHome),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            tooltip: AppStrings.notifications,
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.notifications),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: AppStrings.profile,
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.profile),
          ),
        ],
      ),
      body: switch ((_loading, _children.isEmpty)) {
        (true, _) => const LoadingWidget(message: AppStrings.loading),
        (false, true) => EmptyState(
            icon: Icons.child_care_outlined,
            message: user == null
                ? 'No children linked to this account yet.'
                : 'No children linked to ${user.name} yet.',
          ),
        (false, false) => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _children.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ChildCard(student: _children[i]),
            ),
          ),
      },
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(radius: 24, child: Text(student.name.initials)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: context.text.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${student.grade} • ${student.status.label}',
                    style: context.text.bodySmall
                        ?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              icon: const Icon(Icons.location_on_outlined),
              tooltip: AppStrings.liveTracking,
              onPressed: () => Navigator.of(context).pushNamed(
                AppRoutes.liveTracking,
                arguments: student.id,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
