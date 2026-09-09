import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../theme/app_tokens.dart';
import 'app_navigation.dart';

/// Khung điều hướng chính, đổi hình dạng theo bề rộng **cửa sổ**.
///
/// | Bề rộng cửa sổ | Hình dạng |
/// | --- | --- |
/// | `< AppBreakpoints.rail` | `NavigationBar` ở dưới |
/// | `>= AppBreakpoints.rail` | `NavigationRail` thu gọn |
/// | `>= AppBreakpoints.railExtended` | `NavigationRail` mở rộng, có nhãn |
///
/// ## Vì sao dùng `MediaQuery` ở đây mà `ContentPane` lại dùng `LayoutBuilder`
///
/// Hai câu hỏi khác nhau. "Cửa sổ này nên có rail hay thanh dưới?" là câu hỏi
/// về **cửa sổ** — `MediaQuery.sizeOf` trả lời đúng. "Vùng nội dung còn lại
/// rộng bao nhiêu sau khi rail đã chiếm chỗ?" là câu hỏi về **ràng buộc bố
/// cục** — chỉ `LayoutBuilder` biết, vì bề rộng cửa sổ không trừ đi rail.
/// Dùng `MediaQuery` cho câu hỏi thứ hai sẽ tính thừa đúng bằng bề rộng rail.
///
/// ## Trách nhiệm
///
/// Shell **không** dựng `AppBar`, không bọc `SafeArea` quanh trang và không
/// giới hạn bề rộng nội dung. Trang do `AppScaffold` dựng, bề rộng do
/// `ContentPane` quyết.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  void _onSelect(BuildContext context, AppDestination destination) {
    // `go` chứ không `push`: đây là chuyển nhánh điều hướng chính, không phải
    // mở thêm một trang chồng lên. `push` sẽ chất đống lịch sử mỗi lần bấm
    // qua lại giữa các đích đến.
    context.go(destination.path);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select<AuthProvider, bool>((a) => a.isAdmin);
    final destinations = AppNavigation.visibleDestinations(
      context,
      isAdmin: isAdmin,
    );
    final location = GoRouterState.of(context).uri.path;
    final index = AppNavigation.indexOfLocation(destinations, location);

    final width = MediaQuery.sizeOf(context).width;
    if (width < AppBreakpoints.rail) {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: index < 0 ? 0 : index,
          onDestinationSelected: (i) => _onSelect(context, destinations[i]),
          // Quá 5 đích đến thì nhãn luôn hiện sẽ bị cắt trên máy 360px; chỉ
          // hiện nhãn của mục đang chọn giữ được chữ đọc được.
          labelBehavior: destinations.length > 5
              ? NavigationDestinationLabelBehavior.onlyShowSelected
              : NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
          ],
        ),
      );
    }

    final extended = width >= AppBreakpoints.railExtended;
    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            right: false,
            child: _AdaptiveRail(
              destinations: destinations,
              selectedIndex: index,
              extended: extended,
              onSelect: (i) => _onSelect(context, destinations[i]),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// `NavigationRail` cuộn được khi cửa sổ thấp.
///
/// `NavigationRail` tự nó không cuộn: với 6 đích đến trên một cửa sổ thấp
/// (hoặc khi người dùng phóng to cỡ chữ hệ thống) nó tràn và báo lỗi bố cục.
/// `IntrinsicHeight` + `ConstrainedBox(minHeight: viewport)` là cách dựng
/// chuẩn để rail giãn hết chiều cao khi còn chỗ và cuộn khi hết chỗ.
class _AdaptiveRail extends StatelessWidget {
  const _AdaptiveRail({
    required this.destinations,
    required this.selectedIndex,
    required this.extended,
    required this.onSelect,
  });

  final List<AppDestination> destinations;
  final int selectedIndex;
  final bool extended;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: NavigationRail(
              extended: extended,
              minExtendedWidth: AppBreakpoints.railExtendedWidth,
              // `selectedIndex: null` khi trang hiện tại không thuộc đích đến
              // nào, để rail không tô sáng nhầm mục.
              selectedIndex: selectedIndex < 0 ? null : selectedIndex,
              onDestinationSelected: onSelect,
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
