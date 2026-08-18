import 'package:iconsax/iconsax.dart';
import 'package:flutter/material.dart';

/// Member-shell screens and actions discoverable from global search.
enum MemberSearchDestinationId {
  home,
  bookingHistory,
  sessions,
  profile,
  notifications,
  editProfile,
  payments,
  freezeRequests,
  coaches,
  bookCoach,
}

class MemberSearchDestination {
  const MemberSearchDestination({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.keywords,
  });

  final MemberSearchDestinationId id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> keywords;
}

/// Static catalog of user-side destinations (no network).
abstract final class MemberAppSearchIndex {
  static const destinations = <MemberSearchDestination>[
    MemberSearchDestination(
      id: MemberSearchDestinationId.home,
      title: 'Home',
      subtitle: 'Dashboard, coaches & today’s plan',
      icon: Iconsax.home_2,
      keywords: [
        'home',
        'dashboard',
        'feed',
        'academy',
        'today',
        "today's session",
      ],
    ),
    MemberSearchDestination(
      id: MemberSearchDestinationId.bookingHistory,
      title: 'Booking History',
      subtitle: 'Your enrollments & packages',
      icon: Iconsax.ticket,
      keywords: [
        'booking',
        'booking history',
        'bookings',
        'enrollment',
        'enrollments',
        'package',
        'packages',
        'my booking',
      ],
    ),
    MemberSearchDestination(
      id: MemberSearchDestinationId.sessions,
      title: 'My Sessions',
      subtitle: 'Upcoming & completed training',
      icon: Iconsax.calendar_1,
      keywords: [
        'session',
        'sessions',
        'my session',
        'my sessions',
        'training',
        'schedule',
        'attendance',
        'class',
        'classes',
      ],
    ),
    MemberSearchDestination(
      id: MemberSearchDestinationId.profile,
      title: 'Profile',
      subtitle: 'Account & preferences',
      icon: Iconsax.user,
      keywords: [
        'profile',
        'account',
        'my account',
        'settings',
        'member',
      ],
    ),
    MemberSearchDestination(
      id: MemberSearchDestinationId.notifications,
      title: 'Notifications',
      subtitle: 'Alerts, reminders & updates',
      icon: Iconsax.notification,
      keywords: [
        'notification',
        'notifications',
        'alert',
        'alerts',
        'reminder',
        'reminders',
        'updates',
      ],
    ),
    MemberSearchDestination(
      id: MemberSearchDestinationId.editProfile,
      title: 'Edit Profile',
      subtitle: 'Name, photo & contact info',
      icon: Iconsax.edit_2,
      keywords: [
        'edit profile',
        'update profile',
        'change name',
        'change photo',
        'avatar',
        'contact',
      ],
    ),
    MemberSearchDestination(
      id: MemberSearchDestinationId.payments,
      title: 'Payments',
      subtitle: 'Transactions & receipts',
      icon: Iconsax.wallet_2,
      keywords: [
        'payment',
        'payments',
        'pay',
        'transaction',
        'transactions',
        'receipt',
        'receipts',
        'instapay',
        'wallet',
        'billing',
      ],
    ),
    MemberSearchDestination(
      id: MemberSearchDestinationId.freezeRequests,
      title: 'Freeze Requests',
      subtitle: 'Pause or freeze your sessions',
      icon: Iconsax.pause_circle,
      keywords: [
        'freeze',
        'freeze payment',
        'freeze request',
        'freeze requests',
        'pause',
        'paused',
        'hold',
        'suspend',
      ],
    ),
    MemberSearchDestination(
      id: MemberSearchDestinationId.coaches,
      title: 'Find Coaches',
      subtitle: 'Browse all academy coaches',
      icon: Iconsax.people,
      keywords: [
        'coach',
        'coaches',
        'trainer',
        'trainers',
        'directory',
        'find coach',
        'search coaches',
      ],
    ),
    MemberSearchDestination(
      id: MemberSearchDestinationId.bookCoach,
      title: 'Book a Coach',
      subtitle: 'Start a new enrollment',
      icon: Iconsax.add_circle,
      keywords: [
        'book',
        'book coach',
        'book a coach',
        'new booking',
        'enroll',
        'enrollment',
        'subscribe',
        'subscription',
        'booking page',
      ],
    ),
  ];

  static List<MemberSearchDestination> match(String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return const [];

    return destinations
        .where((d) => _matchesDestination(d, query))
        .toList(growable: false);
  }

  static bool _matchesDestination(MemberSearchDestination d, String query) {
    if (d.title.toLowerCase().contains(query)) return true;
    if (d.subtitle.toLowerCase().contains(query)) return true;
    for (final keyword in d.keywords) {
      if (keyword.contains(query) || query.contains(keyword)) return true;
    }
    return false;
  }
}
