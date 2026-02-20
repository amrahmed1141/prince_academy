
import 'package:flutter/material.dart';

class EColorConstants {
  // Basic colors
  static const Color primaryColor = Color(0xFF96652A);
  static const Color secondaryColor = Color(0xFF03DAC6);

    // Dark grey color
  static const Color darkGrey = Color(0xFF2E2E2E);

  // Light color
  static const Color lightColor = Color(0xFFF6F6F6); // White

  // Dark color
  static const Color darkColor = Color(0xFF272727);
    // Black


  // Light mode colors
  static const Color lightContainerColor = Color(0xFFFFFFFF);
  static const Color lightBorderColor = Color(0xFFE0E0E0);
  static const Color lightBackgroundColor = Color(0xFFF5F5F5);
  static const Color lightTextColor = Color(0xFF000000);
  static const Color lightErrorColor = Color(0xFFB00020);
  static const Color lightValidationColor = Color(0xFF00C853);

  // Dark mode colors
  static const Color darkContainerColor = Color(0xFF121212);
  static const Color darkBorderColor = Color(0xFF373737);
  static const Color darkBackgroundColor = Color(0xFF303030);
  static const Color darkTextColor = Color(0xFFFFFFFF);
  static const Color darkErrorColor = Color(0xFFCF6679);
  static const Color darkValidationColor = Color(0xFF00E676);

  // Method to get container color based on theme mode
  static Color getContainerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkContainerColor
        : lightContainerColor;
  }

  // Method to get border color based on theme mode
  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBorderColor
        : lightBorderColor;
  }

  // Method to get background color based on theme mode
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackgroundColor
        : lightBackgroundColor;
  }

  // Method to get text color based on theme mode
  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextColor
        : lightTextColor;
  }

  // Method to get error color based on theme mode
  static Color getErrorColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkErrorColor
        : lightErrorColor;
  }

  // Method to get validation color based on theme mode
  static Color getValidationColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkValidationColor
        : lightValidationColor;
  }
}
