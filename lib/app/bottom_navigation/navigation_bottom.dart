import 'package:flutter/material.dart';
import 'package:prince_academy/app/bottom_navigation/widgets/glass_floating_nav_bar.dart';
import 'package:prince_academy/features/home/presentation/pages/home/home.dart';
import 'package:prince_academy/features/booking/presentation/pages/booking/booking_screen.dart';
import 'package:prince_academy/features/profile/presentation/pages/profile/profile.dart';
import 'package:prince_academy/features/sessions/session_screen.dart';

class NavigationBottom extends StatefulWidget {
  const NavigationBottom({super.key});

  @override
  State<NavigationBottom> createState() => _NavigationBottomState();
}

class _NavigationBottomState extends State<NavigationBottom> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    BookingScreen(),
    SessionScreen(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _pages[_currentIndex],
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: GlassFloatingNavBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) =>
                  setState(() => _currentIndex = index),
            ),
          ),
        ],
      ),
    );
  }
}
