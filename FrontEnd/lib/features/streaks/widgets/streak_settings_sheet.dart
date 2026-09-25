import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/async_view.dart';
import '../models/streak_settings.dart';
import '../providers/streak_provider.dart';

/// Mở sheet chỉnh mục tiêu ngày và nhắc học; dùng chung cho màn streak và màn
/// cài đặt.
Future<void> showStreakSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const StreakSettingsSheet(),
  );
}

/// Chọn mục tiêu XP mỗi ngày và giờ nhắc học (spec §5.1, §5.3).
class StreakSettingsSheet extends StatefulWidget {
  const StreakSettingsSheet({super.key});

  @override
  State<StreakSettingsSheet> createState() => _StreakSettingsSheetState();
}

class _StreakSettingsSheetState extends State<StreakSettingsSheet> {
  int? _goal;
  bool? _reminderEnabled;
  String? _reminderTime;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Tải sau frame đầu: tải ngay trong initState sẽ báo listener giữa lúc dựng.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<StreakProvider>();
      if (!provider.settings.hasData) provider.loadSettings();
    });
  }

  /// Giờ đang chọn, luôn là một mốc có trong danh sách — thứ hiện trên màn
  /// hình và thứ được gửi đi phải là một.
  String _selectedTime(StreakSettings settings) {
    final options = settings.reminderTimeOptions;
    final time = _reminderTime ?? settings.reminderTime;
    return options.contains(time) ? time : options.first;
  }

  Future<void> _save(StreakSettings settings) async {
    final goal = _goal ?? settings.chosenGoalXp;
    final enabled = _reminderEnabled ?? settings.reminderEnabled;
    final time = _selectedTime(settings);

    final goalChanged = goal != settings.chosenGoalXp;
    final enabledChanged = enabled != settings.reminderEnabled;
    final timeChanged = enabled && time != settings.reminderTime;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (!goalChanged && !enabledChanged && !timeChanged) {
      navigator.pop();
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await context.read<StreakProvider>().saveSettings(
          dailyGoalXp: goalChanged ? goal : null,
          reminderEnabled: enabledChanged ? enabled : null,
          reminderTime: timeChanged ? time : null,
        );
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }
    navigator.pop();
    messenger.showSnackBar(const SnackBar(content: Text('Đã lưu cài đặt.')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StreakProvider>();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: AsyncView<StreakSettings>(
          state: provider.settings,
          onRetry: provider.loadSettings,
          loading: const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          ),
          builder: (context, settings) => _form(context, settings),
        ),
      ),
    );
  }

  Widget _form(BuildContext context, StreakSettings settings) {
    final theme = Theme.of(context);
    final goal = _goal ?? settings.chosenGoalXp;
    final enabled = _reminderEnabled ?? settings.reminderEnabled;
    final time = _selectedTime(settings);
    final times = settings.reminderTimeOptions;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mục tiêu mỗi ngày', style: theme.textTheme.titleMedium),
          AppGap.sm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final option in settings.goalOptions)
                ChoiceChip(
                  label: Text('$option XP'),
                  selected: goal == option,
                  onSelected: (_) => setState(() => _goal = option),
                ),
            ],
          ),
          if (goal != settings.dailyGoalXp) ...[
            AppGap.sm,
            Text(
              'Mục tiêu mới áp dụng từ ngày mai. Hôm nay vẫn tính ${settings.dailyGoalXp} XP.',
              style: theme.textTheme.bodySmall,
            ),
          ],
          const Divider(height: AppSpacing.xxl),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Nhắc học mỗi ngày'),
            subtitle: const Text(
              'Chỉ nhắc khi bạn đang mở ứng dụng, tối đa một lần mỗi ngày trên thiết bị này.',
            ),
            value: enabled,
            onChanged: (value) => setState(() => _reminderEnabled = value),
          ),
          if (enabled) ...[
            AppGap.sm,
            DropdownButtonFormField<String>(
              value: time,
              decoration: InputDecoration(
                labelText: 'Giờ nhắc (giờ Việt Nam)',
                helperText:
                    'Trong khoảng ${settings.reminderWindowStart}–${settings.reminderWindowEnd}.',
              ),
              items: [
                for (final option in times) DropdownMenuItem(value: option, child: Text(option)),
              ],
              onChanged: (value) => setState(() => _reminderTime = value),
            ),
          ],
          if (_error != null) ...[
            AppGap.md,
            Text(_error!, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error)),
          ],
          AppGap.lg,
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : () => _save(settings),
              child: Text(_saving ? 'Đang lưu…' : 'Lưu'),
            ),
          ),
        ],
      ),
    );
  }
}
