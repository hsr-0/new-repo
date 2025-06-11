import 'package:flutter/material.dart';

class OffersPage extends StatelessWidget {
  const OffersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('عروضنا'),
      ),
      body: const Center(
        child: Text(
          'مرحباً بك في صفحة العروض!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
