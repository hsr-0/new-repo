import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

// --- استيراد مكتبات الخرائط ---
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as ap;

import 'package:geolocator/geolocator.dart' as geo;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_color.dart';
import 'package:cosmetic_store/taxi/lib/data/model/location/selected_location_info.dart';
import 'package:cosmetic_store/taxi/lib/environment.dart';

// ✅ تأكد من أن مسار مودل Prediction صحيح
import '../../model/location/prediction.dart';
import '../../repo/location/location_search_repo.dart';
import '../home/home_controller.dart';

class SelectLocationController extends GetxController {
  final LocationSearchRepo locationSearchRepo;
  int selectedLocationIndex;

  SelectLocationController({
    required this.locationSearchRepo,
    required this.selectedLocationIndex,
  });

  // حفظ المسافة والوقت
  double tripDistance = 0.0;
  double tripDuration = 0.0;

  // 🤖 متغيرات Android (MapLibre)
  ml.MaplibreMapController? mapController;

  // 🍎 متغيرات iOS (Apple Maps)
  ap.AppleMapController? appleController;
  Set<ap.Polyline> applePolylines = {};

  // ---------------------------------------------------------------------------

  // إعداد MapLibre (Android)
  void setMapController(ml.MaplibreMapController map) {
    if (Platform.isIOS) return;
    mapController = map;
  }

  // إعداد Apple Maps (iOS)
  void setAppleController(ap.AppleMapController controller) {
    appleController = controller;
  }

  void changeIndex(int i) {
    selectedLocationIndex = i;
    update();
  }

  LatLng pickupLatlong = const LatLng(0, 0);
  LatLng destinationLatlong = const LatLng(0, 0);

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

  List<LatLng> polylineCoordinates = [];
  bool isSearched = false;
  List<Prediction> allPredictions = [];

  void clearTextFiled(int index) {
    if (index == 0) {
      pickUpController.text = '';
    } else {
      destinationController.text = '';
    }
    update();
  }

  void initialize() async {
    if (homeController.selectedLocations.isNotEmpty) {
      final pickupInfo = homeController.getSelectedLocationInfoAtIndex(0);
      if (pickupInfo != null) {
        pickupLatlong = LatLng(pickupInfo.latitude ?? 0, pickupInfo.longitude ?? 0);
        pickUpController.text = pickupInfo.getFullAddress(showFull: true);
      }

      if (homeController.selectedLocations.length > 1) {
        final destInfo = homeController.getSelectedLocationInfoAtIndex(1);
        if (destInfo != null) {
          destinationLatlong = LatLng(destInfo.latitude ?? 0, destInfo.longitude ?? 0);
          destinationController.text = destInfo.getFullAddress(showFull: true);
        }
        await _generateRoutePolyline();
      }
    }

    if (homeController.selectedLocations.length < 2) {
      await getCurrentPosition(isLoading1stTime: true, pickupLocationForIndex: selectedLocationIndex);
    }
  }

