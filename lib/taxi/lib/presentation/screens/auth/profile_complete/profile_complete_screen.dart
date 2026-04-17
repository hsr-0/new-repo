import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/route/route.dart';
import '../../../../core/utils/dimensions.dart';
import '../../../../core/utils/my_color.dart';
import '../../../../core/utils/my_strings.dart';
import '../../../../core/utils/style.dart';
import '../../../../core/utils/url_container.dart';
import '../../../../data/controller/account/profile_complete_controller.dart';
import '../../../../data/repo/account/profile_repo.dart';
import '../../../components/annotated_region/annotated_region_widget.dart';
import '../../../components/buttons/rounded_button.dart';
import '../../../components/custom_loader/custom_loader.dart';
import '../../../components/divider/custom_spacer.dart';
import '../../../components/image/my_network_image_widget.dart';
import '../../../components/text-form-field/custom_text_field.dart';
import '../../../components/will_pop_widget.dart';
import '../auth_background.dart';
import '../registration/widget/country_bottom_sheet.dart';

class ProfileCompleteScreen extends StatefulWidget {
  const ProfileCompleteScreen({super.key});

  @override
  State<ProfileCompleteScreen> createState() => _ProfileCompleteScreenState();
}

class _ProfileCompleteScreenState extends State<ProfileCompleteScreen> {
  @override
  void initState() {
    Get.put(ProfileRepo(apiClient: Get.find()));
    final controller = Get.put(
      ProfileCompleteController(profileRepo: Get.find()),
    );
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      controller.initialData();
    });
  }

  @override
  void dispose() {
    // تنظيف المتحكمات عند الخروج
    Get.delete<ProfileCompleteController>();
    super.dispose();
  }

  final formKey = GlobalKey<FormState>();

  /// ✅ دالة معالجة رقم الهاتف العراقي - تدعم جميع الاحتمالات
  String? _formatIraqiPhoneNumber(String? value) {
    if (value == null || value.isEmpty) return null;

    // 1. إزالة جميع المسافات والشرطات والرموز غير الرقمية
    String cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');

    // 2. معالجة الأرقام التي تبدأ بـ +
    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }

    // 3. إذا كان الرقم يبدأ بـ 964 (كود العراق الدولي) نحذفه ونضيف 0
    if (cleaned.startsWith('964')) {
      cleaned = '0${cleaned.substring(3)}';
    }
    // 4. إذا كان الرقم يبدأ بـ 7 (بدون 0 أو 964) نضيف 0 في البداية
    else if (cleaned.startsWith('7') && cleaned.length == 10) {
      cleaned = '0$cleaned';
    }
    // 5. إذا كان الرقم أقل من 11 خانة ويبدأ بـ 7، نضيف 0
    else if (cleaned.startsWith('7') && cleaned.length < 11) {
      cleaned = '0$cleaned';
    }

    // 6. التأكد أن الرقم يبدأ بـ 0
    if (!cleaned.startsWith('0') && cleaned.length == 11) {
      cleaned = '0$cleaned';
    }

    // 7. إزالة أي أصفار زائدة في البداية (لكن نترك صفر واحد)
    while (cleaned.length > 11 && cleaned.startsWith('00')) {
      cleaned = cleaned.substring(1);
    }


    // 9. التأكد النهائي من الصيغة العراقية: 07 + 9 أرقام = 11 خانة
    if (cleaned.length == 11 && cleaned.startsWith(RegExp(r'^07[789]\d{8}$'))) {
      return cleaned;
    }

    // إرجاع الرقم كما هو بعد التنظيف إذا لم يطابق الصيغة تماماً (للسماح للمستخدم بالإكمال)
    return cleaned;
  }

  /// ✅ دالة التحقق من صحة رقم الهاتف العراقي
  String? _validateIraqiPhone(String? value) {
    if (value == null || value.isEmpty) {
      return MyStrings.enterYourPhoneNumber.tr;
    }

    String cleaned = _formatIraqiPhoneNumber(value) ?? value;

    // التحقق من أن الرقم 11 خانة ويبدأ بـ 07 ويتبع بأحد الأرقام 7،8،9
    if (!RegExp(r'^07[789]\d{8}$').hasMatch(cleaned)) {
      return 'يرجى إدخال رقم هاتف عراقي صحيح (مثال: 07712345678)';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopWidget(
      nextRoute: '',
      child: AnnotatedRegionWidget(
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: MyColor.colorWhite,
          body: GetBuilder<ProfileCompleteController>(
            builder: (controller) => SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AuthBackgroundWidget(
                    colors: [
                      MyColor.colorWhite.withValues(alpha: 0.9),
                      MyColor.colorWhite.withValues(alpha: 0.8)
                    ],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(end: Dimensions.space5),
                            child: IconButton(
                              onPressed: () {
                                Get.offAllNamed(RouteHelper.loginScreen);
                              },
                              icon: Icon(
                                Icons.close,
                                size: Dimensions.space30,
                                color: MyColor.getHeadingTextColor(),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: Dimensions.space20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                MyStrings.profileCompleteTitle.tr,
                                style: boldExtraLarge.copyWith(
                                  fontSize: 32,
                                  color: MyColor.getHeadingTextColor(),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              spaceDown(Dimensions.space5),
                              Text(
                                MyStrings.profileCompleteSubTitle.tr,
                                style: regularDefault.copyWith(
                                  color: MyColor.getBodyTextColor(),
                                  fontSize: Dimensions.fontLarge,
                                ),
                              ),
                              spaceDown(Dimensions.space40),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
                          horizontal: Dimensions.space20,
                          vertical: Dimensions.space20
                      ),
                      child: controller.isLoading
                          ? const CustomLoader()
                          : Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextField(
                              labelText: MyStrings.username.tr,
                              hintText: "${MyStrings.enterYour.tr} ${MyStrings.username.toLowerCase().tr}",
                              textInputType: TextInputType.text,
                              inputAction: TextInputAction.next,
                              focusNode: controller.userNameFocusNode,
                              controller: controller.userNameController,
                              nextFocus: controller.countryFocusNode,
                              onChanged: (value) {
                                return;
                              },
                              validator: (value) {
                                return null;
                              },
                            ),
                            const SizedBox(height: Dimensions.space20),

                            // ✅ حقل الهاتف مع المعالجة الذكية للأرقام العراقية
                            CustomTextField(
                              labelText: MyStrings.phone.tr,
                              hintText: "07XXXXXXXXX",
                              textInputType: TextInputType.phone,
                              inputAction: TextInputAction.next,
                              focusNode: controller.countryFocusNode,
                              controller: controller.mobileNoController,
                              nextFocus: controller.stateFocusNode,
                              maxLength: 11, // لتحديد الطول الأقصى
                              prefixIcon: IntrinsicWidth(
                                child: Padding(
                                  padding: EdgeInsetsGeometry.symmetric(horizontal: Dimensions.space10),
                                  child: GestureDetector(
                                    onTap: () {
                                      CountryBottomSheet.profileBottomSheet(
                                        context,
                                        controller,
                                      );
                                    },
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        spaceSide(Dimensions.space3),
                                        MyImageWidget(
                                          imageUrl: UrlContainer.countryFlagImageLink.replaceAll(
                                            "{countryCode}",
                                            controller.selectedCountryData.countryCode.toString().toLowerCase(),
                                          ),
                                          height: Dimensions.space25,
                                          width: Dimensions.space40,
                                        ),
                                        spaceSide(Dimensions.space5),
                                        Text(
                                          "+${controller.selectedCountryData.dialCode}",
                                          style: regularMediumLarge.copyWith(
                                            fontSize: Dimensions.fontOverLarge,
                                          ),
                                        ),
                                        Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: MyColor.getBodyTextColor(),
                                        ),
                                        spaceSide(Dimensions.space2),
                                        Container(
                                          color: MyColor.naturalTextColor,
                                          width: 1,
                                          height: Dimensions.space30,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // ✅ معالجة فورية عند كل تغيير في النص
                              onChanged: (value) {
                                if (value != null && value.isNotEmpty) {
                                  String? formatted = _formatIraqiPhoneNumber(value);
                                  if (formatted != null && formatted != value) {
                                    // تحديث النص دون إثارة حلقة لا نهائية
                                    controller.mobileNoController.value = TextEditingValue(
                                      text: formatted,
                                      selection: TextSelection.collapsed(offset: formatted.length),
                                    );
                                  }
                                }
                              },
                              // ✅ تحقق صارم من صحة الرقم العراقي
                              validator: (value) => _validateIraqiPhone(value),
                            ),
                            const SizedBox(height: Dimensions.space20),

                            // ✅ تم حذف حقل العنوان (Address)

                            CustomTextField(
                              labelText: MyStrings.state,
                              hintText: "${MyStrings.enterYour.tr} ${MyStrings.state.toLowerCase().tr}",
                              textInputType: TextInputType.text,
                              inputAction: TextInputAction.next,
                              focusNode: controller.stateFocusNode,
                              controller: controller.stateController,
                              nextFocus: controller.cityFocusNode,
                              onChanged: (value) {
                                return;
                              },
                            ),
                            const SizedBox(height: Dimensions.space20),

                            CustomTextField(
                              labelText: MyStrings.city.tr,
                              hintText: "${MyStrings.enterYour.tr} ${MyStrings.city.toLowerCase().tr}",
                              textInputType: TextInputType.text,
                              inputAction: TextInputAction.done,
                              focusNode: controller.cityFocusNode,
                              controller: controller.cityController,
                              onChanged: (value) {
                                return;
                              },
                            ),

                            // ✅ تم حذف حقل الرمز البريدي (Zip Code)

                            const SizedBox(height: Dimensions.space35),

                            RoundedButton(
                              isLoading: controller.submitLoading,
                              text: MyStrings.completeProfile.tr,
                              press: () {
                                if (formKey.currentState!.validate()) {
                                  // ✅ التأكد النهائي من تنسيق الرقم قبل الإرسال
                                  String? finalPhone = _formatIraqiPhoneNumber(
                                      controller.mobileNoController.text
                                  );
                                  if (finalPhone != null) {
                                    controller.mobileNoController.text = finalPhone;
                                  }
                                  controller.updateProfile();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Dimensions.space35),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}