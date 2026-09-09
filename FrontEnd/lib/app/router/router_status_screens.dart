import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/content_pane.dart';
import '../theme/app_tokens.dart';

/// Màn chờ trong lúc khôi phục phiên đăng nhập.
///
/// Chỉ hiện khi `AuthProvider.sessionRestored` còn `false`. Nó **không** gắn
/// với `isLoading` — mọi thao tác khác (đổi mật khẩu, cập nhật hồ sơ) cũng bật
/// `isLoading`, và không thao tác nào trong số đó được phép kéo người dùng về
/// màn chờ.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

/// Trang cho URL không khớp route nào.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, this.location});

  final String? location;

  @override
  Widget build(BuildContext context) {
    return _StatusPage(
      icon: Icons.link_off,
      color: AppColors.warning,
      title: 'Không tìm thấy trang',
      message: location == null
          ? 'Đường dẫn này không tồn tại.'
          : 'Đường dẫn "$location" không tồn tại.',
    );
  }
}

/// Trang cho route đòi quyền mà tài khoản hiện tại không có.
class ForbiddenScreen extends StatelessWidget {
  const ForbiddenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _StatusPage(
      icon: Icons.lock_outline,
      color: AppColors.error,
      title: 'Không có quyền truy cập',
      message: 'Trang này chỉ dành cho quản trị viên.',
    );
  }
}

class _StatusPage extends StatelessWidget {
  const _StatusPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: ContentPane(
            maxWidth: AppContentWidth.form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppGap.xl,
                Icon(icon, size: 64, color: color),
                AppGap.lg,
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                AppGap.sm,
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                AppGap.xl,
                FilledButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Về trang chủ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
