import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ✅ المكتبات المجانية للخرائط
import 'package:maplibre_gl/maplibre_gl.dart' as ml; // بديل flutter_map للاندرويد
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as ap;
import 'package:latlong2/latlong.dart' as ll; // فقط لاستقبال البيانات من الـ Controller
import 'package:geolocator/geolocator.dart' as geo;

import 'package:get/get.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/debouncer.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_icons.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/style.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/util.dart';
import 'package:cosmetic_store/taxi/lib/data/controller/home/home_controller.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/annotated_region/annotated_region_widget.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/buttons/rounded_button.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/custom_loader/custom_loader.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/divider/custom_spacer.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/image/custom_svg_picture.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/text-form-field/location_pick_text_field.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/text/label_text.dart';
import 'package:cosmetic_store/taxi/lib/core/route/route.dart';
import '../../../../../core/utils/dimensions.dart';
import '../../../../../core/utils/helper.dart';
import '../../../../../core/utils/my_color.dart';
import '../../../../../core/utils/my_strings.dart';
import '../../../../../data/controller/location/select_location_controller.dart';
import '../../../../../data/repo/location/location_search_repo.dart';

class LocationPickerScreen extends StatefulWidget {
  final int pickupLocationForIndex;
  const LocationPickerScreen({super.key, required this.pickupLocationForIndex});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> with TickerProviderStateMixin {
  // ---------------------------------------------
  // 🗺️ متغيرات الخرائط
  // ---------------------------------------------

  // Android: OpenFreeMap (MapLibre)
  ml.MaplibreMapController? mapLibreController;
  bool isMapLibreStyleLoaded = false;
  ml.Symbol? pickupSymbol;
  ml.Symbol? destSymbol;

  // iOS: Apple Maps
  ap.AppleMapController? appleController;
  Set<ap.Annotation> appleAnnotations = {};

  bool isMapReady = false;

  // ---------------------------------------------
  // 🎨 الأيقونات
  // ---------------------------------------------
  ap.BitmapDescriptor? pickUpIconApple;
  ap.BitmapDescriptor? destinationIconApple;

  // ---------------------------------------------
  // ⚙️ أدوات التحكم
  // ---------------------------------------------
  final GlobalKey _secondContainerKey = GlobalKey();
  double? _secondContainerHeight;
  int index = 0;
  bool isFirsTime = true;
  final myDeBouncer = MyDeBouncer(delay: const Duration(milliseconds: 600));

  @override
  void initState() {
    index = widget.pickupLocationForIndex;
    super.initState();

    Get.put(LocationSearchRepo(apiClient: Get.find()));
    Get.put(SelectLocationController(locationSearchRepo: Get.find(), selectedLocationIndex: index));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final RenderBox? box = _secondContainerKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        setState(() => _secondContainerHeight = box.size.height);
      }
      await loadMarkerIcons();
      Get.find<SelectLocationController>().initialize();
      _getCurrentLocation();
    });
  }

  Future<void> loadMarkerIcons() async {
    if (Platform.isIOS) {
      pickUpIconApple = await ap.BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(48, 48)), MyIcons.mapMarkerPickUpIcon);
      destinationIconApple = await ap.BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(48, 48)), MyIcons.mapMarkerIcon);
      setState(() {});
    }
  }

  // تحميل أيقونات الماركرز لخريطة MapLibre
  Future<void> _loadMapLibreIcons() async {
    if (mapLibreController == null) return;
    final ByteData pickupBytes = await rootBundle.load(MyIcons.mapMarkerPickUpIcon);
    await mapLibreController!.addImage('pickup_icon', pickupBytes.buffer.asUint8List());

    final ByteData destBytes = await rootBundle.load(MyIcons.mapMarkerIcon);
    await mapLibreController!.addImage('dest_icon', destBytes.buffer.asUint8List());
  }

  // ---------------------------------------------
  // 📍 منطق حركة الكاميرا (تم تبسيطه وتسريعه)
  // ---------------------------------------------
  void _moveCameraTo(double lat, double lng) {
    if (Platform.isIOS && appleController != null) {
      appleController!.animateCamera(ap.CameraUpdate.newLatLngZoom(ap.LatLng(lat, lng), 15.0));
    } else if (!Platform.isIOS && mapLibreController != null) {
      // 🚀 حركة ناعمة ومدمجة من MapLibre مباشرة دون الحاجة لأكواد الأنيميشن القديمة
      mapLibreController!.animateCamera(ml.CameraUpdate.newLatLngZoom(ml.LatLng(lat, lng), 15.0));
    }
  }

  Future<void> _getCurrentLocation() async {
    geo.LocationPermission permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) permission = await geo.Geolocator.requestPermission();

    if (permission == geo.LocationPermission.whileInUse || permission == geo.LocationPermission.always) {
      geo.Position position = await geo.Geolocator.getCurrentPosition();
      _moveCameraTo(position.latitude, position.longitude);
    }
  }

  // ---------------------------------------------
  // 🍏 منطق خرائط أبل (iOS)
  // ---------------------------------------------
  void _updateAppleMarkers(SelectLocationController controller) {
    Set<ap.Annotation> newAnnotations = {};
    if (controller.pickupLatlong.latitude != 0) {
      newAnnotations.add(ap.Annotation(
        annotationId: ap.AnnotationId('pickup'),
        position: ap.LatLng(controller.pickupLatlong.latitude, controller.pickupLatlong.longitude),
        icon: pickUpIconApple ?? ap.BitmapDescriptor.defaultAnnotation,
      ));
    }
    if (controller.destinationLatlong.latitude != 0) {
      newAnnotations.add(ap.Annotation(
        annotationId: ap.AnnotationId('dest'),
        position: ap.LatLng(controller.destinationLatlong.latitude, controller.destinationLatlong.longitude),
        icon: destinationIconApple ?? ap.BitmapDescriptor.defaultAnnotation,
      ));
    }
    setState(() => appleAnnotations = newAnnotations);
  }

  // ---------------------------------------------
  // 🤖 منطق خرائط أندرويد (MapLibre)
  // ---------------------------------------------
  Future<void> _updateMapLibreMarkers(SelectLocationController controller) async {
    if (mapLibreController == null || !isMapLibreStyleLoaded) return;

    // مسح الماركرز السابقة
    await mapLibreController!.clearSymbols();

    // إضافة نقطة الانطلاق
    if (controller.pickupLatlong.latitude != 0) {
      pickupSymbol = await mapLibreController!.addSymbol(ml.SymbolOptions(
        geometry: ml.LatLng(controller.pickupLatlong.latitude, controller.pickupLatlong.longitude),
        iconImage: 'pickup_icon',
        iconSize: 0.5,
      ));
    }

    // إضافة نقطة الوصول
    if (controller.destinationLatlong.latitude != 0) {
      destSymbol = await mapLibreController!.addSymbol(ml.SymbolOptions(
        geometry: ml.LatLng(controller.destinationLatlong.latitude, controller.destinationLatlong.longitude),
        iconImage: 'dest_icon',
        iconSize: 0.5,
      ));
    }
  }

  // ---------------------------------------------
  // 📱 بناء الواجهة
  // ---------------------------------------------
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegionWidget(
      statusBarColor: MyColor.transparentColor,
      child: GetBuilder<SelectLocationController>(
        builder: (controller) {

          // تحديث العلامات على الخريطة تلقائياً بعد بناء الواجهة
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Platform.isIOS) {
              _updateAppleMarkers(controller);
            } else {
              _updateMapLibreMarkers(controller);
            }
          });

          return Scaffold(
            body: Stack(
              children: [
                SizedBox(
                  height: context.height - (_secondContainerHeight ?? 0),
                  child: Platform.isIOS ? _buildAppleMap(controller) : _buildFreeMap(controller),
                ),
                // زر الرجوع
                Positioned(top: 40, left: 15, child: IconButton(
                  style: IconButton.styleFrom(backgroundColor: Colors.white),
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Get.back(),
                )),
                // لودر العمليات
                if (controller.isLoading) const Center(child: CircularProgressIndicator()),
              ],
            ),
            bottomSheet: buildConfirmDestination(controller),
          );
        },
      ),
    );
  }

  // --- 🤖 خرائط أندرويد (MapLibre / OpenFreeMap) ---
  Widget _buildFreeMap(SelectLocationController controller) {
    return ml.MapLibreMap(
      styleString: 'https://tiles.openfreemap.org/styles/liberty', // رابط خرائط OpenFreeMap المجانية
      initialCameraPosition: const ml.CameraPosition(target: ml.LatLng(33.3128, 44.3614), zoom: 12),
      onMapCreated: (c) {
        mapLibreController = c;
        controller.setMapLibreController(c);
        isMapReady = true;
      },
      onStyleLoadedCallback: () async {
        isMapLibreStyleLoaded = true;
        await _loadMapLibreIcons();
        _updateMapLibreMarkers(controller);
      },
      myLocationEnabled: true,
      myLocationRenderMode: ml.MyLocationRenderMode.normal,
      compassEnabled: false,
    );
  }

  // --- 🍎 خرائط أبل (iOS) ---
  Widget _buildAppleMap(SelectLocationController controller) {
    return ap.AppleMap(
      initialCameraPosition: const ap.CameraPosition(target: ap.LatLng(33.3128, 44.3614), zoom: 12),
      onMapCreated: (c) {
        appleController = c;
        controller.setAppleController(c);
        _updateAppleMarkers(controller);
      },
      annotations: appleAnnotations,
      myLocationEnabled: true,
    );
  }

  // --- 📋 القائمة السفلية ---
  Widget buildConfirmDestination(SelectLocationController controller) {
    return Container(
      key: _secondContainerKey,
      padding: const EdgeInsets.all(Dimensions.space16),
      decoration: BoxDecoration(
        color: MyColor.getCardBgColor(),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 5, width: 50, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(5))),
            const SizedBox(height: 15),
            LocationPickTextField(
              labelText: MyStrings.pickUpLocation,
              controller: controller.pickUpController,
              prefixIcon: const Icon(Icons.my_location, color: MyColor.primaryColor),
              onTap: () => controller.changeIndex(0),
              onChanged: (val) => myDeBouncer.run(() => controller.searchYourAddress(locationName: val)),
            ),
            const SizedBox(height: 10),
            LocationPickTextField(
              labelText: MyStrings.destination,
              controller: controller.destinationController,
              prefixIcon: const Icon(Icons.location_on, color: Colors.red),
              onTap: () => controller.changeIndex(1),
              onChanged: (val) => myDeBouncer.run(() => controller.searchYourAddress(locationName: val)),
            ),

            // نتائج البحث
            if (controller.allPredictions.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: controller.allPredictions.length,
                  itemBuilder: (context, i) {
                    final item = controller.allPredictions[i];
                    return ListTile(
                      leading: const Icon(Icons.location_city),
                      title: Text(item.description ?? ""),
                      onTap: () async {
                        await controller.getLangAndLatFromMap(item);
                        controller.updateSelectedAddressFromSearch(item.description ?? '');
                        double lat = controller.selectedLocationIndex == 0 ? controller.pickupLatlong.latitude : controller.destinationLatlong.latitude;
                        double lng = controller.selectedLocationIndex == 0 ? controller.pickupLatlong.longitude : controller.destinationLatlong.longitude;
                        _moveCameraTo(lat, lng);
                        MyUtils.closeKeyboard();
                      },
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),
            RoundedButton(
              text: MyStrings.confirmLocation,
              press: () => Get.back(result: 'true'),
            )
          ],
        ),
      ),
    );
  }
}