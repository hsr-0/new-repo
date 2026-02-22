import 'dart:async';
import 'dart:io';
import 'dart:typed_data'; // ضروري لتحويل الصور
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle; // ضروري لتحميل الصور

// المكتبات الخارجية
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as ap;
import 'package:geolocator/geolocator.dart' as geo;
import 'package:get/get.dart';

// ملفات المشروع الخاصة بك
import 'package:cosmetic_store/taxi/lib/core/utils/debouncer.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_icons.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/style.dart';
// import 'package:cosmetic_store/taxi/lib/core/utils/util.dart'; // غير مستخدم حسب الصورة
import 'package:cosmetic_store/taxi/lib/presentation/components/annotated_region/annotated_region_widget.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/buttons/rounded_button.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/custom_loader/custom_loader.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/image/custom_svg_picture.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/text-form-field/location_pick_text_field.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/text/label_text.dart';
// import '../../../../../core/utils/dimensions.dart'; // غير مستخدم حسب الصورة
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

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  // ---------------------------------------------
  // 🗺️ متغيرات الخرائط
  // ---------------------------------------------
  // ✅ تصحيح الاسم: MapLibreMapController (L كبيرة)
  ml.MapLibreMapController? maplibreController;
  ap.AppleMapController? appleController;

  Set<ap.Annotation> appleAnnotations = {};

  // حالة الخريطة لتجنب الأخطاء
  bool isStyleLoaded = false;

  // 🎨 معرفات الصور للرموز
  final String _pickupIconId = "pickup-icon-id";
  final String _destIconId = "dest-icon-id";

  // ⚙️ أدوات التحكم
  final GlobalKey _secondContainerKey = GlobalKey();
  double? _secondContainerHeight;
  int index = 0;
  final myDeBouncer = MyDeBouncer(delay: const Duration(milliseconds: 600));

  @override
  void initState() {
    index = widget.pickupLocationForIndex;
    super.initState();

    // حقن الكنترولر والريبو
    Get.put(LocationSearchRepo(apiClient: Get.find()));
    var controller = Get.put(
      SelectLocationController(locationSearchRepo: Get.find(), selectedLocationIndex: index),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _calculateBottomHeight();
      controller.initialize();
      _getCurrentLocation();
    });
  }

  void _calculateBottomHeight() {
    final RenderBox? box = _secondContainerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) setState(() => _secondContainerHeight = box.size.height);
  }

  // ==========================================
  // 🤖 Android: MapLibre Logic
  // ==========================================

  // ✅ تصحيح الاسم هنا أيضاً
  void _onMapLibreCreated(ml.MapLibreMapController controller) {
    maplibreController = controller;
  }

  /// هذه الدالة يتم استدعاؤها فقط بعد تحميل الستايل بالكامل
  void _onStyleLoaded() async {
    isStyleLoaded = true;

    // 1. تحميل الصور إلى ذاكرة الخريطة أولاً
    // ملاحظة: تأكد أن المسارات في MyIcons هي لصور PNG
    await _addImageFromAsset(_pickupIconId, MyIcons.mapMarkerPickUpIcon);
    await _addImageFromAsset(_destIconId, MyIcons.mapMarkerIcon);

    // 2. تحديث العلامات الآن بأمان
    _updateMapMarkers(Get.find<SelectLocationController>());
  }

  /// دالة مساعدة لتحويل الصورة من Assets إلى بايتات للخريطة
  Future<void> _addImageFromAsset(String imageName, String assetPath) async {
    if (maplibreController == null) return;
    try {
      final ByteData bytes = await rootBundle.load(assetPath);
      final Uint8List list = bytes.buffer.asUint8List();
      await maplibreController!.addImage(imageName, list);
    } catch (e) {
      debugPrint("Error loading map icon: $e");
    }
  }

  // ==========================================
  // 🍎 iOS: Apple Maps Logic
  // ==========================================
  void _onAppleMapCreated(ap.AppleMapController controller) {
    appleController = controller;
    _updateMapMarkers(Get.find<SelectLocationController>());
  }

  // ==========================================
  // 🔄 المزامنة والتحريك
  // ==========================================

  void _moveCameraTo(double lat, double lng) {
    if (lat == 0 || lng == 0) return;

    if (Platform.isIOS && appleController != null) {
      appleController!.animateCamera(ap.CameraUpdate.newLatLngZoom(ap.LatLng(lat, lng), 15.0));
    }
    else if (maplibreController != null) {
      maplibreController!.animateCamera(ml.CameraUpdate.newLatLngZoom(ml.LatLng(lat, lng), 15.0));
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      geo.Position position = await geo.Geolocator.getCurrentPosition(
          locationSettings: const geo.LocationSettings(accuracy: geo.LocationAccuracy.high)
      );
      _moveCameraTo(position.latitude, position.longitude);
    } catch (e) {
      debugPrint("GPS Error: $e");
    }
  }

  /// دالة تحديث الدبابيس (Markers)
  Future<void> _updateMapMarkers(SelectLocationController controller) async {

    // ✅ iOS Logic
    if (Platform.isIOS) {
      Set<ap.Annotation> newAnnotations = {};
      if (controller.pickupLatlong.latitude != 0) {
        newAnnotations.add(ap.Annotation(
          annotationId: ap.AnnotationId('pickup'),
          position: ap.LatLng(controller.pickupLatlong.latitude, controller.pickupLatlong.longitude),
          icon: ap.BitmapDescriptor.defaultAnnotation,
        ));
      }
      if (controller.destinationLatlong.latitude != 0) {
        newAnnotations.add(ap.Annotation(
          annotationId: ap.AnnotationId('dest'),
          position: ap.LatLng(controller.destinationLatlong.latitude, controller.destinationLatlong.longitude),
          icon: ap.BitmapDescriptor.defaultAnnotation,
        ));
      }
      setState(() => appleAnnotations = newAnnotations);
    }

    // ✅ Android / MapLibre Logic
    else {
      // حماية: إذا لم يتحمل الستايل بعد، لا تفعل شيئاً
      if (maplibreController == null || !isStyleLoaded) return;

      try {
        await maplibreController!.clearSymbols();

        if (controller.pickupLatlong.latitude != 0) {
          await maplibreController!.addSymbol(ml.SymbolOptions(
            geometry: ml.LatLng(controller.pickupLatlong.latitude, controller.pickupLatlong.longitude),
            iconImage: _pickupIconId,
            iconSize: 0.5, // ✅ تم التصغير (0.1 مناسب للصور الكبيرة)
            // ❌ تم حذف iconAllowOverlap لحل الخطأ الأحمر
          ));
        }
        if (controller.destinationLatlong.latitude != 0) {
          await maplibreController!.addSymbol(ml.SymbolOptions(
            geometry: ml.LatLng(controller.destinationLatlong.latitude, controller.destinationLatlong.longitude),
            iconImage: _destIconId,
            iconSize: 0.5, // ✅ تم التصغير
            // ❌ تم حذف iconAllowOverlap لحل الخطأ الأحمر
          ));
        }
      } catch (e) {
        debugPrint("Error updating MapLibre symbols: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegionWidget(
      statusBarColor: MyColor.transparentColor,
      child: GetBuilder<SelectLocationController>(builder: (controller) {

        // تحديث الدبابيس عند تغير الحالة
        WidgetsBinding.instance.addPostFrameCallback((_) => _updateMapMarkers(controller));

        return Scaffold(
          extendBodyBehindAppBar: true,
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              // 1. الخريطة
              SizedBox(
                height: context.height - (_secondContainerHeight ?? 250),
                child: Platform.isIOS ? _buildAppleMap() : _buildMapLibre(),
              ),

              // 2. زر الرجوع
              _buildBackButton(),

              // 3. اللودر
              if (controller.isLoading) const Center(child: CustomLoader()),
            ],
          ),
          bottomSheet: _buildBottomSheet(controller),
        );
      }),
    );
  }

  Widget _buildAppleMap() {
    return ap.AppleMap(
      initialCameraPosition: const ap.CameraPosition(target: ap.LatLng(32.9063, 45.0510), zoom: 12),
      onMapCreated: _onAppleMapCreated,
      annotations: appleAnnotations,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }

  Widget _buildMapLibre() {
    // ✅ تصحيح الاسم: MapLibreMap (L كبيرة)
    return ml.MapLibreMap(
      // 🔗 الرابط الصحيح للسيرفر
      styleString: "https://maps.beytei.com/styles/iraq-taxi-style/style.json",
      initialCameraPosition: const ml.CameraPosition(target: ml.LatLng(32.9063, 45.0510), zoom: 12),
      onMapCreated: _onMapLibreCreated,
      onStyleLoadedCallback: _onStyleLoaded, // مهم جداً
      myLocationEnabled: true,
      trackCameraPosition: true,
      attributionButtonPosition: ml.AttributionButtonPosition.topLeft,
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: 50, left: 20,
      child: InkWell(
        onTap: () => Get.back(),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
        ),
      ),
    );
  }

  Widget _buildBottomSheet(SelectLocationController controller) {
    return Container(
      key: _secondContainerKey,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLocationField(
            title: MyStrings.pickUpLocation,
            textController: controller.pickUpController,
            isSelected: controller.selectedLocationIndex == 0,
            icon: MyIcons.currentLocation,
            onTap: () => controller.changeIndex(0),
            onChanged: (val) => myDeBouncer.run(() => controller.searchYourAddress(locationName: val)),
            onClear: () => controller.clearTextFiled(0),
          ),
          const SizedBox(height: 15),
          _buildLocationField(
            title: MyStrings.destination,
            textController: controller.destinationController,
            isSelected: controller.selectedLocationIndex == 1,
            icon: MyIcons.location,
            onTap: () => controller.changeIndex(1),
            onChanged: (val) => myDeBouncer.run(() => controller.searchYourAddress(locationName: val)),
            onClear: () => controller.clearTextFiled(1),
          ),

          // عرض نتائج البحث
          if (controller.allPredictions.isNotEmpty)
            Container(
              height: 200,
              margin: const EdgeInsets.only(top: 10),
              child: ListView.separated(
                itemCount: controller.allPredictions.length,
                separatorBuilder: (c, i) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final item = controller.allPredictions[i];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.location_on_outlined, color: MyColor.primaryColor),
                    title: Text(item.description ?? "", style: regularDefault.copyWith(fontSize: 14)),
                    onTap: () async {
                      // إخفاء الكيبورد
                      FocusManager.instance.primaryFocus?.unfocus();

                      // جلب الإحداثيات
                      await controller.getLangAndLatFromMap(item);
                      controller.pickLocation();
                      controller.updateSelectedAddressFromSearch(item.description ?? '');

                      // تحريك الكاميرا
                      double lat = controller.selectedLocationIndex == 0 ? controller.pickupLatlong.latitude : controller.destinationLatlong.latitude;
                      double lng = controller.selectedLocationIndex == 0 ? controller.pickupLatlong.longitude : controller.destinationLatlong.longitude;

                      _moveCameraTo(lat, lng);

                      // مسح نتائج البحث
                      controller.allPredictions.clear();
                      controller.update();
                    },
                  );
                },
              ),
            ),

          const SizedBox(height: 20),
          RoundedButton(
            text: MyStrings.confirmLocation,
            press: () => Get.back(result: 'true'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField({
    required String title,
    required TextEditingController textController,
    required bool isSelected,
    required String icon,
    required VoidCallback onTap,
    required Function(String) onChanged,
    required VoidCallback onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabelText(text: title),
        const SizedBox(height: 5),
        LocationPickTextField(
          onTap: onTap,
          onChanged: onChanged,
          controller: textController,
          hintText: title.tr,
          fillColor: isSelected ? MyColor.primaryColor.withOpacity(0.05) : MyColor.textFieldBgColor,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: CustomSvgPicture(image: icon, color: MyColor.primaryColor),
          ),
          suffixIcon: IconButton(onPressed: onClear, icon: const Icon(Icons.close, size: 18, color: Colors.grey)),
        ),
      ],
    );
  }
}
