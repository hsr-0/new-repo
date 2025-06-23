import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/lab/lib/app/data/data_file.dart';
import 'package:cosmetic_store/lab/lib/app/models/model_nearby_lab.dart';
import 'package:cosmetic_store/lab/lib/app/models/model_top_specialist.dart';
import 'package:cosmetic_store/lab/lib/app/routes/app_routes.dart';
import 'package:cosmetic_store/lab/lib/base/color_data.dart';
import 'package:cosmetic_store/lab/lib/base/constant.dart';
import 'package:cosmetic_store/lab/lib/base/widget_utils.dart';
import '../../../models/model_test_panel.dart';

class TabHome extends StatefulWidget {
  const TabHome({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _TabHomeState();
  }
}

class _TabHomeState extends State<TabHome> {
  List<ModelTestPanel> testPanelList = DataFile.testPanelList;
  List<ModelNearbyLab> nearbyLabList = DataFile.nearbyLabList;
  List<ModelTopSpecialist> topSpecialistList = DataFile.topSpecialistList;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        getVerSpace(20.h),
        buildTopProfileView(),
        getVerSpace(16.h),
        buildTopView(),
        getVerSpace(20.h),
        buildTabView(),
        getVerSpace(24.h),
        buildViewAllView(context, 'Tests Panel', () {
          Constant.sendToNext(context, Routes.testsPanelScreenRoute);
        }),
        buildTestPanelView(),
        buildViewAllView(context, 'Nearby Laboratories', () {
          Constant.sendToNext(context, Routes.nearbyLabScreenRoute);
        }),
        buildNearbyLabView(),
        buildViewAllView(context, 'Top Specialist', () {
          Constant.sendToNext(context, Routes.topSpecialistScreenRoute);
        }),
        getVerSpace(10.h),
        buildTopSpecialistView(),
        getVerSpace(50.h),
      ],
    );
  }

  SizedBox buildTopSpecialistView() {
    return SizedBox(
      height: 142.h,
      width: double.infinity,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, index) {
          ModelTopSpecialist specialist = topSpecialistList[index];
          return GestureDetector(
            onTap: () {
              Constant.sendToNext(context, Routes.specialistDetailScreenRoute);
            },
            child: Container(
              height: double.infinity,
              width: 124.h,
              // margin: EdgeInsets.symmetric(horizontal: 20.h),
              decoration: BoxDecoration(
                  border: (index != 3)
                      ? Border(right: BorderSide(width: 2.h, color: fillColor))
                      : null),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: getCircleImage(
                        context, specialist.img, double.infinity),
                  ),
                  getVerSpace(10.h),
                  getCustomFont(specialist.name, 16.sp, Colors.black, 1,
                      fontWeight: FontWeight.w700),
                  getVerSpace(3.h),
                  getCustomFont(specialist.category, 15.sp, greyFontColor, 1,
                      fontWeight: FontWeight.w500),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  SizedBox buildTestPanelView() {
    return SizedBox(
      height: 225.h,
      width: double.infinity,
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: testPanelList.length,
        itemBuilder: (context, index) {
          ModelTestPanel test = testPanelList[index];
          return getShadowDefaultContainer(
            height: 210.h,
            width: 177.h,
            margin: EdgeInsets.only(
                left: (index == 0) ? 20.h : 8.h,
                right: (index == testPanelList.length - 1) ? 20.h : 8.h,
                bottom: 24.h,
                top: 10.h),
            color: Colors.white,
            child: Column(
              children: [
                Expanded(
                    child: getCircularImage(context, double.infinity,
                            double.infinity, 22.h, test.img,
                            boxFit: BoxFit.cover)
                        .marginAll(10.h)),
                getCustomFont(test.title, 18.sp, Colors.black, 1,
                    fontWeight: FontWeight.w700),
                getVerSpace(5.h),
                getCustomFont(test.test, 15.sp, Colors.black, 1,
                    fontWeight: FontWeight.w500),
                getVerSpace(10.h),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildTabView() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        getTabCell('#EEE5FF'.toColor(),'test_icon.svg','Tests',(){
          Constant.sendToNext(context, Routes.testsListsScreenRoute);
        }),
        getHorSpace(20.h),
        getTabCell('#E2F4FF'.toColor(),'lab_icon.svg','labs',(){
          Constant.sendToNext(context, Routes.nearbyLabScreenRoute);
        }),
        getHorSpace(20.h),
        getTabCell('#FFEAFD'.toColor(),'tip_icon.svg','Tips',(){}),
      ],
    ).marginSymmetric(horizontal: 20.h);
  }

  Expanded getTabCell(Color color,String icon,String title,Function function) {
    return Expanded(
        flex: 1,
        child: GestureDetector(
          onTap: (){
            function();
          },
          child: Container(
            height: 62.h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.all(Radius.circular(30.h)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                getHorSpace(5.h),
                Container(
                  height: 54.h,
                  width: 54.h,
                  margin: EdgeInsets.symmetric(vertical: 5.h),
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: Center(
                      child: getSvgImage(icon, height: 24.h, width: 24.h)),
                ),
                // getHorSpace(10.h),
                Expanded(
                  child: Center(
                      child: getCustomFont(title, 15.sp, Colors.black, 1,
                          fontWeight: FontWeight.w500)),
                ),
                getHorSpace(10.h),
              ],
            ),
          ),
        ),
      );
  }

  Container buildTopView() {
    return Container(
      height: 168.h,
      margin: EdgeInsets.symmetric(horizontal: 20.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(22.h)),
        color: accentColor,
      ),
      child: Row(
        children: [
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                flex: 1,
                child: getMultilineCustomFont(
                    'Assured \nLaboratories', 20.sp, Colors.white,
                    fontWeight: FontWeight.w700,
                    txtHeight: 1.4.h,
                    overflow: TextOverflow.fade),
              ),
              getVerSpace(10.h),
              Expanded(
                flex: 1,
                child: getMultilineCustomFont(
                    '100% Guaranteed \nResults', 15.sp, Colors.white,
                    fontWeight: FontWeight.w500,
                    txtHeight: 1.4.h,
                    overflow: TextOverflow.fade),
              ),
            ],
          ).paddingOnly(left: 22.h).paddingSymmetric(vertical: 25.h)),
          Align(
              alignment: Alignment.bottomRight,
              child: getAssetImage('scientist_img.png',
                  width: 258.h, boxFit: BoxFit.cover))
        ],
      ),
    );
  }

  Widget buildTopProfileView() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              getCustomFont('Welcome', 22.sp, Colors.black, 1,
                  fontWeight: FontWeight.w700),
              getVerSpace(3.h),
              getCustomFont('Ahmed Quader', 15.sp, Colors.black, 1,
                  fontWeight: FontWeight.w500),
            ],
          ),
        ),
        InkWell(
            onTap: () {
              Constant.sendToNext(context, Routes.searchScreenRoute);
            },
            child: getSvgImage('search.svg', height: 24.h, width: 24.h)),
        getHorSpace(20.h),
        InkWell(
          onTap: () {
            Constant.sendToNext(context, Routes.notificationScreenRoute);
          },
          child: getShadowDefaultContainer(
              height: 50.h,
              width: 50.h,
              color: Colors.white,
              child: Center(
                  child: getSvgImage('Notification.svg',
                      height: 24.h, width: 24.h))),
        ),
      ],
    ).paddingSymmetric(horizontal: 20.h);
  }
}

