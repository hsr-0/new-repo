import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/lab/lib/base/color_data.dart';
import 'package:cosmetic_store/lab/lib/base/constant.dart';
import 'package:cosmetic_store/lab/lib/base/widget_utils.dart';

import '../../../routes/app_routes.dart';

class LabDetailScreen extends StatefulWidget {
  const LabDetailScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _LabDetailScreenState();
  }
}

class _LabDetailScreenState extends State<LabDetailScreen> {
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
        extendBodyBehindAppBar: true,
        body: Column(
          children: [
            Expanded(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  Stack(
                    children: [
                      buildTopImageView(),
                      Column(
                        children: [
                          getVerSpace(40.h),
                          getBackAppBar(context, () {
                            backClick();
                          }, '', isDivider: false, iconColor: Colors.white),
                          // Align(alignment: Alignment.centerLeft,child: getBackIcon((){},color: Colors.white)),
                          getVerSpace(140.h),
                          buildAboutLabContainer(),
                          getVerSpace(30.h),
                          Row(
                            children: [
                              getCircleImage(context, 'specialist1.png', 68.h),
                              getHorSpace(12.h),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    getCustomFont('Dr. Vina Belgium', 16.sp,
                                        Colors.black, 1,
                                        fontWeight: FontWeight.w700),
                                    getVerSpace(3.h),
                                    getCustomFont(
                                        'Owner', 15.sp, greyFontColor, 1,
                                        fontWeight: FontWeight.w400),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  Constant.sendToNext(
                                      context, Routes.chatScreenRoute);
                                },
                                child: Container(
                                  height: 51.h,
                                  width: 51.h,
                                  decoration: BoxDecoration(
                                    color: fillColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                      child: getSvgImage('chat.svg',
                                          height: 24.h,
                                          width: 24.h,
                                          color: accentColor)),
                                ),
                              )
                            ],
                          ),
                          getVerSpace(20.h),
                          buildTitleRow('About', () {
                            Constant.sendToNext(
                                context, Routes.aboutLabScreenRoute);
                          }),
                          getVerSpace(20.h),
                          buildTitleRow('Location', () {
                            Constant.sendToNext(
                                context, Routes.labLocationScreenRoute);
                          }),
                          getVerSpace(20.h),
                          buildTitleRow('Reviews', () {
                            Constant.sendToNext(
                                context, Routes.labReviewsScreenRoute);
                          }),
                          getVerSpace(30.h),
                        ],
                      ).marginSymmetric(horizontal: 20.h),
                    ],
                  ),
                ],
              ),
            ),
            buildHomeVisitButton(context),
          ],
        ),
      ),
    );
  }

  Widget buildAboutLabContainer() {
    return getShadowDefaultContainer(
      height: 239.h,
      width: double.infinity,
      // margin: EdgeInsets.symmetric(horizontal: 20.h),
      padding: EdgeInsets.all(20.h),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          getCustomFont('Julianne Laboratory', 22.sp, Colors.black, 1,
              fontWeight: FontWeight.w700),
          getVerSpace(14.h),
          Expanded(
            child: Container(
              height: double.infinity,
              width: double.infinity,
              padding: EdgeInsets.all(20.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(22.h)),
                color: 'F8F8FC'.toColor(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildContactRow('+98 9525888565', 'lab_phone.svg'),
                  getVerSpace(20.h),
                  buildContactRow('laboratory@gmail.com', 'lab_email.svg'),
                  getVerSpace(20.h),
                  buildContactRow('09:00 am to 10:00 pm', 'lab_clock.svg'),
                  // getVerSpace(20.h),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget buildHomeVisitButton(BuildContext context) {
    return getButton(
      context,
      accentColor,
      "Home Visit",
      Colors.white,
      () {
        Constant.sendToNext(context, Routes.homeVisitScreenRoute);
      },
      18.sp,
      weight: FontWeight.w700,
      buttonHeight: 60.h,
      borderRadius: BorderRadius.circular(22.h),
      borderWidth: 2.h,
    ).marginSymmetric(horizontal: 20.h, vertical: 30.h);
  }

  Container buildTopImageView() {
    return Container(
      height: 297.h,
      width: double.infinity,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(22.h),
              bottomRight: Radius.circular(22.h)),
          image: DecorationImage(
            image: AssetImage('${Constant.assetImagePath}lab.png'),
            fit: BoxFit.cover,
          )),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x99000000), Color(0x00000000)],
          ),
        ),
      ),
    );
  }

  Widget buildTitleRow(String title, Function function) {
    return InkWell(
      onTap: () {
        function();
      },
      child: getShadowDefaultContainer(
          height: 60.h,
          width: double.infinity,
          color: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 18.h),
          child: Row(
            children: [
              Expanded(
                  child: getCustomFont(title, 17.sp, Colors.black, 1,
                      fontWeight: FontWeight.w500)),
              getSvgImage('arrow_right.svg', height: 24.h, width: 24.h),
            ],
          )),
    );
  }

  Row buildContactRow(String text, String icon) {
    return Row(
      children: [
        getSvgImage(icon, height: 20.h, width: 20.h),
        getHorSpace(8.h),
        getCustomFont(text, 17.sp, Colors.black, 1, fontWeight: FontWeight.w500)
      ],
    );
  }
}
