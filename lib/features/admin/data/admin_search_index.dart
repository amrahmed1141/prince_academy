import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/l10n/app_strings.dart';

/// Admin-shell screens discoverable from dashboard search.
enum AdminSearchDestinationId {
  dashboard,
  manageAcademy,
  addCoach,
  addSession,
  tracking,
  allMembers,
  allCoaches,
  finance,
  pendingPayments,
  todaySessions,
  todayAttendance,
  allSchedules,
  freezeRequests,
  scanQr,
  notifications,
  profile,
  transactions,
}

class AdminSearchDestination {
  const AdminSearchDestination({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.keywords,
  });

  final AdminSearchDestinationId id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> keywords;

  String localizedTitle(AppStrings s) {
    switch (id) {
      case AdminSearchDestinationId.dashboard:
        return s.dashboard;
      case AdminSearchDestinationId.manageAcademy:
        return s.create;
      case AdminSearchDestinationId.addCoach:
        return s.addCoach;
      case AdminSearchDestinationId.addSession:
        return s.addSession;
      case AdminSearchDestinationId.tracking:
        return s.tracking;
      case AdminSearchDestinationId.allMembers:
        return s.allMembers;
      case AdminSearchDestinationId.allCoaches:
        return s.allCoaches;
      case AdminSearchDestinationId.finance:
        return s.finance;
      case AdminSearchDestinationId.pendingPayments:
        return s.pendingPayments;
      case AdminSearchDestinationId.todaySessions:
        return s.todaysSessions;
      case AdminSearchDestinationId.todayAttendance:
        return s.todaysAttendance;
      case AdminSearchDestinationId.allSchedules:
        return s.allSchedules;
      case AdminSearchDestinationId.freezeRequests:
        return s.freezeRequests;
      case AdminSearchDestinationId.scanQr:
        return s.scanQr;
      case AdminSearchDestinationId.notifications:
        return s.notifications;
      case AdminSearchDestinationId.profile:
        return s.adminProfile;
      case AdminSearchDestinationId.transactions:
        return s.allTransactions;
    }
  }

  String localizedSubtitle(AppStrings s) {
    switch (id) {
      case AdminSearchDestinationId.dashboard:
        return s.t('destDashboardSub');
      case AdminSearchDestinationId.manageAcademy:
        return s.t('destCreateSub');
      case AdminSearchDestinationId.addCoach:
        return s.t('destAddCoachSub');
      case AdminSearchDestinationId.addSession:
        return s.t('destAddSessionSub');
      case AdminSearchDestinationId.tracking:
        return s.t('destTrackingSub');
      case AdminSearchDestinationId.allMembers:
        return s.t('destAllMembersSub');
      case AdminSearchDestinationId.allCoaches:
        return s.t('destAllCoachesSub');
      case AdminSearchDestinationId.finance:
        return s.t('destFinanceSub');
      case AdminSearchDestinationId.pendingPayments:
        return s.t('destPendingPaymentsSub');
      case AdminSearchDestinationId.todaySessions:
        return s.t('destTodaySessionsSub');
      case AdminSearchDestinationId.todayAttendance:
        return s.t('destTodayAttendanceSub');
      case AdminSearchDestinationId.allSchedules:
        return s.t('destAllSchedulesSub');
      case AdminSearchDestinationId.freezeRequests:
        return s.t('destFreezeRequestsSub');
      case AdminSearchDestinationId.scanQr:
        return s.t('destScanQrSub');
      case AdminSearchDestinationId.notifications:
        return s.t('destNotificationsSub');
      case AdminSearchDestinationId.profile:
        return s.t('destProfileSub');
      case AdminSearchDestinationId.transactions:
        return s.t('destTransactionsSub');
    }
  }
}

