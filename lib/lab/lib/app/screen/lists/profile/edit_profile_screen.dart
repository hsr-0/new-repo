import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/lab/lib/base/widget_utils.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../../../../base/color_data.dart';
import '../../../../base/constant.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _EditProfileScreenState();
  }
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  void backClick() {
    Constant.backToPrev(context);
  }

  TextEditingController nameController =
      TextEditingController(text: 'Merry Fernandez');
  TextEditingController emailController =
      TextEditingController(text: 'merryfernandez@gmail.com');
  TextEditingController phoneController =
      TextEditingController(text: '+91 6963565985');
  TextEditingController birthController =
      TextEditingController(text: '23 Jan, 1995');

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
                }, 'Edit Profile'),
                getVerSpace(20.h),
                Expanded(
                  child: ListView(
                    children: [
                      Row(
                        children: [
                          getProfileCell(context),
                          Expanded(child: getHorSpace(0.h)),
                        ],
                      ),
                      getVerSpace(30.h),
                      buildTextFieldWidget(context),
                    ],
                  ),
                ),
                buildSaveButton(context),
                getVerSpace(30.h),
              ],
            ),
          ),
        ));
  }

  Widget buildSaveButton(BuildContext context) {
    return getButton(
      context,
      accentColor,
      'Save',
      Colors.white,
      () {
        backClick();
        // Constant.sendToNext(context, Routes.editProfileScreenRoute);
      },
      18.sp,
      borderRadius: BorderRadius.all(Radius.circular(22.h)),
      buttonHeight: 60.h,
    ).marginSymmetric(horizontal: 20.h);
  }

  Widget buildTextFieldWidget(BuildContext context) {
    return Column(
      children: [
        getDefaultTextFiledWithLabel(
          context,
          "Enter full name",
          nameController,
          isEnable: false,
          height: 60.h,
          validator: (email) {
            if (email!.isNotEmpty) {
              return null;
            } else {
              return 'Please enter full name';
            }
          },
        ),
        getVerSpace(20.h),
        getDefaultTextFiledWithLabel(
          context,
          "Enter your email",
          emailController,
          isEnable: false,
          height: 60.h,
          validator: (email) {
            if (email!.isNotEmpty) {
              return null;
            } else {
              return 'Please enter email address';
            }
          },
        ),
        getVerSpace(20.h),
        getDefaultTextFiledWithLabel(
          context,
          "Enter phone number",
          phoneController,
          isEnable: false,
          height: 60.h,
          validator: (email) {
            if (email!.isNotEmpty) {
              return null;
            } else {
              return 'Please enter phone number';
            }
          },
        ),
        getVerSpace(20.h),
        getDefaultTextFiledWithLabel(
          context,
          "Date of Birth",
          birthController,
          isEnable: false,
          height: 60.h,
          withSufix: true,
          suffiximage: 'calender.svg',
          keyboardType: TextInputType.none,
          onTap: () {
            getCalenderBottomSheet(context, 'Select Date', 'Save');
          },
          validator: (email) {
            if (email!.isNotEmpty) {
              return null;
            } else {
              return 'Please enter Date of Birth';
            }
          },
        ),
      ],
    ).marginSymmetric(horizontal: 20.h);
  }

  getProfileCell(BuildContext context) {
    return SizedBox(
      width: 100.h,
      height: 97.h,
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.topLeft,
              child: getCircularImage(
                  context, 92.h, 92.h, 22.h, 'user_profile.png',
                  boxFit: BoxFit.cover),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomRight,
              child: InkWell(
                onTap: () {
                  // imageController.getImage();
                },
                child: Container(
                  width: 36.h,
                  height: 36.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x289a90b8),
                        blurRadius: 32.h,
                        offset: const Offset(0, 9),
                      ),
                    ],
                    color: Colors.white,
                  ),
                  child: Center(
                    child: getSvgImage('edit.svg', height: 24.h, width: 24.h),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).marginSymmetric(horizontal: 20.h);
  }
}

getCalenderBottomSheet(
  BuildContext context,
  String title,
  String btnText, {
  bool withCancelBtn = false,
}) {
  return Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(40.h), topRight: Radius.circular(40.h))),
      Wrap(
        alignment: WrapAlignment.center,
        children: [
          getSvgImage('line1.svg').marginSymmetric(vertical: 10.h),
          Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                  onTap: () {
                    Constant.backToPrev(context);
                  },
                  child: getSvgImage('close.svg', height: 24.h, width: 24.h)
                      .paddingSymmetric(horizontal: 20.h))),
          getCustomFont(title, 20.sp, Colors.black, 1,
              fontWeight: FontWeight.w700, textAlign: TextAlign.center),
          getShadowDefaultContainer(
              height: 363.h,
              color: Colors.white,
              margin: EdgeInsets.all(20.h),
              padding: EdgeInsets.symmetric(horizontal: 10.h),
              child: SfDateRangePicker(
                allowViewNavigation: true,
                showNavigationArrow: true,
                selectionColor: accentColor,
                selectionMode: DateRangePickerSelectionMode.single,
                navigationDirection:
                    DateRangePickerNavigationDirection.horizontal,
                todayHighlightColor: accentColor,
                toggleDaySelection: true,
                monthViewSettings: const DateRangePickerMonthViewSettings(
                  dayFormat: 'E',
                ),
                headerStyle: DateRangePickerHeaderStyle(
                    textStyle: buildTextStyle(
                        context, Colors.black, FontWeight.w700, 16.sp)),
                monthCellStyle: DateRangePickerMonthCellStyle(
                    textStyle: buildTextStyle(
                        context, Colors.black, FontWeight.w500, 15.sp),
                    todayTextStyle: buildTextStyle(
                      context,
                      accentColor,
                      FontWeight.w700,
                      14.sp,
                    )),
              )),
          getVerSpace(20.h),
          Row(
            children: [
              (withCancelBtn)
                  ? Expanded(
                      flex: 1,
                      child: getButton(
                          context, Colors.transparent, 'Cancel', accentColor,
                          () {
                        Constant.backToPrev(context);
                      }, 18.sp,
                          borderRadius: BorderRadius.all(Radius.circular(22.h)),
                          weight: FontWeight.w700,
                          buttonHeight: 60.h,
                          isBorder: true,
                          borderWidth: 2.h,
                          borderColor: accentColor))
                  : getHorSpace(0.h),
              (withCancelBtn) ? getHorSpace(20.h) : getHorSpace(0.h),
              Expanded(
                flex: 1,
                child: getButton(
                  context,
                  accentColor,
                  btnText,
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
