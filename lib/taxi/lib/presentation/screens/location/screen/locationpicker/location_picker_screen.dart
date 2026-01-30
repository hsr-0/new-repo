import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ✅ استيراد المكتبات بأسماء مستعارة لتجنب التعارض
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
  // ---------------------------------------------
  // 🗺️ متغيرات الخرائط (Map Variables)
  // ---------------------------------------------

  // Android: Mapbox
  mb.MapboxMap? mapboxMap;
  mb.PointAnnotationManager? pointAnnotationManager;
  String? pickupAnnotationId;
  String? destinationAnnotationId;

  // iOS: Apple Maps
  ap.AppleMapController? appleController;
  Set<ap.Annotation> appleAnnotations = {};

  // المشتركة
  bool isMapReady = false;

  // ---------------------------------------------
  // 🎨 الصور والأيقونات (Visual Assets)
  // ---------------------------------------------
  Uint8List? pickUpIconBytes;      // للأندرويد
  Uint8List? destinationIconBytes; // للأندرويد

  ap.BitmapDescriptor? pickUpIconApple;      // للآيفون
  ap.BitmapDescriptor? destinationIconApple; // للآيفون

  // ---------------------------------------------
  // ⚙️ أدوات التحكم (Logic Controls)
  // ---------------------------------------------
  final GlobalKey _secondContainerKey = GlobalKey();
  double? _secondContainerHeight;
  TextEditingController searchLocationController = TextEditingController(text: '');
  int index = 0;
  bool isFirsTime = true;

  // ✅ الديباونسر للبحث فقط (وليس لحركة الكاميرا لتجنب التعليق)
  final myDeBouncer = MyDeBouncer(delay: const Duration(milliseconds: 600));

  @override
  void initState() {
    index = widget.pickupLocationForIndex;
    super.initState();
    print("🚀 [Init] Platform: ${Platform.isIOS ? 'iOS (Apple Maps)' : 'Android (Mapbox)'}");

    Get.put(LocationSearchRepo(apiClient: Get.find()));
    var controller = Get.put(
      SelectLocationController(locationSearchRepo: Get.find(), selectedLocationIndex: index),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // حساب ارتفاع البوكس السفلي
      final RenderBox? box = _secondContainerKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        setState(() => _secondContainerHeight = box.size.height);
      }

      // تحميل الصور
      await loadMarkerImages();

      controller.initialize();

      // في الآيفون، نطلب الموقع فوراً لأن الخريطة جاهزة
      if (Platform.isIOS) {
        _getCurrentLocation();
      }
    });
  }

  /// ✅ تحميل صور الدبابيس لكلا النظامين لضمان نفس الشكل الجميل
  Future<void> loadMarkerImages() async {
    try {
      // 1. للأندرويد (Mapbox يحتاج Uint8List)
      pickUpIconBytes = await Helper.getBytesFromAsset(MyIcons.mapMarkerPickUpIcon, 120);
      destinationIconBytes = await Helper.getBytesFromAsset(MyIcons.mapMarkerIcon, 120);

      // 2. للآيفون (Apple Maps يحتاج BitmapDescriptor)
      // نستخدم نفس الأيقونة لتظهر بنفس الجمالية
      pickUpIconApple = await ap.BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(48, 48)),
          MyIcons.mapMarkerPickUpIcon
      );
      destinationIconApple = await ap.BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(48, 48)),
          MyIcons.mapMarkerIcon
      );

      setState(() {});
    } catch (e) {
      print("🔴 [Error] Failed to load marker images: $e");
    }
  }

  // ---------------------------------------------
  // 📍 دوال الخرائط (Map Logic)
  // ---------------------------------------------

  /// 🤖 Mapbox: تم إنشاء الخريطة
  _onMapboxCreated(mb.MapboxMap mapboxMap) {
    this.mapboxMap = mapboxMap;
    Get.find<SelectLocationController>().setMapController(mapboxMap);
  }

  /// 🤖 Mapbox: الستايل جاهز
  _onMapboxStyleLoaded(mb.StyleLoadedEventData data) async {
    isMapReady = true;
    try {
      // إعداد مدير الدبابيس
      pointAnnotationManager = await mapboxMap!.annotations.createPointAnnotationManager();

      // مستمع النقر على الدبوس
      pointAnnotationManager?.addOnPointAnnotationClickListener(AnnotationClickListener(
        onAnnotationClick: (annotation) {
          if (annotation.id == pickupAnnotationId) _handleMarkerClick(0);
          if (annotation.id == destinationAnnotationId) _handleMarkerClick(1);
        },
      ));

      // جلب الموقع وتحديث الدبابيس
      await _getCurrentLocation();
      _updateMapMarkers(Get.find<SelectLocationController>());

    } catch (e) {
      print("🔴 [Mapbox Error] $e");
    }
  }

  /// 🍎 Apple Maps: تم إنشاء الخريطة
  _onAppleMapCreated(ap.AppleMapController controller) {
    appleController = controller;
    isMapReady = true;
    _updateMapMarkers(Get.find<SelectLocationController>());
  }

  /// معالجة النقر على الدبوس (للتعديل)
  void _handleMarkerClick(int type) {
    Get.toNamed(RouteHelper.editLocationPickUpScreen, arguments: type);
  }

  /// 📍 جلب الموقع الحالي (GPS)
  Future<void> _getCurrentLocation() async {
    try {
      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }

      if (permission == geo.LocationPermission.whileInUse || permission == geo.LocationPermission.always) {
        geo.Position position = await geo.Geolocator.getCurrentPosition(desiredAccuracy: geo.LocationAccuracy.high);

        // تحريك الكاميرا لموقع المستخدم
        _moveCameraTo(position.latitude, position.longitude);
      }
    } catch (e) {
      print("❌ Error getting GPS: $e");
    }
  }

  /// 🎥 تحريك الكاميرا (السر في النعومة هنا)
  void _moveCameraTo(double lat, double lng) {
    if (Platform.isIOS && appleController != null) {
      // 🍎 للآيفون: حركة ناعمة قياسية
      appleController!.animateCamera(
        ap.CameraUpdate.newLatLngZoom(ap.LatLng(lat, lng), 15.0),
      );
    } else if (mapboxMap != null && isMapReady) {
      // 🤖 للأندرويد: حركة FlyTo السينمائية (كود الحلم)
      mapboxMap!.flyTo(
        mb.CameraOptions(
          center: mb.Point(coordinates: mb.Position(lng, lat)),
          zoom: 15.0,
        ),
        mb.MapAnimationOptions(duration: 1200), // مدة أطول قليلاً لنعومة فائقة
      );
    }
  }

  /// 📍 تحديث الدبابيس (بدون كراش)
  /// السر: لا نربط هذه الدالة بحركة الكاميرا، بل بتغير البيانات فقط
  Future<void> _updateMapMarkers(SelectLocationController controller) async {
    if (!isMapReady) return;

    // 🍎 منطق الآيفون
    if (Platform.isIOS) {
      Set<ap.Annotation> newAnnotations = {};

      if (controller.pickupLatlong.latitude != 0) {
        newAnnotations.add(ap.Annotation(
          annotationId: ap.AnnotationId('pickup'),
          position: ap.LatLng(controller.pickupLatlong.latitude, controller.pickupLatlong.longitude),
          icon: pickUpIconApple ?? ap.BitmapDescriptor.defaultAnnotation, // استخدام أيقونتنا المخصصة
          onTap: () => _handleMarkerClick(0),
        ));
      }

      if (controller.destinationLatlong.latitude != 0) {
        newAnnotations.add(ap.Annotation(
          annotationId: ap.AnnotationId('destination'),
          position: ap.LatLng(controller.destinationLatlong.latitude, controller.destinationLatlong.longitude),
          icon: destinationIconApple ?? ap.BitmapDescriptor.defaultAnnotation, // استخدام أيقونتنا المخصصة
          onTap: () => _handleMarkerClick(1),
        ));
      }

      setState(() {
        appleAnnotations = newAnnotations;
      });
      return;
    }

    // 🤖 منطق الأندرويد (Mapbox)
    if (pointAnnotationManager == null) return;

    try {
      // حذف القديم (آمن هنا لأننا لا نستدعيه داخل Loop)
      await pointAnnotationManager!.deleteAll();
      pickupAnnotationId = null;
      destinationAnnotationId = null;

      // رسم Pickup
      if (controller.pickupLatlong.latitude != 0 && pickUpIconBytes != null) {
        var options = mb.PointAnnotationOptions(
          geometry: mb.Point(coordinates: mb.Position(
              controller.pickupLatlong.longitude,
              controller.pickupLatlong.latitude
          )),
          image: pickUpIconBytes!,
          iconSize: 1.2, // حجم أكبر قليلاً وواضح
        );
        var annotation = await pointAnnotationManager!.create(options);
        pickupAnnotationId = annotation.id;
      }

      // رسم Destination
      if (controller.destinationLatlong.latitude != 0 && destinationIconBytes != null) {
        var options = mb.PointAnnotationOptions(
          geometry: mb.Point(coordinates: mb.Position(
              controller.destinationLatlong.longitude,
              controller.destinationLatlong.latitude
          )),
          image: destinationIconBytes!,
          iconSize: 1.2,
        );
        var annotation = await pointAnnotationManager!.create(options);
        destinationAnnotationId = annotation.id;
      }
    } catch (e) {
      print("🔴 [Markers Error] $e");
    }
  }

  // ---------------------------------------------
  // 📱 بناء الواجهة (Build UI)
  // ---------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegionWidget(
      statusBarColor: MyColor.transparentColor,
      child: GetBuilder<SelectLocationController>(
        builder: (controller) {

          // ✅ مراقب التغييرات: إذا تغير الموقع في الكنترولر، نحدث الخريطة
          // هذا بديل عن وضع التحديث داخل onCameraMove الذي كان يسبب الكراش
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // نتحقق من شرط بسيط لمنع التكرار اللانهائي إذا لزم الأمر
            // ولكن مع GetBuilder التحديث يأتي من الخارج، لذا هو آمن
            _updateMapMarkers(controller);
          });

          return Scaffold(
            extendBody: true,
            extendBodyBehindAppBar: true,
            backgroundColor: MyColor.screenBgColor,
            resizeToAvoidBottomInset: true,
            body: Stack(
              clipBehavior: Clip.none,
              children: [
                // اللودر الأولي
                if (controller.isLoading && controller.isLoadingFirstTime)
                  const SizedBox.expand()
                else
                  Stack(
                    children: [
                      SizedBox(
                        height: context.height - (_secondContainerHeight ?? 0),
                        // ✅ التبديل الذكي بين الخريطتين
                        child: Platform.isIOS
                            ? _buildAppleMapWidget()
                            : _buildMapboxWidget(),
                      ),
                    ],
                  ),

                // لودر العمليات
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: controller.isLoading
                        ? CircularProgressIndicator(color: MyColor.getPrimaryColor())
                        : const SizedBox.shrink(),
                  ),
                ),

                // زر الرجوع
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

  // --- 🍎 ودجت خرائط أبل (محسنة) ---
  Widget _buildAppleMapWidget() {
    return ap.AppleMap(
      initialCameraPosition: const ap.CameraPosition(
        target: ap.LatLng(33.312805, 44.361488), // موقع افتراضي (بغداد)
        zoom: 12,
      ),
      onMapCreated: _onAppleMapCreated,
      annotations: appleAnnotations,
      myLocationEnabled: true, // تفعيل النقطة الزرقاء
      myLocationButtonEnabled: false,
      mapType: ap.MapType.standard,
      // لا نحتاج onCameraIdle لتحديث الدبابيس، لأننا نحدثها من الكنترولر مباشرة
    );
  }

  // --- 🤖 ودجت خرائط ماب بوكس (كود الحلم) ---
  Widget _buildMapboxWidget() {
    return mb.MapWidget(
      styleUri: mb.MapboxStyles.MAPBOX_STREETS,
      cameraOptions: mb.CameraOptions(
        center: mb.Point(coordinates: mb.Position(44.361488, 33.312805)),
        zoom: 10.0,
      ),
      onMapCreated: _onMapboxCreated,
      onStyleLoadedListener: _onMapboxStyleLoaded,
      // ⚠️ أزلنا onCameraChangeListener لتحديث الدبابيس
      // هذا هو الذي كان يسبب الكراش والبطء
    );
  }

  // ---------------------------------------------
  // 📋 القائمة السفلية (Bottom Sheet)
  // ---------------------------------------------
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

            // --- نتائج البحث ---
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
                        await controller.getLangAndLatFromMap(item).whenComplete(() {
                          controller.pickLocation();
                          controller.updateSelectedAddressFromSearch(item.description ?? '');

                          double lat = controller.selectedLocationIndex == 0
                              ? controller.pickupLatlong.latitude
                              : controller.destinationLatlong.latitude;
                          double lng = controller.selectedLocationIndex == 0
                              ? controller.pickupLatlong.longitude
                              : controller.destinationLatlong.longitude;

                          if (lat != 0 && lng != 0) {
                            // ✅ تحريك الكاميرا إلى النقطة المختارة
                            _moveCameraTo(lat, lng);

                            // ✅ تحديث الدبابيس صراحةً (لأننا أزلنا التحديث التلقائي)
                            _updateMapMarkers(controller);
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

// كلاس مساعد للنقر في ماب بوكس
class AnnotationClickListener extends mb.OnPointAnnotationClickListener {
  final Function(mb.PointAnnotation) onAnnotationClick;
  AnnotationClickListener({required this.onAnnotationClick});

  @override
  void onPointAnnotationClick(mb.PointAnnotation annotation) {
    onAnnotationClick(annotation);
  }
}