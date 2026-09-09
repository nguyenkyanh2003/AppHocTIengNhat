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
    this.loading,
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
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      ViewIdle<T>() ||
      ViewLoading<T>() =>
        loading ?? const Center(child: CircularProgressIndicator()),
      ViewFailure<T>(:final message) =>
        ErrorStateView(message: message, onRetry: onRetry),
      ViewData<T>(:final value) => isEmpty?.call(value) ?? false
          ? EmptyStateView(
              title: emptyTitle,
              message: emptyMessage,
              icon: emptyIcon,
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
            Icon(icon, size: 56, color: AppColors.textDisabled),
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
  const ErrorStateView({super.key, required this.message, this.onRetry});

  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: AppSpacing.page,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
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