SizedBox buildNearbyLabView() {
  List<ModelNearbyLab> nearbyLabList = DataFile.nearbyLabList;

  return SizedBox(
    height: 232.h,
    width: double.infinity,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: nearbyLabList.length,
      itemBuilder: (context, index) {
        ModelNearbyLab lab = nearbyLabList[index];
        return Container(
          height: 198.h,
          width: 247.h,
          margin: EdgeInsets.only(
              left: (index == 0) ? 20.h : 9.h,
              right: (index == 2) ? 20.h : 9.h,
              bottom: 24.h,
              top: 10.h),
          child: GestureDetector(
            onTap: () {
              Constant.sendToNext(context, Routes.labDetailScreenRoute);
            },
            child: Stack(
              children: [
                getCircularImage(context, double.infinity, 150.h, 22.h, lab.img,
                    boxFit: BoxFit.cover),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: getShadowDefaultContainer(
                    height: 85.h,
                    width: double.infinity,
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        getCustomFont(lab.title, 18.sp, Colors.black, 1,
                            fontWeight: FontWeight.w700),
                        getVerSpace(5.h),
                        buildLocationRow(lab.location),
                      ],
                    ).marginAll(12.h),
                  ),
                )
              ],
            ),
          ),
        );
      },
    ),
  );
}

Widget buildViewAllView(BuildContext context, String title, Function function) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      getCustomFont(title, 20.sp, Colors.black, 1, fontWeight: FontWeight.w700),
      GestureDetector(
        onTap: () {
          function();
        },
        child: getCustomFont(
          "View All",
          15.sp,
          accentColor,
          1,
          fontWeight: FontWeight.w500,
        ),
      )
    ],
  ).paddingSymmetric(horizontal: 20.h);
}
