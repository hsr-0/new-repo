import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart' as geo;

// مكتبات الخرائط
import 'package:maplibre_gl/maplibre_gl.dart' as ml; // ✅ استخدام MapLibre بدلاً من flutter_map
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as ap;
import 'package:latlong2/latlong.dart' as ll; // استخدمنا كنية لتجنب التعارض مع LatLng الخاصة بـ MapLibre/Apple

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
  ml.MaplibreMapController? mapLibreController; // ✅ تحديث المتحكم
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

  void _handleMapIdle() {
    if (isDragging) {
      setState(() => isDragging = false);
      _updateLocation(currentLat, currentLng);
    }
  }

  void _updateLocation(double lat, double lng) {
    if (lat == 0 || lng == 0) return;
    final controller = Get.find<SelectLocationController>();
    controller.changeCurrentLatLongBasedOnCameraMove(lat, lng);
    controller.pickLocation(isMapDrag: true);
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
        }

        return Scaffold(
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
                          onMapCreated: (c) {
                            appleController = c;
                            controller.setAppleController(c); // ربط المتحكم بالـ Controller الرئيسي
                          },
                          onCameraMove: (pos) {
                            isDragging = true;
                            currentLat = pos.target.latitude;
                            currentLng = pos.target.longitude;
                          },
                          onCameraIdle: _handleMapIdle,
                          myLocationEnabled: true,
                        )
                            : ml.MapLibreMap( // ✅ استخدام MapLibreMap هنا
                          styleString: 'https://tiles.openfreemap.org/styles/liberty', // ✅ رابط الخرائط المجانية
                          initialCameraPosition: ml.CameraPosition(target: ml.LatLng(initialLat, initialLng), zoom: 16.0),
                          onMapCreated: (c) {
                            mapLibreController = c;
                            controller.setMapLibreController(c); // ربط المتحكم بالـ Controller الرئيسي
                          },
                          onCameraMove: (position) {
                            isDragging = true;
                            currentLat = position.target.latitude;
                            currentLng = position.target.longitude;
                          },
                          onCameraIdle: _handleMapIdle, // ✅ دالة MapLibre لتوقف الحركة
                          myLocationEnabled: true,
                          myLocationRenderMode: ml.MyLocationRenderMode.normal,
                          compassEnabled: false, // اختياري: إخفاء البوصلة إذا أردت
                        ),

                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 35),
                            child: Image.asset(
                              selectedIndex == 0
                                  ? "assets/images/map/pickup_marker.png"
                                  : "assets/images/map/destination_marker.png",
                              width: 45, height: 45,
                              errorBuilder: (c, e, s) => const Icon(Icons.location_on, size: 50, color: MyColor.primaryColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  buildConfirmDestination(controller),
                ],
              ),
              buildTopButtons(),
            ],
          ),
        );
      }),
    );
  }

  Widget buildTopButtons() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back()),
            ),
            CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(icon: const Icon(Icons.my_location), onPressed: _goToMyLocation),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _goToMyLocation() async {
    bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    final pos = await geo.Geolocator.getCurrentPosition();
    if (Platform.isIOS) {
      appleController?.animateCamera(ap.CameraUpdate.newLatLng(ap.LatLng(pos.latitude, pos.longitude)));
    } else {
      // ✅ استخدام animateCamera الخاصة بـ MapLibre
      mapLibreController?.animateCamera(ml.CameraUpdate.newLatLng(ml.LatLng(pos.latitude, pos.longitude)));
    }
  }

  Widget buildConfirmDestination(SelectLocationController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(MyStrings.setYourLocationPerfectly.tr, style: boldDefault),
          const SizedBox(height: 20),
          RoundedButton(text: MyStrings.confirm.tr, press: () => Get.back()),
        ],
      ),
    );
  }
}