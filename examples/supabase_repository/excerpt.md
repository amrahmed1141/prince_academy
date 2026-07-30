# Supabase repository excerpts

## A. BookingRepository — TTL + Hive + SWR

SOURCE: `lib/features/booking/data/repositories/booking_repository.dart`

```dart
/// Direct Supabase access with in-memory TTL (L1) + Hive disk cache (L2).
class BookingRepository {
  BookingRepository(this._remoteDs, {LocalCacheStore? cache})
      : _cache = cache ?? LocalCacheStore.instance {
    _hydrateFromDisk();
  }

  final BookingRemoteDs _remoteDs;
  final LocalCacheStore _cache;
  // …

  static const Duration _bookingsCacheTtl = Duration(minutes: 2);

  List<BookingHistoryModel>? get cachedBookings {
    if (_bookingsCache != null) {
      if (_bookingsCachedAt == null) return _bookingsCache;
      final isValid =
          DateTime.now().difference(_bookingsCachedAt!) < _bookingsCacheTtl;
      if (isValid) return _bookingsCache;
    }
    return _bookingsCache; // stale-while-revalidate: still usable for UI
  }

  Future<List<BookingHistoryModel>> getUserBookings({
    bool force = false,
    int limit = defaultBookingsPageSize,
    int offset = 0,
  }) {
    _hydrateFromDisk();
    _ensureBookingsRealtime();

    final cached = cachedBookings;
    if (!force &&
        offset == 0 &&
        cached != null &&
        _bookingsCachedAt != null &&
        DateTime.now().difference(_bookingsCachedAt!) < _bookingsCacheTtl) {
      return Future.value(cached);
    }
    if (!force && offset == 0 && _bookingsInFlight != null) {
      return _bookingsInFlight!;
    }

    final future = _wrap(
      _remoteDs.getUserBookings(limit: limit, offset: offset),
    ).then((bookings) {
      if (offset == 0) {
        _setBookingsCache(bookings);
        unawaited(_persistBookings(bookings));
        _emitBookings(bookings);
      }
      return bookings;
    }).whenComplete(() {
      if (offset == 0) _bookingsInFlight = null;
    });

    if (offset == 0) _bookingsInFlight = future;
    return future;
  }
}
```

```dart
// DI
sl.registerLazySingleton<BookingRemoteDs>(() => BookingRemoteDs(sl()));
sl.registerLazySingleton<BookingRepository>(
  () => BookingRepository(sl(), cache: sl()),
);
```

## B. StreamRepository — admin live lists

SOURCE: `lib/core/base/stream_repository.dart`  
Concrete: `lib/features/admin/data/repositories/admin_repository.dart`

```dart
abstract class StreamRepository<T> {
  StreamRepository({this.cacheTtl = const Duration(minutes: 2)});

  final Duration cacheTtl;
  T? get cachedValue;
  bool get hasValidCache;
  Stream<T> get stream;
  Future<T> refresh();
  Future<T> fetchFromApi();
}
```

```dart
class AdminRepository extends StreamRepository<List<PendingPaymentModel>> {
  AdminRepository(this._supabase) : super(cacheTtl: const Duration(seconds: 30));

  final SupabaseClient _supabase;

  @override
  Future<List<PendingPaymentModel>> fetchFromApi() async {
    final response = await _supabase
        .from('pending_payments')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (json) => PendingPaymentModel.fromJson(
            Map<String, dynamic>.from(json as Map),
          ),
        )
        .toList();
  }

  Future<List<PendingPaymentModel>> getPendingPayments({bool force = false}) {
    if (!force && hasValidCache && cachedValue != null) {
      return Future.value(cachedValue!);
    }
    return refresh();
  }
}
```
