import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/services/admin_tab_controller.dart';
import 'package:prince_academy/features/admin/presentation/bloc/admin_home/admin_home_bloc.dart';
import 'package:prince_academy/features/admin/presentation/bloc/admin_home/admin_home_event.dart';
import 'package:prince_academy/features/admin/presentation/bloc/coach/coach_bloc.dart';
import 'package:prince_academy/features/admin/presentation/bloc/coach/coach_event.dart';
import 'package:prince_academy/features/admin/presentation/pages/admin_add_info_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/finance_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/qr_scanner_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/tracking/tracking_page.dart';
import 'package:prince_academy/features/admin/presentation/widgets/custom_bottom_navigation.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late final AdminTabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = sl<AdminTabController>();
    _tabController.addListener(_onTabControllerChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabControllerChanged);
    super.dispose();
  }

  void _onTabControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _openQrScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const QrScannerPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _tabController.index;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AdminHomeBloc(
            repository: sl(),
            sessionPreferences: sl(),
          )..add(const AdminHomeStarted()),
        ),
        BlocProvider(
          create: (_) => sl<CoachBloc>()..add(const CoachStarted()),
        ),
      ],
      child: Scaffold(
        backgroundColor: EColorConstants.authFieldBackground,
        body: Stack(
          children: [
            IndexedStack(
              index: currentIndex,
              children: const [
                AdminDashboardPage(),
                AdminAddInfoPage(),
                TrackingPage(),
                FinancePage(),
              ],
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: AdminGlassNavBar(
                selectedIndex: currentIndex,
                onDestinationSelected: _tabController.select,
                onQrPressed: _openQrScanner,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
