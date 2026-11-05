import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';

/// Ghi nhớ đăng nhập và liên kết quên mật khẩu.
class LoginRememberRow extends StatelessWidget {
  const LoginRememberRow({
    super.key,
    required this.rememberMe,
    required this.setRememberMe,
  });

  final bool rememberMe;
  final void Function(bool value) setRememberMe;

  @override
  Widget build(BuildContext context) {
    // Wrap thay Row: màn hẹp (điện thoại 320–360px, cỡ chữ lớn) không đủ chỗ
    // cho cả hai trên một dòng, Row sẽ tràn; Wrap đẩy "Quên mật khẩu?" xuống.
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Checkbox ghi nhớ
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: rememberMe,
              onChanged: (value) {
                setRememberMe(value ?? false);
              },
            ),
            Flexible(
              child: Text(
                'Ghi nhớ đăng nhập',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),

        // Quên mật khẩu
        TextButton(
          onPressed: () {
            context.push('/forgot-password');
          },
          child: const Text('Quên mật khẩu?'),
        ),
      ],
    );
  }
}

/// Nút đăng nhập, tự hiện trạng thái đang gửi.
class LoginButton extends StatelessWidget {
  const LoginButton({
    super.key,
    required this.handleLogin,
  });

  final Future<void> Function() handleLogin;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: authProvider.isLoading
                ? null
                : const LinearGradient(
                    colors: [AppTheme.primaryColor, AppColors.authButtonEnd],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            boxShadow: authProvider.isLoading
                ? []
                : [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: ElevatedButton(
            onPressed: authProvider.isLoading ? null : handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: authProvider.isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Đăng Nhập',
                    style: TextStyle(
                      fontSize: AppTypography.subtitle,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        );
      },
    );
  }
}

/// Đường kẻ giữa nút đăng nhập và nút đăng ký.
class LoginDivider extends StatelessWidget {
  const LoginDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Hoặc',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

/// Lối sang màn đăng ký.
class LoginRegisterButton extends StatelessWidget {
  const LoginRegisterButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.primary,
          width: 2,
        ),
      ),
      child: OutlinedButton(
        onPressed: () {
          context.push('/register');
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'Tạo tài khoản mới',
          style: TextStyle(
            fontSize: AppTypography.subtitle,
            fontWeight: FontWeight.bold,
            color: context.colors.primary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
