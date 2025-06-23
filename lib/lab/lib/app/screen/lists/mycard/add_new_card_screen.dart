import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/lab/lib/base/widget_utils.dart';

import '../../../../base/color_data.dart';
import '../../../../base/constant.dart';

class AddNewCardScreen extends StatefulWidget {
  const AddNewCardScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AddNewCardScreenState();
  }
}

class _AddNewCardScreenState extends State<AddNewCardScreen> {
  void backClick() {
    Constant.backToPrev(context);
  }

  TextEditingController nameController = TextEditingController();
  TextEditingController cardNumController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController cvvController = TextEditingController();

  RxBool saveCard = false.obs;

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
              }, 'Add New Card'),
              getVerSpace(20.h),
              Expanded(
                  child: Column(
                children: [
                  buildTextField(context),
                  buildAddButton(context),
                  getVerSpace(30.h),
                ],
              ))
            ],
          ),
        ),
      ),
    );
  }

  Expanded buildTextField(BuildContext context) {
    return Expanded(
        child: ListView(
      // crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        getDefaultTextFiledWithLabel(
            context, 'Enter card holder name', nameController,
            height: 60.h),
        getVerSpace(20.h),
        getDefaultTextFiledWithLabel(
            context, 'Enter card number', cardNumController,
            height: 60.h),
        getVerSpace(20.h),
        Row(
          children: [
            Expanded(
                flex: 1,
                child: getDefaultTextFiledWithLabel(
                    context, 'MM/YY', dateController,
                    height: 60.h)),
            getHorSpace(20.h),
            Expanded(
                flex: 1,
                child: getDefaultTextFiledWithLabel(
                    context, 'CVV', cvvController,
                    height: 60.h)),
          ],
        ),
        getVerSpace(20.h),
        buildCheckBoxRow(),
      ],
    ).marginSymmetric(horizontal: 20.h));
  }

  Row buildCheckBoxRow() {
    return Row(
      children: [
        ObxValue(
            (p0) => Checkbox(
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: checkBox, width: 1.h),
                  activeColor: accentColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(6.h))),
                  onChanged: (value) {
                    saveCard.value = (saveCard.value) ? false : true;
                  },
                  value: saveCard.value,
                ),
            saveCard),
        getCustomFont('Save Card', 17.sp, Colors.black, 1,
            fontWeight: FontWeight.w500),
      ],
    );
  }

  Widget buildAddButton(BuildContext context) {
    return getButton(
      context,
      accentColor,
      'Add',
      Colors.white,
      () {
        backClick();
        // Constant.sendToNext(context, Routes.myCardScreenRoute);
      },
      18.sp,
      borderRadius: BorderRadius.all(Radius.circular(22.h)),
      buttonHeight: 60.h,
    ).marginSymmetric(horizontal: 20.h);
  }
}
