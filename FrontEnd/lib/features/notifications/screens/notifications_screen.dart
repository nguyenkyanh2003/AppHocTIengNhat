import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../models/notification.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_tile.dart';

/// Thông báo cá nhân: lọc đã đọc/chưa đọc, chạm để đọc nội dung đầy đủ, xoá
/// từng thông báo, đánh dấu tất cả đã đọc.
///
/// Dùng [NotificationProvider] toàn app, nên chấm trên chuông Trang chủ cập
/// nhật ngay sau khi đọc hay xoá ở đây.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NotificationProvider>();
      provider.load(filter: NotificationFilter.all);
      provider.refreshUnreadCount();
    });
  }

  Future<void> _open(NotificationProvider provider, AppNotification notification) {
    provider.markAsRead(notification);
    final isBadge = notification.type == NotificationType.achievement;
    return showAppDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(notification.title),
        content: SingleChildScrollView(child: SelectableText(notification.message)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Đóng')),
          if (isBadge)
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.push('/achievements');
              },
              child: const Text('Xem thành tích'),
            ),
        ],
      ),
    );
  }

  Future<void> _refresh(NotificationProvider provider) =>
      Future.wait([provider.load(page: provider.currentPage), provider.refreshUnreadCount()]);

  void _showMessage(NotificationProvider provider) {
    final message = provider.consumeMessage();
    if (message != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  static String _emptyTitle(NotificationFilter filter) => switch (filter) {
        NotificationFilter.all => 'Chưa có thông báo nào',
        NotificationFilter.unread => 'Không có thông báo chưa đọc',
        NotificationFilter.read => 'Chưa có thông báo đã đọc',
      };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showMessage(provider);
    });

    return AppScaffold(
      title: 'Thông báo',
      onRefresh: () => _refresh(provider),
      actions: [
        IconButton(
          tooltip: 'Đánh dấu tất cả đã đọc',
          icon: const Icon(Icons.done_all),
          onPressed: provider.unreadCount > 0 && !provider.isMarkingAll ? provider.markAllAsRead : null,
        ),
      ],
      body: ContentWidthLimit(
        child: Column(
          children: [
            Padding(
              padding: AppSpacing.page,
              child: Align(
                alignment: Alignment.centerLeft,
                child: NotificationFilterBar(
                  selected: provider.filter,
                  unreadCount: provider.unreadCount,
                  onSelected: (filter) => provider.load(filter: filter),
                ),
              ),
            ),
            Expanded(
              child: AsyncView<NotificationPage>(
                state: provider.page,
                onRetry: () => provider.load(page: provider.currentPage),
                isEmpty: (page) => page.items.isEmpty,
                emptyTitle: _emptyTitle(provider.filter),
                emptyIcon: Icons.notifications_none,
                builder: (context, page) => _list(provider, page),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(NotificationProvider provider, NotificationPage page) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: AppSpacing.pageHorizontal,
            itemCount: page.items.length,
            itemBuilder: (context, index) {
              final notification = page.items[index];
              return NotificationTile(
                notification: notification,
                busy: provider.isBusy(notification.id),
                onOpen: () => _open(provider, notification),
                onDelete: () => provider.delete(notification),
              );
            },
          ),
        ),
        if (page.totalPages > 1)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Trang trước',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: page.page > 1 ? () => provider.load(page: page.page - 1) : null,
                ),
                Text('Trang ${page.page} / ${page.totalPages}'),
                IconButton(
                  tooltip: 'Trang sau',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: page.page < page.totalPages ? () => provider.load(page: page.page + 1) : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
