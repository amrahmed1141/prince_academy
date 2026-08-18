/// Maps transport / PostgREST failures to a short user-facing sentence.
String userFacingRemoteError(Object error, {String? action}) {
  if (isTransientNetworkError(error)) {
    return 'Connection lost. Check your internet and try again.';
  }
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  if (text.isEmpty) {
    return action == null
        ? 'Something went wrong. Please try again.'
        : 'Could not $action. Please try again.';
  }
  if (text.startsWith('Could not ')) return text;
  if (action != null) return 'Could not $action. Please try again.';
  return text;
}

/// TCP / DNS / HTTP-client failures (not PostgREST 4xx/5xx JSON).
bool isTransientNetworkError(Object error) {
  final text = error.toString().toLowerCase();
  return text.contains('socketexception') ||
      text.contains('clientexception') ||
      text.contains('handshakeexception') ||
      text.contains('failed host lookup') ||
      text.contains('connection reset') ||
      text.contains('connection refused') ||
      text.contains('connection closed') ||
      text.contains('connection abort') ||
      text.contains('network is unreachable') ||
      text.contains('no address associated') ||
      text.contains('no route to host') ||
      text.contains('connection timed out') ||
      text.contains('errno = 7') ||
      text.contains('errno = 104') ||
      text.contains('errno = 111') ||
      text.contains('errno = 113');
}
