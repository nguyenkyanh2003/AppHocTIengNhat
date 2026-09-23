Future<void> enterFullscreen() async {}

Future<void> exitFullscreen() async {}

/// Gọi [onExit] khi người dùng tự thoát toàn màn hình từ bên ngoài app.
/// Trả về hàm huỷ đăng ký.
void Function() listenFullscreenExit(void Function() onExit) => () {};
