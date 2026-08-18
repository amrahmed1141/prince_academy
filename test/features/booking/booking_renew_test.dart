import 'package:flutter_test/flutter_test.dart';
import 'package:prince_academy/core/helpers/session_schedule_helper.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';
import 'package:prince_academy/features/booking/data/models/booking_model.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_renew/booking_renew_cubit.dart';

BookingHistoryModel _renewable({
  String id = 'b1',
  String coachId = 'c1',
  String displayStatus = 'expired',
  List<String> days = const ['Sunday', 'Tuesday', 'Thursday'],
  String? paymentMethod = 'instapay',
  double price = 1000,
}) {
  return BookingHistoryModel(
    bookingId: id,
    userId: 'u1',
    coachId: coachId,
    coachName: 'Islam Zombie',
    coachPhoto: 'https://example.com/z.jpg',
    selectedDays: days,
    selectedTime: '8:00 PM',
    totalPrice: price,
    paymentMethod: paymentMethod,
    subscriptionStart: DateTime(2026, 7, 12),
    subscriptionEnd: DateTime(2026, 8, 11),
    bookingStatus: 'active',
    displayStatus: displayStatus,
    totalSessions: 12,
    attendedSessions: 1,
  );
}

void main() {
  group('BookingHistoryModel.fromJson renewable RPC shape', () {
    test('maps get_renewable_bookings columns', () {
      final model = BookingHistoryModel.fromJson({
        'booking_id': '7113f5a6-749b-45b8-9701-f8565637770d',
        'user_id': '02ea9d4d-98f9-4fce-9bf7-539c2bb7882b',
        'coach_id': 'coach-1',
        'branch_id': 'branch-1',
        'branch_name': 'Maadi',
        'coach_name': 'Islam Zombie',
        'coach_photo': 'https://example.com/z.jpg',
        'coach_specialty': 'MMA',
        'selected_days': ['Sunday', 'Tuesday', 'Thursday'],
        'selected_time': '8:00 PM',
        'total_price': 3000.00,
        'payment_method': 'cash',
        'subscription_start': '2026-06-20',
        'subscription_end': '2026-07-20',
        'booking_status': 'active',
        'created_at': '2026-06-20T10:00:00Z',
        'total_sessions': 12,
        'attended_sessions': 5,
        'display_status': 'expired',
      });

      expect(model.bookingId, '7113f5a6-749b-45b8-9701-f8565637770d');
      expect(model.coachName, 'Islam Zombie');
      expect(model.selectedDays, ['Sunday', 'Tuesday', 'Thursday']);
      expect(model.selectedTime, '8:00 PM');
      expect(model.totalPrice, 3000);
      expect(model.paymentMethod, 'cash');
      expect(model.effectiveDisplayStatus, 'expired');
    });
  });

  group('BookingRenewState', () {
    test('hasPrompt only when a booking is waiting and flow is closed', () {
      final waiting = BookingRenewState(queue: [_renewable()]);
      expect(waiting.hasPrompt, isTrue);
      expect(waiting.current?.bookingId, 'b1');
      expect(waiting.copyWith(isFlowOpen: true).hasPrompt, isFalse);
      expect(const BookingRenewState.initial().hasPrompt, isFalse);
    });

    test('removing the current booking advances the queue', () {
      final state = BookingRenewState(
        queue: [_renewable(), _renewable(id: 'b2', coachId: 'c2')],
      );
      final next = state.copyWith(
        queue: state.queue.where((b) => b.bookingId != 'b1').toList(),
      );
      expect(next.current?.bookingId, 'b2');
      expect(next.queue, hasLength(1));
    });

    test('pre-selects canSubmit only after a start date and sessions', () {
      final start = DateTime(2026, 8, 13);
      final end = SessionScheduleHelper.subscriptionEndDate(start);
      final dates = SessionScheduleHelper.generateSessionDates(
        startDate: start,
        selectedDays: const ['Sunday', 'Tuesday', 'Thursday'],
      );
      final ready = BookingRenewState(
        queue: [_renewable()],
        startDate: start,
        endDate: end,
        sessionDates: dates,
        paymentMethod: PaymentMethod.instapay,
      );
      expect(dates, isNotEmpty);
      expect(ready.canSubmit, isTrue);
      expect(ready.copyWith(clearSchedule: true).canSubmit, isFalse);
    });
  });
}
