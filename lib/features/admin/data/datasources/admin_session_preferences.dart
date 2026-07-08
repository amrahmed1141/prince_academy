import 'dart:convert';

import 'package:prince_academy/features/admin/data/models/session_draft.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists admin session form values across app restarts.
class AdminSessionPreferences {
  AdminSessionPreferences(this._prefs);

  static const _lastDraftKey = 'admin_last_session_draft';
  static const _recentPricesKey = 'admin_recent_session_prices';
  static const _maxRecentPrices = 8;

  final SharedPreferences _prefs;

  static Future<AdminSessionPreferences> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AdminSessionPreferences(prefs);
  }

  SessionDraft? readLastDraft() {
    final raw = _prefs.getString(_lastDraftKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return SessionDraft.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLastDraft(SessionDraft draft) async {
    await _prefs.setString(_lastDraftKey, jsonEncode(draft.toJson()));
    await _rememberPrice(draft.pricePerSession);
  }

  List<double> readRecentPrices() {
    final raw = _prefs.getStringList(_recentPricesKey) ?? const [];
    return raw
        .map(double.tryParse)
        .whereType<double>()
        .where((price) => price > 0)
        .toList();
  }

  Future<void> _rememberPrice(double price) async {
    if (price <= 0) return;
    final label = price.toStringAsFixed(price == price.roundToDouble() ? 0 : 2);
    final current = _prefs.getStringList(_recentPricesKey) ?? <String>[];
    final updated = [
      label,
      ...current.where((value) => value != label),
    ].take(_maxRecentPrices).toList();
    await _prefs.setStringList(_recentPricesKey, updated);
  }
}
