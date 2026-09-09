import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/app/shell/app_navigation.dart';
import 'package:apphoctiengnnhat/app/theme/app_scroll_behavior.dart';
import 'package:apphoctiengnnhat/app/theme/app_tokens.dart';
import 'package:apphoctiengnnhat/shared/widgets/app_scaffold.dart';
import 'package:apphoctiengnnhat/shared/widgets/content_pane.dart';

void main() {
  group('ContentPane', () {
    test('màn hẹp giữ nguyên lề gốc, không đẩy nội dung', () {
      final padding = ContentPane.paddingFor(360);
      expect(padding.left, AppSpacing.lg);
      expect(padding.right, AppSpacing.lg);
    });

    test('màn rộng dồn phần thừa vào hai bên đều nhau', () {
      final padding = ContentPane.paddingFor(
        1920,
        maxWidth: AppContentWidth.reading,
      );
      // 1920 − 32 (lề gốc) − 720 = 1168, chia đôi mỗi bên 584, cộng lề gốc 16.
      expect(padding.left, 600);
      expect(padding.right, 600);
      expect(1920 - padding.horizontal, AppContentWidth.reading);
    });

    test('đúng tại điểm nội dung vừa khít', () {
      final padding = ContentPane.paddingFor(
        AppContentWidth.reading + AppSpacing.lg * 2,
        maxWidth: AppContentWidth.reading,
      );
      expect(padding.left, AppSpacing.lg);
    });

    testWidgets('giới hạn bề rộng thật sự chặn nội dung', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ContentPane(
                maxWidth: AppContentWidth.reading,
                child: SizedBox(height: 10, child: Placeholder()),
              ),
            ),
          ),
        ),
      );

      final width = tester.getSize(find.byType(Placeholder)).width;
      expect(width, AppContentWidth.reading);
    });
  });

  group('AppNavigation.indexOfLocation', () {
    const destinations = [
      AppDestination(
        path: '/home',
        label: 'Trang chủ',
        icon: Icons.home,
        selectedIcon: Icons.home,
      ),
      AppDestination(
        path: '/study',
        label: 'Học tập',
        icon: Icons.school,
        selectedIcon: Icons.school,
      ),
      AppDestination(
        path: '/admin',
        label: 'Quản trị',
        icon: Icons.settings,
        selectedIcon: Icons.settings,
      ),
    ];

    test('khớp chính xác đường dẫn đích đến', () {
      expect(AppNavigation.indexOfLocation(destinations, '/study'), 1);
    });

    test('trang con vẫn tô sáng đích đến cha', () {
      expect(AppNavigation.indexOfLocation(destinations, '/admin/users'), 2);
    });

    test('trang ngoài mọi đích đến không tô sáng mục nào', () {
      // `/vocabulary/abc` mở chồng lên: shell không được tô sáng nhầm.
      expect(
          AppNavigation.indexOfLocation(destinations, '/vocabulary/abc'), -1);
    });

    test('không nhận nhầm đường dẫn chỉ trùng tiền tố chuỗi', () {
      expect(AppNavigation.indexOfLocation(destinations, '/homework'), -1);
    });
  });

  group('AppScrollBehavior', () {
    test('nhận kéo bằng chuột và trackpad', () {
      const behavior = AppScrollBehavior();
      expect(behavior.dragDevices, contains(PointerDeviceKind.mouse));
      expect(behavior.dragDevices, contains(PointerDeviceKind.trackpad));
      expect(behavior.dragDevices, contains(PointerDeviceKind.touch));
    });
  });

  group('AppScaffold', () {
    testWidgets('onRefresh dựng nút bấm được, không bọc vùng cuộn', (
      tester,
    ) async {
      var refreshed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: AppScaffold(
            title: 'Từ vựng',
            onRefresh: () async => refreshed++,
            body: const SizedBox(),
          ),
        ),
      );

      // Không có `RefreshIndicator` bọc trang: kéo-để-làm-mới là việc của
      // từng danh sách, và trên desktop cử chỉ đó không tồn tại.
      expect(find.byType(RefreshIndicator), findsNothing);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();
      expect(refreshed, 1);
    });

    testWidgets('không có onRefresh thì không thêm nút thừa', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppScaffold(title: 'Từ vựng', body: SizedBox()),
        ),
      );
      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('SafeArea của body không tiêu thụ lại inset trên', (
      tester,
    ) async {
      const bodyKey = Key('body');
      await tester.pumpWidget(
        const MaterialApp(
          home: AppScaffold(title: 'Từ vựng', body: SizedBox(key: bodyKey)),
        ),
      );

      // `AppBar` đã trừ inset trên rồi; bọc thêm `SafeArea(top: true)` quanh
      // body sẽ đẩy nội dung xuống thêm một lần nữa.
      final safeArea = tester.widget<SafeArea>(
        find
            .ancestor(of: find.byKey(bodyKey), matching: find.byType(SafeArea))
            .first,
      );
      expect(safeArea.top, isFalse);
    });
  });
}
