import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/lab/lib/app/screen/lists/profile/edit_profile_screen.dart';
import 'package:cosmetic_store/lab/lib/base/color_data.dart';
import 'package:cosmetic_store/lab/lib/base/widget_utils.dart';

import '../../../../base/constant.dart';

class EditReminderScreen extends StatefulWidget {
  const EditReminderScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _EditReminderScreenState();
  }
}

class _EditReminderScreenState extends State<EditReminderScreen> {
  void backClick() {
    Constant.backToPrev(context);
  }

  TextEditingController titleController =
      TextEditingController(text: 'Lab Report Acchive');
  TextEditingController dateController =
      TextEditingController(text: 'Thu 25/07/2022');
  TextEditingController timeController =
      TextEditingController(text: '10:30 pm');

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
            }, 'Edit Reminder'),
            getVerSpace(20.h),
            buildTextField(context),
            buildSaveButton(context),
            getVerSpace(30.h),
          ],
        )),
      ),
    );
  }

  Expanded buildTextField(BuildContext context) {
    return Expanded(
      child: ListView(
        // crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          getCustomFont('Reminder me to', 17.sp, Colors.black, 1,
              fontWeight: FontWeight.w500),
          getVerSpace(10.h),
          getDefaultTextFiledWithLabel(
            context,
            '',
            titleController,
            height: 60.h,
          ),
          getVerSpace(20.h),
          getDefaultTextFiledWithLabel(context, '', dateController,
              height: 60.h,
              withSufix: true,
              suffiximage: 'calender.svg', onTap: () {
            getCalenderBottomSheet(context, 'Set Date', 'set',
                withCancelBtn: true);
          }, keyboardType: TextInputType.none),
          getVerSpace(20.h),
          getDefaultTextFiledWithLabel(context, '', timeController,
              height: 60.h,
              withSufix: true,
              suffiximage: 'time.svg', onTap: () {
            getTimeBottomSheet(context);
          }, keyboardType: TextInputType.none),
        ],
      ).marginSymmetric(horizontal: 20.h),
    );
  }

  Widget buildSaveButton(BuildContext context) {
    return getButton(
      context,
      accentColor,
      'Save',
      Colors.white,
      () {
        backClick();
      },
      18.sp,
      weight: FontWeight.w700,
      buttonHeight: 60.h,
      borderRadius: BorderRadius.all(Radius.circular(22.h)),
    ).marginSymmetric(horizontal: 20.h);
  }

  getTimeBottomSheet(BuildContext context) {
    return Get.bottomSheet(
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40.h),
                topRight: Radius.circular(40.h))),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            getSvgImage('line1.svg').marginOnly(top: 10.h),
            getVerSpace(10.h),
            Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                    onTap: () {
                      Constant.backToPrev(context);
                    },
                    child: getSvgImage('close.svg', height: 24.h, width: 24.h)
                        .paddingSymmetric(horizontal: 20.h))),
            getCustomFont('Set Time', 20.sp, Colors.black, 1,
                fontWeight: FontWeight.w700, textAlign: TextAlign.center),
            getVerSpace(20.h),
            TimePickerSpinner(
              is24HourMode: false,
              normalTextStyle: buildTextStyle(
                context,
                greyFontColor,
                FontWeight.w500,
                17.sp,
              ),
              highlightedTextStyle: buildTextStyle(
                context,
                Colors.black,
                FontWeight.w700,
                18.sp,
              ),
              spacing: 40.h,
              itemHeight: 65.h,
              alignment: Alignment.center,
              isForce2Digits: true,
              onTimeChange: (time) {
                setState(() {
                  // _dateTime = time;
                });
              },
            ),
            getVerSpace(20.h),
            Row(
              children: [
                Expanded(
                    flex: 1,
                    child: getButton(
                        context, Colors.transparent, 'Cancel', accentColor, () {
                      Constant.backToPrev(context);
                    }, 18.sp,
                        borderRadius: BorderRadius.all(Radius.circular(22.h)),
                        weight: FontWeight.w700,
                        buttonHeight: 60.h,
                        isBorder: true,
                        borderWidth: 2.h,
                        borderColor: accentColor)),
                getHorSpace(20.h),
                Expanded(
                  flex: 1,
                  child: getButton(
                    context,
                    accentColor,
                    'Set',
                    Colors.white,
                    () {
                      Constant.backToPrev(context);
                    },
                    18.sp,
                    weight: FontWeight.w700,
                    borderRadius: BorderRadius.all(Radius.circular(22.h)),
                    buttonHeight: 60.h,
                  ),
                ),
              ],
            ).marginSymmetric(horizontal: 20.h).marginOnly(bottom: 30.h),
          ],
        ));
  }
}
