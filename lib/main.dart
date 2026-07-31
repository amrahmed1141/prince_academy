import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prince_academy/core/cache/image_cache.dart';
import 'package:prince_academy/core/helpers/realtime_channel_helper.dart';
import 'package:prince_academy/core/services/firebase_messaging_service.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'firebase_options.dart';

bool get _supportsFirebasePush {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase Realtime can throw StateError("Bad state: StreamSink is closed")
  // from reconnect timers after hot restart / flaky sockets. Swallow only that.
  final previousOnError = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    if (RealtimeChannelHelper.isClosedSinkError(error)) {
      debugPrint('Suppressed Realtime reconnect error: $error');
      return true;
    }
    return previousOnError?.call(error, stack) ?? false;
  };

  if (_supportsFirebasePush) {
    // Must be registered before Firebase.initializeApp / runApp.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on PlatformException catch (error, stackTrace) {
      debugPrint('Firebase.initializeApp failed (full rebuild required): $error');
      debugPrintStack(stackTrace: stackTrace);
    } catch (error, stackTrace) {
      debugPrint('Firebase.initializeApp failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseMessagingService.initialize();
      } catch (error, stackTrace) {
        debugPrint('Push notification setup failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  AppImageCache.ensureBudget();
  await bootstrap();
  runApp(const PrinceAcademyApp());
}
