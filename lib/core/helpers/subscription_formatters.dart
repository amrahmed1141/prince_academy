class SubscriptionFormatters {
  static const _dayAbbrev = {
    'mon': 'Mon',
    'monday': 'Mon',
    'tue': 'Tue',
    'tuesday': 'Tue',
    'wed': 'Wed',
    'wednesday': 'Wed',
    'thu': 'Thu',
    'thursday': 'Thu',
    'fri': 'Fri',
    'friday': 'Fri',
    'sat': 'Sat',
    'saturday': 'Sat',
    'sun': 'Sun',
    'sunday': 'Sun',
  };

  static String formatDays(List<String> days) {
    if (days.isEmpty) return 'Schedule not set';
    return days.map((day) => _dayAbbrev[day.toLowerCase()] ?? day).join(', ');
  }

  static String formatExpiryLabel({
    required bool isActive,
    required int daysRemaining,
  }) {
    final absDays = daysRemaining.abs();
    if (isActive) {
      if (daysRemaining == 0) return 'Expires today';
      if (daysRemaining == 1) return 'Expires in 1 day';
      return 'Expires in $daysRemaining days';
    }

    if (absDays == 0) return 'Expired today';
    if (absDays == 1) return 'Expired 1 day ago';
    return 'Expired $absDays days ago';
  }

  static String formatExpiryDetail({
    required DateTime? subscriptionEnd,
    required bool isActive,
    required int daysRemaining,
  }) {
    if (subscriptionEnd == null) {
      return formatExpiryLabel(
        isActive: isActive,
        daysRemaining: daysRemaining,
      );
    }

    final formatted = _formatDate(subscriptionEnd);
    if (isActive) {
      final left =
          daysRemaining == 1 ? '1 day left' : '$daysRemaining days left';
      return 'Expires: $formatted ($left)';
    }
    return formatExpiryLabel(isActive: false, daysRemaining: daysRemaining);
  }

  static String formatDate(DateTime? date) {
    if (date == null) return '—';
    return _formatDate(date);
  }

  static String formatRenewedUntil(DateTime? date) {
    if (date == null) return 'your new end date';
    return _formatDate(date);
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    return '$day/$month/$year';
  }

  static String weekdayName(DateTime date) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[date.weekday - 1];
  }

  static String formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime.toLocal());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m minute${m == 1 ? '' : 's'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h hour${h == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 7) {
      final d = diff.inDays;
      return '$d day${d == 1 ? '' : 's'} ago';
    }
    return formatDate(dateTime);
  }
}
