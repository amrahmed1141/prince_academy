import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prince_academy/features/booking/data/repositories/booking_repository.dart';

/// Keeps the member QR code in sync across profile, FAB, and post-booking flows.
class UserQrService extends ChangeNotifier {
  UserQrService(this._bookingRepository);

  final BookingRepository _bookingRepository;

  String? _qrCode;
  String? _fullName;
  bool _isLoading = false;
  bool _refreshInFlight = false;

  String? get qrCode => _qrCode;
  String? get fullName => _fullName;
  bool get hasQrCode => _qrCode != null && _qrCode!.isNotEmpty;
  bool get isLoading => _isLoading;

  /// Schedules [notifyListeners] after the current frame/sync work so listeners
  /// never call setState during another widget's build phase.
  void _notifySafely() {
    scheduleMicrotask(notifyListeners);
  }

  Future<void> refresh() async {
    if (_refreshInFlight) return;

    _refreshInFlight = true;
    _isLoading = true;

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        _qrCode = null;
        _fullName = null;
        return;
      }

      final profile = await Supabase.instance.client
          .from('profiles')
          .select('qr_code, full_name')
          .eq('id', userId)
          .maybeSingle();

      if (profile != null) {
        _qrCode = profile['qr_code'] as String?;
        _fullName = profile['full_name'] as String?;
      } else {
        _qrCode = await _bookingRepository.getProfileQrCode(userId);
      }
    } catch (_) {
      // Keep last known value on transient errors.
    } finally {
      _isLoading = false;
      _refreshInFlight = false;
      _notifySafely();
    }
  }

  void setQrCode(String code, {String? fullName}) {
    _qrCode = code;
    if (fullName != null) _fullName = fullName;
    _notifySafely();
  }

  void clear() {
    _qrCode = null;
    _fullName = null;
    _notifySafely();
  }
}
