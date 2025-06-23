import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/lab/lib/app/data/data_file.dart';
import 'package:cosmetic_store/lab/lib/app/models/model_payment_method.dart';
import 'package:cosmetic_store/lab/lib/app/screen/lists/tests/test_detail_screen.dart';
import 'package:cosmetic_store/lab/lib/base/widget_utils.dart';

import '../../../../base/color_data.dart';
import '../../../../base/constant.dart';
import '../../../routes/app_routes.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PaymentMethodScreenState();
  }
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  void backClick() {
    Constant.backToPrev(context);
  }

  List<ModelPaymentMethod> paymentMethodList = DataFile.paymentMethodList;
  RxInt selectedPos = 0.obs;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              getVerSpace(20.h),
              getBackAppBar(context, () {
                backClick();
              }, 'Payment Method'),
              getVerSpace(20.h),
              buildPaymentMethodList(),
              buildTotalAmountRow(),
              getVerSpace(35.h),
              buildPayNowButton(context),
              getVerSpace(30.h),
            ],
          ),
        ),
      ),
    );
  }

  Expanded buildPaymentMethodList() {
    return Expanded(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        getCustomFont('Select Payment Method', 18.sp, Colors.black, 1,
            fontWeight: FontWeight.w700),
        Expanded(
          flex: 1,
          child: ListView.builder(
            itemCount: paymentMethodList.length,
            itemBuilder: (context, index) {
              ModelPaymentMethod method = paymentMethodList[index];
              return ObxValue(
                  (p0) => GestureDetector(
                        onTap: () {
                          selectedPos.value = index;
                        },
                        child: Container(
                          height: 60.h,
                          margin: EdgeInsets.symmetric(vertical: 10.h),
                          padding: EdgeInsets.symmetric(horizontal: 20.h),
                          decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(22.h)),
                              border: Border.all(color: 'D8D7DD'.toColor())),
                          child: Row(
                            children: [
                              (selectedPos.value == index)
                                  ? getSvgImage('radio_checked.svg',
                                      height: 24.h, width: 24.h)
                                  : getSvgImage('radio_unchecked.svg',
                                      height: 24.h, width: 24.h),
                              getHorSpace(10.h),
                              getCustomFont(method.name, 17.sp, Colors.black, 1,
                                  fontWeight: FontWeight.w500)
                            ],
                          ),
                        ),
                      ),
                  selectedPos);
            },
          ),
        )
      ],
    ).marginSymmetric(horizontal: 20.h));
  }

  Widget buildPayNowButton(BuildContext context) {
    return getButton(
      context,
      accentColor,
      'Pay Now',
      Colors.white,
      () {
        Constant.sendToNext(context, Routes.paymentScreenRoute);
      },
      18.sp,
      weight: FontWeight.w700,
      buttonHeight: 60.h,
      borderRadius: BorderRadius.circular(22.h),
    ).marginSymmetric(horizontal: 20.h);
  }
}
