import 'package:equatable/equatable.dart';
import 'package:prince_academy/features/admin/data/models/admin_dashboard_model.dart';

class TodaySessionsState extends Equatable {
  const TodaySessionsState({
    this.sessions = const [],
    this.searchQuery = '',
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
  });

  final List<DashboardTodaySession> sessions;
  final String searchQuery;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;

  List<DashboardTodaySession> get visibleSessions {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return sessions;

    return sessions.where((session) {
      final coach = session.coachName.toLowerCase();
      final type = (session.sessionType ?? '').toLowerCase();
      final time = (session.sessionTime ?? '').toLowerCase();
      final branch = (session.branchName ?? '').toLowerCase();
      return coach.contains(query) ||
          type.contains(query) ||
          time.contains(query) ||
          branch.contains(query);
    }).toList();
  }

  TodaySessionsState copyWith({
    List<DashboardTodaySession>? sessions,
    String? searchQuery,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    bool clearError = false,
  }) {
    return TodaySessionsState(
      sessions: sessions ?? this.sessions,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        sessions,
        searchQuery,
        isLoading,
        isRefreshing,
        error,
      ];
}
