import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';

class AuthCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AuthCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        color: EColorConstants.authCardWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: EColorConstants.authDarkBackground.withOpacity(0.25),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: EColorConstants.authSoftGold.withOpacity(0.12),
            blurRadius: 48,
            spreadRadius: -8,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
