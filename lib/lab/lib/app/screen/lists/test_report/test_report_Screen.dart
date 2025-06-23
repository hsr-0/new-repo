import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/lab/lib/app/controller/controller.dart';
import 'package:cosmetic_store/lab/lib/app/routes/app_routes.dart';
import 'package:cosmetic_store/lab/lib/base/color_data.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../../../base/constant.dart';
import '../../../../base/progress_bar.dart';
import '../../../../base/widget_utils.dart';
import '../../home/tab/tab_test_report.dart';

class TestReportScreen extends StatefulWidget {
  const TestReportScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _TestReportScreenState();
  }
}

class _TestReportScreenState extends State<TestReportScreen> {
  void backClick() {
    Constant.backToPrev(context);
  }

  BottomItemSelectionController bottomController =
      Get.put(BottomItemSelectionController());

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              getVerSpace(20.h),
              getBackAppBar(context, () {
                backClick();
              }, 'Test Report Detail',
                  withAction: true, actionIcon: 'download.svg'),
              getVerSpace(20.h),
              Expanded(
                flex: 1,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    buildTestInfoView(),
                    getVerSpace(30.h),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildInfoView(),
                        buildParameterView(),
                        getVerSpace(30.h),
                        buildTotalCholesterolRow(),
                        getVerSpace(30.h),
                        buildGoToHomeButton(context),
                        getVerSpace(30.h),
                      ],
                    ).marginSymmetric(horizontal: 20.h),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTestInfoView() {
    return Row(
      children: [
        Container(
          height: 102.h,
          width: 102.h,
          decoration: BoxDecoration(
            color: 'FDE9E9'.toColor(),
            borderRadius: BorderRadius.circular(22.h),
          ),
          child: Center(
              child: getAssetImage('test3.png', height: 50.h, width: 50.h)),
        ),
        getHorSpace(20.h),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            getCustomFont('Thyroid', 22.sp, Colors.black, 1,
                fontWeight: FontWeight.w700),
            getVerSpace(6.h),
            getCustomFont('MGH35451J', 15.sp, greyFontColor, 1,
                fontWeight: FontWeight.w500),
            getVerSpace(10.h),
            buildDateTimeRow('20 June, 2022,', '05:26 AM')
          ],
        )
      ],
    ).paddingSymmetric(horizontal: 20.h);
  }

  Container buildTotalCholesterolRow() {
    return Container(
      height: 121.h,
      padding: EdgeInsets.all(19.h),
      decoration: BoxDecoration(
          color: "F8F4FF".toColor(),
          borderRadius: BorderRadius.all(Radius.circular(22.h)),
          border: Border.all(color: "EBE0FF".toColor())),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          getCustomFont('Total Cholesterol', 20.sp, Colors.black, 1,
              fontWeight: FontWeight.w700),
          Container(
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: CircularPercentIndicator(
              radius: 40.h,
              lineWidth: 6.h,
              animation: true,
              percent: 0.6,
              backgroundWidth: 6.h,
              backgroundColor: "E0DBF4".toColor(),
              center: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  getCustomFont('120', 18.sp, Colors.black, 1,
                      fontWeight: FontWeight.w700),
                  getVerSpace(3.h),
                  getCustomFont('mg', 15.sp, Colors.black, 1,
                      fontWeight: FontWeight.w500),
                ],
              ),
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Column buildInfoView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        getCustomFont("Beneficiary :", 15.sp, greyFontColor, 1,
            fontWeight: FontWeight.w500),
        getVerSpace(6.h),
        getRichText("Merry Fernandez ", Colors.black, FontWeight.w500, 17.sp,
            "(Female)", greyFontColor, FontWeight.w500, 16.sp),
        getDivider().marginSymmetric(vertical: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                getCustomFont('Strength', 15.sp, greyFontColor, 1,
                    fontWeight: FontWeight.w500),
                getVerSpace(6.h),
                getCustomFont('1/125 mg', 17.sp, Colors.black, 1,
                    fontWeight: FontWeight.w500),
              ],
            ),
            Column(
              children: [
                getCustomFont('Quantity', 15.sp, greyFontColor, 1,
                    fontWeight: FontWeight.w500),
                getVerSpace(6.h),
                getCustomFont('60 Tablets', 17.sp, Colors.black, 1,
                    fontWeight: FontWeight.w500),
              ],
            ),
            Column(
              children: [
                getCustomFont('Refill', 15.sp, greyFontColor, 1,
                    fontWeight: FontWeight.w500),
                getVerSpace(6.h),
                getCustomFont('None', 17.sp, Colors.black, 1,
                    fontWeight: FontWeight.w500),
              ],
            ),
          ],
        ),
        getDivider().marginSymmetric(vertical: 20.h),
      ],
    );
  }

  Column buildParameterView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        getCustomFont("General Parameters", 20.sp, Colors.black, 1,
            fontWeight: FontWeight.w700),
        buildPercentRow("K", "#8870E6", "#E6DDFF", "#F6F6FA", 42),
        buildPercentRow("Mg", "#FF6883", "#FFDDDD", "#FFF6F6", 5),
        buildPercentRow("Ca", "#98ECB0", "#D7F3DA", "#F2FFF0", 54),
        buildPercentRow("Na", "#FFE071", "#F3EDB7", "#FFFEEC", 78),
        buildPercentRow("Kr", "#70DFE6", "#D3F7FF", "#F1FDFE", 34),
      ],
    );
  }

  Widget buildPercentRow(String param, String progressColor, String borderColor,
      String bgColor, int rate) {
    return Row(
      children: [
        SizedBox(
            width: 39.h,
            child: getCustomFont(param, 17.sp, Colors.black, 1,
                fontWeight: FontWeight.w500)),
        Expanded(
          child: FAProgressBar(
            currentValue: rate.toDouble(),
            animatedDuration: Duration.zero,
            backgroundColor: bgColor.toColor(),
            borderRadius: BorderRadius.all(Radius.circular(17.h)),
            size: 10.h,
            border: Border.all(color: borderColor.toColor()),
            progressColor: progressColor.toColor(),
          ),
        ),
        SizedBox(
            width: 50.h,
            child: getCustomFont("$rate%", 17.sp, Colors.black, 1,
                fontWeight: FontWeight.w500, textAlign: TextAlign.right)),
      ],
    ).marginOnly(top: 10.h);
  }

  Widget buildGoToHomeButton(BuildContext context) {
    return getButton(context, accentColor, 'Go to Home', Colors.white, () {
      // bottomController.bottomBarSelectedItem = 0;
      Constant.sendToNext(context, Routes.homeScreenRoute);
    }, 18.sp,
        buttonHeight: 60.h,
        weight: FontWeight.w700,
        borderRadius: BorderRadius.all(Radius.circular(22.h)));
  }
}
