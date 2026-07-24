import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/services/admin_tab_controller.dart';
import 'package:prince_academy/core/widgets/branded_pull_to_refresh.dart';
import 'package:prince_academy/features/admin/data/models/admin_dashboard_model.dart';
import 'package:prince_academy/features/admin/data/models/payment_verification_data.dart';
import 'package:prince_academy/features/admin/data/models/pending_payment_model.dart';
import 'package:prince_academy/features/admin/presentation/bloc/admin_dashboard_cubit.dart';
import 'package:prince_academy/features/admin/presentation/pages/admin_profile.dart';
import 'package:prince_academy/features/admin/presentation/pages/payment_verification_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/pending_payments_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/qr_scanner_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/tracking/user_tracking_detail_page.dart';
import 'package:prince_academy/features/admin/presentation/widgets/dashboard/dashboard_attention_list.dart';
import 'package:prince_academy/features/admin/presentation/widgets/dashboard/dashboard_header.dart';
import 'package:prince_academy/features/admin/presentation/widgets/dashboard/dashboard_kpi_grid.dart';
import 'package:prince_academy/features/admin/presentation/widgets/dashboard/dashboard_quick_actions.dart';
import 'package:prince_academy/features/admin/presentation/widgets/dashboard/dashboard_today_list.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_state.dart';
import 'package:shimmer/shimmer.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AdminDashboardCubit>()..load(),
      child: const _AdminDashboardView(),
    );
  }
}

class _AdminDashboardView extends StatelessWidget {
  const _AdminDashboardView();

  void _openQrScanner(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const QrScannerPage(),
      ),
    );
  }

  void _openPendingPayments(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PendingPaymentsPage()),
    );
  }

  void _openPaymentVerification(
    BuildContext context,
    PendingPaymentModel payment,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentVerificationPage(
          data: PaymentVerificationData.fromPendingPayment(payment),
          onVerified: () {
            if (context.mounted) {
              context.read<AdminDashboardCubit>().refresh();
            }
          },
        ),
      ),
    );
  }

  void _openMemberTracking(
    BuildContext context,
    DashboardTodaySession session,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserTrackingDetailPage(
          userId: session.userId,
          initialName: session.memberName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminName = context.select<AuthBloc, String>((bloc) {
      final state = bloc.state;
      if (state is AuthAuthed) {
        return state.user.fullName?.trim().isNotEmpty == true
            ? state.user.fullName!.trim()
            : 'Admin';
      }
      return 'Admin';
    });

    return Scaffold(
      backgroundColor: EColorConstants.authFieldBackground,
      body: BlocConsumer<AdminDashboardCubit, AdminDashboardState>(
        listenWhen: (previous, current) =>
            previous.errorMessage != current.errorMessage &&
            current.errorMessage != null &&
            current.data != null,
        listener: (context, state) {
          final message = state.errorMessage;
          if (message == null) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.redAccent,
            ),
          );
        },
        builder: (context, state) {
          final data = state.data;

          return Column(
            children: [
              DashboardHeader(
                adminName: adminName,
                pendingCount: data?.pendingPaymentsCount ?? 0,
                onAvatarTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminProfilePage(),
                    ),
                  );
                },
              ),
              Expanded(
                child: BrandedPullToRefresh(
                  onRefresh: () =>
                      context.read<AdminDashboardCubit>().refresh(),
                  child: state.isInitialLoading && data == null
                      ? const _DashboardShimmer()
                      : state.errorMessage != null && data == null
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.5,
                                  child: _DashboardError(
                                    message: state.errorMessage!,
                                    onRetry: () => context
                                        .read<AdminDashboardCubit>()
                                        .load(),
                                  ),
                                ),
                              ],
                            )
                          : ListView(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding:
                                  const EdgeInsets.fromLTRB(20, 8, 20, 120),
                              children: [
                                DashboardKpiGrid(
                                  pendingCount:
                                      data?.pendingPaymentsCount ?? 0,
                                  todayRevenue: data?.todayRevenue ?? 0,
                                  activeMembers:
                                      data?.activeMembersCount ?? 0,
                                  todaySessions:
                                      data?.todaySessionsCount ?? 0,
                                  onPendingTap: () =>
                                      _openPendingPayments(context),
                                  onRevenueTap: () =>
                                      sl<AdminTabController>().goFinance(),
                                  onMembersTap: () =>
                                      sl<AdminTabController>().goTracking(),
                                  onTodayTap: () =>
                                      sl<AdminTabController>().goTracking(),
                                ),
                                const SizedBox(height: 24),
                                DashboardQuickActions(
                                  onScanQr: () => _openQrScanner(context),
                                  onVerifyPayments: () =>
                                      _openPendingPayments(context),
                                  onManageAcademy: () =>
                                      sl<AdminTabController>().goAddInfo(),
                                  onAddSession: () =>
                                      sl<AdminTabController>().goAddInfo(),
                                ),
                                const SizedBox(height: 24),
                                DashboardAttentionList(
                                  payments:
                                      data?.pendingPaymentsPreview ?? const [],
                                  onSeeAll: () =>
                                      _openPendingPayments(context),
                                  onPaymentTap: (payment) =>
                                      _openPaymentVerification(
                                    context,
                                    payment,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                DashboardTodayList(
                                  sessions:
                                      data?.todaySessionsPreview ?? const [],
                                  onSeeAll: () =>
                                      sl<AdminTabController>().goTracking(),
                                  onSessionTap: (session) =>
                                      _openMemberTracking(context, session),
                                ),
                              ],
                            ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardShimmer extends StatelessWidget {
  const _DashboardShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _box(height: 110)),
                  const SizedBox(width: 12),
                  Expanded(child: _box(height: 110)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _box(height: 110)),
                  const SizedBox(width: 12),
                  Expanded(child: _box(height: 110)),
                ],
              ),
              const SizedBox(height: 24),
              _box(height: 88),
              const SizedBox(height: 24),
              _box(height: 160),
              const SizedBox(height: 24),
              _box(height: 160),
            ],
          ),
        ),
      ],
    );
  }

  Widget _box({required double height}) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Iconsax.warning_2,
            size: 48,
            color: EColorConstants.authPlaceholderGray,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: EColorConstants.authPlaceholderGray,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Iconsax.refresh),
            label: const Text('Retry'),
            style: TextButton.styleFrom(
              foregroundColor: EColorConstants.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
