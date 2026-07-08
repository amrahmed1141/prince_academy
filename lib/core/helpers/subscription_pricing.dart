/// Monthly subscription pricing for coach bookings.
///
/// [fullMonthlyPrice] is the coach session price for the 3 sessions/week plan
/// (12 sessions per month), stored in `coach_sessions.price_per_session`.
class SubscriptionPricing {
  SubscriptionPricing._();

  static const int weeksPerMonth = 4;

  /// Sessions included in a one-month subscription.
  static int monthlySessionCount(int sessionsPerWeek) {
    if (sessionsPerWeek <= 0) return 0;
    return sessionsPerWeek * weeksPerMonth;
  }

  /// Monthly subscription total based on how many days per week are selected.
  static double monthlyPrice(double fullMonthlyPrice, int sessionsPerWeek) {
    if (fullMonthlyPrice <= 0 || sessionsPerWeek <= 0) return 0;

    return switch (sessionsPerWeek) {
      >= 3 => fullMonthlyPrice,
      2 => fullMonthlyPrice * 0.8,
      1 => fullMonthlyPrice / 3,
      _ => fullMonthlyPrice,
    };
  }
}
