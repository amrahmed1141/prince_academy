import 'package:supabase_flutter/supabase_flutter.dart';

/// Safe wrappers around Supabase Realtime subscribe/remove.
///
/// The realtime client can throw [StateError] (`StreamSink is closed`) when
/// the websocket is mid-reconnect (hot restart, flaky network). That must
/// never bubble into widget build / unhandled zones.
abstract final class RealtimeChannelHelper {
  static RealtimeChannel? subscribeSafely(
    RealtimeChannel channel, {
    void Function(RealtimeSubscribeStatus status, Object? error)? onStatus,
  }) {
    try {
      channel.subscribe((status, error) {
        try {
          onStatus?.call(status, error);
        } catch (_) {}
      });
      return channel;
    } catch (_) {
      return null;
    }
  }

  static Future<void> removeSafely(
    SupabaseClient client,
    RealtimeChannel? channel,
  ) async {
    if (channel == null) return;
    try {
      await client.removeChannel(channel);
    } catch (_) {
      try {
        channel.unsubscribe();
      } catch (_) {}
    }
  }

  static bool isClosedSinkError(Object error) {
    return error is StateError &&
        error.message.contains('StreamSink is closed');
  }
}
