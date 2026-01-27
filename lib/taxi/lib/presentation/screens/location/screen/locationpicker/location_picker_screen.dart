import 'dart:async'; // ✅ للتايمر (Debounce)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ✅ حل تعارض الأسماء: سمينا مكتبة المواقع geo
import 'package:geolocator/geolocator.dart' as geo;
import 'package:get/get.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
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
  // متغيرات Mapbox
  MapboxMap? mapboxMap;
  PointAnnotationManager? pointAnnotationManager;

  // ✅ أدوات الحماية من الكراش والتكرار
  Timer? _debounceTimer;
  bool isMapReady = false;

  String? pickupAnnotationId;
  String? destinationAnnotationId;

  final GlobalKey _secondContainerKey = GlobalKey();
  double? _secondContainerHeight;
  TextEditingController searchLocationController = TextEditingController(text: '');
  int index = 0;

  Uint8List? pickUpIcon;
  Uint8List? destinationIcon;

  bool isSearching = false;
  bool isFirsTime = true;

  final myDeBouncer = MyDeBouncer(delay: const Duration(milliseconds: 600));

  @override
  void initState() {
    index = widget.pickupLocationForIndex;
    super.initState();
    print("🟢 [InitState] Start Location Picker Screen");

    // إعداد الكنترولر
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
    });
  }

  @override
  void dispose() {
    // ✅ تنظيف التايمر عند الخروج لمنع تسريب الذاكرة
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> loadMarkerImages() async {
    try {
      searchLocationController.text = '';
      pickUpIcon = await Helper.getBytesFromAsset(MyIcons.mapMarkerPickUpIcon, 120);
      destinationIcon = await Helper.getBytesFromAsset(MyIcons.mapMarkerIcon, 120);
      setState(() {});
    } catch (e) {
      print("🔴 [Error] Failed to load marker images: $e");
    }
  }

  // ✅ يتم الاستدعاء عند إنشاء الخريطة
  _onMapCreated(MapboxMap mapboxMap) {
    this.mapboxMap = mapboxMap;
    Get.find<SelectLocationController>().setMapController(mapboxMap);
  }

  // ✅ يتم الاستدعاء عندما يكتمل تحميل الستايل (الخريطة جاهزة)
  _onStyleLoaded(StyleLoadedEventData data) async {
    print("🟢 [Map] Style Loaded - Map Ready");
    isMapReady = true;

    try {
      pointAnnotationManager = await mapboxMap!.annotations.createPointAnnotationManager();

      // إعداد النقر على الدبابيس
      pointAnnotationManager?.addOnPointAnnotationClickListener(AnnotationClickListener(
        onAnnotationClick: (annotation) {
          if (annotation.id == pickupAnnotationId) {
            Get.toNamed(RouteHelper.editLocationPickUpScreen, arguments: 0);
          } else if (annotation.id == destinationAnnotationId) {
            Get.toNamed(RouteHelper.editLocationPickUpScreen, arguments: 1);
          }
        },
      ));

      // 📍 أهم خطوة: جلب موقع المستخدم الحقيقي في الخلفية
      await _getCurrentLocation();

      // تحديث الدبابيس (إذا كانت موجودة مسبقاً)
      _updateMapMarkers(Get.find<SelectLocationController>());

    } catch (e) {
      print("🔴 [Error] Annotation Manager Error: $e");
    }
  }

  // ✅ دالة جلب الموقع الحقيقي (GPS)
  Future<void> _getCurrentLocation() async {
    try {
      // 1. التحقق من الصلاحيات
      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }

      if (permission == geo.LocationPermission.whileInUse || permission == geo.LocationPermission.always) {
        // 2. جلب الموقع بدقة عالية
        geo.Position position = await geo.Geolocator.getCurrentPosition(desiredAccuracy: geo.LocationAccuracy.high);

        print("📍 [GPS] Found Location: ${position.latitude}, ${position.longitude}");

        // 3. تحريك الكاميرا لموقع المستخدم
        if (mapboxMap != null) {
          mapboxMap!.flyTo(
            CameraOptions(
              // نستخدم Position الخاصة بـ Mapbox هنا
              center: Point(coordinates: Position(position.longitude, position.latitude)),
              zoom: 15.0,
            ),
            MapAnimationOptions(duration: 1000), // أنيميشن سلس لمدة ثانية
          );
        }
      }
    } catch (e) {
      print("❌ Error getting GPS location: $e");
    }
  }

  // ✅ مستمع حركة الكاميرا (Debounce لمنع التكرار والكراش)
  _onCameraChangeListener(CameraChangedEventData data) {
    // إلغاء التايمر القديم إذا تحركت الكاميرا مرة أخرى
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    // انتظار نصف ثانية بعد توقف الحركة
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if(isMapReady) {
        // تحديث الدبابيس فقط عندما يتوقف المستخدم
        _updateMapMarkers(Get.find<SelectLocationController>());
      }
    });
  }

  // ✅ دالة تحديث الدبابيس (محمية)
  Future<void> _updateMapMarkers(SelectLocationController controller) async {
    // شرط الحماية: لا تفعل شيئاً إذا لم تكن الخريطة جاهزة
    if (!isMapReady || pointAnnotationManager == null || mapboxMap == null) {
      return;
    }

    try {
      await pointAnnotationManager!.deleteAll();
      pickupAnnotationId = null;
      destinationAnnotationId = null;

      // رسم دبوس الانطلاق
      if (controller.pickupLatlong.latitude != 0 && pickUpIcon != null) {
        var options = PointAnnotationOptions(
          geometry: Point(coordinates: Position(
            controller.pickupLatlong.longitude,
            controller.pickupLatlong.latitude,
          )),
          image: pickUpIcon!,
          iconSize: 1.0,
        );
        var annotation = await pointAnnotationManager!.create(options);
        pickupAnnotationId = annotation.id;
      }

      // رسم دبوس الوجهة
      if (controller.destinationLatlong.latitude != 0 && destinationIcon != null) {
        var options = PointAnnotationOptions(
          geometry: Point(coordinates: Position(
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

  void _moveCameraTo(double lat, double lng) {
    if (mapboxMap != null && isMapReady) {
      mapboxMap!.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(lng, lat)),
          zoom: 16.0,
        ),
        MapAnimationOptions(duration: 800),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegionWidget(
      statusBarColor: MyColor.transparentColor,
      child: GetBuilder<SelectLocationController>(
        builder: (controller) {

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if(isMapReady) _updateMapMarkers(controller);
          });

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
                        child: MapWidget(
                          styleUri: MapboxStyles.MAPBOX_STREETS,
                          cameraOptions: CameraOptions(
                            // ⚠️ موقع افتراضي أولي فقط (بغداد) حتى يعمل الـ GPS
                            center: Point(coordinates: Position(44.361488, 33.312805)),
                            zoom: 10.0,
                          ),
                          onMapCreated: _onMapCreated,
                          // ✅ تمرير المستمعين هنا لمنع الكراش
                          onStyleLoadedListener: _onStyleLoaded,
                          onCameraChangeListener: _onCameraChangeListener,
                        ),
                      ),
                    ],
                  ),

                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: controller.isLoading
                        ? CircularProgressIndicator(color: MyColor.getPrimaryColor())
                        : const SizedBox.shrink(),
                  ),
                ),

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

class AnnotationClickListener extends OnPointAnnotationClickListener {
  final Function(PointAnnotation) onAnnotationClick;
  AnnotationClickListener({required this.onAnnotationClick});

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    onAnnotationClick(annotation);
  }
}
