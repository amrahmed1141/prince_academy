import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';

class AuthTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;

  const AuthTabBar({
    super.key,
    required this.controller,
    this.tabs = const ['Sign In', 'Sign Up', 'Admin'],
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: EColorConstants.authDarkBackground.withOpacity(0.45),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: EColorConstants.authLightPrimary.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: List.generate(tabs.length, (index) {
              final isSelected = controller.index == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => controller.animateTo(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? EColorConstants.authPrimaryGradient
                          : null,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      tabs[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.65),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
