// File synchronized with intricate-web-498607-t6 configuration
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const String _activeApiKey = 'AIzaSyDvV10Hws4gc0x8kQkXcAnqnINbEV7Dllw';
  static const String _projectId = 'intricate-web-498607-t6';

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: _activeApiKey,
    appId: '1:259748474267:web:091f1b39fa5814dae9453e',
    messagingSenderId: '259748474267',
    projectId: _projectId,
    authDomain: '$_projectId.firebaseapp.com',
    storageBucket: '$_projectId.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: _activeApiKey,
    appId: '1:259748474267:android:7ef661293ee0d650e9453e',
    messagingSenderId: '259748474267',
    projectId: _projectId,
    storageBucket: '$_projectId.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: _activeApiKey,
    appId: '1:259748474267:ios:5d5924a14c80f0f501e121',
    messagingSenderId: '259748474267',
    projectId: _projectId,
    storageBucket: '$_projectId.firebasestorage.app',
    iosBundleId: 'com.example.inventory_management_system',
  );

  static const FirebaseOptions macos = ios;
}
