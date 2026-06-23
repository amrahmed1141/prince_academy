import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';

class AdminGlassNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onQrPressed;

  const AdminGlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onQrPressed,
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
                  children: List.generate(2, (index) {
                    final icon = index == 0 ? Iconsax.home_1 : Iconsax.chart;
                    final label = index == 0 ? 'Home' : 'Tracking';
                    return Expanded(
                      child: _AdminNavPillItem(
                        icon: icon,
                        label: label,
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
        _AdminQrFabButton(onPressed: onQrPressed),
      ],
    );
  }
}

class _AdminNavPillItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AdminNavPillItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

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
              icon,
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
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminQrFabButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AdminQrFabButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Material(
        color: EColorConstants.authTextDarkBrown,
        child: InkWell(
          onTap: onPressed,
          child: const SizedBox(
            width: 56,
            height: 56,
            child: Center(
              child: Icon(
                Icons.qr_code_scanner,
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