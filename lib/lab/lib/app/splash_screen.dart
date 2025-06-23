import 'dart:async';

import 'package:cosmetic_store/lab/lib/app/routes/app_routes.dart';
import 'package:cosmetic_store/lab/lib/base/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


import '../base/pref_data.dart';
import '../base/widget_utils.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    getIntro();
  }

  getIntro() async {
    bool isIntro = await PrefData.getIsIntro();
    bool isLogin = await PrefData.getIsSignIn();

    Timer(
      const Duration(seconds: 3),
      () {
        if (isIntro) {
          Constant.sendToNext(context, Routes.introRoute);
        } else {
          if (isLogin) {
            Constant.sendToNext(context, Routes.homeScreenRoute);
          } else {
            Constant.sendToNext(context, Routes.loginRoute);
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    initializeScreenSize(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            getAssetImage("splash_logo.png", width: 146.2.h, height: 206.18.h)
          ],
        ),
      ),
    );
  }
}
