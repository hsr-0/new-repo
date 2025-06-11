import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainSplashPageWidget extends StatelessWidget {
  static const String routeName = 'MainSplashPage';
  static const String routePath = '/';

  const MainSplashPageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 4), () {
      context.go('/sections');
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/beytei.png', width: 300),
            const SizedBox(height: 120),
            const Text(
              'منصة بيتي',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Powered by HSR'),
          ],
        ),
      ),
    );
  }
}
