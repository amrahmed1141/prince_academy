import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/services/admin_tab_controller.dart';
import 'package:prince_academy/core/theme/app_gradients.dart';
import 'package:prince_academy/core/widgets/branded_pull_to_refresh.dart';
import 'package:prince_academy/features/admin/data/models/admin_dashboard_model.dart';
import 'package:prince_academy/features/admin/data/models/low_attendance_member_model.dart';
import 'package:prince_academy/features/admin/data/models/payment_verification_data.dart';
import 'package:prince_academy/features/admin/data/models/pending_payment_model.dart';
import 'package:prince_academy/features/admin/presentation/bloc/admin_dashboard_cubit.dart';
import 'package:prince_academy/features/admin/presentation/pages/admin_profile.dart';
import 'package:prince_academy/features/admin/presentation/pages/all_schedules_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/all_freeze_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/finance_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/payment_verification_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/pending_payments_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/qr_scanner_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/today_sessions_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/tracking/all_coaches_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/tracking/all_members_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/tracking/user_tracking_detail_page.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_smooth_scroll.dart';
import 'package:prince_academy/features/admin/presentation/widgets/dashboard/dashboard_attention_list.dart';
import 'package:prince_academy/features/admin/presentation/widgets/dashboard/dashboard_header.dart';
import 'package:prince_academy/features/admin/presentation/widgets/dashboard/dashboard_kpi_pager.dart';
import 'package:prince_academy/features/admin/presentation/widgets/dashboard/dashboard_pending_payments_list.dart';
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppGradients.homeScreenDecoration(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: BlocListener<AdminDashboardCubit, AdminDashboardState>(
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
          child: const Column(
            children: [
              _DashboardHeaderSection(),
              Expanded(child: _DashboardScrollBody()),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header (auth name + pending badge only) ────────────────────────────────

class _DashboardHeaderSection extends StatelessWidget {
  const _DashboardHeaderSection();

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

    return BlocSelector<AdminDashboardCubit, AdminDashboardState, int>(
      selector: (state) => state.data?.pendingPaymentsCount ?? 0,
      builder: (context, pendingCount) {
        return DashboardHeader(
          adminName: adminName,
          pendingCount: pendingCount,
          onAvatarTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminProfilePage()),
            );
          },
        );
      },
    );
  }
}

// ─── Scroll shell (loading / error / content phase only) ────────────────────

class _DashboardScrollBody extends StatelessWidget {
  const _DashboardScrollBody();

  static bool _shellChanged(
    AdminDashboardState previous,
    AdminDashboardState current,
  ) {
    final wasLoading = previous.isInitialLoading && previous.data == null;
    final isLoading = current.isInitialLoading && current.data == null;
    final wasError = previous.errorMessage != null && previous.data == null;
    final isError = current.errorMessage != null && current.data == null;
    return wasLoading != isLoading ||
        wasError != isError ||
        (isError && previous.errorMessage != current.errorMessage) ||
        (previous.data == null) != (current.data == null);
  }

  @override
  Widget build(BuildContext context) {
    return BrandedPullToRefresh(
      onRefresh: () => context.read<AdminDashboardCubit>().refresh(),
      child: ScrollConfiguration(
        behavior: const AdminSmoothScrollBehavior(),
        child: BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
          buildWhen: _shellChanged,
          builder: (context, state) {
            if (state.isInitialLoading && state.data == null) {
              return const _DashboardShimmer();
            }
            if (state.errorMessage != null && state.data == null) {
              return _DashboardErrorScroll(
                message: state.errorMessage!,
                onRetry: () => context.read<AdminDashboardCubit>().load(),
              );
            }
            return const _DashboardContentScroll();
          },
        ),
      ),
    );
  }
}

class _DashboardContentScroll extends StatelessWidget {
  const _DashboardContentScroll();

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      physics: AdminSmoothScrollBehavior.physics,
      cacheExtent: 480,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed(
              [
                _DashboardKpiSection(),
                SizedBox(height: 24),
                _DashboardTodaySection(),
                SizedBox(height: 24),
                _DashboardAttentionSection(),
                SizedBox(height: 24),
                _DashboardPendingSection(),
                SizedBox(height: 24),
                _DashboardActionsSection(),
              ],
              addAutomaticKeepAlives: false,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Section selectors (each rebuilds only on its own slice) ────────────────

class _KpiSlice {
  const _KpiSlice({
    required this.pendingCount,
    required this.todayRevenue,
    required this.activeMembers,
    required this.todaySessions,
    required this.todayAttended,
    required this.todayBooked,
    required this.coachesCount,
    required this.freezePendingCount,
  });

  final int pendingCount;
  final double todayRevenue;
  final int activeMembers;
  final int todaySessions;
  final int todayAttended;
  final int todayBooked;
  final int coachesCount;
  final int freezePendingCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _KpiSlice &&
          pendingCount == other.pendingCount &&
          todayRevenue == other.todayRevenue &&
          activeMembers == other.activeMembers &&
          todaySessions == other.todaySessions &&
          todayAttended == other.todayAttended &&
          todayBooked == other.todayBooked &&
          coachesCount == other.coachesCount &&
          freezePendingCount == other.freezePendingCount;

  @override
  int get hashCode => Object.hash(
        pendingCount,
        todayRevenue,
        activeMembers,
        todaySessions,
        todayAttended,
        todayBooked,
        coachesCount,
        freezePendingCount,
      );
}

class _DashboardKpiSection extends StatelessWidget {
  const _DashboardKpiSection();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AdminDashboardCubit, AdminDashboardState, _KpiSlice>(
      selector: (state) {
        final data = state.data;
        return _KpiSlice(
          pendingCount: data?.pendingPaymentsCount ?? 0,
          todayRevenue: data?.todayRevenue ?? 0,
          activeMembers: data?.activeMembersCount ?? 0,
          todaySessions: data?.todaySessionsCount ?? 0,
          todayAttended: data?.todayAttendedTotal ?? 0,
          todayBooked: data?.todayBookedCapacity ?? 0,
          coachesCount: data?.coachesCount ?? 0,
          freezePendingCount: data?.freezePendingCount ?? 0,
        );
      },
      builder: (context, slice) {
        return DashboardKpiPager(
          todayAttended: slice.todayAttended,
          todayBooked: slice.todayBooked,
          todaySessions: slice.todaySessions,
          pendingCount: slice.pendingCount,
          todayRevenue: slice.todayRevenue,
          coachesCount: slice.coachesCount,
          membersCount: slice.activeMembers,
          freezePendingCount: slice.freezePendingCount,
          onPendingTap: () => _DashboardNav.openPendingPayments(context),
          onRevenueTap: () => _DashboardNav.openFinance(context),
          onTodaySessionsTap: () => _DashboardNav.openTodaySessions(context),
          onAllSchedulesTap: () => _DashboardNav.openAllSchedules(context),
          onCoachesTap: () => _DashboardNav.openAllCoaches(context),
          onMembersTap: () => _DashboardNav.openAllMembers(context),
          onFreezeTap: () => _DashboardNav.openAllFreeze(context),
        );
      },
    );
  }
}

class _DashboardTodaySection extends StatelessWidget {
  const _DashboardTodaySection();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AdminDashboardCubit, AdminDashboardState,
        List<DashboardTodaySession>>(
      selector: (state) =>
          state.data?.todaySessionsPreview ?? const <DashboardTodaySession>[],
      builder: (context, sessions) {
        return DashboardTodayList(
          sessions: sessions,
          onSeeAll: () => _DashboardNav.openTodaySessions(context),
          onSessionTap: (_) => _DashboardNav.openTodaySessions(context),
        );
      },
    );
  }
}

