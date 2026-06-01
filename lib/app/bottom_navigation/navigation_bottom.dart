import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/helpers/helper_function.dart';
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
    final dark = EHelperFunction.isDarkMode(context);
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        height: 80,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor:
            dark ? EColorConstants.darkColor : EColorConstants.lightColor,
        selectedIndex: _currentIndex,
        indicatorColor: Colors.transparent,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Iconsax.home_1, color: Colors.grey),
            selectedIcon:
                Icon(Iconsax.home_1, color: EColorConstants.primaryColor),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Iconsax.ticket, color: Colors.grey),
            selectedIcon:
                Icon(Iconsax.ticket, color: EColorConstants.primaryColor),
            label: 'Booking',
          ),
          NavigationDestination(
            icon: Icon(Iconsax.calendar_1, color: Colors.grey),
            selectedIcon:
                Icon(Iconsax.calendar_1, color: EColorConstants.primaryColor),
            label: 'Sessions',
          ),
          NavigationDestination(
            icon: Icon(Iconsax.user, color: Colors.grey),
            selectedIcon:
                Icon(Iconsax.user, color: EColorConstants.primaryColor),
            label: 'Profile',
          ),
        ],
      ),
      body: _pages[_currentIndex],
    );
  }
}
