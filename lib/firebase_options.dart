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
    apiKey: 'AIzaSyDtu33ypp9lVPpSKcIjWJrvMtXb-0w4xl0',
    appId: '1:802401034598:web:479c377fa78745caf468a7',
    messagingSenderId: '802401034598',
    projectId: 'mobile-proyek-c',
    authDomain: 'mobile-proyek-c.firebaseapp.com',
    storageBucket: 'mobile-proyek-c.firebasestorage.app',
    measurementId: 'G-8Z4HCYLB71',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDJICXWJ97c0X3EBt9LPSbx6PsPOcZP3GQ',
    appId: '1:802401034598:android:3579bf0545e193abf468a7',
    messagingSenderId: '802401034598',
    projectId: 'mobile-proyek-c',
    storageBucket: 'mobile-proyek-c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB0mv-qVrIMLzOV5Nq-L03fNI7U7KU7k2I',
    appId: '1:802401034598:ios:70f96755842241f9f468a7',
    messagingSenderId: '802401034598',
    projectId: 'mobile-proyek-c',
    storageBucket: 'mobile-proyek-c.firebasestorage.app',
    iosBundleId: 'com.example.eventku',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB0mv-qVrIMLzOV5Nq-L03fNI7U7KU7k2I',
    appId: '1:802401034598:ios:70f96755842241f9f468a7',
    messagingSenderId: '802401034598',
    projectId: 'mobile-proyek-c',
    storageBucket: 'mobile-proyek-c.firebasestorage.app',
    iosBundleId: 'com.example.eventku',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDtu33ypp9lVPpSKcIjWJrvMtXb-0w4xl0',
    appId: '1:802401034598:web:ea5a36518a245210f468a7',
    messagingSenderId: '802401034598',
    projectId: 'mobile-proyek-c',
    authDomain: 'mobile-proyek-c.firebaseapp.com',
    storageBucket: 'mobile-proyek-c.firebasestorage.app',
    measurementId: 'G-NJZ8DNDMXW',
  );

}