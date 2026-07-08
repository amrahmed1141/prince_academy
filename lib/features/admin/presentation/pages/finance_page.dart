import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/features/admin/data/repositories/finance_repository.dart';
import 'package:prince_academy/features/admin/presentation/bloc/finance_bloc.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';

final NumberFormat _egpCurrency =
    NumberFormat.currency(locale: 'en', symbol: 'EGP ', decimalDigits: 2);
final NumberFormat _egpCurrencyNoDecimal =
    NumberFormat.currency(locale: 'en', symbol: 'EGP ', decimalDigits: 0);

class FinancePage extends StatelessWidget {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FinanceCubit>()..load(),
      child: const _FinanceView(),
    );
  }
}

class _FinanceView extends StatefulWidget {
  const _FinanceView();

  @override
  State<_FinanceView> createState() => _FinanceViewState();
}

class _FinanceViewState extends State<_FinanceView> {
  DateTime? _selectedDay;
  late DateTime _selectedMonthStart;
  late int _selectedWeek;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonthStart = DateTime(now.year, now.month, 1);
    _selectedWeek = _weekOfMonth(now);
  }

  void _onDaySelected(DateTime day) {
    setState(() {
      if (_selectedDay != null && DateUtils.isSameDay(_selectedDay, day)) {
        _selectedDay = null;
      } else {
        _selectedDay = day;
      }
    });
  }

  void _onWeekSelected(int week) {
    setState(() {
      _selectedWeek = week;
      _selectedDay = null;
    });
  }

  void _onMonthChanged(DateTime monthStart, {required int week}) {
    setState(() {
      _selectedMonthStart = monthStart;
      _selectedWeek = week;
      _selectedDay = null;
    });
  }

  static int _weekOfMonth(DateTime date) {
    return (((date.day - 1) ~/ 7) + 1).clamp(1, 4);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
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
            previous.errorMessage != current.errorMessage &&
            current.errorMessage != null,
        listener: (context, state) {
          final message = state.errorMessage;
          if (message == null) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.error,
            ),
          );
        },
        buildWhen: (previous, current) =>
            previous.data != current.data ||
            previous.isInitialLoading != current.isInitialLoading ||
            previous.isRefreshing != current.isRefreshing,
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
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => context.read<FinanceCubit>().refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate.fixed([
                      _RevenueCardsRow(
                        data: data,
                        selectedDay: _selectedDay,
                        selectedMonthStart: _selectedMonthStart,
                        selectedWeek: _selectedWeek,
                      ),
                      const SizedBox(height: 16),
                      _FinanceBreakdownSection(
                        data: data,
                        selectedDay: _selectedDay,
                        selectedMonthStart: _selectedMonthStart,
                        selectedWeek: _selectedWeek,
                        onDaySelected: _onDaySelected,
                        onWeekSelected: _onWeekSelected,
                        onMonthChanged: _onMonthChanged,
                      ),
                      const SizedBox(height: 22),
                      const _SectionHeader(title: 'Top Earning Coaches'),
                      const SizedBox(height: 10),
                      _TopCoachesList(coaches: data.topCoaches),
                      const SizedBox(height: 24),
                      const _SectionHeader(title: 'Recent Activity'),
                      const SizedBox(height: 10),
                      _RecentActivityList(items: data.recentActivities),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RevenueCardsRow extends StatelessWidget {
  const _RevenueCardsRow({
    required this.data,
    required this.selectedDay,
    required this.selectedMonthStart,
    required this.selectedWeek,
  });

  final FinanceDashboardData data;
  final DateTime? selectedDay;
  final DateTime selectedMonthStart;
  final int selectedWeek;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final selectedEntry = selectedDay == null
        ? null
        : data.dailyHistory.cast<FinanceDailyIncome?>().firstWhere(
              (item) =>
                  item != null && DateUtils.isSameDay(item.day, selectedDay),
              orElse: () => null,
            );
    final selectedAmount = selectedEntry?.amount ?? 0.0;
    final isTodaySelected =
        selectedDay != null && DateUtils.isSameDay(selectedDay, now);
    final dayTitle = selectedDay == null || isTodaySelected
        ? 'Today'
        : DateFormat('EEE, MMM d').format(selectedDay!);

    final weekAmount = _weekRevenueFor(
      data.dailyHistory,
      selectedMonthStart,
      selectedWeek,
    );
    final previousWeekAmount = _previousWeekRevenue(
      data.dailyHistory,
      selectedMonthStart,
      selectedWeek,
    );
    final weekChange = _percentageChange(weekAmount, previousWeekAmount);

    final isCurrentMonth =
        selectedMonthStart.year == now.year && selectedMonthStart.month == now.month;
    final isCurrentWeek =
        isCurrentMonth && selectedWeek == _FinanceViewState._weekOfMonth(now);
    final weekTitle = isCurrentWeek ? 'Weekly Revenue' : 'Week $selectedWeek';
    final weekSubtitle = selectedWeek > 1
        ? 'vs week ${selectedWeek - 1}'
        : 'vs last week';

    return Row(
      children: [
        Expanded(
          child: _RevenueCard(
            title: dayTitle,
            amount: selectedDay == null ? data.dailyRevenue : selectedAmount,
            change: data.dailyRevenueChange,
            subtitle: 'vs yesterday',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _RevenueCard(
            title: weekTitle,
            amount: weekAmount,
            change: weekChange,
            subtitle: weekSubtitle,
          ),
        ),
      ],
    );
  }

  static double _weekRevenueFor(
    List<FinanceDailyIncome> history,
    DateTime monthStart,
    int week,
  ) {
    return history
        .where(
          (entry) =>
              entry.day.year == monthStart.year &&
              entry.day.month == monthStart.month &&
              _weekOfMonth(entry.day) == week,
        )
        .fold<double>(0, (sum, entry) => sum + entry.amount);
  }

  static double _previousWeekRevenue(
    List<FinanceDailyIncome> history,
    DateTime monthStart,
    int week,
  ) {
    if (week > 1) {
      return _weekRevenueFor(history, monthStart, week - 1);
    }

    final previousMonth = DateTime(monthStart.year, monthStart.month - 1, 1);
    return _weekRevenueFor(history, previousMonth, 4);
  }

  static int _weekOfMonth(DateTime date) {
    return (((date.day - 1) ~/ 7) + 1).clamp(1, 4);
  }

  static double _percentageChange(double current, double previous) {
    if (previous == 0) return current == 0 ? 0 : 100;
    return ((current - previous) / previous) * 100;
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({
    required this.title,
    required this.amount,
    required this.change,
    required this.subtitle,
  });

  final String title;
  final double amount;
  final double change;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final changeColor = change >= 0 ? AppColors.success : AppColors.error;
    final changePrefix = change >= 0 ? '+' : '';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 0.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _egpCurrency.format(amount),
            style: const TextStyle(
              fontSize: 30,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$changePrefix${change.toStringAsFixed(1)}% $subtitle',
            style: TextStyle(
              fontSize: 12,
              color: changeColor,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeGoalCard extends StatelessWidget {
  const _IncomeGoalCard({required this.data});

  final FinanceDashboardData data;

  @override
  Widget build(BuildContext context) {
    final pct = (data.goalProgress * 100).round();
    final maxIncome = data.chart.fold<double>(
      0,
      (max, item) => item.amount > max ? item.amount : max,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Income Goal',
                  style: TextStyle(
                    fontSize: 22,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              Text(
                'TARGET: ${_egpCurrencyNoDecimal.format(data.monthlyGoal)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Monthly Progress',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              Text(
                '$pct%',
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: data.goalProgress,
              minHeight: 8,
              backgroundColor: AppColors.background,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
            ),
          ),
          const SizedBox(height: 18),
          _WeeklyIncomeBarChart(
            items: data.chart,
            maxValue: maxIncome <= 0 ? 1 : maxIncome,
            selectedDay: null,
            onDaySelected: _noopDaySelection,
          ),
        ],
      ),
    );
  }

  static void _noopDaySelection(DateTime _) {}
}

class _FinanceBreakdownSection extends StatelessWidget {
  const _FinanceBreakdownSection({
    required this.data,
    required this.selectedDay,
    required this.selectedMonthStart,
    required this.selectedWeek,
    required this.onDaySelected,
    required this.onWeekSelected,
    required this.onMonthChanged,
  });

  final FinanceDashboardData data;
  final DateTime? selectedDay;
  final DateTime selectedMonthStart;
  final int selectedWeek;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<int> onWeekSelected;
  final void Function(DateTime monthStart, {required int week}) onMonthChanged;

  @override
  Widget build(BuildContext context) {
    final monthRows = data.dailyHistory.where((entry) {
      return entry.day.year == selectedMonthStart.year &&
          entry.day.month == selectedMonthStart.month;
    }).toList();

    final weekRows = monthRows.where((entry) {
      final weekIndex = ((entry.day.day - 1) ~/ 7) + 1;
      return weekIndex == selectedWeek;
    }).toList();

    final weekRevenue =
        weekRows.fold<double>(0, (sum, item) => sum + item.amount);
    final dailyAvg = weekRows.isEmpty ? 0.0 : (weekRevenue / weekRows.length).toDouble();
    final monthRevenue =
        monthRows.fold<double>(0, (sum, item) => sum + item.amount);
    final progress = data.monthlyGoal <= 0
        ? 0.0
        : (monthRevenue / data.monthlyGoal).clamp(0.0, 1.0).toDouble();
    final weekTarget = data.monthlyGoal / 4;
    final weekProgress = weekTarget <= 0
        ? 0.0
        : (weekRevenue / weekTarget).clamp(0.0, 1.0).toDouble();

    final weekCards = List.generate(4, (index) {
      final weekNumber = index + 1;
      final amount = monthRows
          .where((entry) => ((entry.day.day - 1) ~/ 7) + 1 == weekNumber)
          .fold<double>(0, (sum, item) => sum + item.amount);
      return _WeekTabData(
        weekNumber: weekNumber,
        amount: amount,
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MonthHeader(
          selectedMonthStart: selectedMonthStart,
          onPrev: () {
            onMonthChanged(
              DateTime(
                selectedMonthStart.year,
                selectedMonthStart.month - 1,
                1,
              ),
              week: 1,
            );
          },
          onNext: () {
            final now = DateTime.now();
            final next = DateTime(
              selectedMonthStart.year,
              selectedMonthStart.month + 1,
              1,
            );
            if (next.isAfter(DateTime(now.year, now.month, 1))) return;
            onMonthChanged(
              next,
              week: _FinanceViewState._weekOfMonth(now),
            );
          },
        ),
        const SizedBox(height: 10),
        _MonthBreakdownCard(
          monthLabel: DateFormat('MMMM').format(selectedMonthStart).toUpperCase(),
          monthRevenue: monthRevenue,
          weekCards: weekCards,
          selectedWeek: selectedWeek,
          onSelectWeek: onWeekSelected,
        ),
        const SizedBox(height: 12),
        _WeeklyIncomeProgressCard(
          weekRows: weekRows,
          weekRevenue: weekRevenue,
          dailyAverage: dailyAvg,
          weekProgress: weekProgress,
          monthProgress: progress,
          monthGoal: data.monthlyGoal,
          selectedDay: selectedDay,
          onDaySelected: onDaySelected,
        ),
      ],
    );
  }
}

class _WeekTabData {
  const _WeekTabData({
    required this.weekNumber,
    required this.amount,
  });

  final int weekNumber;
  final double amount;
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.selectedMonthStart,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime selectedMonthStart;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy').format(selectedMonthStart);
    return Row(
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
          color: AppColors.textSecondary,
        ),
        Expanded(
          child: Text(
            monthLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
          color: AppColors.textSecondary,
        ),
      ],
    );
  }
}

class _MonthBreakdownCard extends StatelessWidget {
  const _MonthBreakdownCard({
    required this.monthLabel,
    required this.monthRevenue,
    required this.weekCards,
    required this.selectedWeek,
    required this.onSelectWeek,
  });

  final String monthLabel;
  final double monthRevenue;
  final List<_WeekTabData> weekCards;
  final int selectedWeek;
  final ValueChanged<int> onSelectWeek;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$monthLabel BREAKDOWN',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Text(
                _egpCurrencyNoDecimal.format(monthRevenue),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ...weekCards.map((week) {
                final isSelected = selectedWeek == week.weekNumber;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      onTap: () => onSelectWeek(week.weekNumber),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.success : AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'WEEK ${week.weekNumber}',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _egpCurrencyNoDecimal.format(week.amount),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'MONTH',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _egpCurrencyNoDecimal.format(monthRevenue),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyIncomeProgressCard extends StatelessWidget {
  const _WeeklyIncomeProgressCard({
    required this.weekRows,
    required this.weekRevenue,
    required this.dailyAverage,
    required this.weekProgress,
    required this.monthProgress,
    required this.monthGoal,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final List<FinanceDailyIncome> weekRows;
  final double weekRevenue;
  final double dailyAverage;
  final double weekProgress;
  final double monthProgress;
  final double monthGoal;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final maxValue = weekRows.fold<double>(
      0,
      (max, row) => row.amount > max ? row.amount : max,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Weekly Income',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F4EA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'AVG: ${_egpCurrencyNoDecimal.format(dailyAverage)}/DAY',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Weekly total ${_egpCurrencyNoDecimal.format(weekRevenue)}',
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Weekly Goal Progress',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 18,
                  ),
                ),
              ),
              Text(
                '${(weekProgress * 100).round()}%',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                  fontSize: 23,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: weekProgress,
              minHeight: 8,
              backgroundColor: AppColors.background,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
            ),
          ),
          const SizedBox(height: 12),
          _WeeklyIncomeBarChart(
            items: _weekFilledRows(weekRows),
            maxValue: maxValue <= 0 ? 1 : maxValue,
            selectedDay: selectedDay,
            onDaySelected: onDaySelected,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Month progress ${(monthProgress * 100).round()}% of ${_egpCurrencyNoDecimal.format(monthGoal)}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<FinanceDailyIncome> _weekFilledRows(List<FinanceDailyIncome> rows) {
    if (rows.isEmpty) {
      final start = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
      return List.generate(
        7,
        (index) => FinanceDailyIncome(day: start.add(Duration(days: index)), amount: 0),
      );
    }

    final sorted = [...rows]..sort((a, b) => a.day.compareTo(b.day));
    final start = sorted.first.day.subtract(Duration(days: sorted.first.day.weekday - 1));
    return List.generate(7, (index) {
      final date = start.add(Duration(days: index));
      final row = sorted.cast<FinanceDailyIncome?>().firstWhere(
            (item) =>
                item != null &&
                item.day.year == date.year &&
                item.day.month == date.month &&
                item.day.day == date.day,
            orElse: () => null,
          );
      return FinanceDailyIncome(day: date, amount: row?.amount ?? 0);
    });
  }
}

class _WeeklyIncomeBarChart extends StatelessWidget {
  const _WeeklyIncomeBarChart({
    required this.items,
    required this.maxValue,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final List<FinanceDailyIncome> items;
  final double maxValue;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 122,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: items.map((item) {
          final isToday = DateUtils.isSameDay(item.day, DateTime.now());
          final isSelected =
              selectedDay != null && DateUtils.isSameDay(selectedDay, item.day);
          final ratio = (item.amount / maxValue).clamp(0.08, 1.0);
          final barColor = isSelected
              ? AppColors.primary
              : (isToday ? AppColors.success : AppColors.background);
          final label = DateFormat('EEE').format(item.day);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => onDaySelected(item.day),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      height: 24 + (ratio * 56),
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        fontFamily: 'Poppins',
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 32,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        fontFamily: 'Poppins',
      ),
    );
  }
}

class _TopCoachesList extends StatelessWidget {
  const _TopCoachesList({required this.coaches});

  final List<TopEarningCoach> coaches;

  @override
  Widget build(BuildContext context) {
    if (coaches.isEmpty) {
      return const _EmptyCard(label: 'No coach revenue yet');
    }

    return Column(
      children: coaches.map((coach) {
        return Container(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CoachAvatar(
                coachName: coach.name,
                photoUrl: coach.avatarUrl,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coach.name,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      coach.specialty,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _egpCurrencyNoDecimal.format(coach.amount),
                style: const TextStyle(
                  fontSize: 20,
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList({required this.items});

  final List<RecentFinanceActivity> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyCard(label: 'No finance activity yet');
    }

    final dateFormat = DateFormat('MMM d');

    return Column(
      children: items.map((item) {
        final color = item.isIncome ? AppColors.success : AppColors.error;
        final sign = item.isIncome ? '+' : '-';
        final amount = _egpCurrency.format(item.amount.abs());
        return Container(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.12),
                ),
                child: Icon(
                  item.isIncome ? Icons.add : Icons.remove,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      dateFormat.format(item.date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$sign$amount',
                style: TextStyle(
                  fontSize: 25,
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        );
      }).toList(growable: false),
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
        borderRadius: BorderRadius.circular(12),
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
      children: [
        const _ShimmerBox(height: 132),
        const SizedBox(height: 12),
        const _ShimmerBox(height: 290),
        const SizedBox(height: 16),
        const _ShimmerBox(height: 42, width: 220),
        const SizedBox(height: 8),
        ...List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: _ShimmerBox(height: 72),
          ),
        ),
      ],
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({required this.height, this.width});

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
