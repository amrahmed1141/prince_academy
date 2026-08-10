import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/data/repositories/finance_repository.dart';
import 'package:prince_academy/features/admin/presentation/bloc/finance_bloc.dart';
import 'package:prince_academy/features/admin/presentation/widgets/finance/finance_performance_card.dart';
import 'package:prince_academy/features/admin/presentation/widgets/finance/finance_period_selector.dart';
import 'package:prince_academy/features/admin/presentation/widgets/finance/finance_section_header.dart';
import 'package:prince_academy/features/admin/presentation/widgets/finance/finance_transaction_tile.dart';
import 'package:prince_academy/features/admin/presentation/widgets/finance/finance_week_day_totals.dart';
import 'package:prince_academy/features/admin/presentation/widgets/finance/finance_week_tabs.dart';
import 'package:prince_academy/features/admin/presentation/widgets/reject_payment_dialog.dart';

class FinanceDetailsPage extends StatefulWidget {
  const FinanceDetailsPage({super.key});

  @override
  State<FinanceDetailsPage> createState() => _FinanceDetailsPageState();
}

class _FinanceDetailsPageState extends State<FinanceDetailsPage> {
  FinancePeriod _period = FinancePeriod.week;
  DateTime? _selectedDay;
  late DateTime _selectedMonthStart;
  late int _selectedWeek;
  late int _selectedYear;
  String? _expandedBookingId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonthStart = DateTime(now.year, now.month, 1);
    _selectedWeek = _weekOfMonth(now);
    _selectedYear = now.year;
    _selectedDay = _dayInSelectedWeek(DateTime(now.year, now.month, now.day))
        ? DateTime(now.year, now.month, now.day)
        : null;
  }

  bool _dayInSelectedWeek(DateTime day) {
    final weekStart = _weekStartInMonth(_selectedMonthStart, _selectedWeek);
    final weekEnd = weekStart.add(const Duration(days: 6));
    return !day.isBefore(weekStart) && !day.isAfter(weekEnd);
  }

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDay =
          _selectedDay != null && DateUtils.isSameDay(_selectedDay, day)
              ? null
              : day;
      _expandedBookingId = null;
    });
  }

  List<FinanceTransaction> _transactionsForDay(
    List<FinanceTransaction> transactions,
    DateTime day,
  ) {
    return transactions
        .where((tx) => tx.status != FinancePaymentStatus.rejected)
        .where((tx) => DateUtils.isSameDay(tx.date, day))
        .toList(growable: false)
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _reject(FinanceTransaction tx) async {
    final reason = await RejectPaymentDialog.show(context);
    if (reason == null || !mounted) return;
    context.read<FinanceCubit>().rejectPayment(tx.bookingId, reason);
  }

  static int _weekOfMonth(DateTime date) =>
      (((date.day - 1) ~/ 7) + 1).clamp(1, 4);

  static DateTime _startOfWeek(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  DateTime _weekStartInMonth(DateTime monthStart, int week) {
    final day = ((week - 1) * 7) + 1;
    final date = DateTime(monthStart.year, monthStart.month, day);
    return _startOfWeek(date);
  }

  List<FinanceDailyIncome> _chartRows(FinanceDashboardData data) {
    if (_period == FinancePeriod.year) {
      return List.generate(12, (index) {
        final month = DateTime(_selectedYear, index + 1, 1);
        final amount = data.dailyHistory
            .where((e) => e.day.year == _selectedYear && e.day.month == index + 1)
            .fold<double>(0, (sum, e) => sum + e.amount);
        return FinanceDailyIncome(day: month, amount: amount);
      });
    }

    if (_period == FinancePeriod.month) {
      final monthRows = data.dailyHistory.where(
        (e) =>
            e.day.year == _selectedMonthStart.year &&
            e.day.month == _selectedMonthStart.month,
      );
      return List.generate(4, (index) {
        final weekStart = _weekStartInMonth(_selectedMonthStart, index + 1);
        final amount = monthRows
            .where((e) => _weekOfMonth(e.day) == index + 1)
            .fold<double>(0, (sum, e) => sum + e.amount);
        return FinanceDailyIncome(day: weekStart, amount: amount);
      });
    }

    final weekStart = _weekStartInMonth(_selectedMonthStart, _selectedWeek);
    return List.generate(7, (index) {
      final day = weekStart.add(Duration(days: index));
      final match = data.dailyHistory.cast<FinanceDailyIncome?>().firstWhere(
            (item) => item != null && DateUtils.isSameDay(item.day, day),
            orElse: () => null,
          );
      return FinanceDailyIncome(day: day, amount: match?.amount ?? 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F6F2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Finance Details',
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
            previous.busyBookingIds != current.busyBookingIds,
        builder: (context, state) {
          final data = state.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final chartRows = _chartRows(data);
          final chartTotal =
              chartRows.fold<double>(0, (sum, row) => sum + row.amount);
          final weekTabs = List.generate(4, (index) {
            final weekNumber = index + 1;
            final amount = data.dailyHistory
                .where(
                  (entry) =>
                      entry.day.year == _selectedMonthStart.year &&
                      entry.day.month == _selectedMonthStart.month &&
                      (((entry.day.day - 1) ~/ 7) + 1) == weekNumber,
                )
                .fold<double>(0, (sum, entry) => sum + entry.amount);
            return FinanceWeekTabData(weekNumber: weekNumber, amount: amount);
          });

          final performanceTitle = switch (_period) {
            FinancePeriod.week => 'Weekly Performance',
            FinancePeriod.month =>
              '${DateFormat('MMMM').format(_selectedMonthStart)} Performance',
            FinancePeriod.year => '$_selectedYear Performance',
          };

          return RefreshIndicator(
            color: EColorConstants.primaryColor,
            onRefresh: () => context.read<FinanceCubit>().refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                FinancePeriodSelector(
                  value: _period,
                  onChanged: (period) => setState(() => _period = period),
                  onPrevious: () {
                    setState(() {
                      if (_period == FinancePeriod.year) {
                        _selectedYear -= 1;
                      } else if (_period == FinancePeriod.month) {
                        _selectedMonthStart = DateTime(
                          _selectedMonthStart.year,
                          _selectedMonthStart.month - 1,
                          1,
                        );
                        _selectedWeek = 1;
                      } else if (_selectedWeek > 1) {
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
                    });
                  },
                  onNext: () {
                    setState(() {
                      if (_period == FinancePeriod.year) {
                        _selectedYear += 1;
                      } else if (_period == FinancePeriod.month) {
                        _selectedMonthStart = DateTime(
                          _selectedMonthStart.year,
                          _selectedMonthStart.month + 1,
                          1,
                        );
                        _selectedWeek = 1;
                      } else if (_selectedWeek < 4) {
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
                    });
                  },
                ),
                if (_period == FinancePeriod.week) ...[
                  const SizedBox(height: 12),
                  FinanceWeekTabs(
                    weeks: weekTabs,
                    selectedWeek: _selectedWeek,
                    onSelected: (week) {
                      setState(() {
                        _selectedWeek = week;
                        _selectedDay = null;
                      });
                    },
                  ),
                ],
                if (_period == FinancePeriod.month) ...[
                  const SizedBox(height: 12),
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedMonthStart),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
                if (_period == FinancePeriod.year) ...[
                  const SizedBox(height: 12),
                  Text(
                    '$_selectedYear',
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
                  selectedDay: _selectedDay,
                  onDaySelected: _selectDay,
                  labelBuilder: switch (_period) {
                    FinancePeriod.month => (_, index) => 'W${index + 1}',
                    FinancePeriod.year => (item, _) =>
                        DateFormat('MMM').format(item.day).toUpperCase(),
                    FinancePeriod.week => null,
                  },
                ),
                if (_period == FinancePeriod.week) ...[
                  const SizedBox(height: 16),
                  FinanceWeekDayTotals(
                    days: chartRows,
                    selectedDay: _selectedDay,
                    onDaySelected: _selectDay,
                  ),
                  if (_selectedDay != null) ...[
                    const SizedBox(height: 20),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _DayTransactionsSection(
                        key: ValueKey(_selectedDay),
                        day: _selectedDay!,
                        transactions: _transactionsForDay(
                          data.transactions,
                          _selectedDay!,
                        ),
                        expandedBookingId: _expandedBookingId,
                        busyBookingIds: state.busyBookingIds,
                        onExpand: (bookingId) {
                          setState(() {
                            _expandedBookingId =
                                _expandedBookingId == bookingId
                                    ? null
                                    : bookingId;
                          });
                        },
                        onConfirm: (bookingId) => context
                            .read<FinanceCubit>()
                            .verifyPayment(bookingId),
                        onReject: _reject,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DayTransactionsSection extends StatelessWidget {
  const _DayTransactionsSection({
    super.key,
    required this.day,
    required this.transactions,
    required this.expandedBookingId,
    required this.busyBookingIds,
    required this.onExpand,
    required this.onConfirm,
    required this.onReject,
  });

  final DateTime day;
  final List<FinanceTransaction> transactions;
  final String? expandedBookingId;
  final Set<String> busyBookingIds;
  final ValueChanged<String> onExpand;
  final ValueChanged<String> onConfirm;
  final Future<void> Function(FinanceTransaction tx) onReject;

  @override
  Widget build(BuildContext context) {
    final title = DateFormat('EEEE, MMM d').format(day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FinanceSectionHeader(title: title),
        const SizedBox(height: 10),
        if (transactions.isEmpty)
          const _EmptyDayCard()
        else
          ...transactions.map((tx) {
            return FinanceTransactionTile(
              transaction: tx,
              expanded: expandedBookingId == tx.bookingId,
              isBusy: busyBookingIds.contains(tx.bookingId),
              onTap: () => onExpand(tx.bookingId),
              onConfirm: () => onConfirm(tx.bookingId),
              onCancel: () => onReject(tx),
            );
          }),
      ],
    );
  }
}

class _EmptyDayCard extends StatelessWidget {
  const _EmptyDayCard();

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
      child: const Text(
        'No transactions on this day',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}
