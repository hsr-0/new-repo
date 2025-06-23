import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/lab/lib/app/data/data_file.dart';
import 'package:cosmetic_store/lab/lib/app/models/model_payment_type.dart';
import 'package:cosmetic_store/lab/lib/base/widget_utils.dart';

import '../../../../base/color_data.dart';
import '../../../../base/constant.dart';
import '../../../routes/app_routes.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PaymentScreenState();
  }
}

class _PaymentScreenState extends State<PaymentScreen> {
  void backClick() {
    Constant.backToPrev(context);
  }

  List<ModelPaymentCard> paymentTypeList = DataFile.paymentCardList;
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
              }, 'Payment'),
              getVerSpace(20.h),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  getCustomFont('Select Card', 18.sp, Colors.black, 1,
                      fontWeight: FontWeight.w700),
                  getVerSpace(6.h),
                  buildCardListWidget(context),
                ],
              ).marginSymmetric(horizontal: 20.h)),
              getVerSpace(35.h),
              buildContinueButton(context),
              getVerSpace(30.h),
            ],
          ),
        ),
      ),
    );
  }

  Expanded buildCardListWidget(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Column(
        children: [
          ListView.builder(
            shrinkWrap: true,
            itemCount: paymentTypeList.length,
            itemBuilder: (context, index) {
              ModelPaymentCard type = paymentTypeList[index];
              return ObxValue(
                  (p0) => InkWell(
                        onTap: () {
                          selectedPos.value = index;
                        },
                        child: getShadowDefaultContainer(
                            color: Colors.white,
                            margin: EdgeInsets.symmetric(vertical: 10.h),
                            padding: EdgeInsets.symmetric(
                                vertical: 20.h, horizontal: 20.h),
                            child: Row(
                              children: [
                                getSvgImage(type.img,
                                    height: 46.h, width: 46.h),
                                getHorSpace(10.h),
                                Expanded(
                                    child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    getCustomFont(
                                        type.name, 16.sp, Colors.black, 1,
                                        fontWeight: FontWeight.w700),
                                    getVerSpace(3.h),
                                    getCustomFont(
                                        type.num, 15.sp, Colors.black, 1,
                                        fontWeight: FontWeight.w500)
                                  ],
                                )),
                                (selectedPos.value == index)
                                    ? getSvgImage('radio_checked.svg',
                                        height: 24.h, width: 24.h)
                                    : getSvgImage('radio_unchecked.svg',
                                        height: 24.h, width: 24.h),
                              ],
                            )),
                      ),
                  selectedPos);
            },
          ),
          getVerSpace(20.h),
          buildAddCardButton(context)
        ],
      ),
    );
  }

  Widget buildAddCardButton(BuildContext context) {
    return getButton(context, Colors.transparent, 'Add New Card', accentColor,
        () {
      Constant.sendToNext(context, Routes.addNewCardScreenRoute);
    }, 18.sp,
        weight: FontWeight.w700,
        buttonHeight: 60.h,
        buttonWidth: 184.h,
        borderRadius: BorderRadius.all(Radius.circular(22.h)),
        isBorder: true,
        borderColor: accentColor,
        borderWidth: 2.h);
  }

  Widget buildContinueButton(BuildContext context) {
    return getButton(
      context,
      accentColor,
      'Continue',
      Colors.white,
      () {
        Constant.sendToNext(context, Routes.paymentGatewayScreenRoute);
      },
      18.sp,
      weight: FontWeight.w700,
      buttonHeight: 60.h,
      borderRadius: BorderRadius.circular(22.h),
    ).marginSymmetric(horizontal: 20.h);
  }
}
