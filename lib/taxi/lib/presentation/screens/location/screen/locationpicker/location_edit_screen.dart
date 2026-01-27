import 'dart:io'; // ✅ لتحديد نوع النظام
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart' as geo;

// --- مكتبات الخرائط ---
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as ap;

import 'package:cosmetic_store/taxi/lib/core/utils/my_icons.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/style.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/annotated_region/annotated_region_widget.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/buttons/rounded_button.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/card/inner_shadow_container.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/image/custom_svg_picture.dart';
import '../../../../../core/utils/dimensions.dart';
import '../../../../../core/utils/my_color.dart';
import '../../../../../core/utils/my_strings.dart';
import '../../../../../data/controller/location/select_location_controller.dart';

class EditLocationPickerScreen extends StatefulWidget {
  const EditLocationPickerScreen({super.key, required this.selectedIndex});
  final int selectedIndex;

  @override
  State<EditLocationPickerScreen> createState() => _EditLocationPickerScreenState();
}

class _EditLocationPickerScreenState extends State<EditLocationPickerScreen> {
  // متغيرات الخرائط
  mb.MapboxMap? mapboxMap;
  ap.AppleMapController? appleController;

  bool isDragging = false;
  int selectedIndex = 0;

  // الإحداثيات المبدئية (للحفظ المؤقت أثناء السحب)
  double currentLat = 0.0;
  double currentLng = 0.0;

