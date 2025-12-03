import 'package:flutter/material.dart';
import '../core/responsive_helper.dart';

/// Example: Responsive Card Grid Widget
class ResponsiveCardGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;

  const ResponsiveCardGrid({
    Key? key,
    required this.children,
    this.spacing = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveCenter(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getHorizontalPadding(context),
          vertical: ResponsiveHelper.getVerticalPadding(context),
        ),
        child: GridView.count(
          crossAxisCount: ResponsiveHelper.getGridColumns(context),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: ResponsiveHelper.getCardAspectRatio(context),
          children: children,
        ),
      ),
    );
  }
}

/// Example: Responsive Text Widget
class ResponsiveText extends StatelessWidget {
  final String text;
  final bool isHeading;
  final Color? color;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;

  const ResponsiveText(
    this.text, {
    Key? key,
    this.isHeading = false,
    this.color,
    this.fontWeight,
    this.textAlign,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: isHeading
            ? ResponsiveHelper.getHeadingFontSize(context)
            : ResponsiveHelper.getBodyFontSize(context),
        color: color,
        fontWeight: fontWeight,
      ),
      textAlign: textAlign,
    );
  }
}

/// Example: Responsive Layout (Mobile/Tablet/Desktop khác nhau)
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveHelper.responsive(
      context: context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}

/// Example: Responsive Padding Widget
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final bool vertical;
  final bool horizontal;

  const ResponsivePadding({
    Key? key,
    required this.child,
    this.vertical = true,
    this.horizontal = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontal
            ? ResponsiveHelper.getHorizontalPadding(context)
            : 0,
        vertical:
            vertical ? ResponsiveHelper.getVerticalPadding(context) : 0,
      ),
      child: child,
    );
  }
}
