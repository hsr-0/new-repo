import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // ⭐ تأكد أنك أضفت go_router في pubspec.yaml
import 'package:google_fonts/google_fonts.dart'; // ⭐ تأكد أنك أضفت google_fonts في pubspec.yaml

class SplashHomePageWidget extends StatelessWidget {
  const SplashHomePageWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ⭐ نستخدم Future.delayed للانتقال بعد 5 ثواني
    Future.delayed(const Duration(seconds: 2), () {
      GoRouter.of(context).go('/sections');
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ⭐ الشعار
            Image.asset(
              'assets/images/untitled_design__3__1_.png',
              width: 250,
            ),
            const SizedBox(height: 40),

            // ⭐ النص تحت الشعار
            Text(
              'منصة بيتي شريكـــك نحـــو التطـــور',
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // ⭐ نص المالك
            Text(
              'المالـــك  حســــين ســـعـــد',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
