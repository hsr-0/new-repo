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
  double currentLat = 32.5029;
  double currentLng = 45.8219;

  @override
  void initState() {
    selectedIndex = Get.arguments ?? widget.selectedIndex;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<SelectLocationController>().changeIndex(selectedIndex);
    });
  }

  // دالة التقاط توقف الخريطة لجلب العنوان
  void _handleMapIdle() {
    if (isDragging) {
      setState(() => isDragging = false); // تصغير الدبوس
      _updateLocation(currentLat, currentLng);
    }
  }

  void _updateLocation(double lat, double lng) {
    if (lat == 0 || lng == 0) return;
    final controller = Get.find<SelectLocationController>();
    controller.changeCurrentLatLongBasedOnCameraMove(lat, lng);
    controller.pickLocation(isMapDrag: true); // isMapDrag تمنع رسم المسار العشوائي وتقفز الشاشة
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegionWidget(
      child: GetBuilder<SelectLocationController>(builder: (controller) {

        // محاولة جلب الموقع المطلوب (سواء انطلاق أو وجهة)
        final savedLocation = controller.homeController.getSelectedLocationInfoAtIndex(selectedIndex);

        // التحقق مما إذا كان الموقع موجوداً وصالحاً (ليس 0 ولا 0.0)
        if (savedLocation != null && savedLocation.latitude != null && savedLocation.latitude.toString() != "0" && savedLocation.latitude.toString() != "0.0") {
          currentLat = double.tryParse(savedLocation.latitude.toString()) ?? 32.5029;
          currentLng = double.tryParse(savedLocation.longitude.toString()) ?? 45.8219;
        } else {
          // إذا كان الموقع فارغاً (مثلاً الوجهة لم تحدد بعد)، اجعل الخريطة تفتح على نقطة الانطلاق (موقع الزبون الحالي)
          final pickupLocation = controller.homeController.getSelectedLocationInfoAtIndex(0);
          if (pickupLocation != null && pickupLocation.latitude != null && pickupLocation.latitude.toString() != "0" && pickupLocation.latitude.toString() != "0.0") {
            currentLat = double.tryParse(pickupLocation.latitude.toString()) ?? 32.5029;
            currentLng = double.tryParse(pickupLocation.longitude.toString()) ?? 45.8219;
          } else {
            // كخيار أخير في حال عدم وجود أي بيانات
            currentLat = 32.5029;
            currentLng = 45.8219;
          }
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
                        Platform.isIOS
                            ? ap.AppleMap(
                          initialCameraPosition: ap.CameraPosition(target: ap.LatLng(currentLat, currentLng), zoom: 16),
                          onMapCreated: (c) {
                            appleController = c;
                            controller.setAppleController(c);
                          },
                          onCameraMove: (pos) {
                            if (!isDragging) setState(() => isDragging = true); // تكبير الدبوس
                            currentLat = pos.target.latitude;
                            currentLng = pos.target.longitude;
                          },
                          onCameraIdle: _handleMapIdle,
                          myLocationEnabled: true,
                        )
                            : ml.MapLibreMap(
                          styleString: 'https://tiles.openfreemap.org/styles/liberty',
                          initialCameraPosition: ml.CameraPosition(target: ml.LatLng(currentLat, currentLng), zoom: 16.0),
                          onMapCreated: (c) {
                            mapLibreController = c;
                            controller.setMapLibreController(c);
                          },
                          onCameraMove: (position) {
                            if (!isDragging) setState(() => isDragging = true); // تكبير الدبوس
                            currentLat = position.target.latitude;
                            currentLng = position.target.longitude;
                          },
                          onCameraIdle: _handleMapIdle,
                          myLocationEnabled: true,
                          myLocationRenderMode: ml.MyLocationRenderMode.normal,
                          compassEnabled: false,
                        ),

                        // 📍 الدبوس مع الأنيميشن (يكبر عند السحب)
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

                  // مربع العنوان وتأكيد الموقع
                  buildConfirmDestination(controller)
                ],
              ),

              // مؤشر التحميل أثناء جلب العنوان
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
                child: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black), onPressed: () => Get.back()),
              ),
              CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(icon: const Icon(Icons.my_location, color: Colors.black), onPressed: () => _goToMyLocation(controller)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _goToMyLocation(SelectLocationController controller) async {
    bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    // تفعيل اللودينق في الكونترولر
    await controller.getCurrentPosition(pickupLocationForIndex: -1, isFromEdit: true);

    final pos = await geo.Geolocator.getCurrentPosition(desiredAccuracy: geo.LocationAccuracy.high);
    if (Platform.isIOS) {
      appleController?.animateCamera(ap.CameraUpdate.newLatLng(ap.LatLng(pos.latitude, pos.longitude)));
    } else {
      mapLibreController?.animateCamera(ml.CameraUpdate.newLatLngZoom(ml.LatLng(pos.latitude, pos.longitude), 16.0));
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

          // مربع العنوان مع الظل الداخلي
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

          // ✅ تم تعديل زر التأكيد لحل مشكلة تطابق نقطة الانطلاق مع الوجهة
          RoundedButton(
            text: MyStrings.confirm,
            press: () {
              // 1. إجبار الكونترولر على التقاط الإحداثيات النهائية الحالية للدبوس
              controller.selectedLatitude = currentLat;
              controller.selectedLongitude = currentLng;

              // 2. تثبيت الموقع رسمياً في النظام كما لو أنك اخترته من البحث
              controller.openMap(currentLat, currentLng, isMapDrag: false);

              // 3. العودة للشاشة الرئيسية وإرسال إشارة للنجاح
              Get.back(result: true);
            },
            isOutlined: false,
          ),
        ],
      ),
    );
  }
}