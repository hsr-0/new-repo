import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ تمت الإضافة للتعامل مع مسارات الصور
import 'dart:ui' as ui; // ✅ تمت الإضافة لتحويل الصور

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

  // إحداثيات مبدئية (سيتم تحديثها فوراً في setupInitialPosition)
  double _currentLat = 32.5056;
  double _currentLng = 45.8247;

  @override
  void initState() {
    super.initState();
    _setupInitialPosition();
  }

  Future<void> _setupInitialPosition() async {
    final controller = Get.find<SelectLocationController>();
    controller.changeIndex(widget.selectedIndex);

    double? targetLat;
    double? targetLng;

    // 1. الأولوية: جلب الموقع المحفوظ سابقاً من الكنترولر (إذا وجد)
    if (widget.selectedIndex == 0 && controller.pickupLatlong.latitude != 0) {
      targetLat = controller.pickupLatlong.latitude;
      targetLng = controller.pickupLatlong.longitude;
    } else if (widget.selectedIndex == 1 && controller.destinationLatlong.latitude != 0) {
      targetLat = controller.destinationLatlong.latitude;
      targetLng = controller.destinationLatlong.longitude;
    }

    // 2. إذا لم يوجد موقع سابق، نجلب موقع الجهاز الحالي فوراً (لحل مشكلة الكوت)
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

    // تحديث الإحداثيات وتحريك الكاميرا
    if (targetLat != null) {
      setState(() {
        _currentLat = targetLat!;
        _currentLng = targetLng!;
      });
      _moveCameraToCurrent();
    }

    // جلب العنوان النصي من السيرفر للموقع الحالي
    _updateLocationData();
  }

  void _moveCameraToCurrent() {
    if (Platform.isIOS) {
      appleController?.animateCamera(ap.CameraUpdate.newLatLng(ap.LatLng(_currentLat, _currentLng)));
    } else {
      mapLibreController?.animateCamera(ml.CameraUpdate.newLatLng(ml.LatLng(_currentLat, _currentLng)));
    }
  }

  void _onMapIdle() {
    if (!mounted) return;
    setState(() => isDragging = false);

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        _updateLocationData();
      }
    });
  }

  void _updateLocationData() {
    final controller = Get.find<SelectLocationController>();
    controller.changeIndex(widget.selectedIndex);
    controller.changeCurrentLatLongBasedOnCameraMove(_currentLat, _currentLng);

    // 🔥 هذا السطر هو ما يقوم بجلب العنوان ورسم المسار فوراً عند إفلات الدبوس
    controller.openMap(_currentLat, _currentLng, isMapDrag: true);
  }

  // =========================================================================
  // 🔥 دوال تحميل صور المركبات لهذه الشاشة بالتحديد
  // =========================================================================
  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  Future<void> _loadMapStylesAndDrivers() async {
    if (!mounted || mapLibreController == null) return;
    try {
      // تحميل أيقونة السيارة
      final Uint8List carData = await getBytesFromAsset('assets/images/car.png', 100);
      await mapLibreController!.addImage("car_icon", carData);

      // تحميل أيقونة التكتك
      final Uint8List tuktukData = await getBytesFromAsset('assets/images/tuktuk.png', 100);
      await mapLibreController!.addImage("tuktuk_icon", tuktukData);

      // 🔥 تنويه: لكي تظهر السيارات هنا، يجب أن تمرر قائمة السائقين من HomeController
      // لقد تركت لك هذا السطر لتقوم بتفعيله لاحقاً عندما تقوم بجلب السائقين من السيرفر
      // Get.find<HomeController>().drawNearbyDriversOnMap(mapLibreController);

    } catch(e) {
      debugPrint('❌ Error loading images in Edit Screen: $e');
    }
  }
  // =========================================================================

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
              Positioned.fill(
                child: Platform.isIOS ? _buildAppleMap() : _buildMapLibre(),
              ),

              // الدبوس المركزي (الثابت فوق الخريطة)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: AnimatedScale(
                    scale: isDragging ? 1.3 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Image.asset(
                      widget.selectedIndex == 0
                          ? "assets/images/map/pickup_marker.png"
                          : "assets/images/map/destination_marker.png",
                      width: 50,
                      height: 50,
                      errorBuilder: (c, e, s) => Icon(
                        Icons.location_on,
                        size: 50,
                        color: widget.selectedIndex == 0 ? MyColor.primaryColor : Colors.redAccent,
                      ),
                    ),
                  ),
                ),
              ),

              _buildTopBar(),

              Align(
                alignment: Alignment.bottomCenter,
                child: _buildBottomPanel(controller),
              ),

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
      onMapCreated: (c) {
        mapLibreController = c;
        // 🚀 السر هنا: تمرير الكنترولر إلى SelectLocationController لكي يرسم المسار!
        Get.find<SelectLocationController>().setMapLibreController(c);
      },
      onStyleLoadedCallback: _loadMapStylesAndDrivers, // 🔥 استدعاء تحميل الصور بمجرد جاهزية الخريطة
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
      onMapCreated: (c) {
        appleController = c;
        // 🚀 تمرير الكنترولر للـ iOS أيضاً لرسم المسار
        Get.find<SelectLocationController>().setAppleController(c);
      },
      onCameraMove: (pos) {
        if (!isDragging) setState(() => isDragging = true);
        _currentLat = pos.target.latitude;
        _currentLng = pos.target.longitude;
      },
      onCameraIdle: _onMapIdle,
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
                color: widget.selectedIndex == 0 ? MyColor.primaryColor.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)
            ),
            child: Text(
              widget.selectedIndex == 0 ? "نقطة الانطلاق" : "وجهة التوصيل",
              style: boldDefault.copyWith(color: widget.selectedIndex == 0 ? MyColor.primaryColor : Colors.redAccent),
            ),
          ),
          const SizedBox(height: 15),
          InnerShadowContainer(
            padding: const EdgeInsets.all(15),
            backgroundColor: MyColor.neutral50,
            child: Row(
              children: [
                CustomSvgPicture(
                  image: widget.selectedIndex == 0 ? MyIcons.currentLocation : MyIcons.location,
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
            press: () => _handleFinalConfirmation(controller),
          ),
        ],
      ),
    );
  }

  void _handleFinalConfirmation(SelectLocationController controller) {
    // 1. ضمان الفهرس الصحيح قبل الحفظ لمنع تداخل الأندرويد
    controller.changeIndex(widget.selectedIndex);

    String finalAddress = controller.currentAddress.value.isNotEmpty
        ? controller.currentAddress.value
        : "موقع تم تحديده";

    // 2. تحديث الإحداثيات والعنوان بناءً على الفهرس حصراً
    if (widget.selectedIndex == 0) {
      controller.pickupLatlong = ll.LatLng(_currentLat, _currentLng);
      controller.pickUpController.text = finalAddress;
      controller.selectedLatitude = _currentLat;
      controller.selectedLongitude = _currentLng;
    } else {
      controller.destinationLatlong = ll.LatLng(_currentLat, _currentLng);
      controller.destinationController.text = finalAddress;
      // تحديث الإحداثيات المختارة للوجهة (تمنع تكرار موقع الانطلاق)
      controller.selectedLatitude = _currentLat;
      controller.selectedLongitude = _currentLng;
    }

    // 3. حفظ البيانات في الهوم كنترولر للرجوع إليها
    controller.homeController.addLocationAtIndex(
      SelectedLocationInfo(
        address: finalAddress,
        fullAddress: finalAddress,
        latitude: _currentLat,
        longitude: _currentLng,
      ),
      widget.selectedIndex,
    );

    controller.update();
    Get.back(result: true); // إرجاع نتيجة لنجاح العملية
  }
}