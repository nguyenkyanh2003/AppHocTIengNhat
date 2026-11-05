import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// Xây dựng nội dung logo (ảnh hoặc icon)
  Widget _buildLogoContent(BuildContext context) {
    // Thử load ảnh từ assets, nếu không có thì dùng icon
    return FutureBuilder<bool>(
      future: _checkImageExists('assets/images/logo.png'),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == true) {
          // Có ảnh logo -> hiển thị ảnh
          return ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Nếu load ảnh lỗi, fallback về icon
                return _buildDefaultIcon(context);
              },
            ),
          );
        } else {
          // Không có ảnh hoặc đang load -> dùng icon mặc định
          return _buildDefaultIcon(context);
        }
      },
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

  /// Kiểm tra xem file ảnh có tồn tại không
  Future<bool> _checkImageExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }
}
