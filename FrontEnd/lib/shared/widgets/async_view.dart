import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../core/state/view_state.dart';

/// Hiển thị một [ViewState] với đủ bốn nhánh: đang tải, lỗi, rỗng, có dữ liệu.
///
/// Trước đây mỗi màn hình tự viết `if (isLoading) ... else if (error != null)`,
/// nên trạng thái rỗng và lỗi mỗi nơi một kiểu. Mọi màn hình mới phải đi qua
/// widget này thay vì dựng lại các nhánh đó.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.state,
    required this.builder,
    this.onRetry,
    this.isEmpty,
    this.emptyTitle = 'Chưa có dữ liệu',
    this.emptyMessage,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyAction,
    this.loading,
    this.compact = false,
  });

  final ViewState<T> state;
  final Widget Function(BuildContext context, T value) builder;

  /// Gọi lại khi người dùng bấm "Thử lại" ở nhánh lỗi.
  final Future<void> Function()? onRetry;

  /// Cho biết dữ liệu tuy có nhưng rỗng (danh sách không phần tử...).
  final bool Function(T value)? isEmpty;

  final String emptyTitle;
  final String? emptyMessage;
  final IconData emptyIcon;

  /// Nút gợi ý việc làm tiếp ở trạng thái rỗng.
  final Widget? emptyAction;
  final Widget? loading;

  /// Một khối trong trang cuộn, không phải cả màn: tải và lỗi gọn lại để các khối
  /// khác vẫn dùng được. Mỗi khối theo dõi dữ liệu riêng, nên một API hỏng không
  /// làm khối khác hiện số 0 hay "chưa có dữ liệu".
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      ViewIdle<T>() || ViewLoading<T>() => loading ??
          (compact
              ? const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const Center(child: CircularProgressIndicator())),
      ViewFailure<T>(:final message) => ErrorStateView(
          message: message,
          onRetry: onRetry,
          compact: compact,
        ),
      ViewData<T>(:final value) => isEmpty?.call(value) ?? false
          ? EmptyStateView(
              title: emptyTitle,
              message: emptyMessage,
              icon: emptyIcon,
              action: emptyAction,
            )
          : builder(context, value),
    };
  }
}

/// Trạng thái rỗng dùng chung.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: AppSpacing.page,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: context.colors.textDisabled),
            AppGap.lg,
            Text(
              title,
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              AppGap.sm,
              Text(
                message!,
                style: textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[AppGap.lg, action!],
          ],
        ),
      ),
    );
  }
}

/// Trạng thái lỗi dùng chung, luôn kèm lối thoát cho người dùng.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.message,
    this.onRetry,
    this.compact = false,
  });

  final String message;
  final Future<void> Function()? onRetry;

  /// Xem [AsyncView.compact].
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (compact) {
      return Container(
        padding: AppSpacing.card,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: AppRadius.mdAll,
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: context.colors.error),
            AppGap.md,
            Expanded(child: Text(message, style: textTheme.bodyMedium)),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: AppSpacing.page,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: context.colors.error),
            AppGap.lg,
            Text(
              message,
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              AppGap.lg,
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
