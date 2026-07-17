import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/api_service.dart';
import '../../core/services/notifications_repository.dart';
import '../../models/notification.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../utils/extensions.dart';

/// Pickup/drop-off alerts. [embedded] renders as a bottom-nav tab (a plain
/// heading, no back chevron) rather than a pushed screen — see [ProfilePage]
/// for the same convention.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationsRepository _repo = NotificationsRepository.instance;

  List<AppNotification> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _repo.list();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _markRead(AppNotification item) async {
    if (item.read) return;

    // Optimistic: the tap should feel instant, and a failed PATCH just leaves
    // the dot showing again on the next pull — not worth blocking on.
    final i = _items.indexOf(item);
    setState(() {
      if (i != -1) _items[i] = item.copyWith(read: true);
    });

    try {
      await _repo.markRead(item.id);
    } on ApiException {
      if (!mounted) return;
      setState(() {
        if (i != -1) _items[i] = item;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              leading: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              title: const Text(AppStrings.notifications),
            ),
      body: switch ((_loading, _error, _items.isEmpty)) {
        (true, _, _) => const LoadingWidget(message: AppStrings.loading),
        (false, String message, _) => EmptyState(
            icon: Icons.wifi_off_rounded,
            message: message,
            onRetry: _load,
          ),
        (false, null, true) => const EmptyState(
            icon: Icons.notifications_none_rounded,
            message: AppStrings.noNotifications,
          ),
        (false, null, false) => RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                20,
                widget.embedded ? 20 : 8,
                20,
                24,
              ),
              itemCount: _items.length + (widget.embedded ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (widget.embedded) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        AppStrings.notifications,
                        style: context.text.headlineSmall,
                      ),
                    );
                  }
                  i -= 1;
                }
                final item = _items[i];
                return _NotificationTile(
                  item: item,
                  onTap: () => _markRead(item),
                );
              },
            ),
          ),
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}
