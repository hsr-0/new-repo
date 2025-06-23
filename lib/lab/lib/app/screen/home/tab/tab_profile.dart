import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/lab/lib/app/routes/app_routes.dart';
import 'package:cosmetic_store/lab/lib/base/color_data.dart';
import 'package:cosmetic_store/lab/lib/base/constant.dart';
import 'package:cosmetic_store/lab/lib/base/pref_data.dart';
import 'package:cosmetic_store/lab/lib/base/widget_utils.dart';

import '../../../controller/controller.dart';

class TabProfile extends StatefulWidget {
  const TabProfile({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _TabProfileState();
  }
}

class _TabProfileState extends State<TabProfile> {
  BottomItemSelectionController navController =
      Get.put(BottomItemSelectionController());

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: fillColor,
          child: Column(
            children: [
              getVerSpace(20.h),
              getBackAppBar(context, () {}, 'Profile',
                  withAction: true,
                  withLeading: false,
                  isDivider: false,
                  actionIcon: 'setting.svg',
                  iconColor: Colors.black, actionClick: () {
                Constant.sendToNext(context, Routes.settingsScreenRoute);
              }),
              getVerSpace(27.h),
              buildProfileView(context),
              getVerSpace(26.h),
              buildTabContainer(context)
            ],
          ),
        )
      ],
    );
  }

  Widget buildProfileView(BuildContext context) {
    return Row(
      children: [
        getCircularImage(context, 92.h, 92.h, 22.h, 'user_profile.png'),
        getHorSpace(12.h),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            getCustomFont('Merry Fernandez', 18.sp, Colors.black, 1,
                fontWeight: FontWeight.w700),
            getVerSpace(3.h),
            getCustomFont('merryfernandez@gmail.com', 15.sp, Colors.black, 1,
                fontWeight: FontWeight.w500),
          ],
        )
      ],
    ).paddingSymmetric(horizontal: 20.h);
  }

  Expanded buildTabContainer(BuildContext context) {
    return Expanded(
        flex: 1,
        child: Container(
          height: double.infinity,
          width: double.infinity,
          padding: EdgeInsets.all(20.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40.h),
                topRight: Radius.circular(40.h)),
            boxShadow: [
              BoxShadow(
                color: const Color(0x289a90b8),
                blurRadius: 32.h,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: ListView(
            children: [
              buildTabView(context),
            ],
          )
        ));
  }

  Column buildTabView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildDefaultTabWidget('#FFEBF5', 'profile.svg', 'My Profile', () {
          Constant.sendToNext(context, Routes.myProfileScreenRoute);
        }),
        getDivider().marginSymmetric(vertical: 16.h),
        buildDefaultTabWidget('#F9F7DB', 'my_home_visit.svg', 'My Home Visit',
            () {
          Constant.sendToNext(context, Routes.myHomeVisitScreenRoute);
        }),
        getDivider().marginSymmetric(vertical: 16.h),
        buildDefaultTabWidget(
            '#E7EEFF', 'my_tests.svg', 'My Test Bookings', () {}),
        getDivider().marginSymmetric(vertical: 16.h),
        buildDefaultTabWidget('#FFEDE2', 'card.svg', 'My Cards', () {
          Constant.sendToNext(context, Routes.myCardScreenRoute);
        }),
        getVerSpace(57.h),
        buildLogOutButton(context)
      ],
    );
  }

  Widget buildLogOutButton(BuildContext context) {
    return getButton(
      context,
      accentColor,
      'Logout',
      Colors.white,
      () {
        PrefData.setIsSignIn(false);
        navController.bottomBarSelectedItem.value = 0;
        Constant.sendToNext(context, Routes.loginRoute);
      },
      18.sp,
      weight: FontWeight.w700,
      buttonHeight: 60.h,
      borderRadius: BorderRadius.all(Radius.circular(22.h)),
    );
  }
}
