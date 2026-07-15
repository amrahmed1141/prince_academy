import 'package:flutter/material.dart';
import 'package:prince_academy/app/bottom_navigation/widgets/glass_floating_nav_bar.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/services/member_data_prefetch.dart';
import 'package:prince_academy/core/services/user_qr_service.dart';
import 'package:prince_academy/features/home/presentation/pages/home_page.dart';
import 'package:prince_academy/features/booking/presentation/pages/booking_history_page.dart';
import 'package:prince_academy/features/profile/presentation/pages/profile/profile.dart';
import 'package:prince_academy/features/profile/presentation/widgets/qr_code_bottom_sheet.dart';
import 'package:prince_academy/features/sessions/presentation/pages/sessions_page.dart';

class NavigationBottom extends StatefulWidget {
  const NavigationBottom({super.key});

  @override
  State<NavigationBottom> createState() => _NavigationBottomState();
}

class _NavigationBottomState extends State<NavigationBottom> {
  int _currentIndex = 0;
  late final UserQrService _qrService;
  late final List<WidgetBuilder> _tabBuilders;
  late final List<bool> _visitedTabs;

  @override
  void initState() {
    super.initState();
    _qrService = sl<UserQrService>();
    _tabBuilders = [
      (_) => const RepaintBoundary(child: HomePage()),
      (_) => const RepaintBoundary(child: BookingHistoryPage()),
      (_) => const RepaintBoundary(child: SessionsPage()),
      (_) => RepaintBoundary(
            child: ProfilePage(
              isActive: _currentIndex == 3,
            ),
          ),
    ];
    _visitedTabs = List<bool>.filled(_tabBuilders.length, false);
    _visitedTabs[_currentIndex] = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MemberDataPrefetch.warmUnawaited();
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
            children: List<Widget>.generate(_tabBuilders.length, (index) {
              if (!_visitedTabs[index]) {
                return const SizedBox.shrink();
              }
              return _tabBuilders[index](context);
            }),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: GlassFloatingNavBar(
                    selectedIndex: _currentIndex,
                    hasQrCode: _qrService.hasQrCode,
                    onDestinationSelected: (index) {
                      if (index == _currentIndex) return;
                      setState(() {
                        _currentIndex = index;
                        _visitedTabs[index] = true;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ListenableBuilder(
                  listenable: _qrService,
                  builder: (context, _) {
                    return _QrFabButton(
                      onPressed: _onQrFabPressed,
                      hasQrCode: _qrService.hasQrCode,
                      isLoading: _qrService.isLoading,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// QR FAB extracted so only this widget rebuilds on QR service updates.
class _QrFabButton extends StatelessWidget {
  const _QrFabButton({
    required this.onPressed,
    required this.hasQrCode,
    required this.isLoading,
  });

  final VoidCallback onPressed;
  final bool hasQrCode;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Material(
        color: const Color(0xFF3E2723),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.qr_code_2_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
