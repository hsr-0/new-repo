import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as ap;
import 'package:geolocator/geolocator.dart' as geo;

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as ll;
import 'package:cosmetic_store/taxi/lib/core/utils/my_color.dart';
import 'package:cosmetic_store/taxi/lib/data/model/location/selected_location_info.dart';
import 'package:cosmetic_store/taxi/lib/presentation/packages/polyline_animation/polyline_animation_v1.dart';

import '../../model/location/prediction.dart';
import '../../repo/location/location_search_repo.dart';
import '../home/home_controller.dart';

class SelectLocationController extends GetxController {
  final LocationSearchRepo locationSearchRepo;

  // ✅ تعديل 1: أزلنا final من Index الافتراضي لكي نتمكن من السيطرة عليه بالكامل
  int initialIndex;

  // ✅ تعديل 2: أنشأنا متغير محلي يحفظ الفهرس النشط ولن يتغير أبداً بسبب النظام
  int _activeLocationIndex = 0;

  SelectLocationController({
    required this.locationSearchRepo,
    required int selectedLocationIndex, // استقبلناه كمتغير عادي
  }) : initialIndex = selectedLocationIndex {
    // تعيين المتغير المحلي للقيمة الأولية مرة واحدة فقط عند البداية
    _activeLocationIndex = selectedLocationIndex;
  }

  // ✅ تعديل 3: استخدام Getter لضمان الحصول دائماً على الفهرس الصحيح والمحفوظ
  int get selectedLocationIndex => _activeLocationIndex;

  // ===========================================================================
  // متغيرات حفظ المسافة والوقت
  // ===========================================================================
  double tripDistance = 0.0;
  double tripDuration = 0.0;

  ml.MapLibreMapController? mapLibreController;
  ap.AppleMapController? appleController;
  Set<ap.Polyline> applePolylines = {};

  Timer? _idleIgnoreTimer;
  bool ignoreCameraIdle = false;

  void pauseCameraIdle() {
    ignoreCameraIdle = true;
    _idleIgnoreTimer?.cancel();
    _idleIgnoreTimer = Timer(const Duration(milliseconds: 2000), () {
      ignoreCameraIdle = false;
    });
  }

  void setMapLibreController(ml.MapLibreMapController map) {
    if (Platform.isIOS) return;
    mapLibreController = map;
  }

  void setAppleController(ap.AppleMapController controller) {
    appleController = controller;
  }

  // ✅ تعديل 4: دالة التغيير أصبحت تعدل المتغير المحلي المحمي
  void changeIndex(int i) {
    _activeLocationIndex = i;
    update();
  }

  ll.LatLng pickupLatlong = const ll.LatLng(0, 0);
  ll.LatLng destinationLatlong = const ll.LatLng(0, 0);

  geo.Position? currentPosition;
  final currentAddress = "".obs;
  double selectedLatitude = 0.0;
  double selectedLongitude = 0.0;

  bool isLoading = false;
  bool isLoadingFirstTime = false;

  final HomeController homeController = Get.find();
  final TextEditingController searchLocationController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  final TextEditingController pickUpController = TextEditingController();

  final PolylineAnimator animator = PolylineAnimator();
  List<ll.LatLng> polylineCoordinates = [];

  bool isSearched = false;
  List<Prediction> allPredictions = [];
  String selectedAddressFromSearch = '';

  void clearTextFiled(int index) {
    if (index == 0) {
      pickUpController.text = '';
      pickupLatlong = const ll.LatLng(0, 0);
    } else {
      destinationController.text = '';
      destinationLatlong = const ll.LatLng(0, 0);
    }
    clearPolylines();
    update();
  }

  void clearPolylines() {
    polylineCoordinates.clear();
    applePolylines.clear();
    animator.clearPolylines(mapLibreController);
    update();
  }

  void initialize() async {
    // ✅ نضمن أن الفهرس النشط هو نفسه الذي فُتحت به الشاشة في البداية
    _activeLocationIndex = initialIndex;

    if (homeController.selectedLocations.isNotEmpty) {
      final pickupInfo = homeController.getSelectedLocationInfoAtIndex(0);
      if (pickupInfo != null) {
        pickupLatlong = ll.LatLng(pickupInfo.latitude ?? 0, pickupInfo.longitude ?? 0);
        pickUpController.text = pickupInfo.getFullAddress(showFull: true);
      }

      if (homeController.selectedLocations.length > 1) {
        final destInfo = homeController.getSelectedLocationInfoAtIndex(1);
        if (destInfo != null) {
          destinationLatlong = ll.LatLng(destInfo.latitude ?? 0, destInfo.longitude ?? 0);
          destinationController.text = destInfo.getFullAddress(showFull: true);
        }
        await _generateRoutePolyline(fitBounds: true);
      }
    }

    if (homeController.selectedLocations.length < 2) {
      await getCurrentPosition(isLoading1stTime: true, pickupLocationForIndex: _activeLocationIndex);
    }
  }

