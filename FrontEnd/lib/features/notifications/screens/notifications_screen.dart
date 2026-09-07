import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../models/notification.dart';

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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Thông báo'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
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
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Không có thông báo',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
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
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.blue,
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
      color: isUnread ? Colors.blue[50] : Colors.white,
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
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(notification.ngayTao),
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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
        return Colors.blue;
      case 'exercise':
        return Colors.green;
      case 'group':
        return Colors.purple;
      case 'streak':
        return Colors.orange;
      case 'message':
        return Colors.pink;
      default:
        return Colors.grey;
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
