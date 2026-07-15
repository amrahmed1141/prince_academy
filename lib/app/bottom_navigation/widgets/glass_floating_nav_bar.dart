import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/app/bottom_navigation/models/bottom_nav_item_model.dart';

/// Member bottom nav bar (without QR FAB — FAB is sibling in [NavigationBottom]).
class GlassFloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool hasQrCode;

  static const List<BottomNavItemModel> navItems = [
    BottomNavItemModel(
      assetIcon: 'assets/icons/logo.png',
      label: 'Home',
    ),
    BottomNavItemModel(icon: Iconsax.ticket, label: 'Booking'),
    BottomNavItemModel(icon: Iconsax.calendar_1, label: 'Sessions'),
    BottomNavItemModel(icon: Iconsax.user, label: 'Profile'),
  ];

  const GlassFloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.hasQrCode = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: List.generate(navItems.length, (index) {
              final item = navItems[index];
              return Expanded(
                child: _NavPillItem(
                  item: item,
                  isSelected: selectedIndex == index,
                  onTap: () => onDestinationSelected(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavPillItem extends StatelessWidget {
  const _NavPillItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final BottomNavItemModel item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unselectedColor = Colors.grey.shade500;
    final isBrandHome = item.hasAssetIcon;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: isBrandHome ? 32 : 28,
            height: isBrandHome ? 32 : 28,
            decoration: BoxDecoration(
              color: isSelected ? Colors.grey.shade200 : Colors.transparent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: isBrandHome
                ? _BrandHomeIcon(
                    assetPath: item.assetIcon!,
                    isSelected: isSelected,
                  )
                : Icon(
                    item.icon,
                    size: 18,
                    color: isSelected
                        ? EColorConstants.authTextDarkBrown
                        : unselectedColor,
                  ),
          ),
          const SizedBox(height: 1),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? EColorConstants.authTextDarkBrown
                  : unselectedColor,
              fontFamily: 'Poppins',
            ),
            child: Text(
              item.label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Home tab uses [logo.png] as the brand mark (Talabat-style).
class _BrandHomeIcon extends StatelessWidget {
  const _BrandHomeIcon({
    required this.assetPath,
    required this.isSelected,
  });

  final String assetPath;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    // Keep original logo colors; soften when unselected.
    return Opacity(
      opacity: isSelected ? 1 : 0.55,
      child: Image.asset(
        assetPath,
        width: 22,
        height: 22,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => Icon(
          Icons.home_rounded,
          size: 18,
          color: isSelected
              ? EColorConstants.authTextDarkBrown
              : Colors.grey.shade500,
        ),
      ),
    );
  }
}
