import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';

/// Đầu trang màn Đổi mật khẩu.
class ChangePasswordHeader extends StatelessWidget {
  const ChangePasswordHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bảo mật tài khoản',
            style: TextStyle(
              fontSize: AppTypography.title,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đổi mật khẩu thường xuyên để bảo vệ tài khoản của bạn',
            style: TextStyle(
              fontSize: AppTypography.bodySmall,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Hộp báo lỗi đặt ngay trong biểu mẫu.
class FormErrorBox extends StatelessWidget {
  const FormErrorBox({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: context.colors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Danh sách yêu cầu mật khẩu, đánh dấu từng điều đã đạt.
class PasswordRequirements extends StatelessWidget {
  const PasswordRequirements({super.key, required this.rules});

  /// Mỗi điều gồm nội dung và đã đạt hay chưa.
  final List<(String, bool)> rules;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yêu cầu mật khẩu:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppTypography.caption,
            ),
          ),
          const SizedBox(height: 8),
          for (final (text, isMet) in rules) _buildRule(context, text, isMet),
        ],
      ),
    );
  }

  Widget _buildRule(BuildContext context, String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isMet ? AppColors.success : context.colors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: isMet ? AppColors.success : context.colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
