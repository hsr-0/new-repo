import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart' as geo;

import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as ap;
import 'package:latlong2/latlong.dart' as ll;

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
import '../../../../../data/model/location/selected_location_info.dart';

class EditLocationPickerScreen extends StatefulWidget {
  const EditLocationPickerScreen({super.key, required this.selectedIndex});
  final int selectedIndex;

  @override
  State<EditLocationPickerScreen> createState() => _EditLocationPickerScreenState();
}

class _EditLocationPickerScreenState extends State<EditLocationPickerScreen> {
  ml.MapLibreMapController? mapLibreController;
  ap.AppleMapController? appleController;

  bool isDragging = false;
  int selectedIndex = 0;

  // ✅ متغيرات محلية للإحداثيات الحالية
  double _currentLat = 32.5029;
  double _currentLng = 45.8219;

  @override
  void initState() {
    selectedIndex = Get.arguments ?? widget.selectedIndex;
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<SelectLocationController>().changeIndex(selectedIndex);
      _initCurrentLocation();
    });
  }

  // ✅ تهيئة الموقع الحالي عند فتح الشاشة
  void _initCurrentLocation() {
    final controller = Get.find<SelectLocationController>();
    final savedLocation = controller.homeController.getSelectedLocationInfoAtIndex(selectedIndex);

    if (savedLocation != null &&
        savedLocation.latitude != null &&
        savedLocation.latitude.toString().isNotEmpty) {
      final lat = double.tryParse(savedLocation.latitude.toString());
      final lng = double.tryParse(savedLocation.longitude.toString());
      if (lat != null && lng != null && lat != 0 && lng != 0) {
        setState(() {
          _currentLat = lat;
          _currentLng = lng;
        });
        return;
      }
    }

    // Fallback: استخدام موقع الانطلاق إذا كانت الوجهة فارغة
    if (selectedIndex == 1) {
      final pickupLocation = controller.homeController.getSelectedLocationInfoAtIndex(0);
      if (pickupLocation != null && pickupLocation.latitude != null) {
        final lat = double.tryParse(pickupLocation.latitude.toString());
        final lng = double.tryParse(pickupLocation.longitude.toString());
        if (lat != null && lng != null && lat != 0 && lng != 0) {
          setState(() {
            _currentLat = lat;
            _currentLng = lng;
          });
        }
      }
    }
  }

  // دالة التقاط توقف الخريطة لجلب العنوان
  void _handleMapIdle() {
    if (isDragging) {
      setState(() => isDragging = false);
      _updateLocation(_currentLat, _currentLng);
    }
  }

  void _updateLocation(double lat, double lng) {
    if (lat == 0 || lng == 0) return;

    final controller = Get.find<SelectLocationController>();
    controller.changeCurrentLatLongBasedOnCameraMove(lat, lng);
    controller.pickLocation(isMapDrag: true);
  }

  @override
  void dispose() {
    // ✅ تنظيف بسيط لمنع التسرب
    if (Platform.isIOS) {
      appleController = null;
    } else {
      mapLibreController = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegionWidget(
      child: GetBuilder<SelectLocationController>(builder: (controller) {
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
                        Platform.isIOS
                            ? ap.AppleMap(
                          initialCameraPosition: ap.CameraPosition(
                              target: ap.LatLng(_currentLat, _currentLng),
                              zoom: 16
                          ),
                          onMapCreated: (c) {
                            appleController = c;
                            controller.setAppleController(c);
                          },
                          onCameraMove: (pos) {
                            if (!isDragging) setState(() => isDragging = true);
                            _currentLat = pos.target.latitude;
                            _currentLng = pos.target.longitude;
                          },
                          onCameraIdle: _handleMapIdle,
                          myLocationEnabled: true,
                        )
                            : ml.MapLibreMap(
                          styleString: 'https://tiles.openfreemap.org/styles/liberty',
                          initialCameraPosition: ml.CameraPosition(
                              target: ml.LatLng(_currentLat, _currentLng),
                              zoom: 16.0
                          ),
                          onMapCreated: (c) {
                            mapLibreController = c;
                            controller.setMapLibreController(c);
                          },
                          onCameraMove: (position) {
                            if (!isDragging) setState(() => isDragging = true);
                            _currentLat = position.target.latitude;
                            _currentLng = position.target.longitude;
                          },
                          onCameraIdle: _handleMapIdle,
                          myLocationEnabled: true,
                          myLocationRenderMode: ml.MyLocationRenderMode.normal,
                          compassEnabled: false,
                        ),

                        // 📍 الدبوس مع الأنيميشن
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 40),
                            child: AnimatedScale(
                              scale: isDragging ? 1.15 : 1.0,
                              duration: const Duration(milliseconds: 150),
                              child: Image.asset(
                                selectedIndex == 0
                                    ? "assets/images/map/pickup_marker.png"
                                    : "assets/images/map/destination_marker.png",
                                width: 45,
                                height: 45,
                                errorBuilder: (c, e, s) => Icon(
                                  Icons.location_on,
                                  size: 50,
                                  color: selectedIndex == 0 ? MyColor.primaryColor : Colors.redAccent,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  buildConfirmDestination(controller)
                ],
              ),

              // مؤشر التحميل
              Align(
                alignment: Alignment.center,
                child: controller.isLoading
                    ? Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)]
                  ),
                  child: const CircularProgressIndicator(strokeWidth: 3, color: MyColor.primaryColor),
                )
                    : const SizedBox.shrink(),
              ),

              buildTopButtons(controller),
            ],
          ),
        );
      }),
    );
  }

  Widget buildTopButtons(SelectLocationController controller) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
                    onPressed: () => Get.back()
                ),
              ),
              CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                    icon: const Icon(Icons.my_location, color: Colors.black),
                    onPressed: () => _goToMyLocation(controller)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _goToMyLocation(SelectLocationController controller) async {
    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      await controller.getCurrentPosition(pickupLocationForIndex: -1, isFromEdit: true);
      final pos = await geo.Geolocator.getCurrentPosition(desiredAccuracy: geo.LocationAccuracy.high);

      if (Platform.isIOS && appleController != null) {
        appleController?.animateCamera(ap.CameraUpdate.newLatLng(ap.LatLng(pos.latitude, pos.longitude)));
      } else if (!Platform.isIOS && mapLibreController != null) {
        mapLibreController?.animateCamera(ml.CameraUpdate.newLatLngZoom(ml.LatLng(pos.latitude, pos.longitude), 16.0));
      }
    } catch (e) {
      print('❌ Go to my location error: $e');
    }
  }

  Widget buildConfirmDestination(SelectLocationController controller) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      padding: const EdgeInsets.all(Dimensions.space16),
      decoration: const BoxDecoration(
          color: MyColor.colorWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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

          // مربع العنوان
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
                CustomSvgPicture(
                  image: selectedIndex == 0 ? MyIcons.currentLocation : MyIcons.location,
                  color: MyColor.primaryColor,
                ),
                const SizedBox(width: Dimensions.space10),
                Expanded(
                  child: Text(
                    controller.currentAddress.value.isNotEmpty
                        ? controller.currentAddress.value
                        : (controller.homeController.getSelectedLocationInfoAtIndex(selectedIndex)?.fullAddress ?? "جاري التحديد..."),
                    style: regularDefault.copyWith(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: Dimensions.space20),

          // ✅ زر التأكيد - النسخة المتوازنة (تحفظ الموقع + تمنع الكراش)
          RoundedButton(
            text: MyStrings.confirm,
            press: () async {
              // ✅ 1. حفظ الإحداثيات في المتغيرات العامة للكونترولر
              controller.selectedLatitude = _currentLat;
              controller.selectedLongitude = _currentLng;

              // ✅ 2. عنوان احتياطي
              String finalAddress = controller.currentAddress.value.isNotEmpty
                  ? controller.currentAddress.value
                  : (controller.homeController.getSelectedLocationInfoAtIndex(selectedIndex)?.fullAddress ?? "موقع محدد");

              // ✅ 3. الحفظ في الموقع الصحيح بناءً على selectedIndex
              // هذا هو الجزء الأهم الذي كان يسبب المشكلة سابقاً
              if (selectedIndex == 0) {
                // حفظ في موقع الانطلاق
                controller.pickupLatlong = ll.LatLng(_currentLat, _currentLng);
                controller.pickUpController.text = finalAddress;
              } else {
                // حفظ في موقع الوجهة ← هذا هو الذي كان لا يعمل!
                controller.destinationLatlong = ll.LatLng(_currentLat, _currentLng);
                controller.destinationController.text = finalAddress;
              }

              // ✅ 4. تحديث HomeController باستخدام selectedIndex مباشرة (أهم نقطة!)
              controller.homeController.addLocationAtIndex(
                SelectedLocationInfo(
                  address: finalAddress,
                  fullAddress: finalAddress,
                  latitude: _currentLat,
                  longitude: _currentLng,
                ),
                selectedIndex,  // ← استخدم selectedIndex مباشرة، ليس 0 أو 1 ثابت!
              );

              // ✅ 5. تحديث الخريطة الرئيسية
              controller.openMap(_currentLat, _currentLng, isMapDrag: false);
              controller.update();

              // ✅ 6. تأخير بسيط جداً لمنع الكراش على iOS (200ms كافية)
              // لا نزيد أكثر حتى لا نؤخر تجربة المستخدم
              if (Platform.isIOS) {
                await Future.delayed(const Duration(milliseconds: 200));
              }

              // ✅ 7. العودة مع نتيجة
              Get.back(result: true);
            },
            isOutlined: false,
          )
        ],
      ),
    );
  }
}