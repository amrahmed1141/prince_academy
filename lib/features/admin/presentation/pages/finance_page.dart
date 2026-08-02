import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/features/admin/data/repositories/finance_repository.dart';
import 'package:prince_academy/features/admin/presentation/bloc/finance_bloc.dart';
import 'package:prince_academy/features/admin/presentation/pages/pending_payments_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/tracking/all_coaches_page.dart';
import 'package:prince_academy/features/admin/presentation/widgets/finance/finance_coach_tile.dart';
import 'package:prince_academy/features/admin/presentation/widgets/finance/finance_pending_banner.dart';
import 'package:prince_academy/features/admin/presentation/widgets/finance/finance_performance_card.dart';
import 'package:prince_academy/features/admin/presentation/widgets/finance/finance_period_selector.dart';
import 'package:prince_academy/features/admin/presentation/widgets/finance/finance_revenue_card.dart';
import 'package:prince_academy/features/admin/presentation/widgets/finance/finance_section_header.dart';
import 'package:prince_academy/features/admin/presentation/widgets/finance/finance_transaction_tile.dart';
import 'package:prince_academy/features/admin/presentation/widgets/finance/finance_week_tabs.dart';
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
      child: _FinanceView(showBackButton: showBackButton),
    );
  }
}

class _FinanceView extends StatefulWidget {
  const _FinanceView({this.showBackButton = false});

  final bool showBackButton;

  @override
  State<_FinanceView> createState() => _FinanceViewState();
}

class _FinanceViewState extends State<_FinanceView> {
  FinancePeriod _period = FinancePeriod.week;
  DateTime? _selectedDay;
  late DateTime _selectedMonthStart;
  late int _selectedWeek;
  FinanceTxFilter _txFilter = FinanceTxFilter.all;
  String? _expandedBookingId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonthStart = DateTime(now.year, now.month, 1);
    _selectedWeek = _weekOfMonth(now);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  static int _weekOfMonth(DateTime date) {
    return (((date.day - 1) ~/ 7) + 1).clamp(1, 4);
  }

  static DateTime _startOfWeek(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  List<FinanceDailyIncome> _rowsForSelection(FinanceDashboardData data) {
    final monthRows = data.dailyHistory.where((entry) {
      return entry.day.year == _selectedMonthStart.year &&
          entry.day.month == _selectedMonthStart.month;
    }).toList();

    if (_period == FinancePeriod.month) {
      return _fillMonthDays(monthRows, _selectedMonthStart);
    }

    final weekStart = _weekStartInMonth(_selectedMonthStart, _selectedWeek);
    return _fillWeekDays(data.dailyHistory, weekStart);
  }

  DateTime _weekStartInMonth(DateTime monthStart, int week) {
    final day = ((week - 1) * 7) + 1;
    final date = DateTime(monthStart.year, monthStart.month, day);
    return _startOfWeek(date);
  }

  List<FinanceDailyIncome> _fillWeekDays(
    List<FinanceDailyIncome> history,
    DateTime weekStart,
  ) {
    return List.generate(7, (index) {
      final day = weekStart.add(Duration(days: index));
      final match = history.cast<FinanceDailyIncome?>().firstWhere(
            (item) => item != null && DateUtils.isSameDay(item.day, day),
            orElse: () => null,
          );
      return FinanceDailyIncome(day: day, amount: match?.amount ?? 0);
    });
  }

  List<FinanceDailyIncome> _fillMonthDays(
    List<FinanceDailyIncome> monthRows,
    DateTime monthStart,
  ) {
    return List.generate(4, (index) {
      final weekStart = _weekStartInMonth(monthStart, index + 1);
      final amount = monthRows
          .where((row) => _weekOfMonth(row.day) == index + 1)
          .fold<double>(0, (sum, row) => sum + row.amount);
      return FinanceDailyIncome(day: weekStart, amount: amount);
    });
  }

  double _amountForDay(FinanceDashboardData data, DateTime day) {
    final match = data.dailyHistory.cast<FinanceDailyIncome?>().firstWhere(
          (item) => item != null && DateUtils.isSameDay(item.day, day),
          orElse: () => null,
        );
    return match?.amount ?? 0;
  }

  List<FinanceTransaction> _filteredTx(FinanceDashboardData data) {
    return data.transactions.where((tx) {
      return switch (_txFilter) {
        FinanceTxFilter.all =>
          tx.status != FinancePaymentStatus.rejected,
        FinanceTxFilter.confirmed => tx.isConfirmed,
        FinanceTxFilter.pending => tx.isPending,
      };
    }).toList(growable: false);
  }

  Future<void> _reject(BuildContext context, FinanceTransaction tx) async {
    final reason = await RejectPaymentDialog.show(context);
    if (reason == null || !context.mounted) return;
    context.read<FinanceCubit>().rejectPayment(tx.bookingId, reason);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F6F2),
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
              SnackBar(
                content: Text(error),
                backgroundColor: AppColors.error,
              ),
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
            return const _FinanceLoadingView();
          }

