import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

/// Disk-backed JSON cache (Hive) used as L2 under in-memory TTL caches.
class LocalCacheStore {
  LocalCacheStore._();

  static const _boxName = 'app_cache';
  static LocalCacheStore? _instance;

  late final Box<String> _box;

  static LocalCacheStore get instance {
    final store = _instance;
    if (store == null) {
      throw StateError('LocalCacheStore.init() must be called during bootstrap');
    }
    return store;
  }

  static Future<LocalCacheStore> init() async {
    if (_instance != null) return _instance!;
    final box = await Hive.openBox<String>(_boxName);
    final store = LocalCacheStore._().._box = box;
    _instance = store;
    return store;
  }

  // ── Keys ──────────────────────────────────────────────────────────

  static String userProfileKey(String userId) => 'user_profile_$userId';
  static String sessionsSnapshotKey(String userId) =>
      'sessions_snapshot_$userId';
  static String bookingsKey(String userId) => 'bookings_$userId';
  static String coachesKey() => 'coaches_active';
  static String branchesKey() => 'branches_all';
  static String coachProfileKey(String coachId) => 'coach_profile_$coachId';
  static String coachSessionsKey(String coachId) => 'coach_sessions_$coachId';

  // ── Read / write ──────────────────────────────────────────────────

  Map<String, dynamic>? getMap(String key) {
    final raw = _box.get(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  List<dynamic>? getList(String key) {
    final raw = _box.get(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded;
    } catch (_) {}
    return null;
  }

  Future<void> putJson(String key, Object value) async {
    await _box.put(key, jsonEncode(value));
  }

  Future<void> delete(String key) async {
    await _box.delete(key);
  }

  Future<void> clearUser(String userId) async {
    await Future.wait([
      delete(userProfileKey(userId)),
      delete(sessionsSnapshotKey(userId)),
      delete(bookingsKey(userId)),
    ]);
  }

  Future<void> clearAll() => _box.clear();
}
