import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/lab/lib/app/routes/app_routes.dart';
import 'package:cosmetic_store/lab/lib/base/color_data.dart';
import 'package:cosmetic_store/lab/lib/base/widget_utils.dart';

import '../../../base/constant.dart';
import '../../controller/controller.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  void backClick() {
    Constant.sendToNext(context, Routes.loginRoute);
  }

  final signUpGlobalKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  RxBool agreeTerm = false.obs;

  ForgotController controller = Get.put(ForgotController());

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
            key: signUpGlobalKey,
            child: Column(
              children: [
                getVerSpace(10.h),
                loginAppBar(() {
                  backClick();
                }),
                getVerSpace(40.72.h),
                Expanded(
                    child: Column(
                  children: [
                    loginHeader("Sign Up",
                        "Use your details for Create a new account!"),
                    getVerSpace(30.h),
                    buildTextFieldWidget(context),
                    getVerSpace(40.h),
                    buildSignupButton(context),
                    // getVerSpace(42.h),
                  ],
                )),
                buildLoginButton(context),
                getVerSpace(20.h)
              ],
            ).marginSymmetric(horizontal: 20.h),
          ),
        ),
      ),
    );
  }

  Widget buildLoginButton(BuildContext context) {
    return getRichText("Already have an account / ", Colors.black,
        FontWeight.w500, 17.sp, "Login", accentColor, FontWeight.w700, 16.sp,
        txtHeight: 1.41.h, function: () {
      Constant.sendToNext(context, Routes.loginRoute);
    });
  }

  Widget buildSignupButton(BuildContext context) {
    return getButton(context, accentColor, "Sign Up", Colors.white, () {
      Constant.sendToNext(context, Routes.verificationRoute);
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
            context, "Enter phone number", phoneController,
            isEnable: false,
            height: 60.h,
            isprefix: true,
            prefix: GestureDetector(
              onTap: () {
                Get.toNamed(Routes.selectCountryRoute);
              },
              child: Row(
                children: [
                  getHorSpace(18.h),
                  getAssetImage(controller.image.value),
                  getHorSpace(10.h),
                  getCustomFont(controller.code.value, 15.sp, skipColor, 1,
                      fontWeight: FontWeight.w400),
                  getHorSpace(10.h),
                  getSvgImage("arrow_down.svg", width: 24.h, height: 24.h),
                ],
              ),
            ),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
            ],
            constraint: BoxConstraints(maxWidth: 120.h, maxHeight: 24.h),
            keyboardType: TextInputType.number),
        getVerSpace(20.h),
        GetBuilder<SignupController>(
          init: SignupController(),
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
        Row(
          children: [
            GetBuilder<SignupController>(
              builder: (controller) => Checkbox(
                visualDensity: VisualDensity.compact,
                side: BorderSide(color: checkBox, width: 1.h),
                activeColor: accentColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(6.h))),
                onChanged: (value) {
                  controller.isAgree();
                },
                value: controller.agreeTerm.value,
              ),
            ),
            // getHorSpace(10.h),
            getCustomFont(
                'I agree with Terms & Condition', 17.sp, Colors.black, 1,
                fontWeight: FontWeight.w500),
          ],
        ),
      ],
    );
  }
}
