import 'package:supabase_flutter/supabase_flutter.dart';

/// InstaPay payment reference and display constants.
abstract final class PaymentReferenceHelper {
  static const instapayAccountName = 'Prince Academy';
  static const instapayAccountNumber = '0100 XXX XXXX';

  /// Builds reference: PA-FAYOMI-7PM-20260704-AHMED
  static String generate({
    required String coachName,
    required String sessionTime,
    required DateTime startDate,
  }) {
    final coachSlug = _slug(coachName, maxLen: 12);
    final timeSlug = _timeSlug(sessionTime);
    final dateSlug = _dateSlug(startDate);
    final userSlug = _userSlug();
    return 'PA-$coachSlug-$timeSlug-$dateSlug-$userSlug';
  }

  static String _slug(String value, {required int maxLen}) {
    final cleaned = value
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '')
        .replaceAll(RegExp(r'\s+'), '');
    if (cleaned.isEmpty) return 'MEMBER';
    return cleaned.length > maxLen ? cleaned.substring(0, maxLen) : cleaned;
  }

  static String _timeSlug(String time) {
    final match = RegExp(r'(\d{1,2})').firstMatch(time);
    if (match == null) return 'TIME';
    final hour = int.tryParse(match.group(1)!);
    if (hour == null) return 'TIME';
    final isPm = time.toLowerCase().contains('pm');
    final h = isPm && hour < 12 ? hour + 12 : hour;
    return '${h}H';
  }

  static String _dateSlug(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  static String _userSlug() {
    final user = Supabase.instance.client.auth.currentUser;
    final meta = user?.userMetadata;
    final name = meta?['full_name'] as String? ??
        meta?['name'] as String? ??
        user?.email?.split('@').first ??
        'MEMBER';
    return _slug(name, maxLen: 10);
  }
}
