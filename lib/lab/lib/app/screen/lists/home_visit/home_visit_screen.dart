import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/lab/lib/app/routes/app_routes.dart';
import 'package:cosmetic_store/lab/lib/base/widget_utils.dart';

import '../../../../base/color_data.dart';
import '../../../../base/constant.dart';

class HomeVisitScreen extends StatefulWidget {
  const HomeVisitScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _HomeVisitScreenState();
  }
}

class _HomeVisitScreenState extends State<HomeVisitScreen> {
  void backClick() {
    Constant.backToPrev(context);
  }

  RxBool showTime = false.obs;

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
              }, 'Home Visit'),
              getVerSpace(3.h),
              buildLabLocView(context),
            ],
          ),
        ),
      ),
    );
  }

  Expanded buildLabLocView(BuildContext context) {
    return Expanded(
      child: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(22.h), topRight: Radius.circular(22.h)),
          image: DecorationImage(
            image: AssetImage('${Constant.assetImagePath}loc1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            getVerSpace(19.25.h),
            buildTopDistanceView(),
            (showTime.value) ? buildShowTimeWidget(context) : getVerSpace(0.h),
            getVerSpace(16.h),
            buildLabDetailView(context),
            getVerSpace(23.h),
            buildButton(context),
            getVerSpace(20.h),
          ],
        ),
      ),
    );
  }

  Expanded buildTopDistanceView() {
    return Expanded(
      child: ListView(
        children: [
          getShadowDefaultContainer(
              color: Colors.white,
              height: 113.h,
              margin: EdgeInsets.symmetric(horizontal: 20.h),
              padding: EdgeInsets.all(16.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      getSvgImage('hv1.svg', height: 20.h, width: 20.h),
                      Expanded(child: getSvgImage('line.svg')),
                      getSvgImage('hv2.svg', height: 20.h, width: 20.h),
                    ],
                  ),
                  getHorSpace(11.h),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 1,
                        child: getCustomFont('Jivan Road', 17.sp, Colors.black, 1,
                            fontWeight: FontWeight.w500),
                      ),
                      getDivider(endIndent: 8.h)
                          .paddingSymmetric(vertical: 19.h),
                      Expanded(
                        flex: 1,
                        child: getCustomFont('Road Name', 17.sp, Colors.black, 1,
                            fontWeight: FontWeight.w500),
                      )
                    ],
                  )),
                ],
              )),
        ],
      ),
    );
  }

  Widget buildShowTimeWidget(BuildContext context) {
    return getShadowDefaultContainer(
        height: 105.h,
        margin: EdgeInsets.symmetric(horizontal: 20.h),
        padding: EdgeInsets.all(20.h),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      getSvgImage('calender.svg', height: 24.h, width: 24.h),
                      getHorSpace(8.h),
                      getCustomFont('Tomorrow', 17.sp, Colors.black, 1,
                          fontWeight: FontWeight.w500)
                    ],
                  ),
                  getVerSpace(17.h),
                  Row(
                    children: [
                      getSvgImage('time.svg',
                          height: 24.h, width: 24.h, color: Colors.black),
                      getHorSpace(8.h),
                      getCustomFont('12:15 - 12:30', 17.sp, Colors.black, 1,
                          fontWeight: FontWeight.w500)
                    ],
                  ),
                ],
              ),
            ),
            getButton(
              context,
              Colors.transparent,
              'Edit',
              accentColor,
              () {},
              14.sp,
              weight: FontWeight.w700,
              isBorder: true,
              buttonHeight: 40.h,
              buttonWidth: 89.h,
              borderWidth: 2.h,
              borderColor: accentColor,
              borderRadius: BorderRadius.circular(22.h),
            )
          ],
        ));
  }

  Widget buildLabDetailView(BuildContext context) {
    return getShadowDefaultContainer(
      height: 133.h,
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: 20.h,
      ),
      padding: EdgeInsets.symmetric(vertical: 12.h),
      color: Colors.white,
      child: Row(
        children: [
          getHorSpace(12.h),
          getCircularImage(context, 109.h, 109.h, 22.h, 'lab1.png',
              boxFit: BoxFit.cover),
          getHorSpace(16.h),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                getCustomFont('Julianne Laboratory', 18.sp, Colors.black, 1,
                    fontWeight: FontWeight.w700),
                getVerSpace(10.h),
                Row(
                  children: [
                    getSvgImage('lab_phone.svg', height: 20.h, width: 20.h),
                    getHorSpace(10.h),
                    getCustomFont('+98 9525888565', 17.sp, Colors.black, 1,
                        fontWeight: FontWeight.w500),
                  ],
                ),
                getVerSpace(10.h),
                Row(
                  children: [
                    getSvgImage('lab_clock.svg', height: 20.h, width: 20.h),
                    getHorSpace(10.h),
                    getCustomFont(
                        '09:00 am to 10:00 pm', 17.sp, Colors.black, 1,
                        fontWeight: FontWeight.w500),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  ObxValue<RxBool> buildButton(BuildContext context) {
    return ObxValue(
        (p0) => getButton(
                    context,
                    accentColor,
                    (showTime.value) ? 'Confirm Home Visit' : 'Continue',
                    Colors.white, () {
              setState(() {
                (showTime.value)
                    ? Constant.sendToNext(
                        context, Routes.myHomeVisitScreenRoute)
                    : showTime.value = true;
              });
            }, 18.sp,
                    weight: FontWeight.w700,
                    buttonHeight: 60.h,
                    borderRadius: BorderRadius.all(Radius.circular(22.h)))
                .paddingSymmetric(horizontal: 20.h),
        showTime);
  }
}
