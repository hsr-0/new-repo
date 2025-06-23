import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/lab/lib/app/data/data_file.dart';
import 'package:cosmetic_store/lab/lib/app/routes/app_routes.dart';
import 'package:cosmetic_store/lab/lib/base/color_data.dart';
import 'package:cosmetic_store/lab/lib/base/constant.dart';
import 'package:cosmetic_store/lab/lib/base/widget_utils.dart';

import '../../../models/model_tests_list.dart';

class TestsListsScreen extends StatefulWidget {
  const TestsListsScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _TestsListsScreenState();
  }
}

class _TestsListsScreenState extends State<TestsListsScreen> {
  void backClick() {
    Constant.backToPrev(context);
  }

  List<ModelTestsList> testsList = DataFile.testsList;

  @override
  Widget build(BuildContext context) {
    initializeScreenSize(context);
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
              }, 'Tests'),
              getVerSpace(20.h),
              Expanded(
                child: Column(
                  children: [buildTestsListView(), buildAddTestButton(context)],
                ).marginSymmetric(horizontal: 20.h),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAddTestButton(BuildContext context) {
    return getButton(
      context,
      accentColor,
      'Add Test',
      Colors.white,
      () {},
      18.sp,
      weight: FontWeight.w700,
      buttonHeight: 60.h,
      borderRadius: BorderRadius.circular(22.h),
    ).marginSymmetric(vertical: 15.h);
  }

  Expanded buildTestsListView() {
    double margin = 20.h;
    int crossCount = 3;
    if (context.isTablet) {
      crossCount = 4;
    }
    double width = (MediaQuery.of(context).size.width - (margin * crossCount)) /
        crossCount;
    double height = 140.h;
    return Expanded(
      child: GridView.count(
        crossAxisCount: crossCount,
        crossAxisSpacing: margin,
        mainAxisSpacing: margin,
        childAspectRatio: width / height,
        children: List.generate(testsList.length, (index) {
          ModelTestsList tests = testsList[index];
          return InkWell(
            onTap: () {
              Constant.sendToNext(context, Routes.testDetailScreenRoute);
            },
            child: Container(
              height: height,
              width: 111.h,
              padding: EdgeInsets.symmetric(horizontal: 15.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22.h),
                color: tests.bgColor.toColor(),
              ),
              child: Column(
                children: [
                  getVerSpace(14.h),
                  Flexible(
                    child: Container(
                      height: double.infinity,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22.h),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x0c000000),
                            blurRadius: 32.h,
                            offset: const Offset(0, 12),
                          ),
                        ],
                        color: Colors.white,
                      ),
                      child: Center(
                          child: getAssetImage(tests.icon,
                              height: 40.h, width: 40.h)),
                    ),
                  ),
                  getVerSpace(12.h),
                  getCustomFont(tests.title, 15.sp, Colors.black, 1,
                      fontWeight: FontWeight.w500),
                  getVerSpace(12.h),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
