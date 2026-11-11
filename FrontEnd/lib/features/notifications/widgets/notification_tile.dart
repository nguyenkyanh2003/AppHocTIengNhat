import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../models/notification.dart';

/// Một thông báo trong danh sách: chưa đọc thì nền nhấn và tiêu đề đậm. Nút
/// xoá có ở mọi thông báo, đã đọc hay chưa.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.busy,
    required this.onOpen,
    required this.onDelete,
  });

  final AppNotification notification;

  /// Đang đọc/xoá thông báo này — tắt nút xoá để không gửi hai lần.
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    final textTheme = Theme.of(context).textTheme;
    final type = notification.type;
    final badgeIcon = notification.badgeIcon;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      color: unread ? context.colors.primarySoft : null,
      child: ListTile(
        key: ValueKey('notification-${notification.id}'),
        onTap: onOpen,
        leading: CircleAvatar(
          backgroundColor: type.color.withValues(alpha: 0.15),
          // Thông báo huy hiệu hiện đúng biểu tượng của huy hiệu đó.
          child: badgeIcon != null
              ? ExcludeSemantics(child: Text(badgeIcon, style: const TextStyle(fontSize: AppTypography.title)))
              : Icon(type.icon, color: context.colors.readable(type.color), size: 20),
        ),
        title: Text(
          notification.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: unread ? FontWeight.bold : FontWeight.normal),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xs),
            Text(notification.message, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${type.label} · ${timeAgo(notification.createdAt, DateTime.now())}',
              style: textTheme.bodySmall,
            ),
          ],
        ),
        trailing: IconButton(
          tooltip: 'Xoá thông báo',
          icon: const Icon(Icons.delete_outline),
          onPressed: busy ? null : onDelete,
        ),
      ),
    );
  }
}

/// Bộ lọc Tất cả / Chưa đọc / Đã đọc; chip "Chưa đọc" kèm số đếm khi có.
class NotificationFilterBar extends StatelessWidget {
  const NotificationFilterBar({
    super.key,
    required this.selected,
    required this.unreadCount,
    required this.onSelected,
  });

  final NotificationFilter selected;
  final int unreadCount;
  final ValueChanged<NotificationFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        for (final filter in NotificationFilter.values)
          ChoiceChip(
            label: Text(filter == NotificationFilter.unread && unreadCount > 0
                ? '${filter.label} ($unreadCount)'
                : filter.label),
            selected: filter == selected,
            onSelected: (_) => onSelected(filter),
          ),
      ],
    );
  }
}

/// "Vừa xong", "5 phút trước"... quá một tuần thì hiện ngày theo giờ máy.
String timeAgo(DateTime time, DateTime now) {
  final difference = now.difference(time);
  if (difference.inMinutes < 1) return 'Vừa xong';
  if (difference.inHours < 1) return '${difference.inMinutes} phút trước';
  if (difference.inDays < 1) return '${difference.inHours} giờ trước';
  if (difference.inDays < 7) return '${difference.inDays} ngày trước';
  final local = time.toLocal();
  return '${local.day}/${local.month}/${local.year}';
}

extension on NotificationType {
  IconData get icon => switch (this) {
        NotificationType.system => Icons.campaign_outlined,
        NotificationType.lesson => Icons.menu_book,
        NotificationType.exam => Icons.assignment_outlined,
        NotificationType.achievement => Icons.emoji_events_outlined,
      };

  Color get color => switch (this) {
        NotificationType.system => AppColors.info,
        NotificationType.lesson => AppColors.lesson,
        NotificationType.exam => AppColors.jlpt,
        NotificationType.achievement => AppColors.accent,
      };
}
