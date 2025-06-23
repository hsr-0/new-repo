import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/lab/lib/app/routes/app_routes.dart';
import 'package:cosmetic_store/lab/lib/base/color_data.dart';

import '../../../../base/constant.dart';
import '../../../../base/widget_utils.dart';

class TestDetailScreen extends StatefulWidget {
  const TestDetailScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _TestDetailScreenState();
  }
}

class _TestDetailScreenState extends State<TestDetailScreen> {
  void backClick() {
    Constant.backToPrev(context);
  }

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
              }, 'Test Detail', withAction: true, actionIcon: 'add.svg'),
              getVerSpace(20.h),
              buildTopContainer(),
              buildTotalAmountRow(),
              getVerSpace(35.h),
              buildProceedButton(context),
              getVerSpace(30.h),
            ],
          ),
        ),
      ),
    );
  }

  Expanded buildTopContainer() {
    return Expanded(
      flex: 1,
      child: Column(
        children: [
          getShadowDefaultContainer(
              // height: 404.h,
              color: Colors.white,
              margin: EdgeInsets.symmetric(horizontal: 20.h),
              padding: EdgeInsets.all(20.h),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      getCustomFont('02 August, 2022', 17.sp, Colors.black, 1,
                          fontWeight: FontWeight.w500),
                      getSvgImage('menu.svg', height: 24.h, width: 24.h),
                    ],
                  ),
                  getVerSpace(14.h),
                  Row(
                    children: [
                      Container(
                        height: 102.h,
                        width: 102.h,
                        decoration: BoxDecoration(
                          color: 'FDE9E9'.toColor(),
                          borderRadius: BorderRadius.circular(22.h),
                        ),
                        child: Center(
                            child: getAssetImage('test3.png',
                                height: 50.h, width: 50.h)),
                      ),
                      getHorSpace(16.h),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            getCustomFont('Thyroid', 22.sp, Colors.black, 1,
                                fontWeight: FontWeight.w700),
                            getVerSpace(6.h),
                            getCustomFont('Lab Test', 15.sp, greyFontColor, 1,
                                fontWeight: FontWeight.w500),
                          ],
                        ),
                      ),
                      getCustomFont('\$205.00', 17.sp, Colors.black, 1,
                          fontWeight: FontWeight.w500)
                    ],
                  ),
                  getVerSpace(20.h),
                  getDivider(),
                  getVerSpace(20.h),
                  buildTaxRow('Tax', '\$1.50'),
                  getVerSpace(20.h),
                  buildTaxRow('GST', '\$2.50'),
                  getVerSpace(20.h),
                  buildTaxRow('Sub Total', '\$209'),
                  getVerSpace(20.h),
                  getDivider(),
                  getVerSpace(20.h),
                  getTotalRow()
                ],
              )),
        ],
      ),
    );
  }

  Row getTotalRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        getCustomFont('Grand Total', 18.sp, Colors.black, 1,
            fontWeight: FontWeight.w600),
        getCustomFont('\$209', 20.sp, Colors.black, 1,
            fontWeight: FontWeight.w700)
      ],
    );
  }

  Widget buildProceedButton(BuildContext context) {
    return getButton(
      context,
      accentColor,
      'Proceed',
      Colors.white,
      () {
        Constant.sendToNext(context, Routes.reviewTestScreenRoute);
      },
      18.sp,
      weight: FontWeight.w700,
      buttonHeight: 60.h,
      borderRadius: BorderRadius.circular(22.h),
    ).marginSymmetric(horizontal: 20.h);
  }

  Row buildTaxRow(
    String title,
    String rate,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        getCustomFont(title, 17.sp, Colors.black, 1,
            fontWeight: FontWeight.w500),
        getCustomFont(rate, 17.sp, Colors.black, 1, fontWeight: FontWeight.w500)
      ],
    );
  }
}

Widget buildTotalAmountRow() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      getCustomFont('Total Amount Payable', 18.sp, Colors.black, 1,
          fontWeight: FontWeight.w600),
      getCustomFont('\$209', 28.sp, accentColor, 1, fontWeight: FontWeight.w700)
    ],
  ).marginSymmetric(horizontal: 20.h);
}
