import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Edge bounce + snappy fling/overscroll (works well on Android).
///
/// Stock [BouncingScrollPhysics] doubles the fling threshold and feels sluggish.
class FastBounceScrollPhysics extends BouncingScrollPhysics {
  const FastBounceScrollPhysics({super.parent});

  @override
  FastBounceScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return FastBounceScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(
        mass: 0.28,
        stiffness: 520,
        ratio: 1.05,
      );

  @override
  double get minFlingVelocity => kMinFlingVelocity * 0.55;

  @override
  double get dragStartDistanceMotionThreshold => 1.5;
}

/// Smooth, responsive scroll physics for admin tabs (works well on Android).
class AdminSmoothScrollBehavior extends ScrollBehavior {
  const AdminSmoothScrollBehavior();

  static const ScrollPhysics physics = FastBounceScrollPhysics(
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
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
