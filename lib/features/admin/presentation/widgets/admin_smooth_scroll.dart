import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Smooth, responsive scroll physics for admin tabs (works well on Android).
class AdminSmoothScrollBehavior extends ScrollBehavior {
  const AdminSmoothScrollBehavior();

  static const ScrollPhysics physics = BouncingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  );

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => physics;

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class AdminSmoothScrollView extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Future<void> Function()? onRefresh;
  final Color? refreshColor;

  const AdminSmoothScrollView({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 100),
    this.onRefresh,
    this.refreshColor,
  });

  @override
  Widget build(BuildContext context) {
    final scrollView = SingleChildScrollView(
      physics: AdminSmoothScrollBehavior.physics,
      padding: padding,
      child: child,
    );

    if (onRefresh == null) {
      return scrollView;
    }

    return RefreshIndicator(
      color: refreshColor,
      onRefresh: onRefresh!,
      child: scrollView,
    );
  }
}
