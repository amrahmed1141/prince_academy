import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/features/admin/data/models/paged_result.dart';
import 'package:prince_academy/features/admin/data/models/today_attendance_member_model.dart';
import 'package:prince_academy/features/admin/data/repositories/admin_dashboard_repository.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/features/admin/presentation/bloc/today_attendance/today_attendance_state.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_coach_booking_filter_chips.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TodayAttendanceCubit extends Cubit<TodayAttendanceState> {
  TodayAttendanceCubit({
    required AdminDashboardRepository dashboardRepository,
    required CoachRepository coachRepository,
    required SupabaseClient supabase,
  })  : _dashboardRepository = dashboardRepository,
        _coachRepository = coachRepository,
        _supabase = supabase,
        super(const TodayAttendanceState(isLoading: true));

  final AdminDashboardRepository _dashboardRepository;
  final CoachRepository _coachRepository;
  final SupabaseClient _supabase;
  int _requestId = 0;
  Timer? _searchDebounce;

  Future<void> load({bool force = false}) async {
    final requestId = ++_requestId;
    final keepList = state.members.isNotEmpty;

    emit(
      state.copyWith(
        isLoading: !keepList,
        isRefreshing: keepList,
        clearError: true,
        clearLoadMoreError: true,
        clearActionError: true,
      ),
    );

    try {
      final meta = await Future.wait([
        _dashboardRepository.getTodayAttendanceKpiTotals(force: force),
        _dashboardRepository.getTodayAttendanceCoaches(force: force),
      ]);
      if (requestId != _requestId) return;

      final totals = meta[0] as ({int attended, int booked});
      final coachesRaw = meta[1]
          as List<({String coachId, String coachName, String? coachPhoto})>;

      final coaches = coachesRaw
          .map<AdminCoachBookingOption>(
            (c) => (
              coachId: c.coachId,
              coachName: c.coachName,
              coachPhoto: c.coachPhoto,
            ),
          )
          .toList();

      var selectedCoachId = state.selectedCoachId;
      if (selectedCoachId != null &&
          coaches.every((c) => c.coachId != selectedCoachId)) {
        selectedCoachId = null;
      }

      final PagedResult<TodayAttendanceMember> page =
          await _dashboardRepository.getTodayAttendanceMembers(
        limit: TodayAttendanceState.pageSize,
        offset: 0,
        search: state.searchQuery,
        coachId: selectedCoachId,
        force: force,
      );
      if (requestId != _requestId) return;

      emit(
        state.copyWith(
          members: page.items,
          coaches: coaches,
          selectedCoachId: selectedCoachId,
          clearSelectedCoach: selectedCoachId == null,
          kpiAttended: totals.attended,
          kpiBooked: totals.booked,
          hasMore: page.hasMore,
          isLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          clearError: true,
          clearLoadMoreError: true,
        ),
      );
    } catch (e) {
      if (requestId != _requestId) return;
      emit(
        state.copyWith(
          isLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          error: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> refresh() => load(force: true);

  void selectCoach(String? coachId) {
    if (coachId == state.selectedCoachId) return;
    if (coachId == null) {
      emit(state.copyWith(clearSelectedCoach: true));
    } else {
      emit(state.copyWith(selectedCoachId: coachId));
    }
    load(force: true);
  }

  void onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      final trimmed = query.trim();
      if (trimmed == state.searchQuery) return;
      emit(state.copyWith(searchQuery: trimmed));
      load(force: true);
    });
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    if (state.searchQuery.isEmpty) return;
    emit(state.copyWith(searchQuery: ''));
    load(force: false);
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore ||
        state.isLoading ||
        state.isRefreshing ||
        !state.hasMore) {
      return;
    }

    final requestId = ++_requestId;
    emit(
      state.copyWith(
        isLoadingMore: true,
        clearLoadMoreError: true,
      ),
    );

    try {
      final page = await _dashboardRepository.getTodayAttendanceMembers(
        limit: TodayAttendanceState.pageSize,
        offset: state.members.length,
        search: state.searchQuery,
        coachId: state.selectedCoachId,
        force: true,
      );
      if (requestId != _requestId) return;

      emit(
        state.copyWith(
          members: [...state.members, ...page.items],
          hasMore: page.hasMore,
          isLoadingMore: false,
          clearLoadMoreError: true,
        ),
      );
    } catch (e) {
      if (requestId != _requestId) return;
      emit(
        state.copyWith(
          isLoadingMore: false,
          loadMoreError: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<bool> markAttended(TodayAttendanceMember member) async {
    if (member.isAttended) return true;
    if (state.markingBookingIds.contains(member.bookingId)) return false;

    final adminId = _supabase.auth.currentUser?.id;
    if (adminId == null || adminId.isEmpty) {
      emit(
        state.copyWith(
          actionError: 'Admin session expired. Please sign in again.',
        ),
      );
      return false;
    }

    final marking = Set<String>.from(state.markingBookingIds)
      ..add(member.bookingId);
    emit(
      state.copyWith(
        markingBookingIds: marking,
        clearActionError: true,
      ),
    );

    try {
      await _coachRepository.markAttendance(
        bookingId: member.bookingId,
        userId: member.userId,
        coachId: member.coachId,
        adminId: adminId,
      );

      final updated = state.members
          .map(
            (m) => m.bookingId == member.bookingId
                ? m.copyWith(isAttended: true)
                : m,
          )
          .toList();

      final nextMarking = Set<String>.from(state.markingBookingIds)
        ..remove(member.bookingId);

      final nextAttended = (state.kpiAttended + 1).clamp(0, state.kpiBooked);

      emit(
        state.copyWith(
          members: updated,
          markingBookingIds: nextMarking,
          kpiAttended: nextAttended,
          clearActionError: true,
        ),
      );

      unawaited(_refreshKpiOnly());
      return true;
    } catch (e) {
      final nextMarking = Set<String>.from(state.markingBookingIds)
        ..remove(member.bookingId);
      emit(
        state.copyWith(
          markingBookingIds: nextMarking,
          actionError: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return false;
    }
  }

  Future<void> _refreshKpiOnly() async {
    try {
      final totals =
          await _dashboardRepository.getTodayAttendanceKpiTotals(force: true);
      if (isClosed) return;
      emit(
        state.copyWith(
          kpiAttended: totals.attended,
          kpiBooked: totals.booked,
        ),
      );
    } catch (_) {
      // Best-effort; list already updated optimistically.
    }
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
