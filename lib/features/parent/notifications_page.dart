import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
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
  final List<AppNotification> _items = AppNotification.demo;
  final bool _loading = false;

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
        title: const Text(AppStrings.notifications),
      ),
      body: switch ((_loading, _items.isEmpty)) {
        (true, _) => const LoadingWidget(message: AppStrings.loading),
        (false, true) => const EmptyState(
            icon: Icons.notifications_none_rounded,
            message: AppStrings.noNotifications,
          ),
        (false, false) => ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: _items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
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

  /// Debug fixtures — remove alongside `DemoData`.
  static List<AppNotification> get demo => [
        AppNotification(
          id: 'n-1',
          title: 'Tanaka is on board',
          body: 'Picked up at 14 Josiah Chinamano Rd.',
          createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
        ),
        AppNotification(
          id: 'n-2',
          title: 'Bus is 6 minutes away',
          body: 'Tendai is approaching your pickup point.',
          createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
        ),
        AppNotification(
          id: 'n-3',
          title: 'Trip started',
          body: 'The morning run has begun with 5 students.',
          createdAt: DateTime.now().subtract(const Duration(minutes: 21)),
          read: true,
        ),
        AppNotification(
          id: 'n-4',
          title: 'Rufaro was dropped off',
          body: 'Arrived at Hillside Primary yesterday at 07:41.',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          read: true,
        ),
      ];
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: item.read
                  ? AppColors.surfaceVariant
                  : AppColors.accentContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_rounded,
              size: 20,
              color: item.read ? AppColors.textSecondary : AppColors.accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.title, style: context.text.titleSmall),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.createdAt.relative,
                      style: context.text.labelSmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.body,
                  style: context.text.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (!item.read) ...[
            const SizedBox(width: 10),
            Container(
              height: 8,
              width: 8,
              margin: const EdgeInsets.only(top: 6),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
