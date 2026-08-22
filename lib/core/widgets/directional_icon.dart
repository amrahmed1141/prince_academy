import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/// Iconsax arrows set [IconData.matchTextDirection], so RTL flips them.
/// Use these helpers so back / forward glyphs match the desired side.
abstract final class DirectionalIcons {
  /// AppBar / page back — `<` in LTR, `>` in RTL.
  static IconData back(BuildContext context) {
    return Directionality.of(context) == TextDirection.rtl
        ? Iconsax.arrow_right_2
        : Iconsax.arrow_left_2;
  }

  /// Trailing "go" chevron — keep visual `>` in both directions (no mirror).
  static const IconData forwardFixed = Iconsax.arrow_right_3;

  /// Material-style trailing that points toward the end edge.
  static IconData forward(BuildContext context) {
    return Directionality.of(context) == TextDirection.rtl
        ? Iconsax.arrow_left_3
        : Iconsax.arrow_right_3;
  }
}

/// [Icon] that never mirrors under RTL (for fixed `>` chevrons).
class FixedDirectionIcon extends StatelessWidget {
  const FixedDirectionIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
  });

  final IconData icon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: color,
      textDirection: TextDirection.ltr,
    );
  }
}
