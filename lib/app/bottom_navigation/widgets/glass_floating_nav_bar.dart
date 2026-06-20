import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/app/bottom_navigation/models/bottom_nav_item_model.dart';

class GlassFloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onQrPressed;
  final bool hasQrCode;
  final bool isQrLoading;

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
    required this.onQrPressed,
    this.hasQrCode = false,
    this.isQrLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: ClipRRect(
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
          ),
        ),
        const SizedBox(width: 12),
        _QrFabButton(
          onPressed: onQrPressed,
          hasQrCode: hasQrCode,
          isLoading: isQrLoading,
        ),
      ],
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
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isSelected ? Colors.grey.shade200 : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
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

class _QrFabButton extends StatelessWidget {
  const _QrFabButton({
    required this.onPressed,
    required this.hasQrCode,
    required this.isLoading,
  });

  final VoidCallback onPressed;
  final bool hasQrCode;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Material(
        color: EColorConstants.authTextDarkBrown,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.qr_code_2_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
