import 'package:flutter_test/flutter_test.dart';
import 'package:prince_academy/features/admin/data/models/admin_dashboard_model.dart';

void main() {
  group('AdminDashboardData today attendance totals', () {
    test('sums attended and booked across today sessions', () {
      const data = AdminDashboardData(
        pendingPaymentsCount: 0,
        pendingPaymentsPreview: [],
        lowAttendancePreview: [],
        todayRevenue: 0,
        activeMembersCount: 0,
        todaySessionsCount: 2,
        todaySessionsPreview: [
          DashboardTodaySession(
            sessionId: 'a',
            coachId: 'c1',
            coachName: 'A',
            attendedCount: 2,
            bookedCount: 5,
          ),
          DashboardTodaySession(
            sessionId: 'b',
            coachId: 'c2',
            coachName: 'B',
            attendedCount: 3,
            bookedCount: 5,
          ),
        ],
        coachesCount: 0,
        freezePendingCount: 0,
      );

      expect(data.todayAttendedTotal, 5);
      expect(data.todayBookedCapacity, 10);
      expect(data.todayAttendanceProgress, 0.5);
    });

    test('progress is zero when no bookings', () {
      const data = AdminDashboardData(
        pendingPaymentsCount: 0,
        pendingPaymentsPreview: [],
        lowAttendancePreview: [],
        todayRevenue: 0,
        activeMembersCount: 0,
        todaySessionsCount: 0,
        todaySessionsPreview: [],
        coachesCount: 0,
        freezePendingCount: 0,
      );

      expect(data.todayAttendedTotal, 0);
      expect(data.todayBookedCapacity, 0);
      expect(data.todayAttendanceProgress, 0);
    });
  });
}
