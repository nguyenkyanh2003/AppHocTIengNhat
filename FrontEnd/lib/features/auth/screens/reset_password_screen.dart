import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../providers/auth_provider.dart';
import '../widgets/reset_password_form.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';

/// Màn đặt lại mật khẩu mở từ link trong email.
///
/// Link có dạng `<FRONTEND_URL>/#/reset-password?token=...`; token được
/// `AppRouter.onGenerateRoute` đọc từ query và truyền vào đây. Màn hình này
/// phải mở được khi chưa đăng nhập, kể cả trong một phiên trình duyệt mới.
///
/// Token chỉ nằm trong bộ nhớ của màn hình và trong body của request đặt lại
/// mật khẩu: không ghi vào chỗ lưu access token, không cache, không log.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.token});

  final String? token;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  bool _isSubmitting = false;
  bool _succeeded = false;
  String? _errorMessage;

  bool get _hasToken => (widget.token ?? '').trim().isNotEmpty;

  Future<void> _submit(String newPassword) async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.resetPassword(
      widget.token!.trim(),
      newPassword,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      _succeeded = success;
      _errorMessage = success
          ? null
          : authProvider.error ??
              'Không đặt lại được mật khẩu. Vui lòng thử lại.';
    });
  }

  void _goToLogin() {
    context.go('/login');
  }

  void _requestNewLink() {
    context.pushReplacement('/forgot-password');
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Đặt lại mật khẩu',
      body: Center(
        child: SingleChildScrollView(
          child: ContentPane(
            maxWidth: AppContentWidth.form,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: _buildBody(context),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (!_hasToken) {
      return _StatusPanel(
        icon: Icons.link_off,
        color: Theme.of(context).colorScheme.error,
        title: 'Link không hợp lệ',
        message: 'Link đặt lại mật khẩu thiếu mã xác thực. '
            'Hãy yêu cầu gửi lại email khôi phục.',
        actionLabel: 'Gửi lại email khôi phục',
        onAction: _requestNewLink,
      );
    }

    if (_succeeded) {
      return _StatusPanel(
        icon: Icons.check_circle_outline,
        color: AppColors.success,
        title: 'Đã đổi mật khẩu',
        message: 'Mật khẩu mới đã được lưu. '
            'Hãy đăng nhập lại bằng mật khẩu vừa đặt.',
        actionLabel: 'Đăng nhập',
        onAction: _goToLogin,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Nhập mật khẩu mới',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Link khôi phục chỉ dùng được một lần và hết hạn sau 1 giờ.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        ResetPasswordForm(
          isSubmitting: _isSubmitting,
          errorMessage: _errorMessage,
          onSubmit: _submit,
        ),
        const SizedBox(height: AppSpacing.lg),
        TextButton(
          onPressed: _requestNewLink,
          child: const Text('Link đã hết hạn? Gửi lại email khôi phục'),
        ),
      ],
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 64, color: color),
        const SizedBox(height: AppSpacing.lg),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}
