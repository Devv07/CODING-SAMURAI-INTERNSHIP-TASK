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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyDiAoHp51F_aa6QEsu18aKAYmnwfpvn9dw',
    appId: '1:939073028985:web:bef4cc9a854205213965a8',
    messagingSenderId: '939073028985',
    projectId: 'hello-app-ccd8c',
    authDomain: 'hello-app-ccd8c.firebaseapp.com',
    databaseURL: 'https://hello-app-ccd8c-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'hello-app-ccd8c.firebasestorage.app',
    measurementId: 'G-XH8NJ2LTNJ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAW4gl1otOLXxrG4dCRTZNenOCIKUVx4Fs',
    appId: '1:939073028985:android:afb9878cea49f3ad3965a8',
    messagingSenderId: '939073028985',
    projectId: 'hello-app-ccd8c',
    databaseURL: 'https://hello-app-ccd8c-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'hello-app-ccd8c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD5y4CStZCCYVR3ANvugubaVH8VeIICppI',
    appId: '1:939073028985:ios:64585a18af07e8903965a8',
    messagingSenderId: '939073028985',
    projectId: 'hello-app-ccd8c',
    databaseURL: 'https://hello-app-ccd8c-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'hello-app-ccd8c.firebasestorage.app',
    iosClientId: '939073028985-abbppp4bnn8t9u1nkepogulfs4sfb6fq.apps.googleusercontent.com',
    iosBundleId: 'com.example.helloApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDiAoHp51F_aa6QEsu18aKAYmnwfpvn9dw',
    appId: '1:939073028985:web:f389d09ce8bfd6083965a8',
    messagingSenderId: '939073028985',
    projectId: 'hello-app-ccd8c',
    authDomain: 'hello-app-ccd8c.firebaseapp.com',
    databaseURL: 'https://hello-app-ccd8c-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'hello-app-ccd8c.firebasestorage.app',
    measurementId: 'G-SZFP3EHWJ3',
  );
}
