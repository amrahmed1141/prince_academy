import 'package:flutter/foundation.dart';

/// Controls the admin shell bottom-nav tab from anywhere in the admin UI.
class AdminTabController extends ChangeNotifier {
  static const int home = 0;
  static const int addInfo = 1;
  static const int tracking = 2;
  static const int finance = 3;

  int _index = home;

  int get index => _index;

  void select(int index) {
    if (index < home || index > finance) return;
    if (_index == index) return;
    _index = index;
    notifyListeners();
  }

  void goHome() => select(home);

  void goAddInfo() => select(addInfo);

  void goTracking() => select(tracking);

  void goFinance() => select(finance);
}
