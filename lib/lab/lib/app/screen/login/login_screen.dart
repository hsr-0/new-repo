import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/lab/lib/app/controller/controller.dart';
import 'package:cosmetic_store/lab/lib/app/routes/app_routes.dart';
import 'package:cosmetic_store/lab/lib/base/color_data.dart';
import 'package:cosmetic_store/lab/lib/base/pref_data.dart';
import 'package:cosmetic_store/lab/lib/base/widget_utils.dart';

import '../../../base/constant.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  void backClick() {
    Constant.closeApp();
  }

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final formGlobalKey = GlobalKey<FormState>();
  LoginController controller = Get.put(LoginController());

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
            key: formGlobalKey,
            child: Column(
              children: [
                getVerSpace(10.h),
                loginAppBar(() {
                  backClick();
                }),
                getVerSpace(40.72.h),
                Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        loginHeader("Log In",
                            "Use your credentials and login to your account"),
                        getVerSpace(30.h),
                        buildTextFieldWidget(context),
                        getVerSpace(30.h),
                        buildLoginButton(context),
                        getVerSpace(31.h),
                        buildOtherLogin()
                      ],
                    )),
                buildSignUpButton(),
                getVerSpace(20.h)
              ],
            ).marginSymmetric(horizontal: 20.h),
          ),
        ),
      ),
    );
  }

  Widget buildSignUpButton() {
    return getRichText("If you are new / ", Colors.black, FontWeight.w500,
        17.sp, "Create New Account", accentColor, FontWeight.w700, 16.sp,
        txtHeight: 1.41.h, function: () {
      Constant.sendToNext(context, Routes.signUpRoute);
    });
  }

  Column buildOtherLogin() {
    return Column(
      children: [
        getCustomFont("Or Log in with", 15.sp, Colors.black, 1,
            fontWeight: FontWeight.w500, txtHeight: 1.4.h),
        getVerSpace(20.h),
        Row(
          children: [
            getImageButton("phone.svg"),
            getHorSpace(18.h),
            getImageButton("facebook.svg"),
            getHorSpace(18.h),
            getImageButton("google.svg")
          ],
        )
      ],
    );
  }

  Widget buildLoginButton(BuildContext context) {
    return getButton(context, accentColor, "Log In", Colors.white, () {
      PrefData.setIsSignIn(true);
      Constant.sendToNext(context, Routes.homeScreenRoute);
    }, 18.sp,
        weight: FontWeight.w700,
        buttonHeight: 60.h,
        borderRadius: BorderRadius.circular(22.h));
  }

  Column buildTextFieldWidget(BuildContext context) {
    return Column(
      children: [
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
        GetBuilder<LoginController>(
          init: LoginController(),
          builder: (controller) => getDefaultTextFiledWithLabel(
              context, "Enter your password", passwordController,
              isEnable: false,
              height: 60.h,
              validator: (password) {
                if (password!.isNotEmpty) {
                  return null;
                } else {
                  return 'Please enter password';
                }
              },
              withSufix: true,
              suffiximage: "show.svg",
              isPass: controller.show.value,
              imagefunction: () {
                controller.isShow();
              }),
        ),
        getVerSpace(20.h),
        Align(
          alignment: Alignment.topRight,
          child: GestureDetector(
            onTap: () {
              Constant.sendToNext(context, Routes.forgotRoute);
            },
            child: getCustomFont("Forgot Password?", 16.sp, accentColor, 1,
                fontWeight: FontWeight.w700, txtHeight: 1.5.h),
          ),
        ),
      ],
    );
  }
}
