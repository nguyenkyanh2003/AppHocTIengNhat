import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../models/learning_goal.dart';
import '../providers/goal_provider.dart';
import '../services/goal_service.dart';
import '../widgets/goal_card.dart';
import '../widgets/goal_form_dialog.dart';

/// Mục tiêu học tập tích luỹ của tài khoản: "đạt tổng cộng N bài / từ / chữ
/// Kanji". Tiến độ do server đếm từ việc học thật (phase-2-plan A8).
///
/// Provider tạo cùng màn và huỷ khi rời màn; [service] chỉ để test truyền
/// service giả.
class LearningGoalsScreen extends StatelessWidget {
  const LearningGoalsScreen({super.key, this.service});

  final GoalService? service;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GoalProvider(service: service)..load(),
      child: const _GoalsView(),
    );
  }
}

class _GoalsView extends StatefulWidget {
  const _GoalsView();

  @override
  State<_GoalsView> createState() => _GoalsViewState();
}

class _GoalsViewState extends State<_GoalsView> {
  Future<void> _openForm(GoalProvider provider, GoalsSnapshot snapshot, {LearningGoal? goal}) {
    return showAppDialog<void>(
      context: context,
      builder: (_) => GoalFormDialog(
        goal: goal,
        counts: snapshot.counts,
        available: snapshot.available,
        onSubmit: (value) => goal == null
            ? provider.create(GoalDraft(type: value.type, target: value.target!, title: value.title, deadline: value.deadline))
            : provider.update(goal.id, GoalEdit(title: value.title, target: value.target, deadline: value.deadline)),
      ),
    );
  }

  /// Học xong quay về thì tải lại, để tiến độ vừa tăng hiện ngay.
  Future<void> _study(GoalProvider provider, LearningGoal goal) async {
    await context.push(goal.type.studyPath);
    if (mounted) await provider.load();
  }

  Future<void> _delete(GoalProvider provider, LearningGoal goal) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xoá mục tiêu?'),
        content: Text('"${goal.title}" sẽ bị xoá. Những gì bạn đã học không bị ảnh hưởng.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Xoá')),
        ],
      ),
    );
    if (confirmed == true) await provider.delete(goal);
  }

  void _showMessage(GoalProvider provider) {
    final message = provider.consumeMessage();
    if (message != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GoalProvider>();
    final snapshot = provider.state.valueOrNull;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showMessage(provider);
    });

    return AppScaffold(
      title: 'Mục tiêu học tập',
      onRefresh: provider.load,
      floatingActionButton: snapshot == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openForm(provider, snapshot),
              icon: const Icon(Icons.add),
              label: const Text('Thêm mục tiêu'),
            ),
      body: ContentWidthLimit(
        child: AsyncView<GoalsSnapshot>(
          state: provider.state,
          onRetry: provider.load,
          isEmpty: (snapshot) => snapshot.goals.isEmpty,
          emptyTitle: 'Chưa có mục tiêu nào',
          emptyMessage: 'Đặt một mốc như "Đạt 200 từ vựng" — tiến độ tự tăng khi bạn học.',
          emptyIcon: Icons.flag_outlined,
          builder: (context, snapshot) => _list(provider, snapshot),
        ),
      ),
    );
  }

  Widget _list(GoalProvider provider, GoalsSnapshot snapshot) {
    final goals = snapshot.goals;
    final done = goals.where((goal) => goal.isCompleted).length;
    final now = DateTime.now();

    return ListView(
      // Chừa chỗ cho nút nổi để thẻ cuối không bị che.
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
      children: [
        Text('Đã đạt $done/${goals.length} mục tiêu', style: Theme.of(context).textTheme.titleMedium),
        AppGap.md,
        for (final goal in goals)
          GoalCard(
            goal: goal,
            now: now,
            onStudy: () => _study(provider, goal),
            onEdit: () => _openForm(provider, snapshot, goal: goal),
            onDelete: () => _delete(provider, goal),
          ),
      ],
    );
  }
}
