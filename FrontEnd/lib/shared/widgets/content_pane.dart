import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

/// Giới hạn bề rộng và lề của vùng nội dung.
///
/// `ContentPane` **chỉ** làm hai việc: giới hạn bề rộng và đặt lề. Nó không
/// cuộn, không dựng `AppBar`, không biết gì về thanh điều hướng — cuộn thuộc
/// về chính vùng nội dung, khung trang thuộc về `AppScaffold`.
///
/// Dùng cho nội dung **không ảo hoá**, đặt bên trong vùng cuộn:
///
/// ```dart
/// SingleChildScrollView(
///   child: ContentPane(
///     maxWidth: AppContentWidth.reading,
///     child: Column(children: [...]),
///   ),
/// )
/// ```
///
/// Đặt vùng cuộn ở **ngoài** như trên thì thanh cuộn nằm ở mép cửa sổ đúng
/// như thói quen trên web. Bọc ngược lại (`ContentPane` ngoài,
/// `SingleChildScrollView` trong) sẽ kéo thanh cuộn vào giữa màn hình.
///
/// Với danh sách ảo hoá (`ListView.builder`) thì không bọc được — bọc là mất
/// ảo hoá. Dùng [ContentPaneList].
class ContentPane extends StatelessWidget {
  const ContentPane({
    super.key,
    required this.child,
    this.maxWidth = AppContentWidth.reading,
    this.padding = AppSpacing.page,
  });

  final Widget child;

  /// Bề rộng tối đa của nội dung, **chưa tính lề**. Lấy từ [AppContentWidth].
  final double maxWidth;

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth + padding.horizontal),
        child: Padding(padding: padding, child: child),
      ),
    );
  }

  /// Lề ngang để một danh sách ảo hoá có bề rộng dòng đúng bằng [maxWidth],
  /// trong khi bản thân danh sách vẫn trải hết [available] nên thanh cuộn ở
  /// mép ngoài.
  static EdgeInsets paddingFor(
    double available, {
    double maxWidth = AppContentWidth.reading,
    EdgeInsets base = AppSpacing.page,
  }) {
    final surplus = available - base.horizontal - maxWidth;
    final side = base.left + (surplus > 0 ? surplus / 2 : 0);
    return EdgeInsets.fromLTRB(side, base.top, side, base.bottom);
  }
}

/// Giới hạn bề rộng mà **không** đụng vào cấu trúc cuộn bên trong.
///
/// Dùng cho những thân trang không phải một vùng cuộn đơn lẻ — `Column` có
/// `Expanded`, `Consumer`, `TabBarView`, hay nhánh điều kiện. Với các trường
/// hợp đó, [ContentPane] không dùng được: nó bọc thêm `Align`, và `Align`
/// truyền ràng buộc lỏng xuống dưới, làm mọi `Expanded` bên trong vỡ.
///
/// Cách làm ở đây là **chỉ thêm lề ngang**, nên ràng buộc chiều cao đi xuống
/// nguyên vẹn và không widget con nào đổi hành vi. Đổi lại, thanh cuộn nằm ở
/// mép vùng nội dung chứ không ở mép cửa sổ — chấp nhận được, và là cái giá
/// duy nhất để bọc an toàn một thân trang bất kỳ.
class ContentWidthLimit extends StatelessWidget {
  const ContentWidthLimit({
    super.key,
    required this.child,
    this.maxWidth = AppContentWidth.dashboard,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final surplus = constraints.maxWidth - maxWidth;
        if (surplus <= 0) return child;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: surplus / 2),
          child: child,
        );
      },
    );
  }
}

/// Bản dành cho danh sách ảo hoá.
///
/// Truyền `padding` đã tính vào thẳng `ListView.builder` thay vì bọc nó, nên
/// giữ được ảo hoá và giữ thanh cuộn ở mép ngoài:
///
/// ```dart
/// ContentPaneList(
///   maxWidth: AppContentWidth.dashboard,
///   builder: (context, padding) => ListView.builder(
///     padding: padding,
///     itemBuilder: ...,
///   ),
/// )
/// ```
class ContentPaneList extends StatelessWidget {
  const ContentPaneList({
    super.key,
    required this.builder,
    this.maxWidth = AppContentWidth.reading,
    this.padding = AppSpacing.page,
  });

  /// Nhận lề đã tính; trả về danh sách đã gắn lề đó.
  final Widget Function(BuildContext context, EdgeInsets padding) builder;

  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => builder(
        context,
        ContentPane.paddingFor(
          constraints.maxWidth,
          maxWidth: maxWidth,
          base: padding,
        ),
      ),
    );
  }
}
