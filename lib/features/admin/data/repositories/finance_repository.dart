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

    final results = await Future.wait<dynamic>([
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
      _supabase.from('top_earning_coaches').select().limit(10),
      _fetchPaymentRows(),
      _supabase
          .from('pending_payments')
          .select()
          .order('created_at', ascending: false)
          .limit(50),
      _fetchAutoCanceledRows(),
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
    final paymentRows = results[3] as List<Map<String, dynamic>>;
    final pendingRows =
        List<Map<String, dynamic>>.from((results[4] as List).cast<Map>());
    final autoCanceledRows = results[5] as List<Map<String, dynamic>>;

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
    final previousDayRevenue = _latestPreviousDayRevenue(allDailyRows, now);
    final weeklyRevenue =
        chartDays.fold<double>(0, (sum, day) => sum + day.amount);
    final previousWeeklyRevenue = previousWeekRows.fold<double>(
      0,
      (sum, row) =>
          sum +
          _pickDouble(
            row,
            ['amount', 'revenue', 'total_revenue', 'daily_revenue'],
          ),
    );

    final monthlyCurrent = _pickDouble(
      monthlyRow,
      ['current_revenue', 'monthly_revenue', 'revenue', 'amount'],
      fallback: _monthlyRevenueFromDailyRows(allDailyRows, monthStartIso),
    );

    final previousMonthStart = DateTime(now.year, now.month - 1, 1);
    final previousMonthRevenue = _monthlyRevenueFromDailyRows(
      allDailyRows,
      _toIsoDate(previousMonthStart),
    );

    final yearlyRevenue = _yearlyRevenueFromDailyRows(allDailyRows, now.year);
    final previousYearRevenue =
        _yearlyRevenueFromDailyRows(allDailyRows, now.year - 1);

    final topCoaches = coachRows
        .map(
          (row) => TopEarningCoach(
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
          ),
        )
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final pendingTransactions = pendingRows
        .map(_transactionFromPendingRow)
        .where((tx) => tx.amount > 0 || tx.bookingId.isNotEmpty)
        .toList();

    final confirmedTransactions = paymentRows
        .map(_transactionFromPaymentRow)
        .where((tx) => tx.status == FinancePaymentStatus.confirmed)
        .toList();

    final autoCanceledTransactions =
        autoCanceledRows.map(_transactionFromAutoCanceledRow).toList();

    final pendingBookingIds = pendingTransactions.map((t) => t.bookingId).toSet();
    final autoCanceledBookingIds =
        autoCanceledTransactions.map((t) => t.bookingId).toSet();
    final merged = <FinanceTransaction>[
      ...pendingTransactions,
      ...autoCanceledTransactions,
      ...confirmedTransactions.where(
        (tx) =>
            (tx.bookingId.isEmpty ||
                !pendingBookingIds.contains(tx.bookingId)) &&
            (tx.bookingId.isEmpty ||
                !autoCanceledBookingIds.contains(tx.bookingId)),
      ),
    ]..sort((a, b) => b.date.compareTo(a.date));

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
      monthlyRevenue: monthlyCurrent < 0 ? 0 : monthlyCurrent,
      monthlyRevenueChange: _percentageChange(
        current: monthlyCurrent < 0 ? 0 : monthlyCurrent,
        previous: previousMonthRevenue,
      ),
      yearlyRevenue: yearlyRevenue,
      yearlyRevenueChange: _percentageChange(
        current: yearlyRevenue,
        previous: previousYearRevenue,
      ),
      chart: chartDays,
      dailyHistory: dailyHistory,
      topCoaches: topCoaches,
      transactions: merged,
      pendingCount: pendingTransactions.length,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchPaymentRows() async {
    try {
      final response = await _supabase
          .from('payments')
          .select(
            'id, amount, payment_method, status, payment_date, created_at, '
            'booking_id, user_id, profiles:user_id(full_name), '
            'bookings:booking_id(subscription_start, subscription_end, coach_id, '
            'coaches:coach_id(name, specialty))',
          )
          .order('created_at', ascending: false)
          .limit(100);
      return List<Map<String, dynamic>>.from((response as List).cast<Map>());
    } catch (_) {
      final response = await _supabase
          .from('payments')
          .select()
          .order('created_at', ascending: false)
          .limit(100);
      return List<Map<String, dynamic>>.from((response as List).cast<Map>());
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAutoCanceledRows() async {
    try {
      final response = await _supabase
          .from('cash_booking_expiry_log')
          .select(
            'id, booking_id, user_id, coach_id, payment_method, total_price, '
            'booking_created_at, payment_deadline, expired_at, '
            'profiles:user_id(full_name), coaches:coach_id(name)',
          )
          .order('expired_at', ascending: false)
          .limit(50);
      return List<Map<String, dynamic>>.from((response as List).cast<Map>());
    } catch (_) {
      try {
        final response = await _supabase
            .from('cash_booking_expiry_log')
            .select()
            .order('expired_at', ascending: false)
            .limit(50);
        return List<Map<String, dynamic>>.from((response as List).cast<Map>());
      } catch (_) {
        return const [];
      }
    }
  }

  FinanceTransaction _transactionFromPendingRow(Map<String, dynamic> row) {
    final start = _asDate(row['subscription_start']);
    final end = _asDate(row['subscription_end']);
    final coachName = _pickNullableString(row, ['coach_name']);
    return FinanceTransaction(
      id: _pickString(row, ['booking_id', 'id']),
      bookingId: _pickString(row, ['booking_id', 'id']),
      memberName: _pickString(
        row,
        ['full_name', 'user_name'],
        fallback: 'Member',
      ),
      coachName: coachName,
      paymentMethod: _pickString(row, ['payment_method'], fallback: 'cash'),
      detail: _membershipLabel(start, end, coachName),
      date: _asDate(row['created_at']) ?? DateTime.now(),
      amount: _pickDouble(row, ['total_price', 'amount']),
      status: FinancePaymentStatus.pending,
    );
  }

  FinanceTransaction _transactionFromAutoCanceledRow(Map<String, dynamic> row) {
    String memberName = 'Member';
    final profile = row['profiles'];
    if (profile is Map) {
      memberName = _pickString(
        Map<String, dynamic>.from(profile),
        ['full_name', 'name'],
        fallback: 'Member',
      );
    }

    String? coachName;
    final coach = row['coaches'];
    if (coach is Map) {
      coachName = _pickNullableString(
        Map<String, dynamic>.from(coach),
        ['name', 'coach_name'],
      );
    }

    return FinanceTransaction(
      id: _pickString(row, ['id', 'booking_id']),
      bookingId: _pickString(row, ['booking_id']),
      memberName: memberName,
      coachName: coachName,
      paymentMethod: _pickString(row, ['payment_method'], fallback: 'cash'),
      detail: coachName ?? 'Membership',
      date: _asDate(row['expired_at'] ?? row['booking_created_at']) ??
          DateTime.now(),
      amount: _pickDouble(row, ['total_price', 'amount']),
      status: FinancePaymentStatus.autoCanceled,
      cancelReason: 'Cash payment not confirmed before deadline',
    );
  }

  FinanceTransaction _transactionFromPaymentRow(Map<String, dynamic> row) {
    final statusRaw =
        _pickString(row, ['status', 'payment_status']).toLowerCase();
    final status = switch (statusRaw) {
      'pending' || 'pending_payment' || 'awaiting_verification' =>
        FinancePaymentStatus.pending,
      'rejected' || 'refunded' => FinancePaymentStatus.rejected,
      _ => FinancePaymentStatus.confirmed,
    };

    final profile = row['profiles'];
    String memberName = 'Member';
    if (profile is Map) {
      memberName = _pickString(
        Map<String, dynamic>.from(profile),
        ['full_name', 'name'],
        fallback: 'Member',
      );
    } else {
      memberName = _pickString(
        row,
        ['full_name', 'user_name', 'member_name'],
        fallback: 'Member',
      );
    }

    String? coachName;
    DateTime? subStart;
    DateTime? subEnd;
    final booking = row['bookings'];
    if (booking is Map) {
      final bookingMap = Map<String, dynamic>.from(booking);
      subStart = _asDate(bookingMap['subscription_start']);
      subEnd = _asDate(bookingMap['subscription_end']);
      final coach = bookingMap['coaches'];
      if (coach is Map) {
        coachName = _pickNullableString(
          Map<String, dynamic>.from(coach),
          ['name', 'coach_name'],
        );
      }
    }

    return FinanceTransaction(
      id: _pickString(row, ['id', 'payment_id', 'booking_id']),
      bookingId: _pickString(row, ['booking_id']),
      memberName: memberName,
      coachName: coachName,
      paymentMethod: _pickString(row, ['payment_method'], fallback: 'cash'),
      detail: _membershipLabel(subStart, subEnd, coachName),
      date: _asDate(row['created_at'] ?? row['payment_date']) ?? DateTime.now(),
      amount: _pickDouble(row, ['amount', 'total_price', 'paid_amount']),
      status: status,
    );
  }

  String _membershipLabel(DateTime? start, DateTime? end, String? coachName) {
    if (start != null && end != null) {
      final days = end.difference(start).inDays;
      if (days >= 80) return '3 month · ${coachName ?? 'Membership'}';
      if (days >= 50) return '2 month · ${coachName ?? 'Membership'}';
      if (days >= 20) return '1 month · ${coachName ?? 'Membership'}';
    }
    if (coachName != null && coachName.trim().isNotEmpty) {
      return coachName.trim();
    }
    return 'Membership';
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
    return 0;
  }

  double _latestPreviousDayRevenue(
    List<Map<String, dynamic>> rows,
    DateTime now,
  ) {
    final yesterday =
        DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
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

  double _yearlyRevenueFromDailyRows(
    List<Map<String, dynamic>> rows,
    int year,
  ) {
    return rows.fold<double>(0, (sum, row) {
      final date = _asDate(
        row['payment_date'] ?? row['day'] ?? row['date'] ?? row['created_at'],
      );
      if (date == null || date.year != year) return sum;
      return sum +
          _pickDouble(
            row,
            ['daily_revenue', 'amount', 'revenue', 'total_revenue'],
          );
    });
  }
}

enum FinancePaymentStatus { confirmed, pending, rejected, autoCanceled }

class FinanceDashboardData extends Equatable {
  const FinanceDashboardData({
    required this.dailyRevenue,
    required this.dailyRevenueChange,
    required this.weeklyRevenue,
    required this.weeklyRevenueChange,
    required this.monthlyRevenue,
    required this.monthlyRevenueChange,
    required this.yearlyRevenue,
    required this.yearlyRevenueChange,
    required this.chart,
    required this.dailyHistory,
    required this.topCoaches,
    required this.transactions,
    required this.pendingCount,
  });

  final double dailyRevenue;
  final double dailyRevenueChange;
  final double weeklyRevenue;
  final double weeklyRevenueChange;
  final double monthlyRevenue;
  final double monthlyRevenueChange;
  final double yearlyRevenue;
  final double yearlyRevenueChange;
  final List<FinanceDailyIncome> chart;
  final List<FinanceDailyIncome> dailyHistory;
  final List<TopEarningCoach> topCoaches;
  final List<FinanceTransaction> transactions;
  final int pendingCount;

  @override
  List<Object?> get props => [
        dailyRevenue,
        dailyRevenueChange,
        weeklyRevenue,
        weeklyRevenueChange,
        monthlyRevenue,
        monthlyRevenueChange,
        yearlyRevenue,
        yearlyRevenueChange,
        chart,
        dailyHistory,
        topCoaches,
        transactions,
        pendingCount,
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

class FinanceTransaction extends Equatable {
  const FinanceTransaction({
    required this.id,
    required this.bookingId,
    required this.memberName,
    this.coachName,
    required this.paymentMethod,
    required this.detail,
    required this.date,
    required this.amount,
    required this.status,
    this.cancelReason,
  });

  final String id;
  final String bookingId;
  final String memberName;
  final String? coachName;
  final String paymentMethod;
  final String detail;
  final DateTime date;
  final double amount;
  final FinancePaymentStatus status;
  final String? cancelReason;

  bool get isPending => status == FinancePaymentStatus.pending;
  bool get isConfirmed => status == FinancePaymentStatus.confirmed;
  bool get isAutoCanceled => status == FinancePaymentStatus.autoCanceled;

  String get paymentMethodLabel {
    final raw = paymentMethod.toLowerCase();
    if (raw.contains('insta')) return 'InstaPay';
    if (raw == 'cash') return 'Cash';
    if (raw.isEmpty) return 'Payment';
    return paymentMethod[0].toUpperCase() + paymentMethod.substring(1);
  }

  bool matchesSearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final timeHint = [
      date.hour.toString().padLeft(2, '0'),
      date.minute.toString().padLeft(2, '0'),
      '${date.day}',
      '${date.month}',
      '${date.year}',
    ].join(' ');
    return memberName.toLowerCase().contains(q) ||
        (coachName?.toLowerCase().contains(q) ?? false) ||
        paymentMethodLabel.toLowerCase().contains(q) ||
        detail.toLowerCase().contains(q) ||
        timeHint.contains(q) ||
        (cancelReason?.toLowerCase().contains(q) ?? false);
  }

  @override
  List<Object?> get props => [
        id,
        bookingId,
        memberName,
        coachName,
        paymentMethod,
        detail,
        date,
        amount,
        status,
        cancelReason,
      ];
}
