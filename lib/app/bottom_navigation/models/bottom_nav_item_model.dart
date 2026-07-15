import 'package:flutter/material.dart';

class BottomNavItemModel {
  final IconData? icon;
  final String? assetIcon;
  final String label;

  const BottomNavItemModel({
    this.icon,
    this.assetIcon,
    required this.label,
  }) : assert(
          icon != null || assetIcon != null,
          'Provide either icon or assetIcon',
        );

  bool get hasAssetIcon => assetIcon != null;
}
