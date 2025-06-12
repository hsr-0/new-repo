import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyD7cRZeGlqv1LqeCNfkeQUiasGmg8aStj4",
        authDomain: "beytei-me.firebaseapp.com", // عادة تكون بهذا الشكل
        projectId: "beytei-me",
        storageBucket: "beytei-me.firebasestorage.app",
        messagingSenderId: "266994090766",
        appId: "1:266994090766:ios:1e61d51d5dcdb007894d5f",
      ),
    );
  } else {
    await Firebase.initializeApp(); // Android و iOS يستخدمان الملفات المرفقة تلقائياً
  }
}
