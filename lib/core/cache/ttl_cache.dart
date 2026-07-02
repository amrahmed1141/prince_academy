/// Simple in-memory TTL cache for repository layer.
class TtlCache<T> {
  TtlCache({this.ttl = const Duration(minutes: 5)});

  final Duration ttl;
  T? _value;
  DateTime? _cachedAt;

  T? get value {
    if (_value == null || _cachedAt == null) return null;
    if (DateTime.now().difference(_cachedAt!) > ttl) {
      invalidate();
      return null;
    }
    return _value;
  }

  void set(T value) {
    _value = value;
    _cachedAt = DateTime.now();
  }

  void invalidate() {
    _value = null;
    _cachedAt = null;
  }
}
