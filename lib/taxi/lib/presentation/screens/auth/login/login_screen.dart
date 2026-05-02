import 'package:cosmetic_store/taxi/lib/core/utils/my_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/taxi/lib/core/route/route.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/dimensions.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_color.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_strings.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/style.dart';
import 'package:cosmetic_store/taxi/lib/data/controller/auth/login_controller.dart';
import 'package:cosmetic_store/taxi/lib/data/controller/auth/social_auth_controller.dart';
import 'package:cosmetic_store/taxi/lib/data/repo/auth/login_repo.dart';
import 'package:cosmetic_store/taxi/lib/data/repo/auth/social_auth_repo.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/annotated_region/annotated_region_widget.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/buttons/rounded_button.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/image/custom_svg_picture.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/text-form-field/custom_text_field.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/text/default_text.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/will_pop_widget.dart';
import 'package:cosmetic_store/taxi/lib/presentation/screens/auth/auth_background.dart';
import 'package:cosmetic_store/taxi/lib/presentation/screens/auth/social_auth/social_auth_section.dart';

import '../../../../core/utils/my_images.dart';
import '../../../components/divider/custom_spacer.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    Get.put(LoginRepo(apiClient: Get.find()));
    Get.put(LoginController(loginRepo: Get.find()));
    Get.put(SocialAuthRepo(apiClient: Get.find()));
    Get.put(SocialAuthController(authRepo: Get.find()));

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<LoginController>().remember = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopWidget(
      nextRoute: '',
      child: AnnotatedRegionWidget(
        statusBarColor: Colors.transparent,
        child: Scaffold(
          backgroundColor: MyColor.colorWhite,
          body: GetBuilder<LoginController>(
            builder: (controller) => SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AuthBackgroundWidget(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimensions.space20,
                        vertical: Dimensions.space10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          spaceDown(Dimensions.space15),
                          Image.asset(
                            MyImages.appLogoWhite,
                            color: MyColor.colorWhite,
                            width: MediaQuery.of(context).size.width / 2.5,
                          ),
                          spaceDown(Dimensions.space15),
                          Text(
                            MyStrings.loginScreenTitle.tr,
                            style: boldExtraLarge.copyWith(
                              fontSize: 32,
                              color: MyColor.colorWhite,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          spaceDown(Dimensions.space5),
                          Text(
                            MyStrings.loginScreenSubTitle.tr,
                            style: regularDefault.copyWith(
                              color: MyColor.colorWhite,
                              fontSize: Dimensions.fontLarge,
                            ),
                          ),
                          spaceDown(Dimensions.space40),
                        ],
                      ),
                    ),
                  ),

                  // Foreground content
                  Transform.translate(
                    offset: Offset(0, -Dimensions.space20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: MyColor.colorWhite,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(Dimensions.radius25),
                          topRight: Radius.circular(Dimensions.radius25),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: MyColor.colorBlack.withValues(alpha: 0.05),
                            offset: const Offset(0, -30),
                            blurRadius: 15,
                            spreadRadius: -3,
                          ),
                        ],
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimensions.space15,
                        vertical: Dimensions.space15,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          spaceDown(Dimensions.space15),

                          // ✅ 1. قسم أزرار التواصل الاجتماعي (جوجل، أبل، فيسبوك)
                          const SocialAuthSection(),

                          /*
                          // ❌ تم إخفاء زر فيسبوك حالياً
                          spaceDown(Dimensions.space15),
                          GetBuilder<SocialAuthController>(
                            builder: (socialController) => SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: socialController.isFacebookSignInLoading
                                  ? Center(
                                child: CircularProgressIndicator(
                                  color: MyColor.primaryColor,
                                  strokeWidth: 3,
                                ),
                              )
                                  : InkWell(
                                onTap: () {
                                  socialController.signInWithFacebook();
                                },
                                borderRadius: BorderRadius.circular(Dimensions.radius25),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1877F2), // لون فيسبوك الرسمي
                                    borderRadius: BorderRadius.circular(Dimensions.radius25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF1877F2).withValues(alpha: 0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // أيقونة فيسبوك
                                      Container(
                                        padding: EdgeInsets.all(Dimensions.space8),
                                        decoration: BoxDecoration(
                                          color: MyColor.colorWhite,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Image.asset(
                                          MyImages.facebookIcon,
                                          height: 24,
                                          width: 24,
                                        ),
                                      ),
                                      spaceSide(Dimensions.space12),
                                      Text(
                                        MyStrings.signInWithFacebook.tr,
                                        style: boldDefault.copyWith(
                                          color: MyColor.colorWhite,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          */

                          // 🔥 3. إخفاء حقول تسجيل الدخول التقليدية
                          Visibility(
                            visible: false,
                            child: Form(
                              key: formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  spaceDown(Dimensions.space20),
                                  CustomTextField(
                                    controller: controller.emailController,
                                    hintText: MyStrings.usernameOrEmail.tr,
                                    onChanged: (value) {},
                                    focusNode: controller.emailFocusNode,
                                    nextFocus: controller.passwordFocusNode,
                                    textInputType: TextInputType.emailAddress,
                                    inputAction: TextInputAction.next,
                                    prefixIcon: Padding(
                                      padding: EdgeInsetsDirectional.only(
                                        start: Dimensions.space12,
                                        end: Dimensions.space8,
                                      ),
                                      child: CustomSvgPicture(
                                        image: MyIcons.user,
                                        color: MyColor.primaryColor,
                                        height: Dimensions.space30,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value!.isEmpty) {
                                        return MyStrings.fieldErrorMsg.tr;
                                      } else {
                                        return null;
                                      }
                                    },
                                  ),
                                  spaceDown(Dimensions.space20),
                                  CustomTextField(
                                    hintText: MyStrings.password.tr,
                                    controller: controller.passwordController,
                                    focusNode: controller.passwordFocusNode,
                                    onChanged: (value) {},
                                    isShowSuffixIcon: true,
                                    isPassword: true,
                                    textInputType: TextInputType.text,
                                    inputAction: TextInputAction.done,
                                    prefixIcon: Padding(
                                      padding: EdgeInsetsDirectional.only(
                                        start: Dimensions.space12,
                                        end: Dimensions.space8,
                                      ),
                                      child: CustomSvgPicture(
                                        image: MyIcons.password,
                                        color: MyColor.primaryColor,
                                        height: Dimensions.space30,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value!.isEmpty) {
                                        return MyStrings.fieldErrorMsg.tr;
                                      } else {
                                        return null;
                                      }
                                    },
                                  ),
                                  spaceDown(Dimensions.space15),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 28,
                                            height: 28,
                                            child: Checkbox(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(
                                                  Dimensions.space5,
                                                ),
                                              ),
                                              activeColor: MyColor.primaryColor,
                                              checkColor: MyColor.colorWhite,
                                              value: controller.remember,
                                              side: WidgetStateBorderSide.resolveWith(
                                                    (states) => BorderSide(
                                                  width: 2.0,
                                                  color: controller.remember
                                                      ? MyColor.getTextFieldEnableBorder()
                                                      : MyColor.getTextFieldDisableBorder(),
                                                ),
                                              ),
                                              onChanged: (value) {
                                                controller.changeRememberMe();
                                              },
                                            ),
                                          ),
                                          spaceSide(Dimensions.space8),
                                          InkWell(
                                            onTap: () {
                                              controller.changeRememberMe();
                                            },
                                            splashFactory: NoSplash.splashFactory,
                                            child: DefaultText(
                                              text: MyStrings.rememberMe.tr,
                                              textColor: MyColor.getBodyTextColor(),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      InkWell(
                                        onTap: () {
                                          controller.clearTextField();
                                          Get.toNamed(
                                            RouteHelper.forgotPasswordScreen,
                                          );
                                        },
                                        child: DefaultText(
                                          text: MyStrings.forgotPassword.tr,
                                          textColor: MyColor.redCancelTextColor,
                                          textStyle: boldDefault.copyWith(
                                            fontSize: Dimensions.fontLarge,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  spaceDown(Dimensions.space25),
                                  RoundedButton(
                                    isLoading: controller.isSubmitLoading,
                                    text: MyStrings.logIn.tr,
                                    press: () {
                                      if (formKey.currentState!.validate()) {
                                        controller.loginUser();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ✅ 4. قسم إنشاء حساب جديد
                          spaceDown(Dimensions.space30),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: Dimensions.space20,
                              vertical: Dimensions.space20,
                            ),
                            decoration: BoxDecoration(
                              color: MyColor.primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(Dimensions.radius25),
                              border: Border.all(
                                color: MyColor.primaryColor.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  MyStrings.doNotHaveAccount.tr,
                                  style: boldLarge.copyWith(
                                    color: MyColor.getBodyTextColor(),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                spaceDown(Dimensions.space12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Get.offAndToNamed(
                                        RouteHelper.registrationScreen,
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: MyColor.primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(Dimensions.radius25),
                                      ),
                                      elevation: 4,
                                      shadowColor: MyColor.primaryColor.withValues(alpha: 0.4),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.person_add_alt_1_rounded,
                                          color: MyColor.colorWhite,
                                          size: 24,
                                        ),
                                        spaceSide(Dimensions.space10),
                                        Text(
                                          'سجّل حساب جديد',
                                          style: boldDefault.copyWith(
                                            color: MyColor.colorWhite,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          spaceDown(Dimensions.space20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}