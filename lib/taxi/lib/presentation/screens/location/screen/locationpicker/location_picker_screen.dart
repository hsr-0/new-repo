import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// مكتبات الخرائط
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as ap;
import 'package:geolocator/geolocator.dart' as geo;
import 'package:latlong2/latlong.dart' as ll;

import 'package:get/get.dart';
import 'package:cosmetic_store/taxi/lib/core/route/route.dart';
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

import '../../../../../core/utils/dimensions.dart';
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
  ml.MapLibreMapController? mapLibreController;
  ap.AppleMapController? appleController;
  Set<ap.Annotation> appleAnnotations = {};

  bool isMapReady = false;

  // ✅ متغير لمنع التحديث المتكرر للعلامات (مهم جداً لمنع التجميد على iOS)
  bool _markersUpdated = false;

  ap.BitmapDescriptor? pickUpIconApple;
  ap.BitmapDescriptor? destinationIconApple;

  ml.Symbol? pickupSymbol;
  ml.Symbol? destSymbol;

  final GlobalKey _secondContainerKey = GlobalKey();
  double? _secondContainerHeight;
  int index = 0;

  bool isFirstTime = true;

  final myDeBouncer = MyDeBouncer(delay: const Duration(milliseconds: 600));

  final double defaultLat = 32.5056;
  final double defaultLng = 45.8247;

  @override
  void initState() {
    index = widget.pickupLocationForIndex;
    super.initState();

    Get.put(LocationSearchRepo(apiClient: Get.find()));
    Get.put(SelectLocationController(locationSearchRepo: Get.find(), selectedLocationIndex: index));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // ✅ تحقق من mounted قبل أي setState
      if (!mounted) return;

      final RenderBox? box = _secondContainerKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && mounted) {
        setState(() => _secondContainerHeight = box.size.height);
      }

      await _loadMarkerImagesIOS();
      if (mounted) {
        Get.find<SelectLocationController>().initialize();
        _getCurrentLocation();
      }
    });
  }

  @override
  void dispose() {
    // ✅ تنظيف المستمعات لمنع الكراش
    if (mapLibreController != null) {
      mapLibreController!.onSymbolTapped.remove(_onSymbolTapped);
    }
    // ✅ إلغاء أي كاميرا متحركة
    if (Platform.isIOS && appleController != null) {
      appleController = null;
    }
    if (!Platform.isIOS && mapLibreController != null) {
      mapLibreController = null;
    }
    super.dispose();
  }

  Future<void> _loadMarkerImagesIOS() async {
    if (Platform.isIOS) {
      pickUpIconApple = await ap.BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(35, 35)),
          MyIcons.mapMarkerPickUpIcon
      );
      destinationIconApple = await ap.BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(35, 35)),
          MyIcons.mapMarkerIcon
      );
      if (mounted) setState(() {});
    }
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  Future<void> _getCurrentLocation() async {
    geo.LocationPermission permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
    }

    if (permission == geo.LocationPermission.whileInUse || permission == geo.LocationPermission.always) {
      geo.Position position = await geo.Geolocator.getCurrentPosition(desiredAccuracy: geo.LocationAccuracy.high);
      _moveCameraTo(position.latitude, position.longitude);

      final controller = Get.find<SelectLocationController>();
      if (controller.selectedLocationIndex == 0 && controller.pickUpController.text.isEmpty) {
        controller.selectedLatitude = position.latitude;
        controller.selectedLongitude = position.longitude;
        controller.openMap(position.latitude, position.longitude, isMapDrag: false);
      }
    }
  }

  void _moveCameraTo(double lat, double lng) {
    Get.find<SelectLocationController>().pauseCameraIdle();

    if (Platform.isIOS && appleController != null) {
      appleController!.animateCamera(ap.CameraUpdate.newLatLngZoom(ap.LatLng(lat, lng), 17.5));
    } else if (!Platform.isIOS && mapLibreController != null) {
      mapLibreController!.animateCamera(ml.CameraUpdate.newLatLngZoom(ml.LatLng(lat, lng), 17.5));
    }
  }

  // ✅ دالة التحديث الجديدة لتوجيه الخريطة للموقع بعد العودة
  void _refreshMapAfterEdit(int index) {
    if (!mounted) return;

    final controller = Get.find<SelectLocationController>();
    if (index == 0 && controller.pickupLatlong.latitude != 0) {
      _moveCameraTo(controller.pickupLatlong.latitude, controller.pickupLatlong.longitude);
    } else if (index == 1 && controller.destinationLatlong.latitude != 0) {
      _moveCameraTo(controller.destinationLatlong.latitude, controller.destinationLatlong.longitude);
    }

    // ✅ إعادة تعيين علم التحديث للسماح بالتحديث مرة أخرى
    _markersUpdated = false;

    _updateStaticMarkers(controller);
    controller.update();
  }

  // ✅ الانتظار حتى عودة الزبون لتحديث الخريطة
  void _onSymbolTapped(ml.Symbol symbol) async {
    if (!mounted) return;

    if (symbol.id == pickupSymbol?.id) {
      final result = await Get.toNamed(RouteHelper.editLocationPickUpScreen, arguments: 0);
      if (result != null && mounted) _refreshMapAfterEdit(0);
    } else if (symbol.id == destSymbol?.id) {
      final result = await Get.toNamed(RouteHelper.editLocationPickUpScreen, arguments: 1);
      if (result != null && mounted) _refreshMapAfterEdit(1);
    }
  }

  Future<void> _updateStaticMarkers(SelectLocationController controller) async {
    if (!isMapReady || !mounted) return;

    if (Platform.isIOS && appleController != null) {
      Set<ap.Annotation> annotations = {};

      // ✅ إضافة علامة الانطلاق
      if (controller.pickupLatlong.latitude != 0) {
        annotations.add(ap.Annotation(
          annotationId:  ap.AnnotationId('pickup'),
          position: ap.LatLng(controller.pickupLatlong.latitude, controller.pickupLatlong.longitude),
          icon: pickUpIconApple ?? ap.BitmapDescriptor.defaultAnnotation,
          onTap: () async {
            if (!mounted) return;
            try {
              final result = await Get.toNamed(RouteHelper.editLocationPickUpScreen, arguments: 0);
              if (result != null && mounted) _refreshMapAfterEdit(0);
            } catch (e) {
              print('❌ Pickup annotation tap error: $e');
            }
          },
        ));
      }

      // ✅ إضافة علامة الوجهة
      if (controller.destinationLatlong.latitude != 0) {
        annotations.add(ap.Annotation(
          annotationId:  ap.AnnotationId('destination'),
          position: ap.LatLng(controller.destinationLatlong.latitude, controller.destinationLatlong.longitude),
          icon: destinationIconApple ?? ap.BitmapDescriptor.defaultAnnotation,
          onTap: () async {
            if (!mounted) return;
            try {
              final result = await Get.toNamed(RouteHelper.editLocationPickUpScreen, arguments: 1);
              if (result != null && mounted) _refreshMapAfterEdit(1);
            } catch (e) {
              print('❌ Destination annotation tap error: $e');
            }
          },
        ));
      }

      // ✅ تحديث العلامات فقط إذا تغيرت (يمنع التحديث المتكرر)
      if (mounted && (appleAnnotations.length != annotations.length ||
          !_annotationsAreEqual(appleAnnotations, annotations))) {
        setState(() => appleAnnotations = annotations);
      }

    } else if (!Platform.isIOS && mapLibreController != null) {
      try {
        await mapLibreController!.clearSymbols();
        pickupSymbol = null;
        destSymbol = null;

        // ✅ إضافة علامة الانطلاق
        if (controller.pickupLatlong.latitude != 0) {
          pickupSymbol = await mapLibreController!.addSymbol(ml.SymbolOptions(
            geometry: ml.LatLng(controller.pickupLatlong.latitude, controller.pickupLatlong.longitude),
            iconImage: "pickup_icon",
            iconSize: 1.0,
          ));
        }

        // ✅ إضافة علامة الوجهة
        if (controller.destinationLatlong.latitude != 0) {
          destSymbol = await mapLibreController!.addSymbol(ml.SymbolOptions(
            geometry: ml.LatLng(controller.destinationLatlong.latitude, controller.destinationLatlong.longitude),
            iconImage: "dest_icon",
            iconSize: 1.0,
          ));
        }
      } catch (e) {
        print('❌ MapLibre Marker Error: $e');
      }
    }
  }

  // ✅ دالة مساعدة لمقارنة العلامات (لتجنب التحديث غير الضروري)
  bool _annotationsAreEqual(Set<ap.Annotation> set1, Set<ap.Annotation> set2) {
    if (set1.length != set2.length) return false;

    for (var annotation in set1) {
      bool found = false;
      for (var other in set2) {
        if (annotation.annotationId.value == other.annotationId.value &&
            annotation.position.latitude == other.position.latitude &&
            annotation.position.longitude == other.position.longitude) {
          found = true;
          break;
        }
      }
      if (!found) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegionWidget(
      statusBarColor: MyColor.transparentColor,
      child: GetBuilder<SelectLocationController>(
        builder: (controller) {
          // ✅ منع التحديث المتكرر للعلامات - مهم جداً لمنع التجميد على iOS
          if (isMapReady && !_markersUpdated && mounted) {
            _updateStaticMarkers(controller);
            _markersUpdated = true;
          }

          return Scaffold(
            extendBody: true,
            extendBodyBehindAppBar: true,
            backgroundColor: MyColor.screenBgColor,
            resizeToAvoidBottomInset: true,
            body: Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  height: context.height - (_secondContainerHeight ?? 0) + 20,
                  child: Platform.isIOS ? _buildAppleMap(controller) : _buildFreeMap(controller),
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
                        style: IconButton.styleFrom(backgroundColor: MyColor.colorWhite, elevation: 2),
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

  Widget _buildFreeMap(SelectLocationController controller) {
    return ml.MapLibreMap(
      styleString: 'https://tiles.openfreemap.org/styles/liberty',
      initialCameraPosition: ml.CameraPosition(target: ml.LatLng(defaultLat, defaultLng), zoom: 17.5),
      onMapCreated: (c) {
        mapLibreController = c;
        controller.setMapLibreController(c);
        mapLibreController!.onSymbolTapped.add(_onSymbolTapped);
      },
      onStyleLoadedCallback: () async {
        isMapReady = true;
        if (!mounted) return;

        try {
          final Uint8List pickupData = await getBytesFromAsset(MyIcons.mapMarkerPickUpIcon, 120);
          await mapLibreController!.addImage("pickup_icon", pickupData);

          final Uint8List destData = await getBytesFromAsset(MyIcons.mapMarkerIcon, 120);
          await mapLibreController!.addImage("dest_icon", destData);
        } catch(e) {
          print('❌ Image Load Error: $e');
        }
        if (mounted) _updateStaticMarkers(controller);
      },
      myLocationEnabled: true,
      myLocationRenderMode: ml.MyLocationRenderMode.normal,
      compassEnabled: false,
    );
  }

  Widget _buildAppleMap(SelectLocationController controller) {
    return ap.AppleMap(
      initialCameraPosition: ap.CameraPosition(target: ap.LatLng(defaultLat, defaultLng), zoom: 17.5),
      onMapCreated: (c) {
        appleController = c;
        controller.setAppleController(c);
        isMapReady = true;
      },
      annotations: appleAnnotations,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, -5),
          )
        ],
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
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.mediumRadius)),
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
                            if (controller.pickupLatlong.latitude != 0) {
                              _moveCameraTo(controller.pickupLatlong.latitude, controller.pickupLatlong.longitude);
                            }
                          },
                          prefixIcon: Padding(
                            padding: const EdgeInsetsDirectional.only(start: Dimensions.space12, end: Dimensions.space2),
                            child: CustomSvgPicture(image: MyIcons.currentLocation, color: MyColor.primaryColor, height: Dimensions.space35),
                          ),
                          onSubmit: () {},
                          onChanged: (text) {
                            if (isFirstTime == true) {
                              isFirstTime = false;
                              if (mounted) setState(() {});
                            }
                            myDeBouncer.run(() { controller.searchYourAddress(locationName: text); });
                          },
                          hintText: MyStrings.pickUpLocation.tr,
                          radius: Dimensions.moreRadius,
                          inputAction: TextInputAction.done,
                          suffixIcon: Padding(
                            padding: const EdgeInsetsDirectional.only(end: Dimensions.space5),
                            child: IconButton(
                              onPressed: () async { controller.clearTextFiled(0); },
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
                            if (controller.destinationLatlong.latitude != 0) {
                              _moveCameraTo(controller.destinationLatlong.latitude, controller.destinationLatlong.longitude);
                            }
                          },
                          onChanged: (text) {
                            if (isFirstTime == true) {
                              isFirstTime = false;
                              if (mounted) setState(() {});
                            }
                            myDeBouncer.run(() { controller.searchYourAddress(locationName: text); });
                          },
                          hintText: MyStrings.pickUpDestination.tr,
                          radius: Dimensions.mediumRadius,
                          prefixIcon: Padding(
                            padding: const EdgeInsetsDirectional.only(start: Dimensions.space12, end: Dimensions.space2),
                            child: CustomSvgPicture(image: MyIcons.location, color: MyColor.primaryColor, height: Dimensions.space35),
                          ),
                          suffixIcon: Padding(
                            padding: const EdgeInsetsDirectional.only(end: Dimensions.space5),
                            child: IconButton(
                              onPressed: () async { controller.clearTextFiled(1); },
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

            spaceDown(Dimensions.space15),

            // 🔥 زر "تحديد الوجهة عبر الخريطة"
            InkWell(
              onTap: () async {
                controller.changeIndex(1);

                final result = await Get.toNamed(RouteHelper.editLocationPickUpScreen, arguments: 1);

                if (result != null && mounted) {
                  _refreshMapAfterEdit(1);
                }
              },
              borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: Dimensions.space12, horizontal: Dimensions.space15),
                decoration: BoxDecoration(
                  color: MyColor.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                  border: Border.all(color: MyColor.primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: MyColor.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.map_outlined, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: Dimensions.space15),
                    Expanded(
                      child: Text(
                        "تحديد الوجهة عبر الخريطة",
                        style: boldDefault.copyWith(color: MyColor.primaryColor, fontSize: 15),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: MyColor.primaryColor),
                  ],
                ),
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
                        MyUtils.closeKeyboard();
                        controller.pauseCameraIdle();

                        ll.LatLng? latLng = await controller.getLangAndLatFromMap(item);
                        if (latLng != null && mounted) {
                          controller.updateSelectedAddressFromSearch(item.description ?? '');
                          _moveCameraTo(latLng.latitude, latLng.longitude);

                          controller.allPredictions = [];
                          controller.update();

                          controller.selectedLatitude = latLng.latitude;
                          controller.selectedLongitude = latLng.longitude;
                          controller.openMap(latLng.latitude, latLng.longitude, isMapDrag: false);
                        }
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsetsDirectional.symmetric(vertical: Dimensions.space15, horizontal: Dimensions.space8),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.mediumRadius)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_rounded, size: Dimensions.space20, color: MyColor.bodyTextColor),
                            spaceSide(Dimensions.space10),
                            Expanded(
                              child: Text("${item.description}", style: regularDefault.copyWith(color: MyColor.colorBlack)),
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
