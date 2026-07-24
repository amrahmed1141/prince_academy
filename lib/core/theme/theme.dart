import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/theme/custom_theme/appbar_theme.dart';
import 'package:prince_academy/core/theme/custom_theme/bottom_sheet_theme.dart';
import 'package:prince_academy/core/theme/custom_theme/button_theme.dart';
import 'package:prince_academy/core/theme/custom_theme/checkbox_theme.dart';
import 'package:prince_academy/core/theme/custom_theme/chip_theme.dart';
import 'package:prince_academy/core/theme/custom_theme/outlined_button_theme.dart';
import 'package:prince_academy/core/theme/custom_theme/text_field_theme.dart';
import 'package:prince_academy/core/theme/custom_theme/text_theme.dart';

class EAppTheme {
  EAppTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: EColorConstants.lightColor,
    primaryColor: EColorConstants.primaryColor,
    brightness: Brightness.light,
    fontFamily: 'Poppins',
    textTheme: ETextTheme.lightTextTheme,
    elevatedButtonTheme: EEelevatedButtonTheme.lightElevatedTheme,
    appBarTheme: EAppBarTheme.lightAppBarTheme,
    checkboxTheme: ECheckBoxTheme.lightCheckBoxTheme,
    bottomSheetTheme: EBottomSheetTheme.lightBottomSheetTheme,
    chipTheme: EChipTheme.lightChipTheme,
    outlinedButtonTheme: EOutLinedButtonTheme.lightElevatedTheme,
    inputDecorationTheme: ETextFieldTheme.lightInputDecorationTheme,
  );
}
