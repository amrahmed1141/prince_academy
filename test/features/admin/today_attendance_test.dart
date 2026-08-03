import 'package:flutter_test/flutter_test.dart';
import 'package:prince_academy/features/admin/data/models/today_attendance_member_model.dart';
import 'package:prince_academy/features/admin/presentation/bloc/today_attendance/today_attendance_state.dart';

void main() {
  group('TodayAttendanceMember.fromJson', () {
    test('maps snake_case columns and attendance flag', () {
      final member = TodayAttendanceMember.fromJson({
        'booking_id': 'b1',
        'user_id': 'u1',
        'member_name': 'Alex',
        'member_photo': null,
        'session_id': 's1',
        'coach_id': 'c1',
        'coach_name': 'Zombie',
        'coach_photo': null,
        'session_type': 'MMA',
        'session_time': '5:00 PM',
        'branch_name': 'ElZaiton Branch',
        'is_attended': true,
      });

      expect(member.bookingId, 'b1');
      expect(member.userId, 'u1');
      expect(member.memberName, 'Alex');
      expect(member.coachId, 'c1');
      expect(member.coachName, 'Zombie');
      expect(member.sessionType, 'MMA');
      expect(member.sessionTime, '5:00 PM');
      expect(member.branchName, 'ElZaiton Branch');
      expect(member.isAttended, isTrue);
    });

    test('defaults blank names and false attendance', () {
      final member = TodayAttendanceMember.fromJson({
        'booking_id': 'b2',
        'user_id': 'u2',
        'member_name': '  ',
        'session_id': 's2',
        'coach_id': 'c2',
        'coach_name': '',
      });

      expect(member.memberName, 'Member');
      expect(member.coachName, 'Coach');
      expect(member.isAttended, isFalse);
    });
  });

  group('TodayAttendanceState', () {
    const members = [
      TodayAttendanceMember(
        bookingId: 'b1',
        userId: 'u1',
        memberName: 'Alice',
        sessionId: 's1',
        coachId: 'c1',
        coachName: 'Coach One',
        isAttended: true,
      ),
      TodayAttendanceMember(
        bookingId: 'b2',
        userId: 'u2',
        memberName: 'Blake',
        sessionId: 's2',
        coachId: 'c2',
        coachName: 'Coach Two',
        isAttended: false,
      ),
    ];

    test('KPI totals come from kpi fields (not page length)', () {
      const state = TodayAttendanceState(
        members: members,
        kpiAttended: 3,
        kpiBooked: 10,
        hasMore: true,
      );

      expect(state.attendedTotal, 3);
      expect(state.bookedTotal, 10);
      expect(state.visibleMembers, members);
      expect(state.hasMore, isTrue);
      expect(TodayAttendanceState.pageSize, 50);
    });

    test('coach options come from dedicated coaches list', () {
      const state = TodayAttendanceState(
        members: members,
        coaches: [
          (coachId: 'c1', coachName: 'Coach One', coachPhoto: null),
          (coachId: 'c2', coachName: 'Coach Two', coachPhoto: null),
        ],
      );

      expect(state.coachOptions.map((c) => c.coachId), ['c1', 'c2']);
    });
  });
}
