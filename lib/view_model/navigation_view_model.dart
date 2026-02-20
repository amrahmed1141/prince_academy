import 'package:flutter/cupertino.dart';
import 'package:prince_academy/view/booking/booking_screen.dart';
import 'package:prince_academy/view/booking_details/booking.dart';
import 'package:prince_academy/view/home/home.dart';
import 'package:prince_academy/view/profile/profile.dart';

class NavigationViewModel extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  final List<Widget> _pages = [
    const HomeScreen(),
    const BookingScreen(),
    const ProfileScreen()
  ];
  Widget get currentPage => _pages[_currentIndex];

  void changeIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }
}
