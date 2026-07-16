import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../utils/extensions.dart';

/// Pickup/drop-off alerts for the parent's children.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // TODO: load via ApiService.get(ApiConstants.notifications).
  final List<AppNotification> _items = <AppNotification>[];
  final bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.notifications)),
      body: switch ((_loading, _items.isEmpty)) {
        (true, _) => const LoadingWidget(message: AppStrings.loading),
        (false, true) => const EmptyState(
            icon: Icons.notifications_none,
            message: AppStrings.noNotifications,
          ),
        (false, false) => ListView.separated(
            itemCount: _items.length,
            separatorBuilder: (_, _) => const Divider(indent: 72),
            itemBuilder: (context, i) => _NotificationTile(item: _items[i]),
          ),
      },
    );
  }
}

/// A single alert. Lives here until the backend contract is settled — move it
/// to `models/` once it has a real endpoint.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: item.read
            ? context.colors.surfaceContainerHighest
            : context.colors.primaryContainer,
        child: Icon(
          Icons.notifications_outlined,
          color: item.read
              ? context.colors.onSurfaceVariant
              : context.colors.onPrimaryContainer,
        ),
      ),
      title: Text(
        item.title,
        style: TextStyle(
          fontWeight: item.read ? FontWeight.w400 : FontWeight.w600,
        ),
      ),
      subtitle: Text(item.body),
      trailing: Text(
        item.createdAt.relative,
        style: context.text.bodySmall
            ?.copyWith(color: context.colors.onSurfaceVariant),
      ),
    );
  }
}
