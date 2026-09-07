import 'package:flutter/material.dart';

/// Helper class để xử lý responsive design
class ResponsiveHelper {
  /// Breakpoints chuẩn
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Kiểm tra device type
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  /// Get số cột cho grid dựa trên screen size
  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakpoint) return 4;
    if (width >= tabletBreakpoint) return 3;
    if (width >= mobileBreakpoint) return 2;
    return 2;
  }

  /// Get padding dựa trên screen size
  static double getHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakpoint) return 64;
    if (width >= tabletBreakpoint) return 32;
    return 16;
  }

  static double getVerticalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= tabletBreakpoint) return 24;
    return 16;
  }

  /// Get font size dựa trên screen size
  static double getHeadingFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= tabletBreakpoint) return 28;
    return 20;
  }

  static double getBodyFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= tabletBreakpoint) return 16;
    return 14;
  }

  /// Get aspect ratio cho cards
  static double getCardAspectRatio(BuildContext context) {
    if (isDesktop(context)) return 1.8;
    if (isTablet(context)) return 1.7;
    return 1.6;
  }

  /// Widget responsive với builder khác nhau cho từng platform
  static Widget responsive({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    return mobile;
  }

  /// Get max width cho content container (web)
  static double getMaxContentWidth(BuildContext context) {
    if (isDesktop(context)) return 1200;
    if (isTablet(context)) return 900;
    return double.infinity;
  }
}

/// Widget wrapper để center content trên web
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const ResponsiveCenter({
    Key? key,
    required this.child,
    this.maxWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? ResponsiveHelper.getMaxContentWidth(context),
        ),
        child: child,
      ),
    );
  }
}
