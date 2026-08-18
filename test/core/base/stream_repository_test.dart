import 'package:flutter_test/flutter_test.dart';
import 'package:prince_academy/core/base/stream_repository.dart';

class _FakeRepo extends StreamRepository<int> {
  _FakeRepo() : super(cacheTtl: const Duration(seconds: 30));

  Object? nextError;
  int nextValue = 1;
  int fetchCount = 0;

  @override
  Future<int> fetchFromApi() async {
    fetchCount++;
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
    return nextValue;
  }
}

void main() {
  group('StreamRepository', () {
    test('maps socket failures to a user-facing Exception', () async {
      final repo = _FakeRepo()
        ..nextError = Exception(
          'ClientException with SocketException: Connection reset by peer '
          '(OS Error: Connection reset by peer, errno = 104)',
        );

      await expectLater(
        repo.refresh(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Connection lost'),
          ),
        ),
      );
    });

    test('refreshInBackground keeps cache and does not throw', () async {
      final repo = _FakeRepo();
      expect(await repo.refresh(), 1);

      repo.nextError = Exception(
        'ClientException with SocketException: No route to host '
        '(OS Error: No route to host, errno = 113)',
      );

      await expectLater(repo.refreshInBackground(), completes);
      expect(repo.cachedValue, 1);
    });
  });
}
