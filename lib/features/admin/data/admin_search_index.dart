import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

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
}

/// Static catalog of admin destinations (no network).
abstract final class AdminAppSearchIndex {
  static const destinations = <AdminSearchDestination>[
    AdminSearchDestination(
      id: AdminSearchDestinationId.dashboard,
      title: 'Dashboard',
      subtitle: 'KPIs, today, and quick actions',
      icon: Iconsax.home_2,
      keywords: ['dashboard', 'home', 'admin home', 'overview'],
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
      ],
    ),
    AdminSearchDestination(
      id: AdminSearchDestinationId.addCoach,
      title: 'Add Coach',
      subtitle: 'Create a coach profile',
      icon: Iconsax.user_add,
      keywords: ['add coach', 'new coach', 'create coach', 'coach', 'create'],
    ),
    AdminSearchDestination(
      id: AdminSearchDestinationId.addSession,
      title: 'Add Session',
      subtitle: 'Schedule a class',
      icon: Iconsax.add_circle,
      keywords: ['add session', 'new session', 'schedule', 'class', 'create'],
    ),
    AdminSearchDestination(
      id: AdminSearchDestinationId.tracking,
      title: 'Tracking',
      subtitle: 'Members and coaches overview',
      icon: Iconsax.chart,
      keywords: ['tracking', 'track', 'users', 'members list'],
    ),
    AdminSearchDestination(
      id: AdminSearchDestinationId.allMembers,
      title: 'All Members',
      subtitle: 'Search and open member profiles',
      icon: Iconsax.people,
      keywords: ['members', 'all members', 'users', 'member'],
    ),
    AdminSearchDestination(
      id: AdminSearchDestinationId.allCoaches,
      title: 'All Coaches',
      subtitle: 'Coach directory and stats',
      icon: Iconsax.teacher,
      keywords: ['coaches', 'all coaches', 'trainer', 'coach list'],
    ),
    AdminSearchDestination(
      id: AdminSearchDestinationId.finance,
      title: 'Finance',
      subtitle: 'Revenue, coaches, and payouts',
      icon: Iconsax.wallet_2,
      keywords: ['finance', 'revenue', 'money', 'payout', 'earnings'],
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
      ],
    ),
    AdminSearchDestination(
      id: AdminSearchDestinationId.todayAttendance,
      title: "Today's Attendance",
      subtitle: 'Who checked in today',
      icon: Iconsax.tick_square,
      keywords: ['attendance', "today's attendance", 'check in', 'present'],
    ),
    AdminSearchDestination(
      id: AdminSearchDestinationId.allSchedules,
      title: 'All Schedules',
      subtitle: 'Full session timetable',
      icon: Iconsax.calendar,
      keywords: ['schedule', 'schedules', 'timetable', 'all sessions'],
    ),
    AdminSearchDestination(
      id: AdminSearchDestinationId.freezeRequests,
      title: 'Freeze Requests',
      subtitle: 'Approve or review freezes',
      icon: Iconsax.pause_circle,
      keywords: ['freeze', 'freeze requests', 'pause', 'hold'],
    ),
    AdminSearchDestination(
      id: AdminSearchDestinationId.scanQr,
      title: 'Scan QR',
      subtitle: 'Check in a member',
      icon: Iconsax.scan_barcode,
      keywords: ['qr', 'scan', 'scan qr', 'check in', 'scanner'],
    ),
    AdminSearchDestination(
      id: AdminSearchDestinationId.notifications,
      title: 'Notifications',
      subtitle: 'Admin alerts and updates',
      icon: Iconsax.notification,
      keywords: ['notification', 'notifications', 'alerts'],
    ),
    AdminSearchDestination(
      id: AdminSearchDestinationId.profile,
      title: 'Admin Profile',
      subtitle: 'Account and sign out',
      icon: Iconsax.user,
      keywords: ['profile', 'account', 'settings', 'logout'],
    ),
    AdminSearchDestination(
      id: AdminSearchDestinationId.transactions,
      title: 'All Transactions',
      subtitle: 'Full payment history',
      icon: Iconsax.receipt_2,
      keywords: ['transactions', 'transaction', 'history', 'receipts'],
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
  static const pages = [
    'members',
    'coaches',
    'classes',
    'pending payments',
    'attendance',
    'freeze requests',
  ];

  static const tracking = [
    'member name',
    'phone number',
    'coach name',
    'branch',
    'pending payments',
  ];

  static const attendance = [
    'member name',
    'coach name',
    'session type',
    'branch',
    'attendance status',
  ];

  static const sessions = [
    'coach name',
    'class type',
    'branch',
    'day',
    'time slot',
  ];

  static const coaches = [
    'coach name',
    'specialty',
    'active members',
    'today sessions',
  ];

  static const members = [
    'member name',
    'phone number',
    'active bookings',
    'pending payment',
  ];

  static const transactions = [
    'member name',
    'coach name',
    'booking time',
    'confirmed',
    'pending',
  ];
}
