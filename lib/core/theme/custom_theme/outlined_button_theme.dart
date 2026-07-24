import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';

class EOutLinedButtonTheme {
  EOutLinedButtonTheme._();

  static final lightElevatedTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      elevation: 0,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      side: const BorderSide(color: EColorConstants.primaryColor),
      textStyle: const TextStyle(
          fontSize: 16.0, fontWeight: FontWeight.w600, color: Colors.black),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
