import 'package:flutter/material.dart';

/// Hộp thoại trợ giúp.
void showSettingsHelpDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Trợ giúp & Phản hồi'),
      content: const Text(
        'Để được hỗ trợ, vui lòng liên hệ:\n\n'
        'Email: support@apphoctiengnhat.com\n'
        'Điện thoại: 1900-xxxx\n\n'
        'Hoặc gửi phản hồi qua ứng dụng.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );
}

/// Hộp thoại chính sách riêng tư.
void showSettingsPrivacyDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Chính sách riêng tư'),
      content: const SingleChildScrollView(
        child: Text(
          'Chúng tôi cam kết bảo vệ dữ liệu cá nhân của bạn.\n\n'
          '1. Dữ liệu của bạn được mã hóa và bảo vệ\n'
          '2. Chúng tôi không bao giờ chia sẻ thông tin cá nhân\n'
          '3. Bạn có quyền truy cập, chỉnh sửa dữ liệu của mình\n\n'
          'Xem chi tiết tại website của chúng tôi.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );
}

/// Hộp thoại giới thiệu ứng dụng.
void showSettingsAboutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Về ứng dụng'),
      content: const Text(
        'App Học Tiếng Nhật\n'
        'Phiên bản: 1.0.0\n\n'
        'Giúp bạn học tiếng Nhật một cách hiệu quả và vui vẻ.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );
}