  Future<void> searchYourAddress({required String locationName, void Function()? onSuccessCallback}) async {
    if (locationName.trim().isEmpty) {
      allPredictions.clear();
      update();
      return;
    }
    isSearched = true;
    update();

    try {
      final response = await locationSearchRepo.searchAddressByLocationName(
        text: locationName,
        position: currentPosition,
      );

      List<Prediction> finalResults = [];
      if (response != null && response['features'] != null) {
        List features = response['features'];
        for (var item in features) {
          String placeName = item['place_name'] ?? item['text'] ?? "مكان غير معروف";
          String description = item['description'] ?? placeName;
          double lat = 0.0, lng = 0.0;

          if (item['geometry'] != null && item['geometry']['coordinates'] != null) {
            var coords = item['geometry']['coordinates'];
            lng = double.tryParse(coords[0].toString()) ?? 0.0;
            lat = double.tryParse(coords[1].toString()) ?? 0.0;
          } else if (item['center'] != null) {
            var coords = item['center'];
            lng = double.tryParse(coords[0].toString()) ?? 0.0;
            lat = double.tryParse(coords[1].toString()) ?? 0.0;
          }

          if (lat != 0 && lng != 0) {
            finalResults.add(Prediction(description: description, placeId: item['id'].toString(), lat: lat, lng: lng));
          }
        }
      }
      allPredictions = finalResults;
      if (onSuccessCallback != null) onSuccessCallback();
    } catch (e) {
      print('🔴 Search Error: $e');
    } finally {
      isSearched = false;
      update();
    }
  }

  Future<void> openMap(double latitude, double longitude, {bool isMapDrag = false}) async {
    try {
      isLoading = true;
      update();

      String? address = await locationSearchRepo.getActualAddress(latitude, longitude);
      if (address == null || address.isEmpty) address = "موقع محدد في الخريطة";

      currentAddress.value = address;

      // ✅ استخدام المتغير المحلي الموثوق
      if (_activeLocationIndex == 0) {
        pickUpController.text = address;
        pickupLatlong = ll.LatLng(latitude, longitude);
      } else {
        destinationController.text = address;
        destinationLatlong = ll.LatLng(latitude, longitude);
      }

      homeController.addLocationAtIndex(
        SelectedLocationInfo(latitude: latitude, longitude: longitude, fullAddress: address),
        _activeLocationIndex,
      );

      if (pickupLatlong.latitude != 0 && destinationLatlong.latitude != 0) {
        await _generateRoutePolyline(fitBounds: !isMapDrag);
      } else {
        clearPolylines();
      }
    } catch (e) {
      print("🔴 Error in openMap: $e");
    } finally {
      isLoading = false;
      update();
    }
  }

  void updateSelectedAddressFromSearch(String address) {
    selectedAddressFromSearch = address;
    update();
  }

  Future<ll.LatLng?> getLangAndLatFromMap(Prediction prediction) async {
    try {
      final lat = double.tryParse(prediction.lat.toString()) ?? 0.0;
      final lng = double.tryParse(prediction.lng.toString()) ?? 0.0;
      if (lat == 0.0 || lng == 0.0) return null;

      changeCurrentLatLongBasedOnCameraMove(lat, lng);
      animateMapCameraPosition();

      allPredictions = [];
      update();
      return ll.LatLng(lat, lng);
    } catch (e) {
      return null;
    }
  }

  Future<void> _generateRoutePolyline({bool fitBounds = false}) async {
    if (pickupLatlong.latitude == 0 || destinationLatlong.latitude == 0) return;

    final points = await getPolylinePoints();
    if (points.isEmpty) return;

    polylineCoordinates = points;

    animator.clearPolylines(mapLibreController);

    // 🔥 إعادة تشغيل الأنيميشن (المسار العصري)
    if (Platform.isIOS) {
      animator.animatePolyline(
          points,
          'main_route',
          Colors.blueAccent, // لون الخط المتحرك
          MyColor.getPrimaryColor(), // لون الخط الخلفي الثابت
          null,
          onUpdateApple: (p) {
            applePolylines = p;
            update();
          }
      );
    } else {
      animator.animatePolyline(
          points,
          'main_route',
          Colors.yellow, // لون الخط المتحرك
          MyColor.getPrimaryColor(), // لون الخط الخلفي الثابت
          mapLibreController
      );
    }

    if (fitBounds) fitPolylineBounds(points);
  }

