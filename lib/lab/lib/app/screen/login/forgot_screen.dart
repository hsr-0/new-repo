import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/lab/lib/app/routes/app_routes.dart';

import '../../../base/color_data.dart';
import '../../../base/constant.dart';
import '../../../base/widget_utils.dart';

class ForgotScreen extends StatefulWidget {
  const ForgotScreen({Key? key}) : super(key: key);

  @override
  State<ForgotScreen> createState() => _ForgotScreenState();
}

class _ForgotScreenState extends State<ForgotScreen> {
  void backClick() {
    Constant.backToPrev(context);
  }

  TextEditingController emailController = TextEditingController();
  final forgotGlobalKey = GlobalKey<FormState>();

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
            key: forgotGlobalKey,
            child: buildTextFieldWidget(context),
          ),
        ),
      ),
    );
  }

  Widget buildTextFieldWidget(BuildContext context) {
    return Column(
      children: [
        getVerSpace(10.h),
        loginAppBar(() {
          backClick();
        }),
        getVerSpace(40.72.h),
        loginHeader("Forgot Password?",
            "Use your registration email for reset password!"),
        getVerSpace(30.h),
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
        getVerSpace(30.h),
        getButton(context, accentColor, "Submit", Colors.white, () {
          Constant.sendToNext(context, Routes.resetPasswordRoute);
        }, 18.sp,
            weight: FontWeight.w700,
            buttonHeight: 60.h,
            borderRadius: BorderRadius.circular(22.h))
      ],
    ).marginSymmetric(horizontal: 20.h);
  }
}
