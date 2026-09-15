import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../models/notification.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 0;
  String _filterStatus = 'all'; // all, read, unread

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() => _isLoading = true);
      final result = await _notificationService.getNotifications(
        page: _currentPage,
        limit: 20,
        status: _filterStatus == 'all' ? null : _filterStatus,
      );

      setState(() {
        _notifications = result['data'] ?? [];
        _totalPages = result['totalPages'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      _loadNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      _loadNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Thông báo',
      body: ContentWidthLimit(
        child: Column(
          children: [
            // Filter buttons
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterButton('Tất cả', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterButton('Chưa đọc', 'unread'),
                    const SizedBox(width: 8),
                    _buildFilterButton('Đã đọc', 'read'),
                  ],
                ),
              ),
            ),
            // Notifications list
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _notifications.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_none,
                                size: 64,
                                color: AppColors.textDisabled,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Không có thông báo',
                                style: TextStyle(
                                  fontSize: AppTypography.body,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final notification = _notifications[index];
                            return _buildNotificationItem(notification);
                          },
                        ),
            ),
            // Pagination
            if (_totalPages > 1)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _currentPage > 1
                          ? () {
                              setState(() => _currentPage--);
                              _loadNotifications();
                            }
                          : null,
                      child: const Text('Trước'),
                    ),
                    const SizedBox(width: 16),
                    Text('Trang $_currentPage / $_totalPages'),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _currentPage < _totalPages
                          ? () {
                              setState(() => _currentPage++);
                              _loadNotifications();
                            }
                          : null,
                      child: const Text('Tiếp'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, String status) {
    final isSelected = _filterStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = status;
          _currentPage = 1;
        });
        _loadNotifications();
      },
      backgroundColor: AppColors.surfaceVariant,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildNotificationItem(AppNotification notification) {
    final isUnread = notification.trangThai == 'ChuaDoc';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isUnread ? AppColors.primaryLight : Colors.white,
      child: ListTile(
        onTap: () {
          if (isUnread) {
            _markAsRead(notification.id);
          }
        },
        leading: CircleAvatar(
          backgroundColor: _getNotificationColor(notification.loai),
          child: Icon(
            _getNotificationIcon(notification.loai),
            color: Colors.white,
          ),
        ),
        title: Text(
          notification.tieuDe,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.noiDung,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: AppTypography.caption),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(notification.ngayTao),
              style: const TextStyle(fontSize: AppTypography.caption, color: AppColors.textSecondary),
            ),
          ],
        ),
        trailing: isUnread
            ? IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => _deleteNotification(notification.id),
              )
            : null,
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'achievement':
        return Icons.emoji_events;
      case 'lesson':
        return Icons.school;
      case 'exercise':
        return Icons.assignment;
      case 'group':
        return Icons.people;
      case 'streak':
        return Icons.local_fire_department;
      case 'message':
        return Icons.message;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'achievement':
        return Colors.amber;
      case 'lesson':
        return AppColors.primary;
      case 'exercise':
        return AppColors.success;
      case 'group':
        return Colors.purple;
      case 'streak':
        return AppColors.warning;
      case 'message':
        return Colors.pink;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(String? date) {
    if (date == null) return '';
    try {
      final dateTime = DateTime.parse(date);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Vừa xong';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} phút trước';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} giờ trước';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} ngày trước';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return '';
    }
  }
}
