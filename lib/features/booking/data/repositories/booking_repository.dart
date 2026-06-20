import 'package:prince_academy/features/booking/data/datasources/booking_remote_ds.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';
import 'package:prince_academy/features/booking/data/models/booking_model.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';

class BookingRepository {
  final BookingRemoteDs _remoteDs;

  BookingRepository(this._remoteDs);

  Future<CoachSessionModel?> getActiveSession(String coachId) {
    return _remoteDs.getActiveSessionForCoach(coachId);
  }

  Future<BookingModel> submitBooking(BookingModel booking) {
    return _remoteDs.createBooking(booking);
  }

  Future<String?> getProfileQrCode(String userId) {
    return _remoteDs.getProfileQrCode(userId);
  }

  Future<String> ensureUserQrCode(String userId) {
    return _remoteDs.ensureUserQrCode(userId);
  }

  Future<List<BookingHistoryModel>> getUserBookings() {
    return _remoteDs.getUserBookings();
  }
}
