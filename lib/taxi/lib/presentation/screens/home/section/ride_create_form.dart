import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/taxi/lib/core/helper/string_format_helper.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/dimensions.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_color.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_icons.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_strings.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/style.dart';
import 'package:cosmetic_store/taxi/lib/data/controller/home/home_controller.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/bottom-sheet/custom_bottom_sheet.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/buttons/rounded_button.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/card/inner_shadow_container.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/divider/custom_spacer.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/image/custom_svg_picture.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/shimmer/create_ride_shimmer.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/snack_bar/show_custom_snackbar.dart';
import 'package:cosmetic_store/taxi/lib/presentation/screens/home/widgets/bottomsheet/ride_meassage_bottom_sheet_body.dart';
import 'package:cosmetic_store/taxi/lib/presentation/screens/home/widgets/home_offer_rate_widget.dart';
import 'package:cosmetic_store/taxi/lib/presentation/screens/home/widgets/passenger_bottom_sheet.dart';

class RideCreateForm extends StatelessWidget {
  const RideCreateForm({super.key});

  // نقلنا النافذة المنبثقة للخصومات إلى هنا لتعمل من داخل الفورم
  void _showCouponsBottomSheet(BuildContext context, HomeController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MyColor.colorWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(Dimensions.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'الخصومات المتاحة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              controller.availableCoupons.isEmpty
                  ? const Center(child: Text('لا توجد خصومات متاحة حالياً'))
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: controller.availableCoupons.length,
                itemBuilder: (context, index) {
                  final coupon = controller.availableCoupons[index];
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const Icon(Icons.local_offer, color: MyColor.primaryColor),
                      title: Text(coupon['code'] ?? ''),
                      subtitle: const Text('اضغط لتطبيق الخصم'),
                      onTap: () {
                        controller.promoCodeController.text = coupon['code'];
                        controller.verifyPromoCode();
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (controller) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              MyStrings.findDriver.tr,
              style: boldLarge.copyWith(
                color: MyColor.getRideTitleColor(),
                fontWeight: FontWeight.w500,
                fontSize: Dimensions.fontTitleLarge,
              ),
            ),
            spaceDown(Dimensions.space10),

            if (controller.isLoading) ...[
              const CreateRideShimmer(),
            ] else ...[

              // ==========================================
              // بداية قسم كود الخصم (البديل عن دفع كاش)
              // ==========================================
              controller.isCouponApplied
                  ? // حالة: تم تطبيق الخصم بنجاح
              InnerShadowContainer(
                width: double.infinity,
                backgroundColor: MyColor.neutral50,
                borderRadius: Dimensions.largeRadius,
                blur: 6,
                offset: const Offset(3, 3),
                shadowColor: MyColor.colorBlack.withValues(alpha: 0.04),
                isShadowTopLeft: true,
                isShadowBottomRight: true,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: Dimensions.space16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'تم تطبيق الخصم!',
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'كود: ${controller.appliedCouponCode}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        controller.removePromoCode();
                      },
                    )
                  ],
                ),
              )
                  : // حالة: إدخال الكود
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: InnerShadowContainer(
                          backgroundColor: MyColor.neutral50,
                          borderRadius: Dimensions.largeRadius,
                          blur: 6,
                          offset: const Offset(3, 3),
                          shadowColor: MyColor.colorBlack.withValues(alpha: 0.04),
                          isShadowTopLeft: true,
                          isShadowBottomRight: true,
                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.space16),
                          child: TextField(
                            controller: controller.promoCodeController,
                            decoration: InputDecoration(
                              hintText: 'أدخل كود الخصم',
                              hintStyle: regularDefault.copyWith(color: MyColor.getRideSubTitleColor()),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 50, // تناسق مع ارتفاع InnerShadowContainer
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MyColor.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Dimensions.largeRadius),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            controller.verifyPromoCode();
                          },
                          child: const Text('تطبيق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _showCouponsBottomSheet(context, controller),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_offer_outlined, size: 16, color: MyColor.primaryColor),
                        SizedBox(width: 5),
                        Text(
                          'عرض الخصومات المتاحة',
                          style: TextStyle(
                            color: MyColor.primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // ==========================================
              // نهاية قسم كود الخصم
              // ==========================================

              spaceDown(Dimensions.space15),

              // قسم السعر وعدد الأشخاص (لم يتغير)
              IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 2,
                      child: IgnorePointer(
                        ignoring: true,
                        child: InkWell(
                          onTap: () {
                            if (controller.selectedService.id != '-99') {
                              if (controller.isPriceLocked == false) {
                                controller.updateMainAmount(controller.mainAmount);
                                CustomBottomSheet(child: const HomeOfferRateWidget()).customBottomSheet(context);
                              }
                            } else {
                              CustomSnackBar.error(errorList: [MyStrings.pleaseSelectAService]);
                            }
                          },
                          child: InnerShadowContainer(
                            width: double.infinity,
                            backgroundColor: MyColor.neutral50,
                            borderRadius: Dimensions.largeRadius,
                            blur: 6,
                            offset: const Offset(3, 3),
                            shadowColor: MyColor.colorBlack.withValues(alpha: 0.04),
                            isShadowTopLeft: true,
                            isShadowBottomRight: true,
                            padding: const EdgeInsetsGeometry.symmetric(vertical: Dimensions.space16, horizontal: Dimensions.space16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    controller.mainAmount == 0 ? MyStrings.offerYourRate.tr : '${StringConverter.formatDouble(controller.mainAmount.toString())} ${controller.defaultCurrency}',
                                    style: regularDefault.copyWith(
                                      color: MyColor.bodyTextColor,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: MyColor.getRideSubTitleColor(),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    spaceSide(Dimensions.space15),
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () {
                          if (controller.selectedService.id != '-99') {
                            CustomBottomSheet(
                              child: const PassengerBottomSheet(),
                            ).customBottomSheet(context);
                          } else {
                            CustomSnackBar.error(errorList: [MyStrings.pleaseSelectAService]);
                          }
                        },
                        child: InnerShadowContainer(
                          width: double.infinity,
                          backgroundColor: MyColor.neutral50,
                          borderRadius: Dimensions.largeRadius,
                          blur: 6,
                          offset: const Offset(3, 3),
                          shadowColor: MyColor.colorBlack.withValues(alpha: 0.04),
                          isShadowTopLeft: true,
                          isShadowBottomRight: true,
                          padding: const EdgeInsetsGeometry.symmetric(vertical: Dimensions.space16, horizontal: Dimensions.space16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const CustomSvgPicture(
                                      image: MyIcons.user,
                                      color: MyColor.primaryColor,
                                    ),
                                    spaceSide(Dimensions.space8),
                                    Expanded(
                                      child: Text(
                                        "${controller.passenger.toString()} ${MyStrings.person.tr}",
                                        style: regularDefault.copyWith(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: MyColor.getRideSubTitleColor(),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              spaceDown(Dimensions.space15),

              // زر "البحث عن سائق" وزر "الملاحظات"
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: RoundedButton(
                        text: MyStrings.findDriver.tr,
                        isLoading: controller.isSubmitLoading,
                        press: () {
                          if (controller.isValidForNewRide()) {
                            controller.createRide();
                          }
                        },
                        isOutlined: false,
                      ),
                    ),
                    const SizedBox(width: Dimensions.space8),
                    IconButton(
                      onPressed: () {
                        if (controller.selectedService.id != '-99') {
                          CustomBottomSheet(
                            child: const RideMassageBottomSheet(),
                          ).customBottomSheet(context);
                        }
                      },
                      icon: Container(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.space12, vertical: Dimensions.space12),
                        decoration: BoxDecoration(
                          color: MyColor.primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(
                            Dimensions.largeRadius,
                          ),
                          border: Border.all(
                            color: MyColor.primaryColor,
                            width: 1.5,
                          ),
                        ),
                        child: const CustomSvgPicture(
                          image: MyIcons.note,
                          color: MyColor.primaryColor,
                          height: Dimensions.space25,
                          width: Dimensions.space25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
