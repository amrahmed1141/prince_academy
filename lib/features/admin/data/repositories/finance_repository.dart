import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:prince_academy/core/base/stream_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FinanceRepository extends StreamRepository<FinanceDashboardData> {
  FinanceRepository(this._supabase)
      : super(cacheTtl: const Duration(seconds: 30));

  final SupabaseClient _supabase;
  RealtimeChannel? _paymentsChannel;
  RealtimeChannel? _bookingsChannel;

  void ensureRealtimeSubscription() {
    if (_paymentsChannel == null) {
      _paymentsChannel = _supabase
          .channel('finance-payments')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'payments',
            callback: (_) => unawaited(refresh()),
          )
          .subscribe();
    }

    if (_bookingsChannel == null) {
      _bookingsChannel = _supabase
          .channel('finance-bookings')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'bookings',
            callback: (_) => unawaited(refresh()),
          )
          .subscribe();
    }
  }

  Future<FinanceDashboardData> getDashboard({bool force = false}) async {
    if (!force && hasValidCache && cachedValue != null) {
      return cachedValue!;
    }
    return refresh();
  }

  @override
  Future<FinanceDashboardData> fetchFromApi() async {
    final now = DateTime.now();
    final startOfWeek = _startOfWeek(now);
    final previousWeekStart = startOfWeek.subtract(const Duration(days: 7));
    final weekEnd = startOfWeek.add(const Duration(days: 6));

    final monthStart = DateTime(now.year, now.month, 1);
    final monthStartIso = _toIsoDate(monthStart);

    final results = await Future.wait([
      _supabase
          .from('finance_daily_revenue')
          .select()
          .order('payment_date', ascending: false)
          .limit(365),
      _supabase
          .from('finance_monthly_revenue')
          .select()
          .order('month_start', ascending: false)
          .limit(1)
          .maybeSingle(),
      _supabase
          .from('top_earning_coaches')
          .select()
          .limit(5),
      _supabase
          .from('payments')
          .select()
          .order('created_at', ascending: false)
          .limit(12),
    ]);

    final allDailyRows =
        List<Map<String, dynamic>>.from((results[0] as List).cast<Map>());
    final dailyHistory = allDailyRows
        .map(
          (row) => FinanceDailyIncome(
            day: _asDate(
                  row['payment_date'] ??
                      row['day'] ??
                      row['date'] ??
                      row['created_at'],
                ) ??
                now,
            amount: _pickDouble(
              row,
              ['daily_revenue', 'amount', 'revenue', 'total_revenue'],
            ),
          ),
        )
        .toList()
      ..sort((a, b) => a.day.compareTo(b.day));
    final monthlyRow = results[1] == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(results[1] as Map);
    final coachRows =
        List<Map<String, dynamic>>.from((results[2] as List).cast<Map>());
    final activityRows =
        List<Map<String, dynamic>>.from((results[3] as List).cast<Map>());

    final currentWeekRows = allDailyRows.where((row) {
      final date = _asDate(
        row['day'] ??
            row['date'] ??
            row['payment_date'] ??
            row['revenue_day'] ??
            row['created_at'],
      );
      if (date == null) return false;
      return !date.isBefore(startOfWeek) && !date.isAfter(weekEnd);
    }).toList();

    final previousWeekRows = allDailyRows.where((row) {
      final date = _asDate(
        row['day'] ??
            row['date'] ??
            row['payment_date'] ??
            row['revenue_day'] ??
            row['created_at'],
      );
      if (date == null) return false;
      return !date.isBefore(previousWeekStart) && date.isBefore(startOfWeek);
    }).toList();

    final chartDays = List.generate(7, (index) {
      final day = startOfWeek.add(Duration(days: index));
      final existing = currentWeekRows.cast<Map<String, dynamic>?>().firstWhere(
            (row) {
              final date = _asDate(
                row?['day'] ??
                    row?['date'] ??
                    row?['payment_date'] ??
                    row?['revenue_day'] ??
                    row?['created_at'],
              );
              return date != null &&
                  date.year == day.year &&
                  date.month == day.month &&
                  date.day == day.day;
            },
            orElse: () => null,
          );
      if (existing == null) {
        return FinanceDailyIncome(day: day, amount: 0);
      }
      return FinanceDailyIncome(
        day: day,
        amount: _pickDouble(
          existing,
          ['amount', 'revenue', 'total_revenue', 'daily_revenue'],
        ),
      );
    });

    final dailyRevenue = _latestDayRevenue(currentWeekRows, now);
    final previousDayRevenue = _latestPreviousDayRevenue(currentWeekRows, now);
    final weeklyRevenue = chartDays.fold<double>(0, (sum, day) => sum + day.amount);
    final previousWeeklyRevenue = previousWeekRows.fold<double>(
      0,
      (sum, row) =>
          sum +
          _pickDouble(
            row,
            ['amount', 'revenue', 'total_revenue', 'daily_revenue'],
          ),
    );

    final monthlyTarget = _pickDouble(
      monthlyRow,
      ['goal', 'monthly_goal', 'target', 'income_goal'],
      fallback: 40000,
    );
    final monthlyCurrent = _pickDouble(monthlyRow, [
      'current_revenue',
      'monthly_revenue',
      'revenue',
      'amount',
    ], fallback: _monthlyRevenueFromDailyRows(allDailyRows, monthStartIso));

    final topCoaches = coachRows
        .map((row) => TopEarningCoach(
              id: _pickString(row, ['coach_id', 'id']),
              name: _pickString(row, ['coach_name', 'name'], fallback: 'Coach'),
              specialty: _pickString(
                row,
                ['coach_specialty', 'specialty'],
                fallback: 'MMA Coach',
              ),
              avatarUrl: _pickNullableString(
                row,
                ['coach_photo', 'photo_url', 'avatar_url'],
              ),
              amount: _pickDouble(
                row,
                ['total_revenue', 'total_earned_this_month', 'revenue', 'amount'],
              ),
            ))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return FinanceDashboardData(
      dailyRevenue: dailyRevenue,
      dailyRevenueChange: _percentageChange(
        current: dailyRevenue,
        previous: previousDayRevenue,
      ),
      weeklyRevenue: weeklyRevenue,
      weeklyRevenueChange: _percentageChange(
        current: weeklyRevenue,
        previous: previousWeeklyRevenue,
      ),
      monthlyGoal: monthlyTarget <= 0 ? 40000 : monthlyTarget,
      monthlyRevenue: monthlyCurrent < 0 ? 0 : monthlyCurrent,
      chart: chartDays,
      dailyHistory: dailyHistory,
      topCoaches: topCoaches,
      recentActivities: activityRows
          .map((row) => RecentFinanceActivity(
                id: _pickString(row, ['id', 'payment_id']),
                title: _activityTitleFromRow(row),
                date: _asDate(row['created_at']) ?? now,
                amount: _activityAmountFromRow(row),
                isIncome: _activityIsIncomeFromRow(row),
              ))
          .toList(),
    );
  }

  @override
  void dispose() {
    _paymentsChannel?.unsubscribe();
    _bookingsChannel?.unsubscribe();
    _paymentsChannel = null;
    _bookingsChannel = null;
    super.dispose();
  }

  DateTime _startOfWeek(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  String _toIsoDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  DateTime? _asDate(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toLocal();
    if (raw is String) return DateTime.tryParse(raw)?.toLocal();
    return null;
  }

  double _pickDouble(
    Map<String, dynamic> row,
    List<String> keys, {
    double fallback = 0,
  }) {
    for (final key in keys) {
      final value = row[key];
      if (value == null) continue;
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return fallback;
  }

  String _pickString(
    Map<String, dynamic> row,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = row[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return fallback;
  }

  String? _pickNullableString(Map<String, dynamic> row, List<String> keys) {
    final value = _pickString(row, keys);
    return value.isEmpty ? null : value;
  }

  double _latestDayRevenue(List<Map<String, dynamic>> rows, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final todayRow = rows.cast<Map<String, dynamic>?>().firstWhere(
          (row) {
            final date = _asDate(
              row?['day'] ??
                  row?['date'] ??
                  row?['payment_date'] ??
                  row?['revenue_day'] ??
                  row?['created_at'],
            );
            return date != null &&
                date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;
          },
          orElse: () => null,
        );

    if (todayRow != null) {
      return _pickDouble(
        todayRow,
        ['amount', 'revenue', 'total_revenue', 'daily_revenue'],
      );
    }

    if (rows.isEmpty) return 0;
    final sorted = [...rows]
      ..sort((a, b) {
        final da = _asDate(
              a['day'] ?? a['date'] ?? a['payment_date'] ?? a['created_at'],
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final db = _asDate(
              b['day'] ?? b['date'] ?? b['payment_date'] ?? b['created_at'],
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });
    return _pickDouble(
      sorted.first,
      ['amount', 'revenue', 'total_revenue', 'daily_revenue'],
    );
  }

  double _latestPreviousDayRevenue(List<Map<String, dynamic>> rows, DateTime now) {
    final yesterday = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    final row = rows.cast<Map<String, dynamic>?>().firstWhere(
          (item) {
            final date = _asDate(
              item?['day'] ??
                  item?['date'] ??
                  item?['payment_date'] ??
                  item?['revenue_day'] ??
                  item?['created_at'],
            );
            return date != null &&
                date.year == yesterday.year &&
                date.month == yesterday.month &&
                date.day == yesterday.day;
          },
          orElse: () => null,
        );
    if (row == null) return 0;
    return _pickDouble(
      row,
      ['amount', 'revenue', 'total_revenue', 'daily_revenue'],
    );
  }

  double _percentageChange({
    required double current,
    required double previous,
  }) {
    if (previous == 0) {
      if (current == 0) return 0;
      return 100;
    }
    return ((current - previous) / previous) * 100;
  }

  String _activityTitleFromRow(Map<String, dynamic> row) {
    final explicitType = _pickString(
      row,
      ['activity_type', 'type', 'payment_type', 'source'],
    );
    if (explicitType.isNotEmpty) return explicitType;

    final method = _pickString(row, ['payment_method'], fallback: 'Payment');
    final status = _pickString(row, ['status', 'payment_status']);
    if (status.toLowerCase() == 'refunded' || status.toLowerCase() == 'rejected') {
      return '$method Refund';
    }
    return '$method Membership';
  }

  bool _activityIsIncomeFromRow(Map<String, dynamic> row) {
    final amount = _activityAmountFromRow(row);
    if (amount < 0) return false;
    final status = _pickString(row, ['status', 'payment_status']).toLowerCase();
    return status != 'refunded' && status != 'rejected';
  }

  double _activityAmountFromRow(Map<String, dynamic> row) {
    final amount = _pickDouble(
      row,
      ['amount', 'total_price', 'value', 'paid_amount'],
    );
    final status = _pickString(row, ['status', 'payment_status']).toLowerCase();
    if (status == 'refunded' || status == 'rejected') return -amount.abs();
    return amount;
  }

  double _monthlyRevenueFromDailyRows(
    List<Map<String, dynamic>> rows,
    String monthStartIso,
  ) {
    return rows.fold<double>(0, (sum, row) {
      final date = _asDate(
        row['payment_date'] ?? row['day'] ?? row['date'] ?? row['created_at'],
      );
      if (date == null) return sum;
      final rowMonthStart = _toIsoDate(DateTime(date.year, date.month, 1));
      if (rowMonthStart != monthStartIso) return sum;
      return sum +
          _pickDouble(
            row,
            ['daily_revenue', 'amount', 'revenue', 'total_revenue'],
          );
    });
  }
}

class FinanceDashboardData extends Equatable {
  const FinanceDashboardData({
    required this.dailyRevenue,
    required this.dailyRevenueChange,
    required this.weeklyRevenue,
    required this.weeklyRevenueChange,
    required this.monthlyGoal,
    required this.monthlyRevenue,
    required this.chart,
    required this.dailyHistory,
    required this.topCoaches,
    required this.recentActivities,
  });

  final double dailyRevenue;
  final double dailyRevenueChange;
  final double weeklyRevenue;
  final double weeklyRevenueChange;
  final double monthlyGoal;
  final double monthlyRevenue;
  final List<FinanceDailyIncome> chart;
  final List<FinanceDailyIncome> dailyHistory;
  final List<TopEarningCoach> topCoaches;
  final List<RecentFinanceActivity> recentActivities;

  double get goalProgress {
    if (monthlyGoal <= 0) return 0;
    final value = monthlyRevenue / monthlyGoal;
    return value.clamp(0, 1);
  }

  @override
  List<Object?> get props => [
        dailyRevenue,
        dailyRevenueChange,
        weeklyRevenue,
        weeklyRevenueChange,
        monthlyGoal,
        monthlyRevenue,
        chart,
        dailyHistory,
        topCoaches,
        recentActivities,
      ];
}

class FinanceDailyIncome extends Equatable {
  const FinanceDailyIncome({
    required this.day,
    required this.amount,
  });

  final DateTime day;
  final double amount;

  @override
  List<Object?> get props => [day, amount];
}

class TopEarningCoach extends Equatable {
  const TopEarningCoach({
    required this.id,
    required this.name,
    required this.specialty,
    required this.avatarUrl,
    required this.amount,
  });

  final String id;
  final String name;
  final String specialty;
  final String? avatarUrl;
  final double amount;

  @override
  List<Object?> get props => [id, name, specialty, avatarUrl, amount];
}

class RecentFinanceActivity extends Equatable {
  const RecentFinanceActivity({
    required this.id,
    required this.title,
    required this.date,
    required this.amount,
    required this.isIncome,
  });

  final String id;
  final String title;
  final DateTime date;
  final double amount;
  final bool isIncome;

  @override
  List<Object?> get props => [id, title, date, amount, isIncome];
}
