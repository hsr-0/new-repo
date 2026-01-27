import 'dart:async';
import 'dart:io'; // لتحديد نوع النظام
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- استيراد المكتبات بأسماء مستعارة لمنع التعارض ---
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as ap;
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

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  // --- متغيرات التحكم للخرائط ---
  mb.MapboxMap? mapboxMap; // أندرويد
  ap.AppleMapController? appleController; // آيفون

  // --- إدارة الدبابيس ---
  mb.PointAnnotationManager? pointAnnotationManager; // أندرويد
  Set<ap.Annotation> appleAnnotations = {}; // آيفون

  // --- متغيرات عامة ---
  Timer? _debounceTimer;
  bool isMapReady = false;

  // معرفات الدبابيس (لأندرويد)
  String? pickupAnnotationId;
  String? destinationAnnotationId;

  final GlobalKey _secondContainerKey = GlobalKey();
  double? _secondContainerHeight;
  TextEditingController searchLocationController = TextEditingController(text: '');
  int index = 0;

  // الصور
  Uint8List? pickUpIcon; // بايت (أندرويد)
  ap.BitmapDescriptor? pickUpIconApple; // صورة (آيفون)

  Uint8List? destinationIcon; // بايت (أندرويد)
  ap.BitmapDescriptor? destinationIconApple; // صورة (آيفون)

  bool isSearching = false;
  bool isFirsTime = true;

  final myDeBouncer = MyDeBouncer(delay: const Duration(milliseconds: 600));

  @override
  void initState() {
    index = widget.pickupLocationForIndex;
    super.initState();
    print("🟢 [InitState] Start Location Picker Screen (${Platform.operatingSystem})");

    Get.put(LocationSearchRepo(apiClient: Get.find()));
    var controller = Get.put(
      SelectLocationController(locationSearchRepo: Get.find(), selectedLocationIndex: index),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final RenderBox box = _secondContainerKey.currentContext?.findRenderObject() as RenderBox;
      final double height = box.size.height;
      setState(() => _secondContainerHeight = height);

      await loadMarkerImages();
      controller.initialize();

      // إذا كان آيفون، الخريطة تجهز أسرع، نطلب الموقع مباشرة
      if (Platform.isIOS) {
        _getCurrentLocation();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> loadMarkerImages() async {
    try {
      searchLocationController.text = '';

      // تحميل الصور للأندرويد (Uint8List)
      pickUpIcon = await Helper.getBytesFromAsset(MyIcons.mapMarkerPickUpIcon, 120);
      destinationIcon = await Helper.getBytesFromAsset(MyIcons.mapMarkerIcon, 120);

      // تحميل الصور للآيفون (BitmapDescriptor)
      pickUpIconApple = await ap.BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(40, 40)), MyIcons.mapMarkerPickUpIcon);
      destinationIconApple = await ap.BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(40, 40)), MyIcons.mapMarkerIcon);

      setState(() {});
    } catch (e) {
      print("🔴 [Error] Failed to load marker images: $e");
    }
  }

  // ==========================================
  // 🗺️ قسم Mapbox (Android Only)
  // ==========================================

  _onMapboxCreated(mb.MapboxMap mapboxMap) {
    this.mapboxMap = mapboxMap;
    Get.find<SelectLocationController>().setMapController(mapboxMap);
  }

  _onMapboxStyleLoaded(mb.StyleLoadedEventData data) async {
    print("🟢 [Mapbox] Style Loaded");
    isMapReady = true;
    try {
      pointAnnotationManager = await mapboxMap!.annotations.createPointAnnotationManager();
      pointAnnotationManager?.addOnPointAnnotationClickListener(AnnotationClickListener(
        onAnnotationClick: (annotation) {
          _handleMarkerClick(annotation.id == pickupAnnotationId ? 0 : 1);
        },
      ));
      await _getCurrentLocation();
      _updateMapMarkers(Get.find<SelectLocationController>());
    } catch (e) {
      print("🔴 [Error] Annotation Manager Error: $e");
    }
  }

  // ==========================================
  // 🍎 قسم Apple Maps (iOS Only)
  // ==========================================

  _onAppleMapCreated(ap.AppleMapController controller) {
    print("🟢 [Apple Map] Created");
    appleController = controller;
    isMapReady = true;
    _updateMapMarkers(Get.find<SelectLocationController>());
  }

  // ==========================================
  // 📍 المنطق المشترك (Unified Logic)
  // ==========================================

  void _handleMarkerClick(int type) {
    // 0: Pickup, 1: Destination
    Get.toNamed(RouteHelper.editLocationPickUpScreen, arguments: type);
  }

  Future<void> _getCurrentLocation() async {
    try {
      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }

      if (permission == geo.LocationPermission.whileInUse || permission == geo.LocationPermission.always) {
        geo.Position position = await geo.Geolocator.getCurrentPosition(desiredAccuracy: geo.LocationAccuracy.high);

        print("📍 [GPS] Found: ${position.latitude}, ${position.longitude}");
        _moveCameraTo(position.latitude, position.longitude);
      }
    } catch (e) {
      print("❌ Error getting GPS: $e");
    }
  }

  // دالة موحدة لتحريك الكاميرا
  void _moveCameraTo(double lat, double lng) {
    if (Platform.isIOS && appleController != null) {
      appleController!.animateCamera(
        ap.CameraUpdate.newLatLng(ap.LatLng(lat, lng)),
      );
    } else if (mapboxMap != null && isMapReady) {
      mapboxMap!.flyTo(
        mb.CameraOptions(
          center: mb.Point(coordinates: mb.Position(lng, lat)),
          zoom: 16.0,
        ),
        mb.MapAnimationOptions(duration: 800),
      );
    }
  }

  // ✅ الدالة المصححة لتحديث الدبابيس
  Future<void> _updateMapMarkers(SelectLocationController controller) async {
    if (!isMapReady) return;

    // --- تحديث الآيفون ---
    if (Platform.isIOS) {
      setState(() {
        appleAnnotations.clear();

        // نقطة الانطلاق
        if (controller.pickupLatlong.latitude != 0) {
          appleAnnotations.add(ap.Annotation(
            annotationId: ap.AnnotationId('pickup'), // ✅ تم حذف const
            position: ap.LatLng(controller.pickupLatlong.latitude, controller.pickupLatlong.longitude),
            // ✅ استخدام defaultAnnotation
            icon: pickUpIconApple ?? ap.BitmapDescriptor.defaultAnnotation,
            onTap: () => _handleMarkerClick(0),
          ));
        }

        // نقطة الوصول
        if (controller.destinationLatlong.latitude != 0) {
          appleAnnotations.add(ap.Annotation(
            annotationId: ap.AnnotationId('destination'), // ✅ تم حذف const
            position: ap.LatLng(controller.destinationLatlong.latitude, controller.destinationLatlong.longitude),
            // ✅ استخدام defaultAnnotation
            icon: destinationIconApple ?? ap.BitmapDescriptor.defaultAnnotation,
            onTap: () => _handleMarkerClick(1),
          ));
        }
      });
      return;
    }

    // --- تحديث الأندرويد (Mapbox) ---
    if (pointAnnotationManager == null) return;
    try {
      await pointAnnotationManager!.deleteAll();
      pickupAnnotationId = null;
      destinationAnnotationId = null;

      if (controller.pickupLatlong.latitude != 0 && pickUpIcon != null) {
        var options = mb.PointAnnotationOptions(
          geometry: mb.Point(coordinates: mb.Position(
            controller.pickupLatlong.longitude,
            controller.pickupLatlong.latitude,
          )),
          image: pickUpIcon!,
          iconSize: 1.0,
        );
        var annotation = await pointAnnotationManager!.create(options);
        pickupAnnotationId = annotation.id;
      }

      if (controller.destinationLatlong.latitude != 0 && destinationIcon != null) {
        var options = mb.PointAnnotationOptions(
          geometry: mb.Point(coordinates: mb.Position(
            controller.destinationLatlong.longitude,
            controller.destinationLatlong.latitude,
          )),
          image: destinationIcon!,
          iconSize: 1.0,
        );
        var annotation = await pointAnnotationManager!.create(options);
        destinationAnnotationId = annotation.id;
      }
    } catch (e) {
      print("🔴 [Markers Error] $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegionWidget(
      statusBarColor: MyColor.transparentColor,
      child: GetBuilder<SelectLocationController>(
        builder: (controller) {

          // تأكد من تحديث الدبابيس عند تغيير الحالة
          if(isMapReady) _updateMapMarkers(controller);

          return Scaffold(
            extendBody: true,
            extendBodyBehindAppBar: true,
            backgroundColor: MyColor.screenBgColor,
            resizeToAvoidBottomInset: true,
            body: Stack(
              clipBehavior: Clip.none,
              children: [
                if (controller.isLoading && controller.isLoadingFirstTime)
                  const SizedBox.expand()
                else
                  Stack(
                    children: [
                      SizedBox(
                        height: context.height - (_secondContainerHeight ?? 0),
                        // 🔥 هنا يتم التبديل بين الخرائط حسب النظام
                        child: Platform.isIOS
                            ? _buildAppleMapWidget()
                            : _buildMapboxWidget(),
                      ),
                    ],
                  ),

                // Loader
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: controller.isLoading
                        ? CircularProgressIndicator(color: MyColor.getPrimaryColor())
                        : const SizedBox.shrink(),
                  ),
                ),

                // Back Button
                Positioned(
                  top: 0,
                  left: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.space12),
                      child: IconButton(
                        style: IconButton.styleFrom(backgroundColor: MyColor.colorWhite),
                        color: MyColor.colorBlack,
                        onPressed: () => Get.back(result: true),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                    ),
                  ),
                )
              ],
            ),
            bottomSheet: buildConfirmDestination(controller),
          );
        },
      ),
    );
  }

  // --- Widget for iOS ---
  Widget _buildAppleMapWidget() {
    return ap.AppleMap(
      initialCameraPosition: const ap.CameraPosition(
        target: ap.LatLng(33.312805, 44.361488), // بغداد افتراضياً
        zoom: 12,
      ),
      onMapCreated: _onAppleMapCreated,
      annotations: appleAnnotations,
      myLocationEnabled: true,
      myLocationButtonEnabled: false, // نستخدم زر مخصص إذا أردنا
      onCameraIdle: () {
        // عند توقف الحركة في آيفون (للجلب العكسي للعنوان إذا كنت مفعله)
      },
    );
  }

  // --- Widget for Android ---
  Widget _buildMapboxWidget() {
    return mb.MapWidget(
      styleUri: mb.MapboxStyles.MAPBOX_STREETS,
      cameraOptions: mb.CameraOptions(
        center: mb.Point(coordinates: mb.Position(44.361488, 33.312805)),
        zoom: 10.0,
      ),
      onMapCreated: _onMapboxCreated,
      onStyleLoadedListener: _onMapboxStyleLoaded,
      onCameraChangeListener: (mb.CameraChangedEventData data) {
        if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 500), () {
          if(isMapReady) {
            // تحديث المنطق عند توقف الكاميرا
          }
        });
      },
    );
  }

  Widget buildConfirmDestination(SelectLocationController controller) {
    return AnimatedContainer(
      key: _secondContainerKey,
      duration: const Duration(milliseconds: 600),
      height: null,
      padding: const EdgeInsets.all(Dimensions.space16),
      decoration: BoxDecoration(
        color: MyColor.getCardBgColor(),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: 5,
                width: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: MyColor.colorGrey.withOpacity(0.2),
                ),
              ),
            ),
            spaceDown(Dimensions.space10),
            Container(
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsetsDirectional.symmetric(vertical: Dimensions.space3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
              ),
              child: GetBuilder<HomeController>(
                builder: (homeController) {
                  return Container(
                    color: Colors.transparent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LabelText(text: MyStrings.pickUpLocation),
                        spaceDown(Dimensions.space5),
                        LocationPickTextField(
                          fillColor: controller.selectedLocationIndex == 0 ? MyColor.colorWhite : MyColor.textFieldBgColor,
                          shadowColor: controller.selectedLocationIndex == 0 ? MyColor.primaryColor.withOpacity(0.2) : MyColor.colorGrey.withOpacity(0.1),
                          labelText: MyStrings.pickUpLocation,
                          controller: controller.pickUpController,
                          onTap: () {
                            controller.changeIndex(0);
                          },
                          prefixIcon: Padding(
                            padding: const EdgeInsetsDirectional.only(start: Dimensions.space12, end: Dimensions.space2),
                            child: CustomSvgPicture(
                              image: MyIcons.currentLocation,
                              color: MyColor.primaryColor,
                              height: Dimensions.space35,
                            ),
                          ),
                          onSubmit: () {},
                          onChanged: (text) {
                            if (isFirsTime == true) {
                              isFirsTime = false;
                              setState(() {});
                            }
                            myDeBouncer.run(() {
                              controller.searchYourAddress(locationName: text);
                            });
                          },
                          hintText: MyStrings.pickUpLocation.tr,
                          radius: Dimensions.moreRadius,
                          inputAction: TextInputAction.done,
                          suffixIcon: Padding(
                            padding: const EdgeInsetsDirectional.only(end: Dimensions.space5),
                            child: IconButton(
                              onPressed: () async {
                                controller.clearTextFiled(0);
                              },
                              icon: const Icon(Icons.close, size: Dimensions.space20, color: MyColor.bodyTextColor),
                            ),
                          ),
                        ),
                        spaceDown(Dimensions.space15),
                        LabelText(text: MyStrings.destination),
                        spaceDown(Dimensions.space5),
                        LocationPickTextField(
                          fillColor: controller.selectedLocationIndex == 1 ? MyColor.colorWhite : MyColor.textFieldBgColor,
                          shadowColor: controller.selectedLocationIndex == 1 ? MyColor.primaryColor.withOpacity(0.2) : MyColor.colorGrey.withOpacity(0.1),
                          inputAction: TextInputAction.done,
                          labelText: MyStrings.whereToGo,
                          controller: controller.destinationController,
                          onTap: () {
                            controller.changeIndex(1);
                          },
                          onChanged: (text) {
                            if (isFirsTime == true) {
                              isFirsTime = false;
                              setState(() {});
                            }
                            myDeBouncer.run(() {
                              controller.searchYourAddress(locationName: text);
                            });
                          },
                          hintText: MyStrings.pickUpDestination.tr,
                          radius: Dimensions.mediumRadius,
                          prefixIcon: Padding(
                            padding: const EdgeInsetsDirectional.only(start: Dimensions.space12, end: Dimensions.space2),
                            child: CustomSvgPicture(
                              image: MyIcons.location,
                              color: MyColor.primaryColor,
                              height: Dimensions.space35,
                            ),
                          ),
                          suffixIcon: Padding(
                            padding: const EdgeInsetsDirectional.only(end: Dimensions.space5),
                            child: IconButton(
                              onPressed: () async {
                                controller.clearTextFiled(1);
                              },
                              icon: const Icon(Icons.close, size: Dimensions.space20, color: MyColor.bodyTextColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // --- قائمة نتائج البحث (Local Search) ---
            controller.isSearched && controller.allPredictions.isEmpty
                ? const CustomLoader(isPagination: true)
                : GestureDetector(
              onTap: () {},
              child: SizedBox(
                height: controller.allPredictions.isNotEmpty ? context.height * .3 : 0,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: Dimensions.space20),
                  itemCount: controller.allPredictions.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    var item = controller.allPredictions[index];
                    return InkWell(
                      radius: Dimensions.defaultRadius,
                      onTap: () async {
                        // 1. جلب الإحداثيات من نتيجة البحث
                        await controller.getLangAndLatFromMap(item).whenComplete(() {
                          // 2. تحديث البيانات
                          controller.pickLocation();
                          controller.updateSelectedAddressFromSearch(item.description ?? '');

                          // 3. تحديد الإحداثيات لتحريك الكاميرا
                          double lat = controller.selectedLocationIndex == 0
                              ? controller.pickupLatlong.latitude
                              : controller.destinationLatlong.latitude;
                          double lng = controller.selectedLocationIndex == 0
                              ? controller.pickupLatlong.longitude
                              : controller.destinationLatlong.longitude;

                          // 4. تحريك الكاميرا (Unified Method)
                          if (lat != 0 && lng != 0) {
                            _moveCameraTo(lat, lng);
                          }
                        });
                        MyUtils.closeKeyboard();
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsetsDirectional.symmetric(
                          vertical: Dimensions.space15,
                          horizontal: Dimensions.space8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_rounded, size: Dimensions.space20, color: MyColor.bodyTextColor),
                            spaceSide(Dimensions.space10),
                            Expanded(
                              child: Text(
                                "${item.description}",
                                style: regularDefault.copyWith(color: MyColor.colorBlack),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            spaceDown(Dimensions.space15),
            RoundedButton(
              text: MyStrings.confirmLocation,
              press: () {
                Get.back(result: 'true');
              },
              isOutlined: false,
            )
          ],
        ),
      ),
    );
  }
}

// كلاس مساعد للنقر على الدبابيس في أندرويد
class AnnotationClickListener extends mb.OnPointAnnotationClickListener {
  final Function(mb.PointAnnotation) onAnnotationClick;
  AnnotationClickListener({required this.onAnnotationClick});

  @override
  void onPointAnnotationClick(mb.PointAnnotation annotation) {
    onAnnotationClick(annotation);
  }
}