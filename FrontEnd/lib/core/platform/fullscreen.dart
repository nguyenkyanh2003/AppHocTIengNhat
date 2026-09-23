/// Bật / tắt chế độ toàn màn hình của hệ điều hành hoặc trình duyệt.
///
/// Web gọi Fullscreen API của trình duyệt; Android / iOS ẩn thanh hệ thống và
/// xoay ngang. Giao diện toàn màn hình vẫn do Flutter vẽ, ở đây chỉ lo phần
/// "chiếm hết màn hình thật".
export 'fullscreen_stub.dart'
    if (dart.library.io) 'fullscreen_io.dart'
    if (dart.library.js_interop) 'fullscreen_web.dart';
