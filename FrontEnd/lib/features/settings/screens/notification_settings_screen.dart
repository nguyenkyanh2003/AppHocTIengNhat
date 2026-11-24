import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../models/user_settings.dart';
import '../providers/settings_provider.dart';
import '../services/alert_feedback.dart';
import '../widgets/notification_settings_widgets.dart';

/// Ba công tắc báo tin: có báo không, có kêu không, có rung không.
///
/// Đọc và sửa bản cài đặt chung của app ([SettingsProvider]): đổi là lưu ngay
/// và có tác dụng ngay với lời báo huy hiệu, nhắc học và thông báo mới.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Bản chung tải khi đăng nhập; tải hỏng (mất mạng) thì mở màn là lúc thử lại.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SettingsProvider>();
      if (mounted && !provider.isLoaded && !provider.state.isLoading) provider.load();
    });
  }

  Future<void> _change(UserSettings Function(UserSettings current) edit) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<SettingsProvider>().change(edit);
    if (error == null) return;
    messenger.showSnackBar(SnackBar(
      content: Text('Chưa lưu được cài đặt: $error'),
      backgroundColor: AppColors.errorStrong,
    ));
  }

  void _tryAlert(UserSettings settings) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Thông báo thử: tin mới sẽ hiện như thế này.'),
      ));
    context.read<AlertFeedback>().alert(settings);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    return AppScaffold(
      title: 'Cài đặt thông báo',
      body: ContentWidthLimit(
        child: AsyncView<UserSettings>(
          state: provider.state,
          onRetry: provider.load,
          builder: (context, settings) => ListView(
            padding: AppSpacing.page,
            children: [
              NotificationStatusCard(enabled: settings.notificationsEnabled, saving: provider.isSaving),
              AppGap.lg,
              NotificationSwitches(
                settings: settings,
                onNotifications: (value) => _change((current) => current.copyWith(notificationsEnabled: value)),
                onSound: (value) => _change((current) => current.copyWith(soundEnabled: value)),
                onVibrate: (value) => _change((current) => current.copyWith(vibrateEnabled: value)),
              ),
              AppGap.lg,
              OutlinedButton.icon(
                onPressed: settings.notificationsEnabled ? () => _tryAlert(settings) : null,
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Gửi thông báo thử'),
              ),
              AppGap.xl,
              const NotificationScopeNote(),
            ],
          ),
        ),
      ),
    );
  }
}
