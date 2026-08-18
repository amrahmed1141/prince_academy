import 'dart:async';
import 'dart:developer' as developer;

import 'package:prince_academy/core/helpers/remote_error.dart';

/// Broadcast stream + in-memory TTL cache with optional auto-refresh.
abstract class StreamRepository<T> {
  StreamRepository({this.cacheTtl = const Duration(minutes: 2)});

  final Duration cacheTtl;

  StreamController<T>? _controller;
  T? _cachedValue;
  DateTime? _cachedAt;
  Timer? _refreshTimer;
  bool _isFetching = false;
  bool _pendingRefresh = false;

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

  /// Timer / realtime refresh. Never throws into the zone.
  Future<void> refreshInBackground() async {
    try {
      await refresh(silent: true);
    } catch (error) {
      developer.log(
        'Background refresh failed: ${userFacingRemoteError(error)}',
        name: 'StreamRepository',
        error: error,
      );
    }
  }

  Future<T> refresh({bool silent = false}) async {
    if (_isFetching) {
      // A concurrent realtime/mutation tick arrived while a fetch is in flight —
      // queue one follow-up so the latest change is not dropped.
      _pendingRefresh = true;
      if (_cachedValue != null) return _cachedValue as T;
      // First load with no cache: wait for the in-flight fetch to finish.
      while (_isFetching) {
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }
      if (_cachedValue != null && !_pendingRefresh) {
        return _cachedValue as T;
      }
    }

    _isFetching = true;
    _pendingRefresh = false;
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
      final mapped = Exception(userFacingRemoteError(error));
      final hasCache = _cachedValue != null;
      if (silent && hasCache) {
        developer.log(
          'Kept cached ${T.toString()} after refresh failure',
          name: 'StreamRepository',
          error: error,
        );
        _scheduleAutoRefresh();
        return _cachedValue as T;
      }
      if (!_streamController.isClosed) {
        _streamController.addError(mapped, stackTrace);
      }
      Error.throwWithStackTrace(mapped, stackTrace);
    } finally {
      _isFetching = false;
      if (_pendingRefresh) {
        _pendingRefresh = false;
        unawaited(refreshInBackground());
      }
    }
  }

  void _scheduleAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(cacheTtl, () {
      unawaited(refreshInBackground());
    });
  }

  Future<T> fetchFromApi();

  void dispose() {
    _refreshTimer?.cancel();
    _controller?.close();
    _controller = null;
  }
}
