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

                        // هنا يتم استدعاء HomeBody (الشاشة التي تحتوي على البحث عن سائق)
                        HomeBody(controller: controller),

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