  Future<List<ll.LatLng>> getPolylinePoints() async {
    List<ll.LatLng> points = [];

    try {
      final String url = 'https://router.project-osrm.org/route/v1/driving/'
          '${pickupLatlong.longitude},${pickupLatlong.latitude};'
          '${destinationLatlong.longitude},${destinationLatlong.latitude}'
          '?geometries=geojson&overview=full&steps=true';

      print("🚀 [OSRM API] جاري طلب المسار المجاني...");

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {

          final List coordinates = data['routes'][0]['geometry']['coordinates'];
          points = coordinates.map((coord) => ll.LatLng(coord[1].toDouble(), coord[0].toDouble())).toList();

          double meters = double.tryParse(data['routes'][0]['distance'].toString()) ?? 0.0;
          tripDistance = meters / 1000;

          double seconds = double.tryParse(data['routes'][0]['duration'].toString()) ?? 0.0;
          tripDuration = seconds / 60;

        } else {
          print("⚠️ [OSRM] السيرفر لم يجد طريقاً بين هاتين النقطتين.");
        }
      } else {
        print("🔥 [OSRM Error] كود الخطأ: ${response.statusCode}");
      }
    } catch (e) {
      print("🔴 Route Error Exception: $e");
    }
    return points;
  }

  void fitPolylineBounds(List<ll.LatLng> coords) {
    if (coords.isEmpty) return;
    pauseCameraIdle();

    double minLat = 90.0, maxLat = -90.0;
    double minLng = 180.0, maxLng = -180.0;

    for (var point in coords) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    if (Platform.isIOS && appleController != null) {
      appleController!.animateCamera(ap.CameraUpdate.newLatLngBounds(
        ap.LatLngBounds(southwest: ap.LatLng(minLat, minLng), northeast: ap.LatLng(maxLat, maxLng)),
        50.0,
      ));
    } else if (!Platform.isIOS && mapLibreController != null) {
      mapLibreController!.animateCamera(ml.CameraUpdate.newLatLngBounds(
        ml.LatLngBounds(southwest: ml.LatLng(minLat, minLng), northeast: ml.LatLng(maxLat, maxLng)),
        left: 50, top: 100, right: 50, bottom: 300,
      ));
    }
  }

  Future<bool> handleLocationPermission() async {
    bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await geo.Geolocator.openLocationSettings();
      return false;
    }
    geo.LocationPermission permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
    }
    return permission == geo.LocationPermission.always || permission == geo.LocationPermission.whileInUse;
  }

  Future<void> getCurrentPosition({bool isLoading1stTime = false, int pickupLocationForIndex = -1, bool isFromEdit = false}) async {
    isLoadingFirstTime = isLoading1stTime;
    isLoading = true;
    update();
    final hasPermission = await handleLocationPermission();
    if (!hasPermission) { _endLoading(); return; }

    currentPosition = await geo.Geolocator.getCurrentPosition(desiredAccuracy: geo.LocationAccuracy.high);

    if (currentPosition != null) {
      changeCurrentLatLongBasedOnCameraMove(currentPosition!.latitude, currentPosition!.longitude);
      animateMapCameraPosition(isFromEdit: isFromEdit);
    }
    _endLoading();
  }

  void _endLoading() { isLoading = false; isLoadingFirstTime = false; update(); }

  Future<void> pickLocation({bool isMapDrag = false}) async {
    await openMap(selectedLatitude, selectedLongitude, isMapDrag: isMapDrag);
  }

  void changeCurrentLatLongBasedOnCameraMove(double latitude, double longitude) {
    selectedLatitude = latitude;
    selectedLongitude = longitude;
    update();
  }

  void animateMapCameraPosition({bool isFromEdit = false}) {
    if (selectedLatitude == 0) return;
    pauseCameraIdle();

    if (Platform.isIOS && appleController != null) {
      appleController!.animateCamera(ap.CameraUpdate.newLatLng(ap.LatLng(selectedLatitude, selectedLongitude)));
    } else if (!Platform.isIOS && mapLibreController != null) {
      mapLibreController!.animateCamera(ml.CameraUpdate.newLatLngZoom(
          ml.LatLng(selectedLatitude, selectedLongitude), 17.5
      ));
    }
  }

  @override
  void onClose() {
    animator.clearPolylines(mapLibreController);
    searchLocationController.dispose();
    destinationController.dispose();
    pickUpController.dispose();
    super.onClose();
  }
}