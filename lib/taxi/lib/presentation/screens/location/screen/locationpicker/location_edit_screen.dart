import 'dart:io';
import 'dart:async';
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
  final int selectedIndex; // 0 = Pickup, 1 = Destination

  @override
  State<EditLocationPickerScreen> createState() => _EditLocationPickerScreenState();
}

class _EditLocationPickerScreenState extends State<EditLocationPickerScreen> {
  ml.MapLibreMapController? mapLibreController;
  ap.AppleMapController? appleController;

  bool isDragging = false;
  Timer? _debounce;

  // إحداثيات محلية للحفاظ على استقرار الموقع أثناء السحب في أندرويد
  double _currentLat = 32.5056;
  double _currentLng = 45.8247;

  @override
  void initState() {
    super.initState();
    _setupInitialPosition();
  }

  void _setupInitialPosition() {
    final controller = Get.find<SelectLocationController>();
    // الاعتماد الصارم على الـ index الممرر من الشاشة السابقة
    final savedLocation = controller.homeController.getSelectedLocationInfoAtIndex(widget.selectedIndex);

    if (savedLocation != null && savedLocation.latitude != null && savedLocation.latitude != 0) {
      _currentLat = double.tryParse(savedLocation.latitude.toString()) ?? 32.5056;
      _currentLng = double.tryParse(savedLocation.longitude.toString()) ?? 45.8247;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // إخبار الكنترولر بالـ index الصحيح فور الدخول
      controller.changeIndex(widget.selectedIndex);
    });
  }

  // معالجة توقف حركة الخريطة بشكل احترافي
  void _onMapIdle() {
    if (!mounted) return;

    // التأكد من أن الشاشة هي الحالية لمنع التحديثات في الخلفية
    if (ModalRoute.of(context)?.isCurrent != true) return;

    setState(() => isDragging = false);

    // استخدام Debounce أطول قليلاً للأندرويد لضمان الاستقرار
    _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: Platform.isAndroid ? 600 : 400), () {
      if (mounted && _currentLat != 0) {
        _updateLocationData();
      }
    });
  }

  void _updateLocationData() {
    final controller = Get.find<SelectLocationController>();
    // إعادة تأكيد الـ index لمنع القفز لنقطة الانطلاق (0) في أندرويد
    controller.changeIndex(widget.selectedIndex);
    controller.changeCurrentLatLongBasedOnCameraMove(_currentLat, _currentLng);
    controller.pickLocation(isMapDrag: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegionWidget(
      child: GetBuilder<SelectLocationController>(builder: (controller) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              // طبقة الخريطة
              Positioned.fill(
                child: Platform.isIOS ? _buildAppleMap() : _buildMapLibre(),
              ),

              // الدبوس المركزي (Pin)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: AnimatedScale(
                    scale: isDragging ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Image.asset(
                      widget.selectedIndex == 0
                          ? "assets/images/map/pickup_marker.png"
                          : "assets/images/map/destination_marker.png",
                      width: 48,
                      height: 48,
                      errorBuilder: (c, e, s) => Icon(
                        Icons.location_on,
                        size: 50,
                        color: widget.selectedIndex == 0 ? MyColor.primaryColor : Colors.redAccent,
                      ),
                    ),
                  ),
                ),
              ),

              // واجهة التحكم العلوية
              _buildTopBar(controller),

              // اللوحة السفلية للتأكيد
              Align(
                alignment: Alignment.bottomCenter,
                child: _buildBottomPanel(controller),
              ),

              // مؤشر التحميل عند جلب العنوان من السيرفر
              if (controller.isLoading)
                const Center(child: CircularProgressIndicator(color: MyColor.primaryColor)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildMapLibre() {
    return ml.MapLibreMap(
      styleString: 'https://tiles.openfreemap.org/styles/liberty',
      initialCameraPosition: ml.CameraPosition(target: ml.LatLng(_currentLat, _currentLng), zoom: 16),
      onMapCreated: (c) => mapLibreController = c,
      onCameraMove: (pos) {
        if (!isDragging) setState(() => isDragging = true);
        _currentLat = pos.target.latitude;
        _currentLng = pos.target.longitude;
      },
      onCameraIdle: _onMapIdle,
      myLocationEnabled: true,
      compassEnabled: false,
    );
  }

  Widget _buildAppleMap() {
    return ap.AppleMap(
      initialCameraPosition: ap.CameraPosition(target: ap.LatLng(_currentLat, _currentLng), zoom: 16),
      onMapCreated: (c) => appleController = c,
      onCameraMove: (pos) {
        if (!isDragging) setState(() => isDragging = true);
        _currentLat = pos.target.latitude;
        _currentLng = pos.target.longitude;
      },
      onCameraIdle: _onMapIdle,
      myLocationEnabled: true,
    );
  }

  Widget _buildTopBar(SelectLocationController controller) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _circleButton(Icons.arrow_back_ios_new, () => Get.back()),
            _circleButton(Icons.gps_fixed, () => _goToCurrentLocation(controller)),
          ],
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback tap) => CircleAvatar(
    backgroundColor: Colors.white,
    child: IconButton(icon: Icon(icon, color: Colors.black, size: 20), onPressed: tap),
  );

  Future<void> _goToCurrentLocation(SelectLocationController controller) async {
    try {
      final pos = await geo.Geolocator.getCurrentPosition();
      _currentLat = pos.latitude;
      _currentLng = pos.longitude;
      if (Platform.isIOS) {
        appleController?.animateCamera(ap.CameraUpdate.newLatLng(ap.LatLng(_currentLat, _currentLng)));
      } else {
        mapLibreController?.animateCamera(ml.CameraUpdate.newLatLngZoom(ml.LatLng(_currentLat, _currentLng), 16));
      }
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  Widget _buildBottomPanel(SelectLocationController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(MyStrings.setYourLocationPerfectly.tr, style: boldDefault.copyWith(fontSize: 18)),
          const SizedBox(height: 15),
          InnerShadowContainer(
            padding: const EdgeInsets.all(12),
            backgroundColor: MyColor.neutral50,
            child: Row(
              children: [
                CustomSvgPicture(
                  image: widget.selectedIndex == 0 ? MyIcons.currentLocation : MyIcons.location,
                  color: MyColor.primaryColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    controller.currentAddress.value.isNotEmpty
                        ? controller.currentAddress.value
                        : "تحديد الموقع على الخريطة...",
                    maxLines: 2,
                    style: regularDefault.copyWith(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          RoundedButton(
            text: MyStrings.confirm.tr,
            press: () => _handleFinalConfirmation(controller),
          ),
        ],
      ),
    );
  }

  void _handleFinalConfirmation(SelectLocationController controller) {
    // أهم خطوة: تثبيت الـ index قبل الحفظ النهائي
    controller.changeIndex(widget.selectedIndex);

    controller.selectedLatitude = _currentLat;
    controller.selectedLongitude = _currentLng;

    String finalAddress = controller.currentAddress.value.isNotEmpty
        ? controller.currentAddress.value
        : "موقع محدد";

    // التخزين في الحقل الصحيح (Pickup أو Destination)
    if (widget.selectedIndex == 0) {
      controller.pickupLatlong = ll.LatLng(_currentLat, _currentLng);
      controller.pickUpController.text = finalAddress;
    } else {
      controller.destinationLatlong = ll.LatLng(_currentLat, _currentLng);
      controller.destinationController.text = finalAddress;
    }

    // تحديث البيانات في الـ HomeController لعرضها في الشاشة الرئيسية
    controller.homeController.addLocationAtIndex(
      SelectedLocationInfo(
        address: finalAddress,
        fullAddress: finalAddress,
        latitude: _currentLat,
        longitude: _currentLng,
      ),
      widget.selectedIndex,
    );

    Get.back(result: true);
  }
}