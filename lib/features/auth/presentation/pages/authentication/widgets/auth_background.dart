import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';

class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: size.height * 0.08,
            right: -size.width * 0.15,
            child: _OutlineCircle(diameter: size.width * 0.55),
          ),
          Positioned(
            top: size.height * 0.22,
            left: -size.width * 0.2,
            child: _OutlineCircle(diameter: size.width * 0.45),
          ),
          Positioned(
            bottom: size.height * 0.12,
            right: size.width * 0.05,
            child: _OutlineCircle(diameter: size.width * 0.35),
          ),
          Positioned(
            bottom: size.height * 0.28,
            left: -size.width * 0.08,
            child: _OutlineCircle(diameter: size.width * 0.28),
          ),
        ],
      ),
    );
  }
}

class _OutlineCircle extends StatelessWidget {
  final double diameter;

  const _OutlineCircle({required this.diameter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: EColorConstants.authLightPrimary.withOpacity(0.18),
          width: 1.5,
        ),
      ),
    );
  }
}
