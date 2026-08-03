import 'dart:async';

import 'package:prince_academy/core/base/stream_repository.dart';
import 'package:prince_academy/features/admin/data/models/admin_dashboard_model.dart';
import 'package:prince_academy/features/admin/data/models/low_attendance_member_model.dart';
import 'package:prince_academy/features/admin/data/models/paged_result.dart';
import 'package:prince_academy/features/admin/data/models/pending_payment_model.dart';
import 'package:prince_academy/features/admin/data/models/today_attendance_member_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardRepository extends StreamRepository<AdminDashboardData> {
  AdminDashboardRepository(this._supabase)
      : super(cacheTtl: const Duration(seconds: 45));

  final SupabaseClient _supabase;

  static const _previewLimit = 5;

  RealtimeChannel? _bookingsChannel;
  RealtimeChannel? _paymentsChannel;
  RealtimeChannel? _coachSessionsChannel;
  RealtimeChannel? _attendanceChannel;
  Timer? _realtimeDebounce;

  static const _lowAttendanceLookbackDays = 14;

  void ensureRealtimeSubscription() {
    if (_bookingsChannel == null) {
      _bookingsChannel = _supabase
          .channel('admin-dashboard-bookings')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'bookings',
            callback: (_) => _scheduleRealtimeRefresh(),
          )
          .subscribe();
    }

    if (_paymentsChannel == null) {
      _paymentsChannel = _supabase
          .channel('admin-dashboard-payments')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'payments',
            callback: (_) => _scheduleRealtimeRefresh(),
          )
          .subscribe();
    }

    if (_coachSessionsChannel == null) {
      _coachSessionsChannel = _supabase
          .channel('admin-dashboard-coach-sessions')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'coach_sessions',
            callback: (_) => _scheduleRealtimeRefresh(),
          )
          .subscribe();
    }

    if (_attendanceChannel == null) {
      _attendanceChannel = _supabase
          .channel('admin-dashboard-attendance')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'attendance',
            callback: (_) => _scheduleRealtimeRefresh(),
          )
          .subscribe();
    }
  }

  void _scheduleRealtimeRefresh() {
    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(const Duration(milliseconds: 600), () {
      unawaited(refresh());
    });
  }

  Future<AdminDashboardData> getDashboard({bool force = false}) async {
    if (!force && hasValidCache && cachedValue != null) {
      return cachedValue!;
    }
    return refresh();
  }

  /// Today's coach sessions. Shares the dashboard TTL cache so a second open
  /// (or opening after the dashboard warmed the cache) skips the network.
  Future<List<DashboardTodaySession>> getTodaySessions({
    bool force = false,
  }) async {
    final data = await getDashboard(force: force);
    return List<DashboardTodaySession>.from(data.todaySessionsPreview);
  }

  /// Members booked on today's sessions (detail for the attendance KPI).
  /// Not folded into [fetchFromApi] — loaded only by the detail page.
  Future<PagedResult<TodayAttendanceMember>> getTodayAttendanceMembers({
    int limit = 50,
    int offset = 0,
    String? search,
    String? coachId,
    bool force = false,
  }) async {
    // [force] kept for caller symmetry with other list APIs.
    final safeLimit = limit.clamp(1, 100);
    final safeOffset = offset < 0 ? 0 : offset;
    final trimmedSearch = search?.trim();
    final searchParam =
        (trimmedSearch == null || trimmedSearch.isEmpty) ? null : trimmedSearch;
    final coachParam =
        (coachId == null || coachId.trim().isEmpty) ? null : coachId.trim();

    try {
      var query = _supabase.from('today_attendance_members').select(
            'booking_id, user_id, member_name, member_photo, '
            'session_id, coach_id, coach_name, coach_photo, '
            'session_type, session_time, branch_name, is_attended',
          );

      if (coachParam != null) {
        query = query.eq('coach_id', coachParam);
      }

      if (searchParam != null) {
        final escaped = searchParam.replaceAll(RegExp(r'[%_,]'), '');
        if (escaped.isNotEmpty) {
          query = query.or(
            'member_name.ilike.%$escaped%,'
            'coach_name.ilike.%$escaped%,'
            'session_type.ilike.%$escaped%,'
            'session_time.ilike.%$escaped%,'
            'branch_name.ilike.%$escaped%',
          );
        }
      }

      final response = await query
          .order('is_attended')
          .order('member_name')
          .range(safeOffset, safeOffset + safeLimit - 1);

      final members = (response as List)
          .map(
            (json) => TodayAttendanceMember.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();

      return PagedResult(
        items: members,
        hasMore: members.length >= safeLimit,
      );
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'load today attendance members'));
    }
  }

  /// KPI totals for today (matches dashboard Σ attended / Σ booked).
  Future<({int attended, int booked})> getTodayAttendanceKpiTotals({
    bool force = false,
  }) async {
    final sessions = await getTodaySessions(force: force);
    final attended = sessions.fold<int>(0, (sum, s) => sum + s.attendedCount);
    final booked = sessions.fold<int>(0, (sum, s) => sum + s.bookedCount);
    return (attended: attended, booked: booked);
  }

  /// Distinct coaches with sessions today (for filter chips).
  Future<List<({String coachId, String coachName, String? coachPhoto})>>
      getTodayAttendanceCoaches({bool force = false}) async {
    final sessions = await getTodaySessions(force: force);
    final seen = <String>{};
    final coaches =
        <({String coachId, String coachName, String? coachPhoto})>[];
    for (final session in sessions) {
      if (session.coachId.isEmpty || !seen.add(session.coachId)) continue;
      coaches.add((
        coachId: session.coachId,
        coachName: session.coachName,
        coachPhoto: session.coachPhoto,
      ));
    }
    coaches.sort(
      (a, b) => a.coachName.toLowerCase().compareTo(b.coachName.toLowerCase()),
    );
    return coaches;
  }

  @override
  Future<AdminDashboardData> fetchFromApi() async {
    // Opportunistic cleanup of unconfirmed cash bookings past the 3-day window.
    // Primary schedule is pg_cron; this covers gaps when cron is unavailable.
    await _expireUnconfirmedCashBookings();

    final results = await Future.wait([
      _fetchPendingPayments(),
      _fetchLowAttendanceMembers(),
      _fetchTodayRevenue(),
      _fetchActiveMembersCount(),
      _fetchTodaySessions(),
      _fetchCoachesCount(),
      _fetchFreezePendingCount(),
    ]);

    final pending = results[0] as List<PendingPaymentModel>;
    final lowAttendance = results[1] as List<LowAttendanceMemberModel>;
    final todayRevenue = results[2] as double;
    final activeMembersCount = results[3] as int;
    final todaySessions = results[4] as List<DashboardTodaySession>;
    final coachesCount = results[5] as int;
    final freezePendingCount = results[6] as int;

    return AdminDashboardData(
      pendingPaymentsCount: pending.length,
      pendingPaymentsPreview: pending.take(_previewLimit).toList(),
      lowAttendancePreview: lowAttendance.take(_previewLimit).toList(),
      todayRevenue: todayRevenue,
      activeMembersCount: activeMembersCount,
      todaySessionsCount: todaySessions.length,
      todaySessionsPreview: todaySessions,
      coachesCount: coachesCount,
      freezePendingCount: freezePendingCount,
    );
  }

  Future<void> _expireUnconfirmedCashBookings() async {
    try {
      await _supabase.rpc('auto_delete_expired_cash_bookings');
    } catch (_) {
      // Best-effort — cron / next refresh will retry.
    }
  }

  /// Legacy alias used by older call sites.
  Future<AdminDashboardData> loadDashboard({bool force = false}) =>
      getDashboard(force: force);

  Future<List<DashboardTodaySession>> _fetchTodaySessions() async {
    try {
      final response = await _supabase.from('today_coach_sessions').select(
            'session_id, coach_id, coach_name, coach_photo, '
            'branch_id, branch_name, session_type, session_time, '
            'duration_minutes, booked_count, attended_count',
          );

      final sessions = (response as List)
          .map(
            (json) => DashboardTodaySession.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();

      sessions.sort((a, b) {
        final aTime = a.sessionTime ?? '';
        final bTime = b.sessionTime ?? '';
        final byTime = aTime.compareTo(bTime);
        if (byTime != 0) return byTime;
        return a.coachName.compareTo(b.coachName);
      });

      return sessions;
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'load today sessions'));
    }
  }

  Future<List<LowAttendanceMemberModel>> _fetchLowAttendanceMembers() async {
    try {
      final response = await _supabase.rpc(
        'get_dashboard_low_attendance_members',
        params: {
          'p_days': _lowAttendanceLookbackDays,
          'p_limit': _previewLimit,
        },
      );

      if (response == null) return [];

      return (response as List)
          .map(
            (json) => LowAttendanceMemberModel.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'load low-attendance members'));
    }
  }

  Future<List<PendingPaymentModel>> _fetchPendingPayments() async {
    try {
      final response = await _supabase
          .from('pending_payments')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (json) => PendingPaymentModel.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'load pending payments'));
    }
  }

  Future<double> _fetchTodayRevenue() async {
    try {
      final today = _toIsoDate(DateTime.now());
      final response = await _supabase
          .from('finance_daily_revenue')
          .select()
          .eq('payment_date', today)
          .maybeSingle();

      if (response == null) {
        final all = await _supabase
            .from('finance_daily_revenue')
            .select()
            .order('payment_date', ascending: false)
            .limit(7);

        final rows = List<Map<String, dynamic>>.from((all as List).cast<Map>());
        for (final row in rows) {
          final date = _asDate(
            row['payment_date'] ??
                row['day'] ??
                row['date'] ??
                row['created_at'],
          );
          if (date == null) continue;
          if (_isSameDay(date, DateTime.now())) {
            return _pickDouble(
              row,
              ['daily_revenue', 'amount', 'revenue', 'total_revenue'],
            );
          }
        }
        return 0;
      }

      final row = Map<String, dynamic>.from(response);
      return _pickDouble(
        row,
        ['daily_revenue', 'amount', 'revenue', 'total_revenue'],
      );
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'load today revenue'));
    }
  }

  Future<int> _fetchActiveMembersCount() async {
    try {
      final response =
          await _supabase.from('active_users_with_qr').select('user_id');
      return (response as List).length;
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'load active members count'));
    }
  }

  Future<int> _fetchCoachesCount() async {
    try {
      final response = await _supabase
          .from('coaches')
          .select('id')
          .eq('is_active', true);
      return (response as List).length;
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'load coaches count'));
    }
  }

  /// Best-effort — missing RPC / schema must not block the dashboard.
  Future<int> _fetchFreezePendingCount() async {
    try {
      final response = await _supabase.rpc('get_freeze_dashboard_count');
      if (response is int) return response;
      if (response is num) return response.toInt();
      return int.tryParse(response?.toString() ?? '') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static String _mapPostgrestError(PostgrestException e, String action) {
    final message = e.message.trim();
    if (message.isEmpty) {
      return 'Could not $action. Please try again.';
    }
    return 'Could not $action. $message';
  }

  static String _toIsoDate(DateTime date) {
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    final al = a.toLocal();
    final bl = b.toLocal();
    return al.year == bl.year && al.month == bl.month && al.day == bl.day;
  }

  static double _pickDouble(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value is num) return value.toDouble();
      if (value != null) {
        final parsed = double.tryParse(value.toString());
        if (parsed != null) return parsed;
      }
    }
    return 0;
  }

  @override
  void dispose() {
    _realtimeDebounce?.cancel();
    _bookingsChannel?.unsubscribe();
    _paymentsChannel?.unsubscribe();
    _coachSessionsChannel?.unsubscribe();
    _attendanceChannel?.unsubscribe();
    _bookingsChannel = null;
    _paymentsChannel = null;
    _coachSessionsChannel = null;
    _attendanceChannel = null;
    super.dispose();
  }
}
