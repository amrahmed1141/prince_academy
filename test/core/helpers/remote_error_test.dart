import 'package:flutter_test/flutter_test.dart';
import 'package:prince_academy/core/helpers/remote_error.dart';

void main() {
  group('isTransientNetworkError', () {
    test('detects connection reset by peer', () {
      expect(
        isTransientNetworkError(
          Exception(
            'ClientException with SocketException: Connection reset by peer '
            '(OS Error: Connection reset by peer, errno = 104), '
            'address = sfeudxyhmivlinvshvpe.supabase.co, port = 54657',
          ),
        ),
        isTrue,
      );
    });

    test('detects no route to host', () {
      expect(
        isTransientNetworkError(
          Exception(
            'ClientException with SocketException: No route to host '
            '(OS Error: No route to host, errno = 113)',
          ),
        ),
        isTrue,
      );
    });

    test('ignores PostgREST business errors', () {
      expect(
        isTransientNetworkError(Exception('Could not load pending payments.')),
        isFalse,
      );
    });
  });

  group('userFacingRemoteError', () {
    test('hides socket details', () {
      expect(
        userFacingRemoteError(
          Exception(
            'ClientException with SocketException: Connection reset by peer '
            '(OS Error: Connection reset by peer, errno = 104), uri='
            'https://sfeudxyhmivlinvshvpe.supabase.co/rest/v1/finance_daily_revenue',
          ),
        ),
        'Connection lost. Check your internet and try again.',
      );
    });

    test('keeps already-mapped messages', () {
      expect(
        userFacingRemoteError(Exception('Could not load today revenue. Please try again.')),
        'Could not load today revenue. Please try again.',
      );
    });
  });
}
