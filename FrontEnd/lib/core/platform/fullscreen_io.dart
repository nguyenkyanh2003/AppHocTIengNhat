import 'package:flutter/services.dart';

Future<void> enterFullscreen() async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
}

Future<void> exitFullscreen() async {
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: SystemUiOverlay.values,
  );
  // Danh sách rỗng = trả về hướng xoay mặc định của app.
  await SystemChrome.setPreferredOrientations(const []);
}

/// Trên thiết bị, thoát toàn màn hình luôn đi qua nút trong app hoặc nút Back
/// (Navigator tự xử lý), nên không có gì để lắng nghe.
void Function() listenFullscreenExit(void Function() onExit) => () {};
