// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC1PwRLe259_SjunGwgbvS8VFVTbSgM4Yo',
    appId: '1:807301628316:web:e3398d71462e9c1d060859',
    messagingSenderId: '807301628316',
    projectId: 'socialapp-37079',
    authDomain: 'socialapp-37079.firebaseapp.com',
    storageBucket: 'socialapp-37079.firebasestorage.app',
    measurementId: 'G-X61TZJEM4W',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCYiSA1cxQkh5i7hkFzovw8cfXW6Dq-t1Q',
    appId: '1:807301628316:android:7dde0b5dc1e7b047060859',
    messagingSenderId: '807301628316',
    projectId: 'socialapp-37079',
    storageBucket: 'socialapp-37079.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDAO2e6TYnuj2pE6Otgv4owFy1W_n8l550',
    appId: '1:807301628316:ios:1a66100bf9f47be9060859',
    messagingSenderId: '807301628316',
    projectId: 'socialapp-37079',
    storageBucket: 'socialapp-37079.firebasestorage.app',
    iosBundleId: 'com.example.socialApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDAO2e6TYnuj2pE6Otgv4owFy1W_n8l550',
    appId: '1:807301628316:ios:1a66100bf9f47be9060859',
    messagingSenderId: '807301628316',
    projectId: 'socialapp-37079',
    storageBucket: 'socialapp-37079.firebasestorage.app',
    iosBundleId: 'com.example.socialApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC1PwRLe259_SjunGwgbvS8VFVTbSgM4Yo',
    appId: '1:807301628316:web:48a7463177d9d82d060859',
    messagingSenderId: '807301628316',
    projectId: 'socialapp-37079',
    authDomain: 'socialapp-37079.firebaseapp.com',
    storageBucket: 'socialapp-37079.firebasestorage.app',
    measurementId: 'G-1RCFWE1FP6',
  );
}
