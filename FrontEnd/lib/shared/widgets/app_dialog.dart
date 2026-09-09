import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Mở hộp thoại với hành vi bàn phím đúng trên mọi nền tảng.
///
/// `showDialog` của Flutter gắn Esc vào **cùng một công tắc** với việc bấm ra
/// ngoài: đặt `barrierDismissible: false` để biểu mẫu khỏi mất dữ liệu khi lỡ
/// bấm nhầm thì cũng chặn luôn Esc, và người chỉ dùng bàn phím bị mắc kẹt
/// trong hộp thoại.
///
/// Hàm này tách hai thứ đó ra:
///
/// - [dismissOnBarrierTap] quyết định bấm ra ngoài có đóng không.
/// - Esc **luôn** đóng được.
///
/// Trên desktop và web, Esc là cách đóng hộp thoại mà ai cũng thử đầu tiên,
/// nên nó không được phép phụ thuộc vào lựa chọn về con chuột.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool dismissOnBarrierTap = true,
  bool useRootNavigator = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: dismissOnBarrierTap,
    useRootNavigator: useRootNavigator,
    builder: (dialogContext) {
      if (dismissOnBarrierTap) return builder(dialogContext);

      // `barrierDismissible: false` đã gỡ `DismissIntent` khỏi route, nên gắn
      // lại Esc ở đây thay vì bật lại cả việc bấm ra ngoài.
      return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.of(dialogContext).maybePop(),
        },
        child: Focus(autofocus: true, child: builder(dialogContext)),
      );
    },
  );
}
