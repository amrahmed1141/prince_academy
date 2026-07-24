import 'package:equatable/equatable.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';

abstract class BookingHistoryState extends Equatable {
  const BookingHistoryState();

  @override
  List<Object?> get props => [];
}

class BookingHistoryInitial extends BookingHistoryState {
  const BookingHistoryInitial();
}

class BookingHistoryLoading extends BookingHistoryState {
  const BookingHistoryLoading();
}

class BookingHistoryLoaded extends BookingHistoryState {
  final List<BookingHistoryModel> allBookings;
  final String? activeFilter;
  final String searchQuery;
  final bool isRefreshing;
  final bool hasMore;
  final bool isLoadingMore;

  static const int pageSize = 50;

  const BookingHistoryLoaded({
    required this.allBookings,
    this.activeFilter,
    this.searchQuery = '',
    this.isRefreshing = false,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  BookingHistoryLoaded copyWith({
    List<BookingHistoryModel>? allBookings,
    String? activeFilter,
    bool clearFilter = false,
    String? searchQuery,
    bool? isRefreshing,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return BookingHistoryLoaded(
      allBookings: allBookings ?? this.allBookings,
      activeFilter: clearFilter ? null : (activeFilter ?? this.activeFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  List<BookingHistoryModel> get bookings {
    var list = allBookings;
    if (activeFilter != null) {
      list = list
          .where((booking) => booking.effectiveDisplayStatus == activeFilter)
          .toList();
    }
    if (searchQuery.isNotEmpty) {
      list = list.where(_matchesSearch).toList();
    }
    return list;
  }

  bool get hasSearchQuery => searchQuery.isNotEmpty;

  bool _matchesSearch(BookingHistoryModel booking) {
    final q = searchQuery;
    return booking.coachName.toLowerCase().contains(q) ||
        (booking.coachSpecialty?.toLowerCase().contains(q) ?? false) ||
        (booking.branchName?.toLowerCase().contains(q) ?? false) ||
        booking.effectiveDisplayStatus.toLowerCase().contains(q) ||
        booking.bookingStatus.toLowerCase().contains(q);
  }

  int countForFilter(String? filter) {
    if (filter == null) return allBookings.length;
    return allBookings
        .where((booking) => booking.effectiveDisplayStatus == filter)
        .length;
  }

  @override
  List<Object?> get props =>
      [allBookings, activeFilter, searchQuery, isRefreshing, hasMore, isLoadingMore];
}

class BookingHistoryError extends BookingHistoryState {
  final String message;

  const BookingHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
