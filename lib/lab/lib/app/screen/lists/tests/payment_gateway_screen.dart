import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/lab/lib/app/dialog/booking_done_dialog.dart';
import 'package:cosmetic_store/lab/lib/app/screen/lists/tests/test_detail_screen.dart';
import 'package:cosmetic_store/lab/lib/base/widget_utils.dart';

import '../../../../base/color_data.dart';
import '../../../../base/constant.dart';

class PaymentGatewayScreen extends StatefulWidget {
  const PaymentGatewayScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PaymentGatewayScreenState();
  }
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
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
                }, 'Payment Gateway'),
                getVerSpace(20.h),
                buildCardDetailContainer(),
                buildTotalAmountRow(),
                getVerSpace(35.h),
                buildPayNowButton(context),
                getVerSpace(30.h),
              ],
            ),
          ),
        ));
  }

  Expanded buildCardDetailContainer() {
    return Expanded(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        getShadowDefaultContainer(
            color: Colors.white,
            margin: EdgeInsets.symmetric(horizontal: 20.h),
            padding: EdgeInsets.all(20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                getCustomFont(
                    'Your Secured Payment Detail', 18.sp, Colors.black, 1,
                    fontWeight: FontWeight.w700),
                getVerSpace(29.h),
                buildInfoRow('Name :', 'Merry Fernandez'),
                getDivider().marginSymmetric(vertical: 16.h),
                buildInfoRow('Mobile No :', '+91 8925559623'),
                getDivider().marginSymmetric(vertical: 16.h),
                buildInfoRow('Amount :', '\$209'),
                getDivider().marginSymmetric(vertical: 16.h),
                buildInfoRow('Transaction ID :', 'PREPAYmtXEU'),
                getDivider().marginSymmetric(vertical: 16.h),
                buildInfoRow('Payment To :', 'MI Labs'),
                getDivider().marginSymmetric(vertical: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    getCustomFont('Card:', 17.sp, greyFontColor, 1,
                        fontWeight: FontWeight.w500),
                    Column(
                      children: [
                        Row(
                          children: [
                            getSvgImage('mastercard.svg',
                                height: 34.h, width: 34.h),
                            getHorSpace(8.h),
                            getCustomFont('Master Card', 17.sp, Colors.black, 1,
                                fontWeight: FontWeight.w500),
                          ],
                        ),
                        getCustomFont(
                            'XXXX XXXX XXXX 2563', 15.sp, greyFontColor, 1,
                            fontWeight: FontWeight.w500),
                      ],
                    )
                  ],
                ),
              ],
            )),
        getVerSpace(20.h),
        getMultilineCustomFont(
                'Your payment will be processed securely via paytm gateway',
                15.sp,
                greyFontColor,
                fontWeight: FontWeight.w500)
            .paddingSymmetric(horizontal: 20.h)
      ],
    ));
  }

  Row buildInfoRow(String title, String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        getCustomFont(title, 17.sp, greyFontColor, 1,
            fontWeight: FontWeight.w500),
        getCustomFont(name, 17.sp, Colors.black, 1,
            fontWeight: FontWeight.w500),
      ],
    );
  }

  Widget buildPayNowButton(BuildContext context) {
    return getButton(
      context,
      accentColor,
      'Pay Now',
      Colors.white,
      () {
        showDialog(
            builder: (context) {
              return const BookingDoneDialog();
            },
            context: context);
      },
      18.sp,
      weight: FontWeight.w700,
      buttonHeight: 60.h,
      borderRadius: BorderRadius.circular(22.h),
    ).marginSymmetric(horizontal: 20.h);
  }
}