          final data = state.data;
          if (data == null) {
            return Center(
              child: ElevatedButton(
                onPressed: () => context.read<FinanceCubit>().load(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EColorConstants.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            );
          }

          return _FinanceBody(
            data: data,
            busyBookingIds: state.busyBookingIds,
            period: _period,
            selectedDay: _selectedDay,
            selectedMonthStart: _selectedMonthStart,
            selectedWeek: _selectedWeek,
            txFilter: _txFilter,
            expandedBookingId: _expandedBookingId,
            chartRows: _rowsForSelection(data),
            filteredTransactions: _filteredTx(data),
            onRefresh: () => context.read<FinanceCubit>().refresh(),
            onPeriodChanged: (period) {
              setState(() {
                _period = period;
                if (period == FinancePeriod.day && _selectedDay == null) {
                  final now = DateTime.now();
                  _selectedDay = DateTime(now.year, now.month, now.day);
                }
              });
            },
            onPreviousPeriod: () {
              setState(() {
                if (_period == FinancePeriod.month) {
                  _selectedMonthStart = DateTime(
                    _selectedMonthStart.year,
                    _selectedMonthStart.month - 1,
                    1,
                  );
                  _selectedWeek = 1;
                  _selectedDay = null;
                } else if (_period == FinancePeriod.week) {
                  if (_selectedWeek > 1) {
                    _selectedWeek -= 1;
                  } else {
                    _selectedMonthStart = DateTime(
                      _selectedMonthStart.year,
                      _selectedMonthStart.month - 1,
                      1,
                    );
                    _selectedWeek = 4;
                  }
                  _selectedDay = null;
                } else if (_selectedDay != null) {
                  _selectedDay =
                      _selectedDay!.subtract(const Duration(days: 1));
                  _selectedMonthStart =
                      DateTime(_selectedDay!.year, _selectedDay!.month, 1);
                  _selectedWeek = _weekOfMonth(_selectedDay!);
                }
              });
            },
            onNextPeriod: () {
              setState(() {
                if (_period == FinancePeriod.month) {
                  _selectedMonthStart = DateTime(
                    _selectedMonthStart.year,
                    _selectedMonthStart.month + 1,
                    1,
                  );
                  _selectedWeek = 1;
                  _selectedDay = null;
                } else if (_period == FinancePeriod.week) {
                  if (_selectedWeek < 4) {
                    _selectedWeek += 1;
                  } else {
                    _selectedMonthStart = DateTime(
                      _selectedMonthStart.year,
                      _selectedMonthStart.month + 1,
                      1,
                    );
                    _selectedWeek = 1;
                  }
                  _selectedDay = null;
                } else if (_selectedDay != null) {
                  _selectedDay = _selectedDay!.add(const Duration(days: 1));
                  _selectedMonthStart =
                      DateTime(_selectedDay!.year, _selectedDay!.month, 1);
                  _selectedWeek = _weekOfMonth(_selectedDay!);
                }
              });
            },
            onWeekSelected: (week) {
              setState(() {
                _selectedWeek = week;
                _selectedDay = null;
              });
            },
            onDaySelected: (day) {
              setState(() {
                if (_selectedDay != null &&
                    DateUtils.isSameDay(_selectedDay, day)) {
                  _selectedDay = null;
                } else {
                  _selectedDay = day;
                  _selectedMonthStart = DateTime(day.year, day.month, 1);
                  _selectedWeek = _weekOfMonth(day);
                }
              });
            },
            onTxFilterChanged: (filter) {
              setState(() {
                _txFilter = filter;
                _expandedBookingId = null;
              });
            },
            onTransactionTap: (tx) {
              if (!tx.isPending) return;
              setState(() {
                _expandedBookingId =
                    _expandedBookingId == tx.bookingId ? null : tx.bookingId;
              });
            },
            onConfirm: (tx) =>
                context.read<FinanceCubit>().verifyPayment(tx.bookingId),
            onCancel: (tx) => _reject(context, tx),
            onPendingBannerTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PendingPaymentsPage(),
                ),
              );
            },
            onSeeAllCoaches: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AllCoachesPage(),
                ),
              );
            },
            dayAmount: (day) => _amountForDay(data, day),
          );
        },
      ),
    );
  }
}

