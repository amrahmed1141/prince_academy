import 'package:prince_academy/features/admin/data/models/admin_dashboard_model.dart';
import 'package:prince_academy/features/admin/data/models/pending_payment_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardRepository {
  AdminDashboardRepository(this._supabase);

  final SupabaseClient _supabase;

  static const _previewLimit = 5;

  Future<AdminDashboardData> loadDashboard() async {
    final results = await Future.wait([
      _fetchPendingPayments(),
      _fetchTodayRevenue(),
      _fetchActiveMembersCount(),
      _fetchTodaySessions(),
    ]);

    final pending = results[0] as List<PendingPaymentModel>;
    final todayRevenue = results[1] as double;
    final activeMembersCount = results[2] as int;
    final todaySessions = results[3] as List<DashboardTodaySession>;

    return AdminDashboardData(
      pendingPaymentsCount: pending.length,
      pendingPaymentsPreview: pending.take(_previewLimit).toList(),
      todayRevenue: todayRevenue,
      activeMembersCount: activeMembersCount,
      todaySessionsCount: todaySessions.length,
      todaySessionsPreview: todaySessions.take(_previewLimit).toList(),
    );
  }

  Future<List<PendingPaymentModel>> _fetchPendingPayments() async {
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
  }

  Future<double> _fetchTodayRevenue() async {
    final today = _toIsoDate(DateTime.now());
    final response = await _supabase
        .from('finance_daily_revenue')
        .select()
        .eq('payment_date', today)
        .maybeSingle();

    if (response == null) {
      // Fallback: match by common alternate column names for today's row.
      final all = await _supabase
          .from('finance_daily_revenue')
          .select()
          .order('payment_date', ascending: false)
          .limit(7);

      final rows = List<Map<String, dynamic>>.from((all as List).cast<Map>());
      for (final row in rows) {
        final date = _asDate(
          row['payment_date'] ?? row['day'] ?? row['date'] ?? row['created_at'],
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
  }

  Future<int> _fetchActiveMembersCount() async {
    final response = await _supabase.from('active_users_with_qr').select('user_id');
    return (response as List).length;
  }

  Future<List<DashboardTodaySession>> _fetchTodaySessions() async {
    final response = await _supabase.from('today_bookings').select();

    final sessions = (response as List)
        .map(
          (json) => DashboardTodaySession.fromJson(
            Map<String, dynamic>.from(json as Map),
          ),
        )
        .toList();

    sessions.sort((a, b) {
      final aTime = a.selectedTime ?? '';
      final bTime = b.selectedTime ?? '';
      return aTime.compareTo(bTime);
    });

    return sessions;
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
}
