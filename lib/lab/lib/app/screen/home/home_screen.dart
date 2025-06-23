 // ignore: library_prefixes
import 'package:convex_bottom_bar/convex_bottom_bar.dart' as bottomBar;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/lab/lib/app/screen/home/tab/tab_chat.dart';
import 'package:cosmetic_store/lab/lib/app/screen/home/tab/tab_home.dart';
import 'package:cosmetic_store/lab/lib/app/screen/home/tab/tab_home_visit.dart';
import 'package:cosmetic_store/lab/lib/app/screen/home/tab/tab_profile.dart';
import 'package:cosmetic_store/lab/lib/app/screen/home/tab/tab_test_report.dart';
import 'package:cosmetic_store/lab/lib/base/widget_utils.dart';

import '../../controller/controller.dart';
import '../../data/data_file.dart';
import '../../models/model_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _HomeScreenState();
  }
}

class _HomeScreenState extends State<HomeScreen> {
  List<Widget> bottomViewList = [
    const TabHome(),
    const TabTestReports(),
    const TabHomeVisit(),
    const TabChat(),
    const TabProfile(),
  ];

  List<ModelBottomNav> allBottomNavList = DataFile.bottomList;
  final controller = Get.put(BottomItemSelectionController());

  @override
  Widget build(BuildContext context) {
    initializeScreenSize(context);
    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop();
        return false;
      },
      child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
              child: Obx(() =>
                  bottomViewList[controller.bottomBarSelectedItem.value])),
          bottomNavigationBar: bottomBar.ConvexAppBar.builder(
            disableDefaultTabController: false,
            onTap: (index) {
              controller.bottomBarSelectedItem.value = index;
            },
            onTapNotify: (index) {
              controller.bottomBarSelectedItem.value = index;
              return true;
            },
            // elevation: 1,
            count: allBottomNavList.length,
            backgroundColor: Colors.white,
            itemBuilder: Builder(),
            top: -45.h,
            // curveSize: 80.h,
            // curve: Curves.easeOut,
            initialActiveIndex: 0,
            height: 75.h,
          )),
    );
  }
}

class Builder extends bottomBar.DelegateBuilder {
  List<ModelBottomNav> allBottomNavList = DataFile.bottomList;
  final controller = Get.put(BottomItemSelectionController());

  @override
  Widget build(BuildContext context, int index, bool active) {
    ModelBottomNav nav = allBottomNavList[index];
    if (index == 2) {
      return Center(
        child: getSvgImage('home_visit.svg', width: 54.h, height: 54.h)
            .marginOnly(bottom: 47.h),
      );
    }
    return ObxValue(
        (p0) => getSvgImage(
              (controller.bottomBarSelectedItem.value == index)
                  ? nav.activeIcon
                  : nav.icon,
              width: 24.h,
              height: 24.h,
            ),
        controller.bottomBarSelectedItem);
  }

  @override
  bool fixed() {
    return true;
  }
}
