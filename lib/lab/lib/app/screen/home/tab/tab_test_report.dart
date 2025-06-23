import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/lab/lib/app/controller/controller.dart';
import 'package:cosmetic_store/lab/lib/app/data/data_file.dart';
import 'package:cosmetic_store/lab/lib/app/routes/app_routes.dart';
import 'package:cosmetic_store/lab/lib/app/screen/home/tab/tab_home.dart';
import 'package:cosmetic_store/lab/lib/base/color_data.dart';
import 'package:cosmetic_store/lab/lib/base/constant.dart';
import 'package:cosmetic_store/lab/lib/base/widget_utils.dart';

import '../../../models/model_latest_report.dart';

class TabTestReports extends StatefulWidget {
  const TabTestReports({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _TabTestReportsState();
  }
}

class _TabTestReportsState extends State<TabTestReports> {
  BottomItemSelectionController bottomController =
      Get.put(BottomItemSelectionController());

  List<ModelLatestReport> latestReportList = DataFile.latestReportList;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        getVerSpace(20.h),
        getBackAppBar(context, () {}, 'Test Reports', withLeading: false),
        getVerSpace(20.h),
        buildReportView(context)
      ],
    );
  }

  Expanded buildReportView(BuildContext context) {
    return Expanded(
      child: (latestReportList.isEmpty)
          ? buildNoTestReportView(context)
          : buildTestReportView(context),
    );
  }

  ListView buildTestReportView(BuildContext context) {
    return ListView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              Container(
                height: 129.h,
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 20.h),
                decoration: BoxDecoration(
                  color: lightAccentColor,
                  borderRadius: BorderRadius.all(
                    Radius.circular(22.h),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          getCustomFont('Heart Rate', 17.sp, Colors.black, 1,
                              fontWeight: FontWeight.w500),
                          getVerSpace(14.h),
                          getRichText(
                              '92 ',
                              Colors.black,
                              FontWeight.w700,
                              35.h,
                              'bpm',
                              Colors.black,
                              FontWeight.w700,
                              22.h)
                        ],
                      ).paddingAll(20.h),
                    ),
                    getSvgImage('Vector.svg', width: 141.h).paddingAll(20.h)
                  ],
                ),
              ),
              getVerSpace(20.h),
              buildContainerRow(),
              getVerSpace(20.h),
              buildViewAllView(context, 'Latest Report', () {}),
              buildLatestReportListView(),
              getVerSpace(100.h),
            ],
          );
  }

  Column buildNoTestReportView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        getNoDataWidget(
          context,
          'No Test Reports Yet!',
          'Once you go to home, then you go to \nliabrary for get reports.',
          "no_report_icon.svg",
          withButton: true,
          btnText: 'Go to Home',
          btnClick: () {
            bottomController.bottomBarSelectedItem.value = 0;
          },
        ),
        getVerSpace(100.h),
      ],
    );
  }

  Widget buildContainerRow() {
    return Row(
      children: [
        buildTestContainer(
            'blood_bag.svg', 'Blood Group', 'A+', '#FFEDED'.toColor()),
        getHorSpace(20.h),
        buildTestContainer(
            'weighing_scale.svg', 'Weight', '20 kg', '#FFF4D8'.toColor()),
      ],
    ).paddingSymmetric(horizontal: 20.h);
  }

  ListView buildLatestReportListView() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: latestReportList.length,
      itemBuilder: (context, index) {
        ModelLatestReport report = latestReportList[index];
        return InkWell(
          onTap: () {
            Constant.sendToNext(context, Routes.testReportScreenRoute);
          },
          child: getShadowDefaultContainer(
              // height: 80.h,
              color: Colors.white,
              margin: EdgeInsets.symmetric(horizontal: 20.h, vertical: 10.h),
              padding: EdgeInsets.all(20.h),
              child: Column(
                children: [
                  Row(
                    children: [
                      getCustomFont('MGH35451J', 17.sp, Colors.black, 1,
                          fontWeight: FontWeight.w500),
                      getHorSpace(12.h),
                      Expanded(
                          child: getCustomFont(
                              report.testName, 18.sp, Colors.black, 1,
                              fontWeight: FontWeight.w700)),
                      buildPopupMenuButton(
                        (value) {
                          handleClick(value);
                        },
                      )
                    ],
                  ),
                  getVerSpace(10.h),
                  Row(
                    children: [
                      getCustomFont('Beneficiary :', 15.sp, greyFontColor, 1,
                          fontWeight: FontWeight.w500),
                      getHorSpace(10.h),
                      getCustomFont(report.name, 17.sp, Colors.black, 1,
                          fontWeight: FontWeight.w500),
                    ],
                  ),
                  getVerSpace(14.h),
                  Row(
                    children: [
                      Expanded(
                          child: buildDateTimeRow(report.date, report.time)),
                      getSvgImage('download.svg', width: 24.h, height: 24.h),
                    ],
                  ),
                ],
              )),
        );
      },
    );
  }

  PopupMenuButton<String> buildPopupMenuButton(
      PopupMenuItemSelected handleClick) {
    return PopupMenuButton<String>(
      onSelected: handleClick,
      color: Colors.white,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(22.h))),
      elevation: 2.h,
      itemBuilder: (BuildContext context) {
        return {'Edit', 'Delete'}.map((String choice) {
          return PopupMenuItem<String>(
            padding: EdgeInsets.zero,
            value: choice,
            height: 45.h,
            enabled: true,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                getVerSpace(10.h),
                getCustomFont(choice, 15.sp, Colors.black, 1,
                        fontWeight: FontWeight.w500)
                    .paddingSymmetric(horizontal: 14.h),
                (choice == 'Edit')
                    ? getDivider().paddingOnly(top: 20.h)
                    : getVerSpace(0),
              ],
            ),
          );
        }).toList();
      },
      child: getSvgImage('menu.svg', height: 24.h, width: 24.h),
    );
  }

  Expanded buildTestContainer(
      String icon, String title, String subtitle, Color color) {
    return Expanded(
      flex: 1,
      child: Container(
        height: 76.h,
        // width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(22.h)),
          color: color,
        ),
        child: Row(
          children: [
            getIconContainer(60.h, 60.h, Colors.white, icon).paddingAll(8.h),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                getCustomFont(title, 15.sp, Colors.black, 1,
                    fontWeight: FontWeight.w500),
                getVerSpace(3.h),
                getCustomFont(subtitle, 22.sp, Colors.black, 1,
                    fontWeight: FontWeight.w800),
              ],
            ))
          ],
        ),
      ),
    );
  }

  void handleClick(String value) {
    switch (value) {
      case 'Edit':
        break;
      case 'Delete':
        break;
    }
  }
}

Row buildDateTimeRow(String date, String time) {
  return Row(
    children: [
      getSvgImage('calender.svg', height: 20.h, width: 20.h),
      getHorSpace(4.h),
      getCustomFont(date, 15.sp, greyFontColor, 1, fontWeight: FontWeight.w500),
      getHorSpace(10.h),
      getSvgImage('time.svg', height: 20.h, width: 20.h),
      getHorSpace(4.h),
      getCustomFont(time, 15.sp, greyFontColor, 1, fontWeight: FontWeight.w500),
    ],
  );
}
