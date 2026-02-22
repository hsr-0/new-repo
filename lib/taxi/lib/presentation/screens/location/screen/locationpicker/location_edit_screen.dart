import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart' as geo;

// ✅ استيراد المكتبة
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as ap;

// تأكد من مساراتك
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

  // ✅ تصحيح الاسم: حرف L كبير
  ml.MapLibreMapController? maplibreController;
  ap.AppleMapController? appleController;

  bool isDragging = false;
  int selectedIndex = 0;

  double currentLat = 0.0;
  double currentLng = 0.0;

  @override
  void initState() {
    selectedIndex = Get.arguments ?? widget.selectedIndex;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<SelectLocationController>().changeIndex(selectedIndex);
    });
  }

  // ==========================================
  // 🤖 Android: MapLibre Logic
  // ==========================================

  void _onMapLibreCreated(ml.MapLibreMapController controller) {
    maplibreController = controller;
    // ❌ تم حذف addListener لأننا سنستخدم onCameraMove الأصلية لضمان الأداء
  }

  // ✅ هذه الدالة ضرورية لجعل الدبوس يرتفع أثناء التحريك
  void _onMapLibreCameraMove(ml.CameraPosition position) {
    if (!isDragging) {
      setState(() {
        isDragging = true; // هذا يرفع الدبوس للأعلى
      });
    }
    currentLat = position.target.latitude;
    currentLng = position.target.longitude;
  }

  void _onCameraIdle() async {
    setState(() => isDragging = false); // هذا ينزل الدبوس عند التوقف

    // نستخدم القيم المخزنة من CameraMove لأنها أسرع وأدق
    _updateLocation(currentLat, currentLng);
  }

  // ==========================================
  // 🍎 iOS: Apple Maps Logic
  // ==========================================
  void _onAppleMapCreated(ap.AppleMapController controller) {
    appleController = controller;
  }

  void _onAppleCameraMove(ap.CameraPosition position) {
    if (!isDragging) setState(() => isDragging = true);
    currentLat = position.target.latitude;
    currentLng = position.target.longitude;
  }

  void _onAppleCameraIdle() {
    setState(() => isDragging = false);
    _updateLocation(currentLat, currentLng);
  }

  // ==========================================
  // 📍 Shared Logic
  // ==========================================
  void _updateLocation(double lat, double lng) {
    if (lat == 0 || lng == 0) return;
    currentLat = lat;
    currentLng = lng;

    final controller = Get.find<SelectLocationController>();
    controller.changeCurrentLatLongBasedOnCameraMove(lat, lng);
    controller.pickLocation(isMapDrag: true);
  }

  Future<void> _goToMyLocation() async {
    try {
      geo.Position position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(accuracy: geo.LocationAccuracy.high),
      );

      if (Platform.isIOS && appleController != null) {
        appleController!.animateCamera(ap.CameraUpdate.newLatLng(ap.LatLng(position.latitude, position.longitude)));
      } else if (maplibreController != null) {
        maplibreController!.animateCamera(ml.CameraUpdate.newLatLngZoom(ml.LatLng(position.latitude, position.longitude), 16.0));
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegionWidget(
      child: GetBuilder<SelectLocationController>(builder: (controller) {

        double initialLat = 32.5029;
        double initialLng = 45.8219;

        final savedLocation = controller.homeController.getSelectedLocationInfoAtIndex(selectedIndex);
        if (savedLocation != null && savedLocation.latitude != null) {
          initialLat = double.tryParse(savedLocation.latitude.toString()) ?? 32.5029;
          initialLng = double.tryParse(savedLocation.longitude.toString()) ?? 45.8219;
          currentLat = initialLat;
          currentLng = initialLng;
        }

        return Scaffold(
          extendBody: true,
          extendBodyBehindAppBar: true,
          backgroundColor: MyColor.screenBgColor,
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Platform.isIOS
                            ? ap.AppleMap(
                          initialCameraPosition: ap.CameraPosition(target: ap.LatLng(initialLat, initialLng), zoom: 16),
                          onMapCreated: _onAppleMapCreated,
                          onCameraMove: _onAppleCameraMove,
                          onCameraIdle: _onAppleCameraIdle,
                          myLocationEnabled: true,
                        )
                        // ✅ هنا التعديل الجذري
                            : ml.MapLibreMap(
                          styleString: "https://maps.beytei.com/styles/iraq-taxi-style/style.json",
                          initialCameraPosition: ml.CameraPosition(target: ml.LatLng(initialLat, initialLng), zoom: 16.0),
                          onMapCreated: _onMapLibreCreated,

                          // ✅ تمت إعادة onCameraMove وتعمل بشكل صحيح مع MapLibre
                          onCameraMove: _onMapLibreCameraMove,

                          onCameraIdle: _onCameraIdle,
                          trackCameraPosition: true,
                          myLocationEnabled: true,

                          // ✅ تحسين بسيط: إخفاء زر البوصلة لأنه قد يتداخل مع التصميم
                          compassEnabled: false,
                        ),

                        // الدبوس المركزي
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 35),
                            child: AnimatedScale(
                              scale: isDragging ? 1.2 : 1.0, // ✅ الآن سيعمل هذا التأثير بشكل ممتاز
                              duration: const Duration(milliseconds: 150),
                              child: Image.asset(
                                selectedIndex == 0 ? "assets/images/map/pickup_marker.png" : "assets/images/map/destination_marker.png",
                                width: 45, height: 45,
                                errorBuilder: (context, error, stackTrace) => Icon(Icons.location_on, size: 50, color: selectedIndex == 0 ? MyColor.primaryColor : Colors.redAccent),
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
              _buildTopButtons(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTopButtons() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.space12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _circleBtn(Icons.arrow_back_ios_new_rounded, () => Get.back()),
              _circleBtn(Icons.my_location, _goToMyLocation),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback press) => CircleAvatar(backgroundColor: MyColor.colorWhite, child: IconButton(icon: Icon(icon, color: MyColor.colorBlack, size: 20), onPressed: press));

  Widget buildConfirmDestination(SelectLocationController controller) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space16),
      decoration: const BoxDecoration(color: MyColor.colorWhite, borderRadius: BorderRadius.vertical(top: Radius.circular(25)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(MyStrings.setYourLocationPerfectly.tr, style: boldDefault.copyWith(fontSize: 16)),
          const SizedBox(height: Dimensions.space20),
          InnerShadowContainer(
            padding: const EdgeInsets.all(Dimensions.space12),
            child: Row(
              children: [
                CustomSvgPicture(image: selectedIndex == 0 ? MyIcons.currentLocation : MyIcons.location, color: MyColor.primaryColor),
                const SizedBox(width: Dimensions.space10),
                Expanded(child: Text(controller.currentAddress.value.isEmpty ? "جاري التحديد..." : controller.currentAddress.value, style: regularDefault, maxLines: 2, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          const SizedBox(height: Dimensions.space20),
          RoundedButton(text: MyStrings.confirm.tr, press: () => Get.back()),
        ],
      ),
    );
  }
}