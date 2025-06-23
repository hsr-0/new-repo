import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/lab/lib/base/color_data.dart';

import '../../../../base/constant.dart';
import '../../../../base/widget_utils.dart';
import '../../../routes/app_routes.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MyProfileScreenState();
  }
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  void backClick() {
    Constant.backToPrev(context);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        backClick();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    getVerSpace(20.h),
                    getBackAppBar(context, () {
                      backClick();
                    }, 'My Profile'),
                    getVerSpace(20.h),
                    getCircularImage(
                            context, 92.h, 92.h, 22.h, 'user_profile.png',
                            boxFit: BoxFit.cover)
                        .marginSymmetric(horizontal: 20.h),
                    getVerSpace(31.h),
                    buildProfileTextField().marginSymmetric(horizontal: 20.h)
                  ],
                ),
              ),
              buildEditProfileButton(context),
              getVerSpace(30.h),
            ],
          ),
        ),
      ),
    );
  }

  Wrap buildProfileTextField() {
    return Wrap(
      children: [
        buildRow('Full Name', 'Merry Fernandez'),
        getDivider().marginSymmetric(vertical: 16.h),
        buildRow('Email', 'merryfernandez@gmail.com'),
        getDivider().marginSymmetric(vertical: 16.h),
        buildRow('Mobile Number', '+91 6963565985'),
        getDivider().marginSymmetric(vertical: 16.h),
        buildRow('Date of Birth', '23 Jan, 1995'),
        getDivider().marginSymmetric(vertical: 16.h),
      ],
    );
  }

  Widget buildEditProfileButton(BuildContext context) {
    return getButton(
      context,
      accentColor,
      'Edit Profile',
      Colors.white,
      () {
        Constant.sendToNext(context, Routes.editProfileScreenRoute);
      },
      18.sp,
      borderRadius: BorderRadius.all(Radius.circular(22.h)),
      buttonHeight: 60.h,
    ).marginSymmetric(horizontal: 20.h);
  }

  Row buildRow(String title, String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        getCustomFont(title, 17.sp, greyFontColor, 1,
            fontWeight: FontWeight.w500),
        getCustomFont(name, 17.sp, Colors.black, 1,
            fontWeight: FontWeight.w500),
      ],
    );
  }
}
