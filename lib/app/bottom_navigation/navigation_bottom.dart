import 'package:flutter/material.dart';
import 'package:prince_academy/app/bottom_navigation/widgets/glass_floating_nav_bar.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/services/user_qr_service.dart';
import 'package:prince_academy/features/home/presentation/pages/home/home.dart';
import 'package:prince_academy/features/booking/presentation/pages/booking_history_page.dart';
import 'package:prince_academy/features/profile/presentation/pages/profile/profile.dart';
import 'package:prince_academy/features/profile/presentation/widgets/qr_code_bottom_sheet.dart';
import 'package:prince_academy/features/sessions/session_screen.dart';

class NavigationBottom extends StatefulWidget {
  const NavigationBottom({super.key});

  @override
  State<NavigationBottom> createState() => _NavigationBottomState();
}

class _NavigationBottomState extends State<NavigationBottom> {
  int _currentIndex = 0;
  late final UserQrService _qrService;

  @override
  void initState() {
    super.initState();
    _qrService = sl<UserQrService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _qrService.refresh();
    });
  }

  void _onQrFabPressed() {
    if (_qrService.hasQrCode) {
      showMemberQrBottomSheet(
        context,
        qrCode: _qrService.qrCode!,
        memberName: _qrService.fullName,
      );
      return;
    }
    showNoQrSnackBar(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              const RepaintBoundary(child: HomeScreen()),
              const RepaintBoundary(child: BookingHistoryPage()),
              const RepaintBoundary(child: SessionScreen()),
              RepaintBoundary(
                child: ProfilePage(
                  isActive: _currentIndex == 3,
                ),
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: ListenableBuilder(
              listenable: _qrService,
              builder: (context, _) {
                return GlassFloatingNavBar(
                  selectedIndex: _currentIndex,
                  hasQrCode: _qrService.hasQrCode,
                  isQrLoading: _qrService.isLoading,
                  onQrPressed: _onQrFabPressed,
                  onDestinationSelected: (index) {
                    if (index == _currentIndex) return;
                    setState(() => _currentIndex = index);
                    if (index == 3) {
                      _qrService.refresh();
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