  @override
  void initState() {
    selectedIndex = Get.arguments ?? widget.selectedIndex;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Get.find<SelectLocationController>().changeIndex(selectedIndex);
    });
  }

  // ==========================================
  // 🤖 Android: Mapbox Logic
  // ==========================================
  void _onMapboxCreated(mb.MapboxMap mapboxMap) {
    this.mapboxMap = mapboxMap;
  }

  void _onMapboxCameraChange(mb.CameraChangedEventData event) {
    if (!isDragging) setState(() => isDragging = true);
  }

  Future<void> _onMapboxIdle(mb.MapIdleEventData event) async {
    setState(() => isDragging = false);
    if (mapboxMap != null) {
      final cameraState = await mapboxMap!.getCameraState();
      final point = cameraState.center;
      _updateLocation(point.coordinates.lat.toDouble(), point.coordinates.lng.toDouble());
    }
  }

  // ==========================================
  // 🍎 iOS: Apple Maps Logic
  // ==========================================
  void _onAppleMapCreated(ap.AppleMapController controller) {
    appleController = controller;
  }

  void _onAppleCameraMove(ap.CameraPosition position) {
    if (!isDragging) setState(() => isDragging = true);
    // تحديث الإحداثيات الحالية أثناء الحركة (اختياري)
    currentLat = position.target.latitude;
    currentLng = position.target.longitude;
  }

  void _onAppleCameraIdle() async {
    setState(() => isDragging = false);
    if (appleController != null) {
      // للأسف AppleMapController لا يعطي المركز مباشرة عند التوقف في النسخ القديمة
      // نعتمد على آخر إحداثيات تم تسجيلها في onCameraMove
      _updateLocation(currentLat, currentLng);
    }
  }

  // ==========================================
  // 📍 Shared Logic
  // ==========================================
  void _updateLocation(double lat, double lng) {
    if(lat == 0 || lng == 0) return;

    currentLat = lat;
    currentLng = lng;

    final controller = Get.find<SelectLocationController>();
    controller.changeCurrentLatLongBasedOnCameraMove(lat, lng);

    // استدعاء دالة جلب العنوان (Reverse Geocoding)
    controller.pickLocation();
  }

  Future<void> _goToMyLocation() async {
    final controller = Get.find<SelectLocationController>();
    await controller.getCurrentPosition(pickupLocationForIndex: -1, isFromEdit: true);

    try {
      geo.Position position = await geo.Geolocator.getCurrentPosition(desiredAccuracy: geo.LocationAccuracy.high);

      if (Platform.isIOS && appleController != null) {
        appleController!.animateCamera(ap.CameraUpdate.newLatLng(ap.LatLng(position.latitude, position.longitude)));
      } else if (mapboxMap != null) {
        mapboxMap!.flyTo(
            mb.CameraOptions(center: mb.Point(coordinates: mb.Position(position.longitude, position.latitude)), zoom: 16.0),
            mb.MapAnimationOptions(duration: 1000)
        );
      }
    } catch (e) { print("Error: $e"); }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegionWidget(
      child: GetBuilder<SelectLocationController>(builder: (controller) {

        // تحديد الموقع الافتراضي
        double initialLat = 32.5029;
        double initialLng = 45.8219;
        final savedLocation = controller.homeController.getSelectedLocationInfoAtIndex(selectedIndex);
        if (savedLocation != null && savedLocation.latitude != null) {
          initialLat = double.tryParse(savedLocation.latitude.toString()) ?? 32.5029;
          initialLng = double.tryParse(savedLocation.longitude.toString()) ?? 45.8219;

          // تحديث مبدئي للمتغيرات المحلية
          currentLat = initialLat;
          currentLng = initialLng;
        }

        return Scaffold(
          extendBody: true,
          extendBodyBehindAppBar: true,
          backgroundColor: MyColor.screenBgColor,
          resizeToAvoidBottomInset: true,
          body: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        // 🗺️ تبديل الخريطة حسب النظام
                        Platform.isIOS
                            ? ap.AppleMap(
                          initialCameraPosition: ap.CameraPosition(target: ap.LatLng(initialLat, initialLng), zoom: 16),
                          onMapCreated: _onAppleMapCreated,
                          onCameraMove: _onAppleCameraMove,
                          onCameraIdle: _onAppleCameraIdle,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                        )
                            : mb.MapWidget(
                          styleUri: mb.MapboxStyles.MAPBOX_STREETS,
                          cameraOptions: mb.CameraOptions(center: mb.Point(coordinates: mb.Position(initialLng, initialLat)), zoom: 16.0),
                          onMapCreated: _onMapboxCreated,
                          onCameraChangeListener: _onMapboxCameraChange,
                          onMapIdleListener: _onMapboxIdle,
                        ),

                        // 📍 الدبوس الثابت (Overlay)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 35), // لرفع الدبوس ليكون رأسه في المركز
                            child: AnimatedScale(
                              scale: isDragging ? 1.1 : 1.0,
                              duration: const Duration(milliseconds: 100),
                              child: Image.asset(
                                selectedIndex == 0
                                    ? "assets/images/map/pickup_marker.png"
                                    : "assets/images/map/destination_marker.png",
                                width: 45,
                                height: 45,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                      Icons.location_on,
                                      size: 50,
                                      color: selectedIndex == 0 ? MyColor.primaryColor : Colors.redAccent
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // مربع التأكيد
                  buildConfirmDestination()
                ],
              ),

              // مؤشر التحميل
              Align(
                alignment: Alignment.center,
                child: controller.isLoading
                    ? Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)]),
                  child: const CircularProgressIndicator(strokeWidth: 3, color: MyColor.primaryColor),
                )
                    : const SizedBox.shrink(),
              ),

              // زر الرجوع
              Positioned(
                top: 0, left: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(Dimensions.space12),
                    child: CircleAvatar(
                      backgroundColor: MyColor.colorWhite,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: MyColor.colorBlack),
                        onPressed: () => Get.back(result: true),
                      ),
                    ),
                  ),
                ),
              ),

              // زر "موقعي الحالي"
              Positioned(
                top: 0, right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(Dimensions.space12),
                    child: CircleAvatar(
                      backgroundColor: MyColor.colorWhite,
                      child: IconButton(
                        icon: const Icon(Icons.my_location, color: MyColor.colorBlack),
                        onPressed: _goToMyLocation,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget buildConfirmDestination() {
    return GetBuilder<SelectLocationController>(
      builder: (controller) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          padding: const EdgeInsets.all(Dimensions.space16),
          decoration: BoxDecoration(
              color: MyColor.colorWhite,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: Dimensions.space10),
              Text(MyStrings.setYourLocationPerfectly.tr, style: boldDefault.copyWith(fontSize: 18)),
              const SizedBox(height: 5),
              Text(MyStrings.zoomInToSetExactLocation.tr, style: lightDefault.copyWith(color: MyColor.bodyTextColor, fontSize: 12)),
              const SizedBox(height: Dimensions.space20),

              InnerShadowContainer(
                width: double.infinity,
                backgroundColor: MyColor.neutral50,
                borderRadius: Dimensions.largeRadius,
                blur: 6,
                offset: const Offset(3, 3),
                shadowColor: MyColor.colorBlack.withOpacity(0.04),
                isShadowTopLeft: true,
                isShadowBottomRight: true,
                padding: const EdgeInsets.all(Dimensions.space12),
                child: Row(
                  children: [
                    CustomSvgPicture(image: selectedIndex == 0 ? MyIcons.currentLocation : MyIcons.location, color: MyColor.primaryColor),
                    const SizedBox(width: Dimensions.space10),
                    Expanded(
                      child: Text(
                        controller.currentAddress.value.isNotEmpty
                            ? controller.currentAddress.value
                            : (controller.homeController.getSelectedLocationInfoAtIndex(controller.selectedLocationIndex)?.fullAddress ?? "جاري التحديد..."),
                        style: regularDefault.copyWith(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: Dimensions.space20),
              RoundedButton(
                text: MyStrings.confirm,
                press: () => Get.back(),
                isOutlined: false,
              ),
            ],
          ),
        );
      },
    );
  }
}