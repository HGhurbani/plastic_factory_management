import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
      apiKey: "AIzaSyCvhDNHFRn8hFl2xNihHS620j1deIrulNA",
      authDomain: "factory-system-914ef.firebaseapp.com",
      projectId: "factory-system-914ef",
      storageBucket: "factory-system-914ef.firebasestorage.app",
      messagingSenderId: "92456828886",
      appId: "1:92456828886:web:9176502f7d3a556ccfae77",
      measurementId: "G-ETQTWKB5KZ"
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAhtbaOJDh9rq0fHP6SmAseMO5FlYEExms',
    appId: '1:92456828886:android:a22bb74b39a371bccfae77',
    messagingSenderId: '92456828886',
    projectId: 'factory-system-914ef',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    iosBundleId: 'com.example.app',
  );
}
