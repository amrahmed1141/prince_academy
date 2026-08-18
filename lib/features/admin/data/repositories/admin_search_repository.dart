import 'package:equatable/equatable.dart';
import 'package:prince_academy/features/admin/data/admin_search_index.dart';
import 'package:prince_academy/features/admin/data/models/active_user_model.dart';
import 'package:prince_academy/features/admin/data/models/coach_model.dart';
import 'package:prince_academy/features/admin/data/models/paged_result.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';

class AdminSearchResults extends Equatable {
  const AdminSearchResults({
    this.destinations = const [],
    this.coaches = const [],
    this.sessions = const [],
    this.members = const [],
  });

  static const empty = AdminSearchResults();

  final List<AdminSearchDestination> destinations;
  final List<CoachModel> coaches;
  final List<CoachSessionModel> sessions;
  final List<ActiveUser> members;

  bool get isEmpty =>
      destinations.isEmpty &&
      coaches.isEmpty &&
      sessions.isEmpty &&
      members.isEmpty;

  @override
  List<Object?> get props => [destinations, coaches, sessions, members];
}

/// Admin global search: pages plus coaches, classes, and members.
class AdminSearchRepository {
  AdminSearchRepository(this._coaches);

  final CoachRepository _coaches;

  static const _hitCap = 8;

  Future<AdminSearchResults> search(String rawQuery) async {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return AdminSearchResults.empty;

    final destinations = AdminAppSearchIndex.match(query);

    final bundle = await Future.wait<Object>([
      _coaches.fetchCoaches(),
      _coaches.getAllSessionsWithCoach(),
      _coaches.getMembers(search: rawQuery.trim(), limit: 20),
    ]);

    final coaches = bundle[0] as List<CoachModel>;
    final sessions = bundle[1] as List<CoachSessionModel>;
    final membersPage = bundle[2] as PagedResult<ActiveUser>;

    return AdminSearchResults(
      destinations: destinations,
      coaches: _filterCoaches(coaches, query),
      sessions: _filterSessions(sessions, query),
      members: membersPage.items.take(_hitCap).toList(growable: false),
    );
  }

  List<CoachModel> _filterCoaches(List<CoachModel> coaches, String query) {
    return coaches
        .where((c) {
          final haystack = [
            c.name,
            c.specialty,
            c.branchName ?? '',
          ].join(' ').toLowerCase();
          return haystack.contains(query);
        })
        .take(_hitCap)
        .toList(growable: false);
  }

  List<CoachSessionModel> _filterSessions(
    List<CoachSessionModel> sessions,
    String query,
  ) {
    return sessions
        .where((s) {
          final haystack = [
            s.sessionType,
            s.coachName ?? '',
            s.coachSpecialty ?? '',
            s.branchName ?? '',
            ...s.days,
            ...s.timeSlots,
            'class',
            'classes',
            'session',
          ].join(' ').toLowerCase();
          return haystack.contains(query);
        })
        .take(_hitCap)
        .toList(growable: false);
  }
}
