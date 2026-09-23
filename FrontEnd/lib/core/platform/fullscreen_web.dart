import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Đưa cả trang vào toàn màn hình (không chỉ thẻ video), để phụ đề và thanh
/// điều khiển do Flutter vẽ vẫn hiện.
Future<void> enterFullscreen() async {
  final root = web.document.documentElement;
  if (root == null || web.document.fullscreenElement != null) return;
  try {
    await root.requestFullscreen().toDart;
  } catch (_) {
    // Trình duyệt có thể từ chối; giao diện vẫn phủ kín cửa sổ.
  }
}

Future<void> exitFullscreen() async {
  if (web.document.fullscreenElement == null) return;
  try {
    await web.document.exitFullscreen().toDart;
  } catch (_) {}
}

/// Esc hoặc nút của trình duyệt thoát toàn màn hình mà app không hay biết;
/// lắng nghe để đóng luôn giao diện toàn màn hình.
void Function() listenFullscreenExit(void Function() onExit) {
  final listener = ((web.Event _) {
    if (web.document.fullscreenElement == null) onExit();
  }).toJS;
  web.document.addEventListener('fullscreenchange', listener);
  return () => web.document.removeEventListener('fullscreenchange', listener);
}
