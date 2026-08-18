import 'package:equatable/equatable.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';
import 'package:prince_academy/features/home/data/models/coaches_model.dart';
import 'package:prince_academy/features/search/data/member_app_search_index.dart';
import 'package:prince_academy/features/sessions/data/models/session_model.dart';

class GlobalSearchCategoryHit extends Equatable {
  const GlobalSearchCategoryHit({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String? imageUrl;

  @override
  List<Object?> get props => [id, name, imageUrl];
}

/// Aggregated, already-filtered hits for one query.
class GlobalSearchResults extends Equatable {
  const GlobalSearchResults({
    this.destinations = const [],
    this.coaches = const [],
    this.sessions = const [],
    this.bookings = const [],
    this.categories = const [],
  });

  static const empty = GlobalSearchResults();

  final List<MemberSearchDestination> destinations;
  final List<CoachModel> coaches;
  final List<Session> sessions;
  final List<BookingHistoryModel> bookings;
  final List<GlobalSearchCategoryHit> categories;

  bool get isEmpty =>
      destinations.isEmpty &&
      coaches.isEmpty &&
      sessions.isEmpty &&
      bookings.isEmpty &&
      categories.isEmpty;

  int get totalCount =>
      destinations.length +
      coaches.length +
      sessions.length +
      bookings.length +
      categories.length;

  @override
  List<Object?> get props =>
      [destinations, coaches, sessions, bookings, categories];
}