class _FinanceBody extends StatelessWidget {
  const _FinanceBody({
    required this.data,
    required this.busyBookingIds,
    required this.period,
    required this.selectedDay,
    required this.selectedMonthStart,
    required this.selectedWeek,
    required this.txFilter,
    required this.expandedBookingId,
    required this.chartRows,
    required this.filteredTransactions,
    required this.onRefresh,
    required this.onPeriodChanged,
    required this.onPreviousPeriod,
    required this.onNextPeriod,
    required this.onWeekSelected,
    required this.onDaySelected,
    required this.onTxFilterChanged,
    required this.onTransactionTap,
    required this.onConfirm,
    required this.onCancel,
    required this.onPendingBannerTap,
    required this.onSeeAllCoaches,
    required this.dayAmount,
  });

  final FinanceDashboardData data;
  final Set<String> busyBookingIds;
  final FinancePeriod period;
  final DateTime? selectedDay;
  final DateTime selectedMonthStart;
  final int selectedWeek;
  final FinanceTxFilter txFilter;
  final String? expandedBookingId;
  final List<FinanceDailyIncome> chartRows;
  final List<FinanceTransaction> filteredTransactions;
  final Future<void> Function() onRefresh;
  final ValueChanged<FinancePeriod> onPeriodChanged;
  final VoidCallback onPreviousPeriod;
  final VoidCallback onNextPeriod;
  final ValueChanged<int> onWeekSelected;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<FinanceTxFilter> onTxFilterChanged;
  final ValueChanged<FinanceTransaction> onTransactionTap;
  final ValueChanged<FinanceTransaction> onConfirm;
  final ValueChanged<FinanceTransaction> onCancel;
  final VoidCallback onPendingBannerTap;
  final VoidCallback onSeeAllCoaches;
  final double Function(DateTime day) dayAmount;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayAmount = selectedDay == null
        ? data.dailyRevenue
        : dayAmount(selectedDay!);
    final todayLabel = selectedDay == null ||
            DateUtils.isSameDay(selectedDay, now)
        ? 'Today'
        : DateFormat('EEE, MMM d').format(selectedDay!);

    final weekTabs = List.generate(4, (index) {
      final weekNumber = index + 1;
      final amount = data.dailyHistory
          .where(
            (entry) =>
                entry.day.year == selectedMonthStart.year &&
                entry.day.month == selectedMonthStart.month &&
                (((entry.day.day - 1) ~/ 7) + 1) == weekNumber,
          )
          .fold<double>(0, (sum, entry) => sum + entry.amount);
      return FinanceWeekTabData(weekNumber: weekNumber, amount: amount);
    });

    final performanceTitle = switch (period) {
      FinancePeriod.day => 'Daily Performance',
      FinancePeriod.week => 'Weekly Performance',
      FinancePeriod.month =>
        '${DateFormat('MMMM').format(selectedMonthStart)} Performance',
    };

    final chartTotal = chartRows.fold<double>(0, (sum, row) => sum + row.amount);
    final topCoaches = data.topCoaches.take(5).toList(growable: false);

