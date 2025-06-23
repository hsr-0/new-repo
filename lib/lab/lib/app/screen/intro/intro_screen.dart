import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/lab/lib/base/color_data.dart';
import 'package:cosmetic_store/lab/lib/base/widget_utils.dart';

import '../../../base/constant.dart';
import '../../../base/pref_data.dart';
import '../../controller/controller.dart';
import '../../data/data_file.dart';
import '../../models/intro_model.dart';
import '../../routes/app_routes.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({Key? key}) : super(key: key);

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  void backClick() {
    Constant.closeApp();
  }

  IntroController controller = Get.put(IntroController());
  List<ModelIntro> introLists = DataFile.introList;

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
          child: GetBuilder<IntroController>(
            init: IntroController(),
            builder: (controller) => Stack(
              children: [
                PageView.builder(
                  physics: const BouncingScrollPhysics(),
                  controller: controller.pageController,
                  onPageChanged: (value) {
                    controller.selectedPage.value = value;
                    controller.change(value.obs);
                  },
                  itemCount: introLists.length,
                  itemBuilder: (context, index) {
                    ModelIntro modalIntro = introLists[index];
                    return Column(
                      children: [
                        getAssetImage(
                          modalIntro.image ?? "",
                          height: 478.h,
                          width: double.infinity,
                        ),
                        getVerSpace(30.h),
                        getCustomFont(
                            modalIntro.title ?? "", 24.sp, Colors.black, 1,
                            fontWeight: FontWeight.w700, txtHeight: 1.5.h),
                        getVerSpace(10.h),
                        getMultilineCustomFont(modalIntro.discription ?? '',
                                17.sp, Colors.black,
                                txtHeight: 1.41.h,
                                fontWeight: FontWeight.w500,
                                textAlign: TextAlign.center)
                            .marginSymmetric(horizontal: 20.h),
                      ],
                    );
                  },
                ),
                buildSkipButton(),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: controller.select.value == 3
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            getButton(context, Colors.white, "Log In",
                                    accentColor, () {
                              PrefData.setIsIntro(false);
                              Get.toNamed(Routes.loginRoute);
                            }, 18.sp,
                                    weight: FontWeight.w700,
                                    buttonHeight: 60.h,
                                    borderRadius: BorderRadius.circular(22.h),
                                    borderWidth: 2.h,
                                    isBorder: true,
                                    borderColor: accentColor)
                                .marginSymmetric(horizontal: 20.h),
                            getVerSpace(20.h),
                            getButton(context, accentColor, "Sign Up",
                                    Colors.white, () {
                              PrefData.setIsIntro(false);
                              Get.toNamed(Routes.signUpRoute);
                            }, 18.sp,
                                    weight: FontWeight.w700,
                                    buttonHeight: 60.h,
                                    borderRadius: BorderRadius.circular(22.h))
                                .marginSymmetric(horizontal: 20.h),
                            getVerSpace(40.h)
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                introLists.length - 1,
                                (position) {
                                  return getSvgImage(
                                          position == controller.select.value
                                              ? "select_dot.svg"
                                              : "dot.svg",
                                          width: 10.h,
                                          height: 10.h)
                                      .paddingOnly(
                                          left: position == 0 ? 0 : 5.h,
                                          right: 5.h);
                                },
                              ),
                            ),
                            getVerSpace(40.h),
                            getButton(
                                    context,
                                    accentColor,
                                    controller.select.value == 2
                                        ? "Get Started"
                                        : "Next",
                                    Colors.white, () {
                              if (controller.select.value <= 2) {
                                controller
                                    .change(controller.select.value.obs + 1);
                              }
                              controller.pageController.animateToPage(
                                  controller.select.value,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInSine);
                            }, 18.sp,
                                    weight: FontWeight.w700,
                                    buttonHeight: 60.h,
                                    borderRadius: BorderRadius.circular(22.h))
                                .marginSymmetric(horizontal: 20.h),
                            getVerSpace(40.h),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Align buildSkipButton() {
    return Align(
      alignment: Alignment.topRight,
      child: GestureDetector(
        onTap: () {
          PrefData.setIsIntro(false);
          Get.toNamed(Routes.loginRoute);
        },
        child: getCustomFont("Skip", 17.sp, skipColor, 1,
                fontWeight: FontWeight.w500, txtHeight: 1.41.h)
            .paddingOnly(top: 37.h, right: 19.h),
      ),
    );
  }
}
