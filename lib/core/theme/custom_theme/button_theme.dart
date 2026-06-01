import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';

class EEelevatedButtonTheme {
  EEelevatedButtonTheme._();

  static final lightElevatedTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: EColorConstants.primaryColor,
      foregroundColor: Colors.white,
      disabledBackgroundColor: Colors.grey,
      disabledForegroundColor: Colors.grey,
      padding: const EdgeInsets.symmetric(vertical: 18),
      side: const BorderSide(color:EColorConstants.primaryColor),
      textStyle: const TextStyle(
          fontSize: 16.0, fontWeight: FontWeight.w500, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  static final darkElevatedtheme = ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor:EColorConstants.primaryColor,
      foregroundColor: Colors.white,
      disabledBackgroundColor: Colors.grey,
      disabledForegroundColor: Colors.grey,
      padding: const EdgeInsets.symmetric(vertical: 18),
      side: const BorderSide(color: EColorConstants.primaryColor),
      textStyle: const TextStyle(
          fontSize: 16.0, fontWeight: FontWeight.w500, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