  // ===========================================================================
  // ✅ البحث المحدث للسيرفر الخاص
  // ===========================================================================
  Future<void> searchYourAddress({required String locationName}) async {
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
        for (var item in response['features']) {
          var coords = item['geometry']['coordinates'];
          finalResults.add(Prediction(
            description: item['place_name'] ?? item['text'] ?? "",
            placeId: item['id'].toString(),
            lat: coords[1].toDouble(),
            lng: coords[0].toDouble(),
          ));
        }
      }
      allPredictions = finalResults;
    } catch (e) {
      print('🔴 Search Error: $e');
    } finally {
      isSearched = false;
      update();
    }
  }

  // ===========================================================================
  // ➕ الدوال التي تمت إضافتها لحل مشكلة الأخطاء (Missing Methods)
  // ===========================================================================

  // ✅ 1. دالة معالجة اختيار نتيجة البحث وتحويلها لإحداثيات
  Future<void> getLangAndLatFromMap(Prediction prediction) async {
    isLoading = true;
    update();

    try {
      // استخدام الإحداثيات الموجودة في نتيجة البحث مباشرة
      selectedLatitude = prediction.lat ?? 0.0;
      selectedLongitude = prediction.lng ?? 0.0;

      // تحريك الكاميرا إلى الموقع الجديد
      animateMapCameraPosition();

      // حفظ الإحداثيات في المتغير المناسب (نقطة الانطلاق أو الوصول)
      if (selectedLocationIndex == 0) {
        pickupLatlong = LatLng(selectedLatitude, selectedLongitude);
      } else {
        destinationLatlong = LatLng(selectedLatitude, selectedLongitude);
      }

    } catch (e) {
      print("⚠️ Error setting location from search: $e");
    } finally {
      isLoading = false;
      update();
    }
  }

  // ✅ 2. دالة تحديث النص في الحقول بعد الاختيار من البحث
  void updateSelectedAddressFromSearch(String address) {
    if (selectedLocationIndex == 0) {
      pickUpController.text = address;
      currentAddress.value = address;
    } else {
      destinationController.text = address;
    }
    update();
  }

  // ===========================================================================
  // 🗺️ جلب المسار (Routing Logic)
  // ===========================================================================
  Future<List<LatLng>> getPolylinePoints() async {
    List<LatLng> points = [];
    try {
      final String url = 'https://maps.beytei.com/route/v1/driving/'
          '${pickupLatlong.longitude},${pickupLatlong.latitude};'
          '${destinationLatlong.longitude},${destinationLatlong.latitude}'
          '?geometries=geojson&overview=full';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final List coords = route['geometry']['coordinates'];
          points = coords.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();

          tripDistance = (route['distance'] ?? 0.0) / 1000;
          tripDuration = (route['duration'] ?? 0.0) / 60;
        }
      }
    } catch (e) {
      print("🔴 Routing Server Error: $e");
    }
    return points;
  }

  Future<void> _generateRoutePolyline({bool fitBounds = true}) async {
    if (pickupLatlong.latitude == 0 || destinationLatlong.latitude == 0) return;

    final points = await getPolylinePoints();
    polylineCoordinates = points;

    if (Platform.isIOS) {
      applePolylines.clear();
      applePolylines.add(ap.Polyline(
        polylineId: ap.PolylineId('route'),
        points: points.map((e) => ap.LatLng(e.latitude, e.longitude)).toList(),
        color: MyColor.getPrimaryColor(),
        width: 5,
      ));
    } else if (mapController != null) {
      await mapController!.clearLines();
      await mapController!.addLine(ml.LineOptions(
        geometry: points.map((e) => ml.LatLng(e.latitude, e.longitude)).toList(),
        lineColor: "#${MyColor.getPrimaryColor().value.toRadixString(16).substring(2)}",
        lineWidth: 4.0,
      ));
    }

    if (fitBounds) _fitPolylineBounds(points);
    update();
  }

  void _fitPolylineBounds(List<LatLng> coords) {
    if (coords.isEmpty) return;

    if (Platform.isIOS && appleController != null) {
      double minLat = coords.map((e) => e.latitude).reduce((a, b) => a < b ? a : b);
      double maxLat = coords.map((e) => e.latitude).reduce((a, b) => a > b ? a : b);
      double minLng = coords.map((e) => e.longitude).reduce((a, b) => a < b ? a : b);
      double maxLng = coords.map((e) => e.longitude).reduce((a, b) => a > b ? a : b);

      appleController!.animateCamera(ap.CameraUpdate.newLatLngBounds(
        ap.LatLngBounds(southwest: ap.LatLng(minLat, minLng), northeast: ap.LatLng(maxLat, maxLng)),
        50.0,
      ));
    } else if (mapController != null) {
      mapController!.animateCamera(ml.CameraUpdate.newLatLngBounds(
        ml.LatLngBounds(
          southwest: ml.LatLng(coords.map((e)=>e.latitude).reduce((a,b)=>a<b?a:b), coords.map((e)=>e.longitude).reduce((a,b)=>a<b?a:b)),
          northeast: ml.LatLng(coords.map((e)=>e.latitude).reduce((a,b)=>a>b?a:b), coords.map((e)=>e.longitude).reduce((a,b)=>a>b?a:b)),
        ),
        left: 50, top: 50, right: 50, bottom: 300,
      ));
    }
  }

  void animateMapCameraPosition({bool isFromEdit = false}) {
    if (selectedLatitude == 0) return;

    if (Platform.isIOS && appleController != null) {
      appleController!.animateCamera(ap.CameraUpdate.newLatLng(ap.LatLng(selectedLatitude, selectedLongitude)));
    } else if (mapController != null) {
      try {
        mapController!.animateCamera(ml.CameraUpdate.newLatLngZoom(
            ml.LatLng(selectedLatitude, selectedLongitude), 16.0
        ));
      } catch (e) {
        print("⚠️ Camera Animation Protected: $e");
      }
    }
  }

  Future<void> openMap(double latitude, double longitude, {bool isMapDrag = false}) async {
    try {
      isLoading = true; update();
      String? address = await locationSearchRepo.getActualAddress(latitude, longitude);
      currentAddress.value = address ?? "موقع محدد";

      if (selectedLocationIndex == 0) {
        pickUpController.text = currentAddress.value;
        pickupLatlong = LatLng(latitude, longitude);
      } else {
        destinationController.text = currentAddress.value;
        destinationLatlong = LatLng(latitude, longitude);
      }

      homeController.addLocationAtIndex(
        SelectedLocationInfo(latitude: latitude, longitude: longitude, fullAddress: currentAddress.value),
        selectedLocationIndex,
      );

      if (pickupLatlong.latitude != 0 && destinationLatlong.latitude != 0) {
        await _generateRoutePolyline(fitBounds: !isMapDrag);
      }
    } finally {
      isLoading = false; update();
    }
  }

  Future<void> getCurrentPosition({bool isLoading1stTime = false, int pickupLocationForIndex = -1, bool isFromEdit = false}) async {
    isLoadingFirstTime = isLoading1stTime;
    isLoading = true; update();

    geo.Position position = await geo.Geolocator.getCurrentPosition();
    selectedLatitude = position.latitude;
    selectedLongitude = position.longitude;

    animateMapCameraPosition(isFromEdit: isFromEdit);

    isLoading = false; isLoadingFirstTime = false; update();
  }

  void changeCurrentLatLongBasedOnCameraMove(double latitude, double longitude) {
    selectedLatitude = latitude;
    selectedLongitude = longitude;
    update();
  }

  Future<void> pickLocation({bool isMapDrag = false}) async {
    await openMap(selectedLatitude, selectedLongitude, isMapDrag: isMapDrag);
  }

  @override
  void onClose() {
    searchLocationController.dispose();
    destinationController.dispose();
    pickUpController.dispose();
    super.onClose();
  }
}