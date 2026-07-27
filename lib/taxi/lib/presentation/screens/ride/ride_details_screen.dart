import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:cosmetic_store/taxi/lib/core/helper/string_format_helper.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/dimensions.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_animation.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_color.dart';
import 'package:cosmetic_store/taxi/lib/data/controller/map/ride_map_controller.dart';
import 'package:cosmetic_store/taxi/lib/data/controller/pusher/pusher_ride_controller.dart';
import 'package:cosmetic_store/taxi/lib/data/controller/ride/ride_details/ride_details_controller.dart';
import 'package:cosmetic_store/taxi/lib/data/controller/ride/ride_meassage/ride_meassage_controller.dart';
import 'package:cosmetic_store/taxi/lib/data/repo/message/message_repo.dart';
import 'package:cosmetic_store/taxi/lib/data/repo/ride/ride_repo.dart';
import 'package:cosmetic_store/taxi/lib/presentation/screens/ride/widget/poly_line_map.dart';
import 'package:cosmetic_store/taxi/lib/presentation/screens/ride/widget/ride_details_bottom_sheet_widget.dart';
import 'package:toastification/toastification.dart';

class RideDetailsScreen extends StatefulWidget {
  final String rideId;

  const RideDetailsScreen({super.key, required this.rideId});

  @override
  State<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {
  DraggableScrollableController draggableScrollableController = DraggableScrollableController();

  // 🔥 1. حفظ مرجع للـ MapController للتحكم في التتبع
  late RideMapController _mapController;

  @override
  void initState() {
    Get.put(RideRepo(apiClient: Get.find()));

    // 🔥 2. حفظ المرجع هنا
    _mapController = Get.put(RideMapController());

    Get.put(MessageRepo(apiClient: Get.find()));
    Get.put(RideMessageController(repo: Get.find()));
    final controller = Get.put(RideDetailsController(repo: Get.find(), mapController: _mapController));
    Get.put(PusherRideController(apiClient: Get.find(), rideMessageController: Get.find(), rideDetailsController: controller, rideID: widget.rideId));

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // استدعاء البيانات الأولية
      controller.initialData(widget.rideId);

      // 🔥 بدء التتبع مباشرة (بدون .then لأن initialData ترجع void)
      Future.delayed(const Duration(milliseconds: 500), () {
        final status = controller.ride.status;
        if (status == 'active' || status == 'running' || status == 'accepted' || status == 'pick_up') {
          _mapController.startLiveTracking(widget.rideId);
        }
      });

      Get.find<PusherRideController>().ensureConnection();
    });
  }

  @override
  void dispose() {
    // 🔥 4. إيقاف التتبع وتنظيف الذاكرة عند الخروج من الشاشة
    _mapController.stopLiveTracking(widget.rideId);
    super.dispose();
  }

  Future _zoomBasedOnExtent(double extent) async {
    // نتحقق من وجود النقاط، لكن لا نمررها للدالة لأنها تعرفها مسبقاً
    if (_mapController.polylineCoordinates.isEmpty) return;
    _mapController.fitPolylineBounds();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RideDetailsController>(
      builder: (controller) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarBrightness: Brightness.light,
            statusBarIconBrightness: Brightness.dark,
          ),
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (bool didPop, d) async {
              if (didPop) return;
              printE(Get.previousRoute);
              Get.back();
              toastification.dismissAll();
            },
            child: Scaffold(
              extendBody: true,
              body: Stack(
                children: [
                  // Map
                  controller.isLoading
                      ? SizedBox(
                    height: context.height,
                    width: double.infinity,
                    child: LottieBuilder.asset(
                      MyAnimation.rideDetailsLoadingAnimation,
                    ),
                  )
                      : SizedBox(
                    height: context.isTablet ? context.height : context.height / 1.3,
                    // 🔥 5. تغليف الخريطة بـ GetBuilder لضمان تحديث موقع السيارة
                    child: GetBuilder<RideMapController>(
                      builder: (mapCtrl) {
                        return const PolyLineMapScreen();
                      },
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.space12),
                        child: IconButton(
                          style: IconButton.styleFrom(backgroundColor: MyColor.colorWhite),
                          color: MyColor.colorBlack,
                          onPressed: () => Get.back(result: true),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        ),
                      ),
                    ),
                  )
                ],
              ),
              bottomSheet: controller.isLoading
                  ? Container(
                color: MyColor.colorWhite,
                height: context.height / 4,
                child: const SizedBox.shrink(),
              )
                  : AnimatedPadding(
                padding: EdgeInsetsDirectional.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                duration: const Duration(milliseconds: 500),
                curve: Curves.decelerate,
                child: DraggableScrollableSheet(
                  controller: draggableScrollableController,
                  snap: true,
                  shouldCloseOnMinExtent: true,
                  expand: false,
                  initialChildSize: 0.4,
                  minChildSize: 0.4,
                  maxChildSize: 0.8,
                  snapSizes: const [0.4, 0.5, 0.7, 0.8],
                  snapAnimationDuration: const Duration(milliseconds: 500),
                  builder: (context, scrollController) {
                    return NotificationListener<DraggableScrollableNotification>(
                      onNotification: (notification) {
                        _zoomBasedOnExtent(notification.extent);
                        return true;
                      },
                      child: RideDetailsBottomSheetWidget(
                        scrollController: scrollController,
                        draggableScrollableController: draggableScrollableController,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}