/// Static catalog of admin destinations (no network).
abstract final class AdminAppSearchIndex {
  static const destinations = <AdminSearchDestination>[
    AdminSearchDestination(
      id: AdminSearchDestinationId.dashboard,
      title: 'Dashboard',
      subtitle: 'KPIs, today, and quick actions',
      icon: Iconsax.home_2,
      keywords: [
        'dashboard',
        'home',
        'admin home',
        'overview',
        'لوحة',
        'لوحة التحكم',
        'الرئيسية',
      ],
    ),
    AdminSearchDestination(
      id: AdminSearchDestinationId.manageAcademy,
      title: 'Create',
      subtitle: 'Add coaches and sessions',
      icon: Iconsax.add_circle,
      keywords: [
        'manage',
        'manage academy',
        'add info',
        'create',
        'academy',
        'إنشاء',
        'اضافة',
        'إضافة',
      ],
    ),
    AdminSearchDestination(
      id: AdminSearchDestinationId.addCoach,
      title: 'Add Coach',
      subtitle: 'Create a coach profile',
      icon: Iconsax.user_add,
      keywords: [
        'add coach',
        'new coach',
        'create coach',
        'coach',
        'create',
        'مدرب',
        'إضافة مدرب',
      ],
    ),
    AdminSearchDestination(
      id: AdminSearchDestinationId.addSession,
      title: 'Add Session',
      subtitle: 'Schedule a class',
      icon: Iconsax.add_circle,
      keywords: [
        'add session',
        'new session',
        'schedule',
        'class',
        'create',
        'حصة',
        'إضافة حصة',
        'جلسة',
      ],
    ),
    AdminSearchDestination(
      id: AdminSearchDestinationId.tracking,
      title: 'Tracking',
      subtitle: 'Members and coaches overview',
      icon: Iconsax.chart,
      keywords: [
        'tracking',
        'track',
        'users',
        'members list',
        'متابعة',
        'تتبع',
      ],
    ),
    AdminSearchDestination(
      id: AdminSearchDestinationId.allMembers,
      title: 'All Members',
      subtitle: 'Search and open member profiles',
      icon: Iconsax.people,
      keywords: [
        'members',
        'all members',
        'users',
        'member',
        'أعضاء',
        'الاعضاء',
        'الأعضاء',
      ],
    ),
    AdminSearchDestination(
      id: AdminSearchDestinationId.allCoaches,
      title: 'All Coaches',
      subtitle: 'Coach directory and stats',
      icon: Iconsax.teacher,
      keywords: [
        'coaches',
        'all coaches',
        'trainer',
        'coach list',
        'مدربين',
        'المدربين',
        'المدربون',
      ],
    ),
    AdminSearchDestination(
      id: AdminSearchDestinationId.finance,
      title: 'Finance',
      subtitle: 'Revenue, coaches, and payouts',
      icon: Iconsax.wallet_2,
      keywords: [
        'finance',
        'revenue',
        'money',
        'payout',
        'earnings',
        'مالية',
        'المالية',
        'إيراد',
      ],
    ),
    AdminSearchDestination(
      id: AdminSearchDestinationId.pendingPayments,
      title: 'Pending Payments',
      subtitle: 'Verify or reject screenshots',
      icon: Iconsax.tick_circle,
      keywords: [
        'pending',
        'pending payments',
        'verify',
        'verify payment',
        'payment',
        'payments',
        'instapay',
        'مدفوعات',
        'معلق',
        'تحقق',
      ],
    ),
    AdminSearchDestination(
      id: AdminSearchDestinationId.todaySessions,
      title: "Today's Sessions",
      subtitle: 'Classes running today',
      icon: Iconsax.calendar_1,
      keywords: [
        'today',
        "today's sessions",
        'today sessions',
        'sessions',
        'classes',
        'حصص اليوم',
        'اليوم',
      ],
    ),
    AdminSearchDestination(
      id: AdminSearchDestinationId.todayAttendance,
      title: "Today's Attendance",
      subtitle: 'Who checked in today',
      icon: Iconsax.tick_square,
      keywords: [
        'attendance',
        "today's attendance",
        'check in',
        'present',
        'حضور',
        'حضور اليوم',
      ],
    ),
    AdminSearchDestination(
      id: AdminSearchDestinationId.allSchedules,
      title: 'All Schedules',
      subtitle: 'Full session timetable',
      icon: Iconsax.calendar,
      keywords: [
        'schedule',
        'schedules',
        'timetable',
        'all sessions',
        'جداول',
        'جدول',
      ],
    ),
    AdminSearchDestination(
      id: AdminSearchDestinationId.freezeRequests,
      title: 'Freeze Requests',
      subtitle: 'Approve or review freezes',
      icon: Iconsax.pause_circle,
      keywords: [
        'freeze',
        'freeze requests',
        'pause',
        'hold',
        'تجميد',
        'طلبات التجميد',
      ],
    ),
    AdminSearchDestination(
      id: AdminSearchDestinationId.scanQr,
      title: 'Scan QR',
      subtitle: 'Check in a member',
      icon: Iconsax.scan_barcode,
      keywords: [
        'qr',
        'scan',
        'scan qr',
        'check in',
        'scanner',
        'مسح',
        'باركود',
      ],
    ),
    AdminSearchDestination(
      id: AdminSearchDestinationId.notifications,
      title: 'Notifications',
      subtitle: 'Admin alerts and updates',
      icon: Iconsax.notification,
      keywords: [
        'notification',
        'notifications',
        'alerts',
        'إشعارات',
        'اشعارات',
        'تنبيهات',
      ],
    ),
    AdminSearchDestination(
      id: AdminSearchDestinationId.profile,
      title: 'Admin Profile',
      subtitle: 'Name, notifications and sign out',
      icon: Iconsax.user,
      keywords: [
        'profile',
        'account',
        'settings',
        'logout',
        'language',
        'ملف',
        'اللغة',
        'حساب',
      ],
    ),
    AdminSearchDestination(
      id: AdminSearchDestinationId.transactions,
      title: 'All Transactions',
      subtitle: 'Full payment history',
      icon: Iconsax.receipt_2,
      keywords: [
        'transactions',
        'transaction',
        'history',
        'receipts',
        'معاملات',
        'سجل',
      ],
    ),
  ];

  static List<AdminSearchDestination> match(String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return const [];

    return destinations
        .where((d) => _matches(d, query))
        .toList(growable: false);
  }

  static bool _matches(AdminSearchDestination d, String query) {
    if (d.title.toLowerCase().contains(query)) return true;
    if (d.subtitle.toLowerCase().contains(query)) return true;
    for (final keyword in d.keywords) {
      if (keyword.contains(query) || query.contains(keyword)) return true;
    }
    return false;
  }
}

abstract final class AdminSearchHints {
  static List<String> pages(BuildContext context) =>
      context.s.searchHintPages;

  static List<String> tracking(BuildContext context) =>
      context.s.searchHintTracking;

  static List<String> attendance(BuildContext context) =>
      context.s.searchHintAttendance;

  static List<String> sessions(BuildContext context) =>
      context.s.searchHintSessions;

  static List<String> coaches(BuildContext context) =>
      context.s.searchHintCoaches;

  static List<String> members(BuildContext context) =>
      context.s.searchHintMembers;

  static List<String> transactions(BuildContext context) =>
      context.s.searchHintTransactions;
}
