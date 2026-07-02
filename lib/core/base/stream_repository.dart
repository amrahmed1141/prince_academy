import 'dart:async';

/// Broadcast stream + in-memory TTL cache with optional auto-refresh.
abstract class StreamRepository<T> {
  StreamRepository({this.cacheTtl = const Duration(minutes: 2)});

  final Duration cacheTtl;

  StreamController<T>? _controller;
  T? _cachedValue;
  DateTime? _cachedAt;
  Timer? _refreshTimer;
  bool _isFetching = false;

  StreamController<T> get _streamController {
    _controller ??= StreamController<T>.broadcast();
    return _controller!;
  }

  Stream<T> get stream => _streamController.stream;

  T? get cachedValue => _cachedValue;

  bool get hasValidCache {
    if (_cachedValue == null || _cachedAt == null) return false;
    return DateTime.now().difference(_cachedAt!) < cacheTtl;
  }

  void invalidateStreamCache() {
    _cachedValue = null;
    _cachedAt = null;
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<T> refresh() async {
    if (_isFetching && _cachedValue != null) {
      return _cachedValue as T;
    }

    _isFetching = true;
    try {
      final data = await fetchFromApi();
      _cachedValue = data;
      _cachedAt = DateTime.now();
      if (!_streamController.isClosed) {
        _streamController.add(data);
      }
      _scheduleAutoRefresh();
      return data;
    } catch (error, stackTrace) {
      if (!_streamController.isClosed) {
        _streamController.addError(error, stackTrace);
      }
      rethrow;
    } finally {
      _isFetching = false;
    }
  }

  void _scheduleAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(cacheTtl, () {
      refresh();
    });
  }

  Future<T> fetchFromApi();

  void dispose() {
    _refreshTimer?.cancel();
    _controller?.close();
    _controller = null;
  }
}
