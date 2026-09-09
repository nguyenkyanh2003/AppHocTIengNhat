import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Cho phép kéo vùng cuộn bằng chuột và trackpad.
///
/// Mặc định Flutter chỉ nhận kéo bằng ngón tay và bút. Trên web/desktop, điều
/// đó làm mọi thứ vốn "vuốt để chuyển" trở thành bất động: `PageView` của màn
/// học thẻ, học bài và làm bài tập, cùng `TabBarView` của sáu màn khác.
///
/// Sửa một lần ở `MaterialApp.scrollBehavior` thay vì bọc `ScrollConfiguration`
/// quanh từng widget — mọi vùng cuộn trong ứng dụng đều nhận cùng một luật.
///
/// Đây là lối vào **thứ hai**, không phải lối duy nhất: thao tác nào chỉ có
/// đường vuốt vẫn phải có nút hoặc phím bấm được, vì kéo bằng chuột không hiện
/// ra cho người dùng thấy.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}
