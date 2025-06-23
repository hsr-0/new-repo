import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/lab/lib/app/controller/controller.dart';
import 'package:cosmetic_store/lab/lib/app/dialog/password_change_dialog.dart';

import '../../../base/color_data.dart';
import '../../../base/constant.dart';
import '../../../base/widget_utils.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  void backClick() {
    Constant.backToPrev(context);
  }

  TextEditingController oldPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPassController = TextEditingController();
  final resetGlobalKey = GlobalKey<FormState>();
  ResetController controller = Get.put(ResetController());

  @override
  Widget build(BuildContext context) {
    initializeScreenSize(context);
    return WillPopScope(
      onWillPop: () async {
        backClick();
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Form(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            key: resetGlobalKey,
            child: Column(
              children: [
                getVerSpace(10.h),
                loginAppBar(() {
                  backClick();
                }),
                getVerSpace(40.72.h),
                loginHeader("Reset Password",
                    "Enter your new password for reset password!"),
                getVerSpace(30.h),
                buildTextFieldWidget(context),
                getVerSpace(30.h),
                buildSubmitButton(context)
              ],
            ).marginSymmetric(horizontal: 20.h),
          ),
        ),
      ),
    );
  }

  Widget buildSubmitButton(BuildContext context) {
    return getButton(context, accentColor, "Submit", Colors.white, () {
      showDialog(
          builder: (context) {
            return const PasswordChangeDialog();
          },
          context: context);
    }, 18.sp,
        weight: FontWeight.w700,
        buttonHeight: 60.h,
        borderRadius: BorderRadius.circular(22.h));
  }

  Column buildTextFieldWidget(BuildContext context) {
    return Column(
      children: [
        GetBuilder<ResetController>(
          init: ResetController(),
          builder: (controller) => getDefaultTextFiledWithLabel(
              context, "Old password", oldPasswordController,
              isEnable: false,
              height: 60.h,
              validator: (email) {
                if (email!.isNotEmpty) {
                  return null;
                } else {
                  return 'Please enter old passsword';
                }
              },
              withSufix: true,
              suffiximage: "show.svg",
              isPass: controller.isOld.value,
              imagefunction: () {
                controller.isChangeOld();
              }),
        ),
        getVerSpace(20.h),
        GetBuilder<ResetController>(
          init: ResetController(),
          builder: (controller) => getDefaultTextFiledWithLabel(
              context, "New password", newPasswordController,
              isEnable: false,
              height: 60.h,
              validator: (email) {
                if (email!.isNotEmpty) {
                  return null;
                } else {
                  return 'Please enter new password';
                }
              },
              withSufix: true,
              suffiximage: "show.svg",
              isPass: controller.isNew.value,
              imagefunction: () {
                controller.isChangeNew();
              }),
        ),
        getVerSpace(20.h),
        GetBuilder<ResetController>(
          init: ResetController(),
          builder: (controller) => getDefaultTextFiledWithLabel(
              context, "Confirm password", confirmPassController,
              isEnable: false,
              height: 60.h,
              validator: (email) {
                if (email!.isNotEmpty) {
                  return null;
                } else {
                  return 'Please enter confirm password';
                }
              },
              withSufix: true,
              suffiximage: "show.svg",
              isPass: controller.isConf.value,
              imagefunction: () {
                controller.isChangeConf();
              }),
        ),
      ],
    );
  }
}
