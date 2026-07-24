import 'package:flutter/material.dart';

class EColorConstants {
  // Basic colors
  static const Color primaryColor = Color(0xFF96652A);
  static const Color secondaryColor = Color(0xFF03DAC6);

  // Prince MMA auth palette
  static const Color authDarkBackground = Color(0xFF2B1808);
  static const Color authDeepPrimary = Color(0xFF5F3A14);
  static const Color authLightPrimary = Color(0xFFC18A45);
  static const Color authSoftGold = Color(0xFFD6A85C);
  static const Color authCardWhite = Color(0xFFFFFFFF);
  static const Color authFieldBackground = Color(0xFFF7F4EF);
  static const Color authFieldBorder = Color(0xFFE4C7A5);
  static const Color authTextDarkBrown = Color(0xFF4A2A0D);
  static const Color authPlaceholderGray = Color(0xFF8E8E93);

  static const LinearGradient authBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [authDarkBackground, primaryColor, authDeepPrimary],
  );

  static const LinearGradient authPrimaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [authLightPrimary, primaryColor, authDeepPrimary],
  );

  static const Color darkGrey = Color(0xFF2E2E2E);

  // Light color
  static const Color lightColor = Color(0xFFF6F6F6);

  static const Color lightContainerColor = Color(0xFFFFFFFF);
  static const Color lightBorderColor = Color(0xFFE0E0E0);
  static const Color lightBackgroundColor = Color(0xFFF5F5F5);
  static const Color lightTextColor = Color(0xFF000000);
  static const Color lightErrorColor = Color(0xFFB00020);
  static const Color lightValidationColor = Color(0xFF00C853);

  static Color getContainerColor(BuildContext context) => lightContainerColor;

  static Color getBorderColor(BuildContext context) => lightBorderColor;

  static Color getBackgroundColor(BuildContext context) => lightBackgroundColor;

  static Color getTextColor(BuildContext context) => lightTextColor;

  static Color getErrorColor(BuildContext context) => lightErrorColor;

  static Color getValidationColor(BuildContext context) => lightValidationColor;
}
