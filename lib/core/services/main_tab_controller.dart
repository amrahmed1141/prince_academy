import 'package:flutter/foundation.dart';

/// Controls the member shell bottom-nav tab from anywhere in the app.
class MainTabController extends ChangeNotifier {
  static const int home = 0;
  static const int booking = 1;
  static const int sessions = 2;
  static const int profile = 3;

  int _index = home;

  int get index => _index;

  void select(int index) {
    if (index < home || index > profile) return;
    if (_index == index) return;
    _index = index;
    notifyListeners();
  }

  void goHome() => select(home);

  void goBooking() => select(booking);

  void goSessions() => select(sessions);
}
