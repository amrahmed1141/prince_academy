import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/theme/app_gradients.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/features/admin/data/repositories/finance_repository.dart';
import 'package:prince_academy/features/admin/presentation/bloc/finance_bloc.dart';
import 'package:prince_academy/features/admin/presentation/pages/all_finance_transactions_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/finance_details_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/pending_payments_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/tracking/all_coaches_page.dart';
import 'package:prince_academy/features/admin/presentation/widgets/finance/finance_coach_tile.dart';
import 'package:prince_academy/features/admin/presentation/widgets/finance/finance_compact_kpi.dart';
import 'package:prince_academy/features/admin/presentation/widgets/finance/finance_pending_banner.dart';
import 'package:prince_academy/features/admin/presentation/widgets/finance/finance_section_header.dart';
import 'package:prince_academy/features/admin/presentation/widgets/finance/finance_transaction_tile.dart';
import 'package:prince_academy/features/admin/presentation/widgets/reject_payment_dialog.dart';

class FinancePage extends StatelessWidget {
  const FinancePage({
    super.key,
    this.showBackButton = false,
  });

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FinanceCubit>()..load(),
      child: _FinanceHomeView(showBackButton: showBackButton),
    );
  }
}

class _FinanceHomeView extends StatefulWidget {
  const _FinanceHomeView({this.showBackButton = false});

  final bool showBackButton;

  @override
  State<_FinanceHomeView> createState() => _FinanceHomeViewState();
}

class _FinanceHomeViewState extends State<_FinanceHomeView> {
  String? _expandedBookingId;

  Future<void> _reject(FinanceTransaction tx) async {
    final reason = await RejectPaymentDialog.show(context);
    if (reason == null || !mounted) return;
    context.read<FinanceCubit>().rejectPayment(tx.bookingId, reason);
  }

  @override
  Widget build(BuildContext context) {
    return AppGradients.lightBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: widget.showBackButton,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: AppColors.textPrimary,
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: const Text(
          'Finance',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: BlocConsumer<FinanceCubit, FinanceState>(
        listenWhen: (previous, current) =>
            previous.errorMessage != current.errorMessage ||
            previous.successMessage != current.successMessage,
        listener: (context, state) {
          final error = state.errorMessage;
          final success = state.successMessage;
          if (error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), backgroundColor: AppColors.error),
            );
            context.read<FinanceCubit>().clearMessages();
          } else if (success != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success),
                backgroundColor: AppColors.success,
              ),
            );
            context.read<FinanceCubit>().clearMessages();
            setState(() => _expandedBookingId = null);
          }
        },
        buildWhen: (previous, current) =>
            previous.data != current.data ||
            previous.isInitialLoading != current.isInitialLoading ||
            previous.busyBookingIds != current.busyBookingIds,
        builder: (context, state) {
          if (state.isInitialLoading && state.data == null) {
            return const _HomeLoading();
          }

          final data = state.data;
          if (data == null) {
            return Center(
              child: ElevatedButton(
                onPressed: () => context.read<FinanceCubit>().load(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EColorConstants.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text('Retry'),
              ),
            );
          }

          final recent = data.transactions
              .where((tx) => tx.status != FinancePaymentStatus.rejected)
              .take(8)
              .toList(growable: false);
          final coaches = data.topCoaches.take(5).toList(growable: false);

          return RefreshIndicator(
            color: EColorConstants.primaryColor,
            onRefresh: () => context.read<FinanceCubit>().refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                FinanceCompactKpiRow(
                  todayAmount: data.dailyRevenue,
                  weeklyAmount: data.weeklyRevenue,
                  monthlyAmount: data.monthlyRevenue,
                  todayChange: data.dailyRevenueChange,
                  weeklyChange: data.weeklyRevenueChange,
                  monthlyChange: data.monthlyRevenueChange,
                ),
                const SizedBox(height: 12),
                FinanceNavRow(
                  label: 'View finance details',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<FinanceCubit>(),
                          child: const FinanceDetailsPage(),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                FinancePendingBanner(
                  count: data.pendingCount,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PendingPaymentsPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                FinanceSectionHeader(
                  title: 'Top Earning Coaches',
                  actionLabel: 'See all',
                  onAction: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AllCoachesPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                if (coaches.isEmpty)
                  const _EmptyCard(label: 'No coach revenue yet')
                else
                  ...coaches.map((coach) => FinanceCoachTile(coach: coach)),
                const SizedBox(height: 16),
                FinanceSectionHeader(
                  title: 'Recent Transactions',
                  actionLabel: 'View all',
                  onAction: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<FinanceCubit>(),
                          child: const AllFinanceTransactionsPage(),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                if (recent.isEmpty)
                  const _EmptyCard(label: 'No transactions yet')
                else
                  ...recent.map((tx) {
                    return FinanceTransactionTile(
                      transaction: tx,
                      expanded: _expandedBookingId == tx.bookingId,
                      isBusy: state.busyBookingIds.contains(tx.bookingId),
                      onTap: () {
                        if (!tx.isPending) return;
                        setState(() {
                          _expandedBookingId =
                              _expandedBookingId == tx.bookingId
                                  ? null
                                  : tx.bookingId;
                        });
                      },
                      onConfirm: () => context
                          .read<FinanceCubit>()
                          .verifyPayment(tx.bookingId),
                      onCancel: () => _reject(tx),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    ));
  }
}

class _HomeLoading extends StatelessWidget {
  const _HomeLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: List.generate(
            3,
            (_) => const Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: 8),
                child: _Box(height: 88),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _Box(height: 52),
        const SizedBox(height: 14),
        const _Box(height: 56),
        const SizedBox(height: 20),
        const _Box(height: 24),
        const SizedBox(height: 10),
        const _Box(height: 72),
        const SizedBox(height: 16),
        const _Box(height: 24),
        const SizedBox(height: 10),
        const _Box(height: 88),
        const SizedBox(height: 10),
        const _Box(height: 88),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEFE8E0),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
