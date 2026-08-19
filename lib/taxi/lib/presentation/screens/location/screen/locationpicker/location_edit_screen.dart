import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

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

  bool _isConfirming = false; // 🔥 حالة الدوران والحفظ

  // إحداثيات مبدئية سيتم تحديثها فوراً
  double _currentLat = 33.3152; // مركز بغداد كافتراضي
  double _currentLng = 44.3661;

  // ✅ متغير محلي لمعرفة الفهرس الحالي بشكل قاطع
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.selectedIndex;
    _setupInitialPosition();
  }

  Future<void> _setupInitialPosition() async {
    print("📍 [Setup] بدء تهيئة الموقعInitial...");
    final controller = Get.find<SelectLocationController>();
    controller.changeIndex(currentIndex);

    double? targetLat;
    double? targetLng;

    if (currentIndex == 0 && controller.pickupLatlong.latitude != 0) {
      targetLat = controller.pickupLatlong.latitude;
      targetLng = controller.pickupLatlong.longitude;
    } else if (currentIndex == 1 && controller.destinationLatlong.latitude != 0) {
      targetLat = controller.destinationLatlong.latitude;
      targetLng = controller.destinationLatlong.longitude;
    }

    if (targetLat == null || targetLat == 0) {
      try {
        bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          geo.Position position = await geo.Geolocator.getCurrentPosition(
              desiredAccuracy: geo.LocationAccuracy.high
          );
          targetLat = position.latitude;
          targetLng = position.longitude;
        }
      } catch (e) {
        debugPrint("Location service error: $e");
      }
    }

    if (targetLat != null) {
      if (mounted) {
        setState(() {
          _currentLat = targetLat!;
          _currentLng = targetLng!;
        });
      }
      _moveCameraToCurrent();
    }

    // جلب العنوان النصي من السيرفر للموقع الحالي (مرة واحدة فقط عند الفتح)
    _updateLocationData();
  }

  void _moveCameraToCurrent() {
    if (Platform.isIOS) {
      appleController?.animateCamera(ap.CameraUpdate.newLatLngZoom(ap.LatLng(_currentLat, _currentLng), 16.0));
    } else {
      mapLibreController?.animateCamera(ml.CameraUpdate.newLatLngZoom(ml.LatLng(_currentLat, _currentLng), 16.0));
    }
  }

  void _updateLocationData() {
    final controller = Get.find<SelectLocationController>();
    controller.changeIndex(currentIndex);
    controller.changeCurrentLatLongBasedOnCameraMove(_currentLat, _currentLng);
    controller.openMap(_currentLat, _currentLng, isMapDrag: true);
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  Future<void> _loadMapStylesAndDrivers() async {
    if (!mounted || mapLibreController == null) return;
    try {
      final Uint8List carData = await getBytesFromAsset('assets/images/car.png', 100);
      await mapLibreController!.addImage("car_icon", carData);
      final Uint8List tuktukData = await getBytesFromAsset('assets/images/tuktuk.png', 100);
      await mapLibreController!.addImage("tuktuk_icon", tuktukData);
    } catch(e) {
      debugPrint('❌ Error loading images in Edit Screen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegionWidget(
      child: GetBuilder<SelectLocationController>(builder: (controller) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              Positioned.fill(
                child: Platform.isIOS ? _buildAppleMap() : _buildMapLibre(),
              ),

              // ✅ الدبوس الثابت في المنتصف
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Image.asset(
                    currentIndex == 0
                        ? "assets/images/map/pickup_marker.png"
                        : "assets/images/map/destination_marker.png",
                    width: 50,
                    height: 50,
                    errorBuilder: (c, e, s) => Icon(
                      Icons.location_on,
                      size: 50,
                      color: currentIndex == 0 ? MyColor.primaryColor : Colors.redAccent,
                    ),
                  ),
                ),
              ),

              _buildTopBar(),

              Align(
                alignment: Alignment.bottomCenter,
                child: _buildBottomPanel(controller),
              ),

              // 🔥🔥🔥 شاشة الانتظار والدوران (Overlay) 🔥🔥🔥
              if (_isConfirming)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15)],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              height: 45, width: 45,
                              child: CircularProgressIndicator(color: MyColor.primaryColor, strokeWidth: 3),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              "جاري حفظ الموقع بدقة...",
                              style: boldDefault.copyWith(color: MyColor.colorBlack, fontSize: 14),
                            ),
                          ],
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

  Widget _buildMapLibre() {
    return ml.MapLibreMap(
      styleString: 'https://tiles.openfreemap.org/styles/liberty',
      initialCameraPosition: ml.CameraPosition(target: ml.LatLng(_currentLat, _currentLng), zoom: 16),
      onMapCreated: (c) {
        mapLibreController = c;
        Get.find<SelectLocationController>().setMapLibreController(c);
      },
      onStyleLoadedCallback: _loadMapStylesAndDrivers,
      // ❌ تمت إزالة onCameraMove و onCameraIdle تماماً لحماية الأداء والاعتماد على التأكيد فقط
      myLocationEnabled: true,
      compassEnabled: false,
    );
  }

  Widget _buildAppleMap() {
    return ap.AppleMap(
      initialCameraPosition: ap.CameraPosition(target: ap.LatLng(_currentLat, _currentLng), zoom: 16),
      onMapCreated: (c) {
        appleController = c;
        Get.find<SelectLocationController>().setAppleController(c);
      },
      // ❌ تمت إزالة onCameraMove و onCameraIdle
      myLocationEnabled: true,
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _circleButton(Icons.arrow_back_ios_new, () => Get.back()),
            _circleButton(Icons.gps_fixed, () => _goToCurrentLocation()),
          ],
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback tap) => CircleAvatar(
    backgroundColor: Colors.white,
    child: IconButton(
        icon: Icon(icon, color: Colors.black, size: 20),
        onPressed: tap
    ),
  );

  Future<void> _goToCurrentLocation() async {
    try {
      final pos = await geo.Geolocator.getCurrentPosition();
      _currentLat = pos.latitude;
      _currentLng = pos.longitude;
      _moveCameraToCurrent();
      _updateLocationData();
    } catch (e) {
      debugPrint("GPS error: $e");
    }
  }

  Widget _buildBottomPanel(SelectLocationController controller) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
                color: currentIndex == 0 ? MyColor.primaryColor.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)
            ),
            child: Text(
              currentIndex == 0 ? "نقطة الانطلاق" : "وجهة التوصيل",
              style: boldDefault.copyWith(color: currentIndex == 0 ? MyColor.primaryColor : Colors.redAccent),
            ),
          ),
          const SizedBox(height: 15),
          InnerShadowContainer(
            padding: const EdgeInsets.all(15),
            backgroundColor: MyColor.neutral50,
            child: Row(
              children: [
                CustomSvgPicture(
                  image: currentIndex == 0 ? MyIcons.currentLocation : MyIcons.location,
                  color: MyColor.primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    controller.currentAddress.value.isNotEmpty
                        ? controller.currentAddress.value
                        : "جاري جلب العنوان...",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: regularDefault.copyWith(fontSize: 14, color: MyColor.colorBlack),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          RoundedButton(
            text: MyStrings.confirm.tr,
            press: () async => await _handleFinalConfirmation(controller),
          ),
        ],
      ),
    );
  }

  // 🔥🔥🔥 الدالة المعدلة والجذرية (نفس طريقة تطبيق المطعم + طباعات التشخيص) 🔥🔥🔥
  Future<void> _handleFinalConfirmation(SelectLocationController controller) async {
    if (_isConfirming) return;
    setState(() => _isConfirming = true);

    print("📍 [EditLocationPicker] 1. بدء عملية التأكيد...");
    print("📍 [EditLocationPicker] 2. الإحداثيات قبل القراءة: Lat=$_currentLat, Lng=$_currentLng");

    double finalLat = _currentLat;
    double finalLng = _currentLng;

    // 🔥 الحل الجذري: قراءة إحداثيات منتصف الشاشة (الدبوس) بدقة 100% لحظة الضغط
    if (!Platform.isIOS && mapLibreController != null) {
      try {
        print("📍 [EditLocationPicker] 3. جاري قراءة موقع الكاميرا (queryCameraPosition)...");
        final cameraPosition = await mapLibreController!.queryCameraPosition();
        if (cameraPosition != null) {
          finalLat = cameraPosition.target.latitude;
          finalLng = cameraPosition.target.longitude;
          print("✅ [EditLocationPicker] 4. تم قراءة موقع الكاميرا بنجاح: Lat=$finalLat, Lng=$finalLng");
        } else {
          print("⚠️ [EditLocationPicker] 4. cameraPosition كان null!");
        }
      } catch (e) {
        print("❌ [EditLocationPicker] خطأ في queryCameraPosition: $e");
      }
    } else if (Platform.isIOS) {
      print("🍎 [EditLocationPicker] استخدام إحداثيات Apple Maps: Lat=$finalLat, Lng=$finalLng");
    }

    // 🛑 حماية: إذا كانت الإحداثيات لا تزال صفراً أو غير صالحة، نمنع الحفظ
    if (finalLat == 0.0 && finalLng == 0.0) {
      print("❌ [EditLocationPicker] الإحداثيات صفرية! لا يمكن الحفظ.");
      if (mounted) setState(() => _isConfirming = false);
      return;
    }

    print("📍 [EditLocationPicker] 5. تحديث المتغيرات المحلية: Lat=$finalLat, Lng=$finalLng");
    _currentLat = finalLat;
    _currentLng = finalLng;

    print("📍 [EditLocationPicker] 6. استدعاء controller.changeIndex($currentIndex)");
    controller.changeIndex(currentIndex);

    print("📍 [EditLocationPicker] 7. استدعاء controller.changeCurrentLatLongBasedOnCameraMove...");
    controller.changeCurrentLatLongBasedOnCameraMove(_currentLat, _currentLng);

    print("📍 [EditLocationPicker] 8. استدعاء controller.openMap لجلب العنوان...");
    // 🛑 انتظار جلب العنوان من السيرفر لضمان حفظ العنوان الصحيح وليس القديم
    await controller.openMap(_currentLat, _currentLng, isMapDrag: true);

    print("📍 [EditLocationPicker] 9. العنوان المجلوب: ${controller.currentAddress.value}");

    String finalAddress = controller.currentAddress.value.isNotEmpty
        ? controller.currentAddress.value
        : "موقع تم تحديده";

    print("📍 [EditLocationPicker] 10. حفظ الإحداثيات في Controller...");
    if (currentIndex == 0) {
      controller.pickupLatlong = ll.LatLng(_currentLat, _currentLng);
      controller.pickUpController.text = finalAddress;
      controller.selectedLatitude = _currentLat;
      controller.selectedLongitude = _currentLng;
      print("✅ [EditLocationPicker] تم حفظ نقطة الانطلاق: Lat=$_currentLat, Lng=$_currentLng");
    } else {
      controller.destinationLatlong = ll.LatLng(_currentLat, _currentLng);
      controller.destinationController.text = finalAddress;
      controller.selectedLatitude = _currentLat;
      controller.selectedLongitude = _currentLng;
      print("✅ [EditLocationPicker] تم حفظ وجهة التوصيل: Lat=$_currentLat, Lng=$_currentLng");
    }

    print("📍 [EditLocationPicker] 11. حفظ في homeController.addLocationAtIndex...");
    controller.homeController.addLocationAtIndex(
      SelectedLocationInfo(
        address: finalAddress,
        fullAddress: finalAddress,
        latitude: _currentLat,
        longitude: _currentLng,
      ),
      currentIndex,
    );

    print("📍 [EditLocationPicker] 12. استدعاء controller.update()...");
    controller.update();

    print("📍 [EditLocationPicker] 13. العودة للشاشة السابقة Get.back(result: true)...");
    if (mounted) {
      setState(() => _isConfirming = false);
      Get.back(result: true);
    }
  }
}