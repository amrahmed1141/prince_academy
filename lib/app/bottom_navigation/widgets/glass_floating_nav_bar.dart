import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/app/bottom_navigation/models/bottom_nav_item_model.dart';

class GlassFloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const List<BottomNavItemModel> navItems = [
    BottomNavItemModel(icon: Iconsax.home_1, label: 'Home'),
    BottomNavItemModel(icon: Iconsax.ticket, label: 'Booking'),
    BottomNavItemModel(icon: Iconsax.calendar_1, label: 'Sessions'),
    BottomNavItemModel(icon: Iconsax.user, label: 'Profile'),
  ];

  const GlassFloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = EColorConstants.primaryColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withOpacity(0.55)
                : Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.10)
                  : Colors.black.withOpacity(0.06),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.4)
                    : Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (index) {
              final item = navItems[index];
              return Expanded(
                child: AnimatedBottomNavItem(
                  index: index,
                  item: item,
                  isSelected: selectedIndex == index,
                  primaryColor: primaryColor,
                  onTap: onDestinationSelected,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class AnimatedBottomNavItem extends StatelessWidget {
  final int index;
  final BottomNavItemModel item;
  final bool isSelected;
  final Color primaryColor;
  final ValueChanged<int> onTap;

  const AnimatedBottomNavItem({
    super.key,
    required this.index,
    required this.item,
    required this.isSelected,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedColor = isDark ? Colors.grey[400]! : Colors.grey[500]!;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// Icon
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.7,
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  item.icon,
                  color: isSelected ? primaryColor : unselectedColor,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 2),
            /// Label — always visible, changes color on selection
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? primaryColor : unselectedColor,
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
      ),
    );
  }
}