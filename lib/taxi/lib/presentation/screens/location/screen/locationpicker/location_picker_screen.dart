import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
// ✅ مكتبة Mapbox الرسمية
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

// ✅ استيراد ملف الراوت لنستخدمه عند النقر
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
  // ✅ متحكمات Mapbox
  MapboxMap? mapboxMap;
  PointAnnotationManager? pointAnnotationManager;

  // متغيرات لحفظ IDs الخاصة بالدبابيس لتمييزها عند النقر
  String? pickupAnnotationId;
  String? destinationAnnotationId;

  final GlobalKey _secondContainerKey = GlobalKey();
  double? _secondContainerHeight;
  TextEditingController searchLocationController = TextEditingController(text: '');
  int index = 0;

  // صور الدبابيس
  Uint8List? pickUpIcon;
  Uint8List? destinationIcon;

  bool isSearching = false;
  bool isFirsTime = true;

  // لمنع تكرار البحث (Debouncer)
  final myDeBouncer = MyDeBouncer(delay: const Duration(milliseconds: 600));

  @override
  void initState() {
    index = widget.pickupLocationForIndex;
    super.initState();
    print("🟢 [InitState] تم بدء تشغيل شاشة اختيار الموقع.");

    // حقن الريبو والكنترولر
    Get.put(LocationSearchRepo(apiClient: Get.find()));
    var controller = Get.put(
      SelectLocationController(locationSearchRepo: Get.find(), selectedLocationIndex: index),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print("🟡 [UI] جاري حساب أبعاد الشاشة...");
      final RenderBox box = _secondContainerKey.currentContext?.findRenderObject() as RenderBox;
      final double height = box.size.height;
      setState(() => _secondContainerHeight = height);

      await loadMarkerImages();
      controller.initialize();
    });
  }

  // ✅ تحميل الصور مع طباعة الأخطاء
  Future<void> loadMarkerImages() async {
    try {
      print("🟡 [Markers] جاري تحميل صور الدبابيس من Assets...");
      searchLocationController.text = '';
      // حجم الأيقونة 120 مناسب للأداء
      pickUpIcon = await Helper.getBytesFromAsset(MyIcons.mapMarkerPickUpIcon, 120);
      destinationIcon = await Helper.getBytesFromAsset(MyIcons.mapMarkerIcon, 120);
      print("🟢 [Markers] تم تحميل الصور بنجاح.");
      setState(() {});
    } catch (e) {
      print("🔴 [Error] خطأ في تحميل صور الدبابيس: $e");
    }
  }

  // ✅ إنشاء الخريطة وإعداد النقر
  _onMapCreated(MapboxMap mapboxMap) async {
    print("🟢 [Map] تم إنشاء الخريطة بنجاح.");
    this.mapboxMap = mapboxMap;

    // ربط الخريطة بالكنترولر (مهم جداً للتحكم بها لاحقاً)
    Get.find<SelectLocationController>().setMapController(mapboxMap);

    try {
      // 1. إنشاء مدير العلامات
      pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
      print("🟢 [Map] تم إنشاء مدير العلامات (Annotation Manager).");

      // 2. تفعيل الاستماع للنقر
      pointAnnotationManager?.addOnPointAnnotationClickListener(AnnotationClickListener(
        onAnnotationClick: (annotation) {
          print("👆 [Click] تم الضغط على الدبوس ID: ${annotation.id}");

          if (annotation.id == pickupAnnotationId) {
            print("🚀 [Nav] الانتقال لتعديل نقطة الانطلاق.");
            // الانتقال للشاشة التي عدلناها قبل قليل (EditLocationPickerScreen)
            Get.toNamed(RouteHelper.editLocationPickUpScreen, arguments: 0);
          } else if (annotation.id == destinationAnnotationId) {
            print("🚀 [Nav] الانتقال لتعديل الوجهة.");
            Get.toNamed(RouteHelper.editLocationPickUpScreen, arguments: 1);
          } else {
            print("🟡 [Click] تم ضغط دبوس غير معروف.");
          }
        },
      ));

      // 3. رسم الدبابيس الأولية
      _updateMapMarkers(Get.find<SelectLocationController>());

    } catch (e) {
      print("🔴 [Error] خطأ أثناء إعداد الخريطة: $e");
    }
  }

  // ✅ تحديث الدبابيس على الخريطة
  Future<void> _updateMapMarkers(SelectLocationController controller) async {
    if (pointAnnotationManager == null || mapboxMap == null) {
      print("🟡 [Markers] الخريطة غير جاهزة بعد، تم تخطي التحديث.");
      return;
    }

    try {
      // حذف الدبابيس القديمة
      await pointAnnotationManager!.deleteAll();
      pickupAnnotationId = null;
      destinationAnnotationId = null;
      print("🗑️ [Markers] تم حذف الدبابيس القديمة.");

      // 1. رسم دبوس الانطلاق (Pickup)
      if (controller.pickupLatlong.latitude != 0 && pickUpIcon != null) {
        print("📍 [Markers] جاري رسم دبوس الانطلاق...");
        var options = PointAnnotationOptions(
          geometry: Point(coordinates: Position(
            controller.pickupLatlong.longitude, // Longitude
            controller.pickupLatlong.latitude,  // Latitude
          )),
          image: pickUpIcon!,
          iconSize: 1.0,
        );
        var annotation = await pointAnnotationManager!.create(options);
        pickupAnnotationId = annotation.id;
      }

      // 2. رسم دبوس الوجهة (Destination)
      if (controller.destinationLatlong.latitude != 0 && destinationIcon != null) {
        print("📍 [Markers] جاري رسم دبوس الوجهة...");
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
      print("🔴 [Error] خطأ أثناء تحديث الدبابيس: $e");
    }
  }

  // ✅ تحريك الكاميرا (FlyTo)
  void _moveCameraTo(double lat, double lng) {
    if (mapboxMap != null) {
      print("📷 [Camera] تحريك الكاميرا إلى: $lat, $lng");
      mapboxMap!.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(lng, lat)),
          zoom: 16.0,
        ),
        MapAnimationOptions(duration: 800),
      );
    } else {
      print("🔴 [Error] متحكم الخريطة فارغ (null)!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegionWidget(
      statusBarColor: MyColor.transparentColor,
      child: GetBuilder<SelectLocationController>(
        builder: (controller) {

          // تحديث العلامات عند تغير حالة الكنترولر (مثل اختيار موقع جديد)
          WidgetsBinding.instance.addPostFrameCallback((_) {
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
                if (controller.isLoading && controller.isLoadingFirstTime)
                  const SizedBox.expand()
                else
                  Stack(
                    children: [
                      SizedBox(
                        height: context.height - (_secondContainerHeight ?? 0),
                        // ✅ الخريطة الرسمية
                        child: MapWidget(
                          styleUri: MapboxStyles.MAPBOX_STREETS,
                          cameraOptions: CameraOptions(
                            center: Point(coordinates: Position(
                              controller.pickupLatlong.longitude != 0 ? controller.pickupLatlong.longitude : 45.8219,
                              controller.pickupLatlong.latitude != 0 ? controller.pickupLatlong.latitude : 32.5029,
                            )),
                            zoom: 14.0,
                          ),
                          onMapCreated: _onMapCreated,
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

  // ✅ بناء الـ Bottom Sheet (حقول البحث والقائمة)
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
                        // -------------------------
                        // ✅ حقل نقطة الانطلاق
                        // -------------------------
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
                            print("🔎 [Search] البحث عن الانطلاق: $text");
                            if (isFirsTime == true) {
                              isFirsTime = false;
                              setState(() {});
                            }
                            // ✅ الاستدعاء الضروري لعمل البحث
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
                        // -------------------------
                        // ✅ حقل الوجهة
                        // -------------------------
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
                            print("🔎 [Search] البحث عن الوجهة: $text");
                            if (isFirsTime == true) {
                              isFirsTime = false;
                              setState(() {});
                            }
                            // ✅ الاستدعاء الضروري لعمل البحث
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
            // عرض قائمة النتائج إذا كان هناك بحث
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
                        print("👆 [List] تم اختيار الموقع: ${item.description}");

                        // جلب الإحداثيات وحفظها
                        await controller.getLangAndLatFromMap(item).whenComplete(() {
                          controller.pickLocation();
                          controller.updateSelectedAddressFromSearch(item.description ?? '');

                          // تحريك الكاميرا إلى الموقع المختار
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
                print("✅ [Button] تم تأكيد الموقع.");
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

// ✅ كلاس المستمع للنقر (ضروري جداً لكي يعمل النقر على الدبوس)
class AnnotationClickListener extends OnPointAnnotationClickListener {
  final Function(PointAnnotation) onAnnotationClick;
  AnnotationClickListener({required this.onAnnotationClick});

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    onAnnotationClick(annotation);
  }
}