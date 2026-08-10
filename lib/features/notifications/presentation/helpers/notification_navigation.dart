import 'package:flutter/material.dart';

import 'package:prince_academy/features/admin/presentation/pages/all_freeze_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/pending_payments_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/today_sessions_page.dart';
import 'package:prince_academy/features/booking/presentation/pages/booking_history_page.dart';
import 'package:prince_academy/features/booking/presentation/pages/my_freeze_requests_page.dart';
import 'package:prince_academy/features/sessions/presentation/pages/sessions_page.dart';

/// Shared deep-link target for push banners and in-app notification taps.
class NotificationNavigation {
  const NotificationNavigation._();

  static String typeOf(Map<String, dynamic>? data, {String? fallbackType}) {
    final raw = (data?['type'] ?? data?['route'] ?? fallbackType ?? '')
        .toString()
        .toLowerCase()
        .trim();
    return raw;
  }

  static String? bookingIdOf(Map<String, dynamic>? data) {
    final value = data?['booking_id'] ?? data?['bookingId'];
    if (value == null) return null;
    final id = value.toString().trim();
    return id.isEmpty ? null : id;
  }

  /// Destination widget for a notification type / payload.
  ///
  /// [fallback] is used when the type is unknown or admin-only for a member.
  static Widget destination({
    required bool isAdmin,
    required Widget fallback,
    String? type,
    Map<String, dynamic>? data,
  }) {
    final raw = typeOf(data, fallbackType: type);

    switch (raw) {
      case 'booking':
      case 'booking_confirmed':
      case 'booking_rejected':
      case 'booking_auto_cancelled':
      case 'subscription':
        return const BookingHistoryPage();
      case 'payment':
      case 'payment_pending':
        return isAdmin
            ? const PendingPaymentsPage()
            : const BookingHistoryPage();
      case 'session':
      case 'session_reminder':
      case 'attendance':
        return isAdmin
            ? const TodaySessionsPage()
            : const SessionsPage(showBackButton: true);
      case 'freeze':
      case 'freeze_request':
      case 'freeze_review':
        if (isAdmin) return const AllFreezePage();
        return const MyFreezeRequestsPage();
      case 'attention':
      case 'needs_attention':
        return isAdmin ? const TodaySessionsPage() : fallback;
      case 'admin':
        return isAdmin ? const PendingPaymentsPage() : fallback;
      default:
        return fallback;
    }
  }

  static Future<void> open(
    BuildContext context, {
    required bool isAdmin,
    required Widget fallback,
    String? type,
    Map<String, dynamic>? data,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => destination(
          isAdmin: isAdmin,
          fallback: fallback,
          type: type,
          data: data,
        ),
      ),
    );
  }
}
