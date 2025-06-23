import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cosmetic_store/lab/lib/base/widget_utils.dart';

import '../../../../base/constant.dart';

class LabLocationScreen extends StatefulWidget {
  const LabLocationScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _LabLocationScreenState();
  }
}

class _LabLocationScreenState extends State<LabLocationScreen> {
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
              }, 'Location'),
              getVerSpace(20.h),
              Expanded(
                  child: Container(
                height: double.infinity,
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 20.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(22.h)),
                  image: DecorationImage(
                    image: AssetImage(
                        '${Constant.assetImagePath}location_img.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    buildNavigatorBtn(),
                    buildBottomContainerView(context)
                  ],
                ),
              )),
              getVerSpace(20.h),
            ],
          ),
        ),
      ),
    );
  }

  Align buildNavigatorBtn() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        height: 50.h,
        width: 50.h,
        margin: EdgeInsets.only(right: 20.h),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Center(
            child: getSvgImage('situation.svg', height: 24.h, width: 24.h)),
      ),
    );
  }

  Widget buildBottomContainerView(BuildContext context) {
    return getShadowDefaultContainer(
        height: 101.h,
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 20.h, vertical: 20.h),
        padding: EdgeInsets.symmetric(vertical: 6.h),
        color: Colors.white,
        child: Row(
          children: [
            getHorSpace(6.h),
            getCircularImage(context, 89.h, 89.h, 22.h, 'lab1.png',
                boxFit: BoxFit.cover),
            getHorSpace(10.h),
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
        ));
  }
}
