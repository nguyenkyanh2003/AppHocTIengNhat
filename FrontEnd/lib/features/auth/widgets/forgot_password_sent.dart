import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';

/// Đã gửi liên kết đặt lại mật khẩu tới [email].
class ForgotPasswordSentView extends StatelessWidget {
  const ForgotPasswordSentView({super.key, required this.email, required this.onResend});

  final String email;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_circle_outline, size: 60, color: context.colors.readable(AppColors.success)),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Email đã được gửi!',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.success),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Chúng tôi đã gửi liên kết đặt lại mật khẩu đến email của bạn.',
          style: textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          email,
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: context.colors.primary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Quay lại đăng nhập',
            style: TextStyle(fontSize: AppTypography.body, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextButton(onPressed: onResend, child: const Text('Không nhận được email? Gửi lại')),
      ],
    );
  }
}