class _DashboardAttentionSection extends StatelessWidget {
  const _DashboardAttentionSection();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AdminDashboardCubit, AdminDashboardState,
        List<LowAttendanceMemberModel>>(
      selector: (state) =>
          state.data?.lowAttendancePreview ??
          const <LowAttendanceMemberModel>[],
      builder: (context, members) {
        return DashboardAttentionList(
          members: members,
          onSeeAll: () => _DashboardNav.openAllMembers(context),
          onMemberTap: (member) =>
              _DashboardNav.openMemberDetail(context, member),
        );
      },
    );
  }
}

class _DashboardPendingSection extends StatelessWidget {
  const _DashboardPendingSection();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AdminDashboardCubit, AdminDashboardState,
        List<PendingPaymentModel>>(
      selector: (state) =>
          state.data?.pendingPaymentsPreview ??
          const <PendingPaymentModel>[],
      builder: (context, payments) {
        return DashboardPendingPaymentsList(
          payments: payments,
          onSeeAll: () => _DashboardNav.openPendingPayments(context),
          onPaymentTap: (payment) =>
              _DashboardNav.openPaymentVerification(context, payment),
        );
      },
    );
  }
}

class _DashboardActionsSection extends StatelessWidget {
  const _DashboardActionsSection();

  @override
  Widget build(BuildContext context) {
    return DashboardQuickActions(
      onScanQr: () => _DashboardNav.openQrScanner(context),
      onVerifyPayments: () => _DashboardNav.openPendingPayments(context),
      onManageAcademy: () => sl<AdminTabController>().goAddInfo(),
      onAddSession: () => sl<AdminTabController>().goAddInfo(),
    );
  }
}

// ─── Navigation helpers ─────────────────────────────────────────────────────

abstract final class _DashboardNav {
  static void openQrScanner(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const QrScannerPage(),
      ),
    );
  }

  static void openPendingPayments(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PendingPaymentsPage()),
    );
  }

  static void openAllMembers(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AllMembersPage()),
    );
  }

  static void openTodaySessions(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TodaySessionsPage()),
    );
  }

  static void openAllSchedules(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AllSchedulesPage()),
    );
  }

  static void openAllFreeze(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AllFreezePage()),
    );
  }

  static void openAllCoaches(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AllCoachesPage()),
    );
  }

  static void openFinance(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const FinancePage(showBackButton: true),
      ),
    );
  }

  static void openMemberDetail(
    BuildContext context,
    LowAttendanceMemberModel member,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserTrackingDetailPage(
          userId: member.userId,
          initialName: member.fullName,
          phone: member.phone,
        ),
      ),
    );
  }

  static void openPaymentVerification(
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
}

// ─── Loading / error (also smooth-scrollable for pull-to-refresh) ───────────

class _DashboardShimmer extends StatelessWidget {
  const _DashboardShimmer();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: AdminSmoothScrollBehavior.physics,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          sliver: SliverToBoxAdapter(
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Column(
                children: [
                  _box(height: 150),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _box(height: 110)),
                      const SizedBox(width: 10),
                      Expanded(child: _box(height: 110)),
                      const SizedBox(width: 10),
                      Expanded(child: _box(height: 110)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(child: _box(height: 10, width: 40)),
                  const SizedBox(height: 24),
                  _box(height: 88),
                  const SizedBox(height: 24),
                  _box(height: 120),
                  const SizedBox(height: 24),
                  _box(height: 160),
                  const SizedBox(height: 24),
                  _box(height: 120),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _box({required double height, double? width}) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

class _DashboardErrorScroll extends StatelessWidget {
  const _DashboardErrorScroll({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: AdminSmoothScrollBehavior.physics,
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
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
          ),
        ),
      ],
    );
  }
}
