import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/state/provider_reset_service.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/hub_tile.dart';
import '../providers/auth_provider.dart';

/// Ô Đăng xuất ở cuối hub Tài khoản — **chỗ duy nhất** trong app để đăng xuất.
///
/// Trước đây màn Hồ sơ và màn Cài đặt mỗi nơi có một nút riêng, làm theo hai
/// cách khác nhau (một nơi xoá dữ liệu provider, một nơi không). Gom về đây để
/// mọi lần đăng xuất đi đúng một đường: hỏi lại → xoá dữ liệu của phiên →
/// đăng xuất → về màn đăng nhập.
class LogoutTile extends StatelessWidget {
  const LogoutTile({super.key});

  @override
  Widget build(BuildContext context) {
    return HubTile(
      label: 'Đăng xuất',
      subtitle: 'Thoát khỏi tài khoản trên máy này',
      icon: Icons.logout,
      color: AppColors.error,
      labelColor: AppColors.error,
      onTap: () => _confirmAndLogout(context),
    );
  }

  Future<void> _confirmAndLogout(BuildContext context) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Xoá dữ liệu của phiên trước khi đăng xuất, để người đăng nhập sau không
    // thấy lại dữ liệu của người vừa thoát.
    ProviderResetService.resetAllProviders(context);
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    context.go('/login');
  }
}
