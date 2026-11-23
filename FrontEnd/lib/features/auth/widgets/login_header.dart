import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_tokens.dart';

/// Logo và lời chào ở đầu màn đăng nhập.
class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo với gradient và shadow đẹp hơn
        Container(
          width: 180,
          height: 180,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.colors.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: _buildLogoContent(context),
        ),

        const SizedBox(height: 24),

        // Tiêu đề thân thiện hơn
        Text(
          'Chào mừng trở lại!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
        ),

        const SizedBox(height: 8),

        // Mô tả
        Text(
          'Đăng nhập để tiếp tục học tiếng Nhật',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: context.colors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Logo của app; ảnh hỏng thì về icon. Không tải thử ảnh trước để kiểm có
  /// tồn tại: trên web như vậy là tải ảnh hai lần.
  Widget _buildLogoContent(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(context),
      ),
    );
  }

  /// Icon mặc định khi không có ảnh
  Widget _buildDefaultIcon(BuildContext context) {
    return Icon(
      Icons.translate, // Icon dịch thuật - liên quan đến học ngôn ngữ
      size: 80,
      color: context.colors.primary,
    );
  }
}
