import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/lab/lib/app/routes/app_routes.dart';
import 'package:cosmetic_store/lab/lib/base/widget_utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../base/constant.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SettingsScreenState();
  }
}

class _SettingsScreenState extends State<SettingsScreen> {
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
              getVerSpace(20.h),
              getBackAppBar(context, () {
                backClick();
              }, 'Settings'),
              getVerSpace(20.h),
              buildSettingTabList(context)
            ],
          ),
        ),
      ),
    );
  }

  Expanded buildSettingTabList(BuildContext context) {
    return Expanded(
        child: Column(
      children: [
        buildDefaultTabWidget('EBF7FE', 'time.svg', 'Reminder', () {
          Constant.sendToNext(context, Routes.reminderScreenRoute);
        }),
        getDivider().marginSymmetric(vertical: 16.h),
        buildDefaultTabWidget(
            'E7FCE2', 'terms.svg', 'Terms & Conditions', () {}),
        getDivider().marginSymmetric(vertical: 16.h),
        buildDefaultTabWidget('FFEBE0', 'notifications.svg', 'Notifications',
            () {
          Constant.sendToNext(context, Routes.notificationScreenRoute);
        }),
        getDivider().marginSymmetric(vertical: 16.h),
        buildDefaultTabWidget('E9EEFF', 'privacy.svg', 'Privacy Policy', () async {
          // Constant.launchURL("http://www.google.com");
          await launchUrl(
              Uri.parse("http://www.google.com"),
              mode: LaunchMode.externalApplication,
          );
        }),
        getDivider().marginSymmetric(vertical: 16.h),
        buildDefaultTabWidget('F9F7DB', 'language.svg', 'Language', () { }),
        getDivider().marginSymmetric(vertical: 16.h),
        buildDefaultTabWidget('EEE7FF', 'contact.svg', 'Contact Us', () async{
          await launchUrl(
              Uri.parse("http://www.google.com"),
              mode: LaunchMode.externalApplication,
          );
        }),
      ],
    ).marginSymmetric(horizontal: 20.h));
  }
}
