import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/lab/lib/app/routes/app_routes.dart';
import 'package:cosmetic_store/lab/lib/base/widget_utils.dart';

import '../../../../base/color_data.dart';
import '../../../../base/constant.dart';
import '../../../data/data_file.dart';
import '../../../models/model_payment_type.dart';

class MyCardScreen extends StatefulWidget {
  const MyCardScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MyCardScreenState();
  }
}

class _MyCardScreenState extends State<MyCardScreen> {
  void backClick() {
    Constant.backToPrev(context);
  }

  List<ModelPaymentCard> paymentCardList = DataFile.paymentCardList;

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
            }, 'My Cards'),
            getVerSpace(20.h),
            Expanded(
              flex: 1,
              child: (paymentCardList.isEmpty)
                  ? buildNoCardDataWidget(context)
                  : buildCardList(context),
            )
          ],
        )),
      ),
    );
  }

  Widget buildCardList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        getCustomFont('Your Cards', 17.sp, Colors.black, 1,
            fontWeight: FontWeight.w500),
        getVerSpace(4.h),
        buildCardListWidget(context),
        buildAddNewCardButton(context),
        getVerSpace(30.h),
      ],
    ).marginSymmetric(horizontal: 20.h);
  }

  Column buildNoCardDataWidget(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        getNoDataWidget(context, 'No Cards Yet!',
            'Come on, maybe we still have a \nchance', 'no_card_icon.svg',
            withButton: true, btnText: 'Add New Card', btnClick: () {
          Constant.sendToNext(context, Routes.addNewCardScreenRoute);
        }),
        getVerSpace(100.h),
      ],
    );
  }

  Widget buildAddNewCardButton(BuildContext context) {
    return getButton(
      context,
      accentColor,
      'Add New Card',
      Colors.white,
      () {
        Constant.sendToNext(context, Routes.addNewCardScreenRoute);
      },
      18.sp,
      borderRadius: BorderRadius.all(Radius.circular(22.h)),
      buttonHeight: 60.h,
    );
  }

  Widget buildCardListWidget(BuildContext context) {
    return Expanded(
      flex: 1,
      child: ListView(
        children: [
          ListView.builder(
            shrinkWrap: true,
            itemCount: paymentCardList.length,
            itemBuilder: (context, index) {
              ModelPaymentCard type = paymentCardList[index];
              return getShadowDefaultContainer(
                  color: Colors.white,
                  margin: EdgeInsets.symmetric(vertical: 10.h),
                  padding:
                      EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.h),
                  child: Row(
                    children: [
                      getSvgImage(type.img, height: 46.h, width: 46.h),
                      getHorSpace(10.h),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          getCustomFont(type.name, 16.sp, Colors.black, 1,
                              fontWeight: FontWeight.w700),
                          getVerSpace(3.h),
                          getCustomFont(type.num, 15.sp, Colors.black, 1,
                              fontWeight: FontWeight.w500)
                        ],
                      )),
                      buildPopupMenuButton(
                        (value) {
                          handleClick(value);
                        },
                      ),
                    ],
                  ));
            },
          ),
        ],
      ),
    );
  }

  void handleClick(String value) {
    switch (value) {
      case 'Edit':
        Constant.sendToNext(context, Routes.editCardScreenRoute);
        break;
      case 'Delete':
        break;
    }
  }
}
