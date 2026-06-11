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

  /// Pages are created once and reused to preserve tab state,
  /// prevent rebuilds, and avoid repeated API calls on tab switch.
  static const List<Widget> _pages = [
    RepaintBoundary(child: HomeScreen()),
    RepaintBoundary(child: BookingScreen()),
    RepaintBoundary(child: SessionScreen()),
    RepaintBoundary(child: ProfilePage()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          /// IndexedStack keeps all pages alive in memory.
          /// Only the active page is visible; the rest remain mounted.
          /// This prevents widget rebuilds and preserves scroll positions,
          /// form state, and tab state across navigation.
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),

          /// Floating glassmorphism nav bar positioned over content.
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: GlassFloatingNavBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                /// Prevent rebuild if same tab is tapped (no-op).
                if (index == _currentIndex) return;
                setState(() => _currentIndex = index);
              },
            ),
          ),
        ],
      ),
    );
  }
}