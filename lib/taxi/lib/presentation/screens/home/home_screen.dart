import 'dart:io';
import 'package:cosmetic_store/taxi/lib/core/utils/dimensions.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_color.dart';
import 'package:cosmetic_store/taxi/lib/data/controller/home/home_controller.dart';
import 'package:cosmetic_store/taxi/lib/data/controller/location/app_location_controller.dart';
import 'package:cosmetic_store/taxi/lib/data/repo/home/home_repo.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/divider/custom_spacer.dart';
import 'package:cosmetic_store/taxi/lib/presentation/screens/dashboard/dashboard_background.dart';
import 'package:cosmetic_store/taxi/lib/presentation/screens/home/widgets/home_app_bar.dart';
import 'package:cosmetic_store/taxi/lib/presentation/screens/home/widgets/home_body.dart';

import 'widgets/location_pickup_widget.dart';

class HomeScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState>? dashBoardScaffoldKey;

  const HomeScreen({super.key, this.dashBoardScaffoldKey});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  double appBarSize = 90.0;

  @override
  void initState() {
    Get.put(HomeRepo(apiClient: Get.find()));
    Get.put(AppLocationController());
    final controller = Get.put(
      HomeController(homeRepo: Get.find(), appLocationController: Get.find()),
    );
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      controller.initialData(shouldLoad: true);
      // جلب الخصومات المتاحة عند فتح الشاشة
      controller.getAvailableCoupons();
    });
  }

  void openDrawer() {
    if (widget.dashBoardScaffoldKey != null) {
      widget.dashBoardScaffoldKey?.currentState?.openEndDrawer();
    }
  }

  // نافذة منبثقة لعرض الخصومات المتاحة
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
                      title: Text(coupon['code'] ?? ''), // تأكد من مفتاح الـ JSON القادم من السيرفر
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
        return DashboardBackground(
          child: Scaffold(
            extendBody: true,
            backgroundColor: MyColor.transparentColor,
            extendBodyBehindAppBar: false,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(appBarSize),
              child: HomeScreenAppBar(
                controller: controller,
                openDrawer: openDrawer,
              ),
            ),
            body: Stack(
              children: [
                RefreshIndicator(
                  color: MyColor.primaryColor,
                  backgroundColor: MyColor.colorWhite,
                  onRefresh: () async {
                    controller.initialData(shouldLoad: true);
                    controller.getAvailableCoupons();
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.space16),
                    physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
                    child: Column(
                      children: [
                        LocationPickUpHomeWidget(controller: controller),
                        spaceDown(Dimensions.space20),
                        HomeBody(controller: controller),
                        spaceDown(Dimensions.space20),

                        // ======== قسم كود الخصم ========
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: MyColor.colorWhite,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 5,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: controller.isCouponApplied
                              ? // حالة: تم تطبيق الخصم
                          Row(
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
                          )
                              : // حالة: إدخال الكود واقتراح الخصومات
                          Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 45,
                                      child: TextField(
                                        controller: controller.promoCodeController,
                                        decoration: InputDecoration(
                                          hintText: 'أدخل كود الخصم',
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    height: 45,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: MyColor.primaryColor,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                              const SizedBox(height: 10),
                              // زر إظهار الخصومات المقترحة
                              GestureDetector(
                                onTap: () => _showCouponsBottomSheet(context, controller),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
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
                        ),
                        // ======== نهاية قسم كود الخصم ========

                        spaceDown(Dimensions.space20),
                      ],
                    ),
                  ),
                ),

                // زر الرجوع الخاص بالآيفون
                if (Platform.isIOS)
                  Positioned(
                    right: 0,
                    top: MediaQuery.of(context).size.height * 0.4,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800.withOpacity(0.7),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 5,
                              offset: const Offset(-2, 0),
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}