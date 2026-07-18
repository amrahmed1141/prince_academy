// File generated from the existing Firebase Android and iOS config files.
// Re-run FlutterFire CLI if the Firebase app IDs or bundle IDs change.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'FirebaseOptions have not been configured for web.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'FirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyChbCTyxxX7pbaDeRTgMCJyLRjAFXIfqMA',
    appId: '1:124408585431:android:6138f121581ea9855d6492',
    messagingSenderId: '124408585431',
    projectId: 'ecommerce-provider-e2f9a',
    storageBucket: 'ecommerce-provider-e2f9a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA_EGTRlKkctwSIYWBvRTlZ40-jLqrBkSg',
    appId: '1:124408585431:ios:a01adee7de8b31f45d6492',
    messagingSenderId: '124408585431',
    projectId: 'ecommerce-provider-e2f9a',
    storageBucket: 'ecommerce-provider-e2f9a.firebasestorage.app',
    iosBundleId: 'com.example.princeAcademy',
  );
}
