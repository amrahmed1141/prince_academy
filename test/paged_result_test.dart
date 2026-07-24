import 'package:flutter_test/flutter_test.dart';
import 'package:prince_academy/features/admin/data/models/active_user_model.dart';
import 'package:prince_academy/features/admin/data/models/paged_result.dart';

void main() {
  group('PagedResult hasMore', () {
    test('full page keeps hasMore true', () {
      final page = PagedResult<ActiveUser>(
        items: List.generate(
          50,
          (i) => ActiveUser(
            userId: 'u$i',
            fullName: 'User $i',
            totalBookings: 1,
            activeBookings: 1,
            expiredBookings: 0,
          ),
        ),
        hasMore: true,
        totalCount: 120,
      );

      expect(page.items.length, 50);
      expect(page.hasMore, isTrue);
      expect(page.totalCount, 120);
    });

    test('short page flips hasMore to false', () {
      final first = PagedResult<ActiveUser>(
        items: List.generate(
          50,
          (i) => ActiveUser(
            userId: 'u$i',
            fullName: 'User $i',
            totalBookings: 1,
            activeBookings: 1,
            expiredBookings: 0,
          ),
        ),
        hasMore: true,
      );
      final second = PagedResult<ActiveUser>(
        items: List.generate(
          20,
          (i) => ActiveUser(
            userId: 'u${50 + i}',
            fullName: 'User ${50 + i}',
            totalBookings: 1,
            activeBookings: 1,
            expiredBookings: 0,
          ),
        ),
        hasMore: false,
        totalCount: 70,
      );

      final merged = [...first.items, ...second.items];
      final hasMore = second.items.length >= 50;

      expect(merged.length, 70);
      expect(hasMore, isFalse);
      expect(second.hasMore, isFalse);
      expect(second.totalCount, 70);
    });

    test('hasMore derived from page length vs page size', () {
      bool computeHasMore(int pageLength, int pageSize) =>
          pageLength >= pageSize;

      expect(computeHasMore(50, 50), isTrue);
      expect(computeHasMore(20, 50), isFalse);
      expect(computeHasMore(0, 50), isFalse);
    });
  });
}
