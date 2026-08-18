import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';
import 'package:prince_academy/features/home/data/models/catgeory_model.dart';
import 'package:prince_academy/features/home/data/models/coaches_model.dart';
import 'package:prince_academy/features/home/data/repositories/home_coach_repository.dart';
import 'package:prince_academy/features/search/data/member_app_search_index.dart';
import 'package:prince_academy/features/search/data/models/global_search_models.dart';
import 'package:prince_academy/features/sessions/data/models/session_model.dart';
import 'package:prince_academy/features/sessions/data/repositories/sessions_repository.dart';

/// Cross-feature member search. Reuses existing repos (cache-first).
class GlobalSearchRepository {
  GlobalSearchRepository({
    required HomeCoachRepository coaches,
    required SessionsRepository sessions,
  })  : _coaches = coaches,
        _sessions = sessions;

  final HomeCoachRepository _coaches;
  final SessionsRepository _sessions;

  Future<GlobalSearchResults> search(String rawQuery) async {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return GlobalSearchResults.empty;

    final destinations = MemberAppSearchIndex.match(query);

    final bundle = await Future.wait<Object>([
      _coaches.getActiveCoaches(),
      _sessions.refreshSessions(),
    ]);

    final coaches = bundle[0] as List<CoachModel>;
    final snapshot = bundle[1] as SessionsSnapshot;

    return GlobalSearchResults(
      destinations: destinations,
      coaches: _filterCoaches(coaches, query),
      sessions: _filterSessions(snapshot.sessions, query),
      bookings: _filterBookings(snapshot.bookings, query),
      categories: _filterCategories(query),
    );
  }

  List<CoachModel> _filterCoaches(List<CoachModel> coaches, String query) {
    return coaches
        .where(
          (c) =>
              c.name.toLowerCase().contains(query) ||
              c.specialty.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  List<Session> _filterSessions(List<Session> sessions, String query) {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    return sessions.where((s) {
      final haystack = [
        s.coachName,
        s.coachSpecialty,
        s.sessionStatus,
        s.dayName,
        s.selectedTime,
        s.branchName ?? '',
        if (_isSameDay(s.sessionDate, todayKey)) 'today',
        if (_isSameDay(s.sessionDate, todayKey)) "today's session",
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList(growable: false);
  }

  List<BookingHistoryModel> _filterBookings(
    List<BookingHistoryModel> bookings,
    String query,
  ) {
    return bookings.where((b) {
      final haystack = [
        b.coachName,
        b.coachSpecialty ?? '',
        b.displayStatus,
        b.bookingStatus,
        b.branchName ?? '',
        b.selectedTime ?? '',
        'booking',
        'booking session',
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList(growable: false);
  }

  List<GlobalSearchCategoryHit> _filterCategories(String query) {
    final matchAllByLabel =
        'category'.startsWith(query) || 'categories'.startsWith(query);

    return categories
        .where((c) {
          final name = (c.name ?? '').toLowerCase();
          return name.contains(query) || matchAllByLabel;
        })
        .map(
          (c) => GlobalSearchCategoryHit(
            id: c.id ?? c.name ?? '',
            name: c.name ?? '',
            imageUrl: c.imageUrl,
          ),
        )
        .toList(growable: false);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
