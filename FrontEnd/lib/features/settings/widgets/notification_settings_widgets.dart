import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../models/user_settings.dart';

/// Trạng thái tổng: thông báo đang bật hay tắt, và đang lưu thay đổi.
class NotificationStatusCard extends StatelessWidget {
  const NotificationStatusCard({super.key, required this.enabled, required this.saving});

  final bool enabled;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.colors.primarySoft,
        borderRadius: AppRadius.lgAll,
      ),
      child: Column(
        children: [
          Icon(
            enabled ? Icons.notifications_active : Icons.notifications_off_outlined,
            size: 52,
            color: enabled ? context.colors.primary : context.colors.textSecondary,
          ),
          AppGap.md,
          Text(
            enabled ? 'Thông báo đang bật' : 'Thông báo đang tắt',
            style: const TextStyle(fontSize: AppTypography.title, fontWeight: FontWeight.bold),
          ),
          AppGap.xs,
          // Giữ chỗ cố định để thẻ không nhảy khi dòng "đang lưu" hiện rồi tắt.
          SizedBox(
            height: AppSpacing.lg,
            child: saving
                ? Text('Đang lưu…', style: TextStyle(color: context.colors.textSecondary))
                : null,
          ),
        ],
      ),
    );
  }
}

/// Ba công tắc. Tắt "Nhận thông báo" thì hai công tắc kia không còn tác dụng
/// nên mờ đi, nhưng vẫn giữ lựa chọn để bật lại là như cũ.
class NotificationSwitches extends StatelessWidget {
  const NotificationSwitches({
    super.key,
    required this.settings,
    required this.onNotifications,
    required this.onSound,
    required this.onVibrate,
  });

  final UserSettings settings;
  final ValueChanged<bool> onNotifications;
  final ValueChanged<bool> onSound;
  final ValueChanged<bool> onVibrate;

  @override
  Widget build(BuildContext context) {
    final enabled = settings.notificationsEnabled;
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Nhận thông báo'),
            subtitle: const Text('Báo ngay khi có huy hiệu mới, đến giờ nhắc học hay có thông báo mới.'),
            value: enabled,
            onChanged: onNotifications,
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up_outlined),
            title: const Text('Âm thanh'),
            subtitle: const Text('Phát âm báo ngắn kèm mỗi lời báo. Máy để im lặng thì không kêu.'),
            value: settings.soundEnabled,
            onChanged: enabled ? onSound : null,
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: const Text('Rung'),
            subtitle: const Text('Rung nhẹ kèm mỗi lời báo (trên điện thoại).'),
            value: settings.vibrateEnabled,
            onChanged: enabled ? onVibrate : null,
          ),
        ],
      ),
    );
  }
}

/// Nói rõ ba công tắc tác động tới những gì, để người dùng không đoán.
class NotificationScopeNote extends StatelessWidget {
  const NotificationScopeNote({super.key});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: context.colors.textSecondary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ứng dụng báo khi:', style: style.copyWith(fontWeight: FontWeight.bold)),
        AppGap.xs,
        Text('• Bạn vừa nhận huy hiệu mới.', style: style),
        Text('• Đến giờ nhắc học mà hôm nay bạn chưa học (giờ nhắc chỉnh ở Mục tiêu và nhắc học).', style: style),
        Text('• Quản trị viên hoặc nhóm học gửi thông báo mới cho bạn.', style: style),
        AppGap.sm,
        Text(
          'Tắt "Nhận thông báo" thì không lời báo nào bật lên; thông báo vẫn được giữ trong màn Thông báo để bạn xem sau.',
          style: style,
        ),
      ],
    );
  }
}
