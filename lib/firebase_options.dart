import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDemoWebApiKey',
    appId: '1:123456789:web:abcdefghijklmnopqr',
    messagingSenderId: '123456789',
    projectId: 'samaki-fresh-connect-dev',
    authDomain: 'samaki-fresh-connect-dev.firebaseapp.com',
    databaseURL: 'https://samaki-fresh-connect-dev.firebaseio.com',
    storageBucket: 'samaki-fresh-connect-dev.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDemoAndroidApiKey',
    appId: '1:123456789:android:abcdefghijklmnopqr',
    messagingSenderId: '123456789',
    projectId: 'samaki-fresh-connect-dev',
    databaseURL: 'https://samaki-fresh-connect-dev.firebaseio.com',
    storageBucket: 'samaki-fresh-connect-dev.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDemoiOSApiKey',
    appId: '1:123456789:ios:abcdefghijklmnopqr',
    messagingSenderId: '123456789',
    projectId: 'samaki-fresh-connect-dev',
    databaseURL: 'https://samaki-fresh-connect-dev.firebaseio.com',
    storageBucket: 'samaki-fresh-connect-dev.appspot.com',
    iosBundleId: 'com.samakifresh.connect',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDemomacOSApiKey',
    appId: '1:123456789:macos:abcdefghijklmnopqr',
    messagingSenderId: '123456789',
    projectId: 'samaki-fresh-connect-dev',
    databaseURL: 'https://samaki-fresh-connect-dev.firebaseio.com',
    storageBucket: 'samaki-fresh-connect-dev.appspot.com',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyDemoLinuxApiKey',
    appId: '1:123456789:linux:abcdefghijklmnopqr',
    messagingSenderId: '123456789',
    projectId: 'samaki-fresh-connect-dev',
    databaseURL: 'https://samaki-fresh-connect-dev.firebaseio.com',
    storageBucket: 'samaki-fresh-connect-dev.appspot.com',
  );
}
