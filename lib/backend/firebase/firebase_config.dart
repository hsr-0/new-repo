import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyAilQ6XMREBQPdrjphYcoiQb4xrr93hZgs",
            authDomain: "plant-shop-aaacc.firebaseapp.com",
            projectId: "plant-shop-aaacc",
            storageBucket: "plant-shop-aaacc.firebasestorage.app",
            messagingSenderId: "659160261509",
            appId: "1:659160261509:web:57bfb4d430d39f29b69aec",
            measurementId: "G-6Y0Z10N5DB"));
  } else {
    await Firebase.initializeApp();
  }
}
