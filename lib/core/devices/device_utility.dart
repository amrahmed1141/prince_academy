import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EDeviceUtils {
  // Method to get screen orientation
  static Orientation getScreenOrientation(BuildContext context) {
    return MediaQuery.of(context).orientation;
  }

  // Method to set the status bar color
  static void setStatusBarColor(Color color) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: color,
    ));
  }

  // Method to hide the keyboard
  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }


  static bool isIOS() {
    return Platform.isIOS;
  }

  static bool isAndroid() {
    return Platform.isAndroid;
  }

  static double getAppBarHeight() {
    return kToolbarHeight;
  }
  static double getBottomNavigationHeight() {
    return kBottomNavigationBarHeight;
  }
}