    return RefreshIndicator(
      color: EColorConstants.primaryColor,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                FinanceRevenueCard(
                  label: todayLabel,
                  amount: todayAmount,
                  changePercent:
                      selectedDay == null || DateUtils.isSameDay(selectedDay, now)
                          ? data.dailyRevenueChange
                          : null,
                  changeSubtitle: 'vs yesterday',
                ),
                const SizedBox(height: 10),
                FinanceRevenueCard(
                  label: 'Weekly',
                  amount: period == FinancePeriod.week ||
                          period == FinancePeriod.day
                      ? chartTotal
                      : data.weeklyRevenue,
                  changePercent: data.weeklyRevenueChange,
                  changeSubtitle: 'vs last week',
                ),
                const SizedBox(height: 10),
                FinanceRevenueCard(
                  label: 'Monthly',
                  amount: data.monthlyRevenue,
                  changePercent: data.monthlyRevenueChange,
                  changeSubtitle: 'vs last month',
                ),
                const SizedBox(height: 18),
                FinancePeriodSelector(
                  value: period,
                  onChanged: onPeriodChanged,
                  onPrevious: onPreviousPeriod,
                  onNext: onNextPeriod,
                ),
                if (period == FinancePeriod.week ||
                    period == FinancePeriod.day) ...[
                  const SizedBox(height: 12),
                  FinanceWeekTabs(
                    weeks: weekTabs,
                    selectedWeek: selectedWeek,
                    onSelected: onWeekSelected,
                  ),
                ],
                if (period == FinancePeriod.month) ...[
                  const SizedBox(height: 12),
                  Text(
                    DateFormat('MMMM yyyy').format(selectedMonthStart),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                FinancePerformanceCard(
                  title: performanceTitle,
                  total: chartTotal,
                  items: chartRows,
                  selectedDay: selectedDay,
                  onDaySelected: onDaySelected,
                  labelBuilder: period == FinancePeriod.month
                      ? (_, index) => 'W${index + 1}'
                      : null,
                ),
                const SizedBox(height: 14),
                FinancePendingBanner(
                  count: data.pendingCount,
                  onTap: onPendingBannerTap,
                ),
                const SizedBox(height: 20),
                FinanceSectionHeader(
                  title: 'Top Earning Coaches',
                  actionLabel: 'See all',
                  onAction: onSeeAllCoaches,
                ),
                const SizedBox(height: 10),
                if (topCoaches.isEmpty)
                  const _EmptyCard(label: 'No coach revenue yet')
                else
                  ...topCoaches.map((coach) => FinanceCoachTile(coach: coach)),
                const SizedBox(height: 16),
                const FinanceSectionHeader(title: 'Recent Transactions'),
                const SizedBox(height: 10),
                FinanceTxFilterChips(
                  value: txFilter,
                  onChanged: onTxFilterChanged,
                ),
                const SizedBox(height: 12),
                if (filteredTransactions.isEmpty)
                  const _EmptyCard(label: 'No transactions yet')
                else
                  ...filteredTransactions.map((tx) {
                    return FinanceTransactionTile(
                      transaction: tx,
                      expanded: expandedBookingId == tx.bookingId,
                      isBusy: busyBookingIds.contains(tx.bookingId),
                      onTap: () => onTransactionTap(tx),
                      onConfirm: () => onConfirm(tx),
                      onCancel: () => onCancel(tx),
                    );
                  }),
              ]),
            ),
          ),
        ],
      ),
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

class _FinanceLoadingView extends StatelessWidget {
  const _FinanceLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _ShimmerBox(height: 96),
        SizedBox(height: 10),
        _ShimmerBox(height: 96),
        SizedBox(height: 10),
        _ShimmerBox(height: 96),
        SizedBox(height: 16),
        _ShimmerBox(height: 48),
        SizedBox(height: 14),
        _ShimmerBox(height: 200),
        SizedBox(height: 14),
        _ShimmerBox(height: 52),
        SizedBox(height: 16),
        _ShimmerBox(height: 72),
        SizedBox(height: 8),
        _ShimmerBox(height: 72),
      ],
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({required this.height});

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
