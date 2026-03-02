import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

// --- تم استبدال flutter_map بمكتبة MapLibre المجانية المتوافقة مع OpenFreeMap ---
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as ap;

import 'package:geolocator/geolocator.dart' as geo;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart'; // نستخدم LatLng لتوحيد البيانات مع باقي أجزاء التطبيق
import 'package:cosmetic_store/taxi/lib/core/utils/my_color.dart';
import 'package:cosmetic_store/taxi/lib/data/model/location/selected_location_info.dart';
import 'package:cosmetic_store/taxi/lib/environment.dart';

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

  // ===========================================================================
  // 🆕 بيانات المسافة والوقت
  // ===========================================================================
  double tripDistance = 0.0; // بالكيلومتر
  double tripDuration = 0.0; // بالدقائق

  // ===========================================================================
  // 🤖 متغيرات الاندرويد (MapLibre / OpenFreeMap)
  // ===========================================================================
  ml.MaplibreMapController? mapLibreController;
  ml.Line? routeLine; // مرجع لخط المسار لتحديثه دون مسح الخريطة

  // ===========================================================================
  // 🍎 متغيرات iOS (Apple Maps)
  // ===========================================================================
  ap.AppleMapController? appleController;
  Set<ap.Polyline> applePolylines = {};

  // ---------------------------------------------------------------------------

  // إعداد MapLibre (Android)
  void setMapLibreController(ml.MaplibreMapController controller) {
    mapLibreController = controller;
    update();
  }

  // إعداد Apple Maps (iOS Only)
  void setAppleController(ap.AppleMapController controller) {
    appleController = controller;
    update();
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
  String selectedAddressFromSearch = '';

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
  // ✅ دالة البحث (استخدام Nominatim المجاني كبديل لـ Mapbox)
  // ===========================================================================
  Future<void> searchYourAddress({
    required String locationName,
    void Function()? onSuccessCallback,
  }) async {
    if (locationName.trim().isEmpty) {
      allPredictions.clear();
      update();
      return;
    }

    isSearched = true;
    update();

    try {
      // حصر البحث في العراق (iq) لضمان السرعة والدقة
      final String url = 'https://nominatim.openstreetmap.org/search?q=$locationName&format=json&limit=5&addressdetails=1&countrycodes=iq';
      final response = await http.get(Uri.parse(url), headers: {'User-Agent': 'BeyteiApp'});

      List<Prediction> finalResults = [];

      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        for (var item in data) {
          finalResults.add(Prediction(
            description: item['display_name'],
            placeId: item['place_id'].toString(),
            lat: double.parse(item['lat']),
            lng: double.parse(item['lon']),
          ));
        }
      }

      allPredictions = finalResults;
      if (onSuccessCallback != null) onSuccessCallback();

    } catch (e) {
      debugPrint('🔴 Search Error: $e');
    } finally {
      isSearched = false;
      update();
    }
  }

  // ===========================================================================
  // ✅ جلب العنوان من الإحداثيات (Reverse Geocoding)
  // ===========================================================================
  Future<void> openMap(double latitude, double longitude, {bool isMapDrag = false}) async {
    try {
      isLoading = true;
      update();

      String? address = await locationSearchRepo.getActualAddress(latitude, longitude);
      if (address == null || address.isEmpty) address = "موقع محدد في الخريطة";

      currentAddress.value = address;

      if (selectedLocationIndex == 0) {
        pickUpController.text = address;
        pickupLatlong = LatLng(latitude, longitude);
      } else {
        destinationController.text = address;
        destinationLatlong = LatLng(latitude, longitude);
      }

      homeController.addLocationAtIndex(
        SelectedLocationInfo(
          latitude: latitude,
          longitude: longitude,
          fullAddress: address,
        ),
        selectedLocationIndex,
      );

      if (pickupLatlong.latitude != 0 && destinationLatlong.latitude != 0) {
        await _generateRoutePolyline(fitBounds: !isMapDrag);
      }
    } catch (e) {
      debugPrint("🔴 Error in openMap: $e");
    } finally {
      isLoading = false;
      update();
    }
  }

  void updateSelectedAddressFromSearch(String address) {
    selectedAddressFromSearch = address;
    update();
  }

  void clearSearchField() {
    allPredictions = [];
    searchLocationController.clear();
    update();
  }

  Future<LatLng?> getLangAndLatFromMap(Prediction prediction) async {
    try {
      final lat = double.tryParse(prediction.lat.toString()) ?? 0.0;
      final lng = double.tryParse(prediction.lng.toString()) ?? 0.0;
      if (lat == 0.0 || lng == 0.0) return null;

      changeCurrentLatLongBasedOnCameraMove(lat, lng);
      animateMapCameraPosition();

      allPredictions = [];
      update();
      return LatLng(lat, lng);
    } catch (e) {
      debugPrint("🔴 Error selection: ${e.toString()}");
      return null;
    }
  }

  // ===========================================================================
  // 🗺️ وظائف رسم المسار (استخدام OSRM المجاني)
  // ===========================================================================
  Future<void> _generateRoutePolyline({bool fitBounds = true}) async {
    if (pickupLatlong.latitude == 0 || destinationLatlong.latitude == 0) return;

    final points = await getPolylinePointsFromOSRM();
    polylineCoordinates = points;

    _drawPolylineUnified(points);

    if (fitBounds) {
      fitPolylineBounds(points);
    }
  }

  Future<void> _drawPolylineUnified(List<LatLng> coordinates) async {
    if (coordinates.isEmpty) return;

    if (Platform.isIOS && appleController != null) {
      applePolylines.clear();
      applePolylines.add(ap.Polyline(
        polylineId: ap.PolylineId('route'),
        points: coordinates.map((e) => ap.LatLng(e.latitude, e.longitude)).toList(),
        color: MyColor.getPrimaryColor(),
        width: 5,
      ));
    } else if (!Platform.isIOS && mapLibreController != null) {
      if (routeLine != null) await mapLibreController!.removeLine(routeLine!);

      String hexColor = '#${MyColor.getPrimaryColor().value.toRadixString(16).substring(2, 8)}';

      routeLine = await mapLibreController!.addLine(ml.LineOptions(
        geometry: coordinates.map((e) => ml.LatLng(e.latitude, e.longitude)).toList(),
        lineColor: hexColor,
        lineWidth: 5.0,
      ));
    }
    update();
  }

  Future<List<LatLng>> getPolylinePointsFromOSRM() async {
    List<LatLng> points = [];
    try {
      final String url = 'https://router.project-osrm.org/route/v1/driving/'
          '${pickupLatlong.longitude},${pickupLatlong.latitude};'
          '${destinationLatlong.longitude},${destinationLatlong.latitude}'
          '?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final List coords = data['routes'][0]['geometry']['coordinates'];
          points = coords.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();

          tripDistance = (data['routes'][0]['distance'] as num).toDouble() / 1000;
          tripDuration = (data['routes'][0]['duration'] as num).toDouble() / 60;
        }
      }
    } catch (e) {
      debugPrint("🔴 OSRM Route Error: $e");
    }
    return points;
  }

  void fitPolylineBounds(List<LatLng> coords) {
    if (coords.isEmpty) return;

    double minLat = coords.map((e) => e.latitude).reduce((a, b) => a < b ? a : b);
    double maxLat = coords.map((e) => e.latitude).reduce((a, b) => a > b ? a : b);
    double minLng = coords.map((e) => e.longitude).reduce((a, b) => a < b ? a : b);
    double maxLng = coords.map((e) => e.longitude).reduce((a, b) => a > b ? a : b);

    if (Platform.isIOS && appleController != null) {
      appleController!.animateCamera(ap.CameraUpdate.newLatLngBounds(
        ap.LatLngBounds(southwest: ap.LatLng(minLat, minLng), northeast: ap.LatLng(maxLat, maxLng)),
        50.0,
      ));
    } else if (!Platform.isIOS && mapLibreController != null) {
      mapLibreController!.animateCamera(
          ml.CameraUpdate.newLatLngBounds(
            ml.LatLngBounds(southwest: ml.LatLng(minLat, minLng), northeast: ml.LatLng(maxLat, maxLng)),
            left: 50.0, right: 50.0, top: 50.0, bottom: 50.0,
          )
      );
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

    currentPosition = await geo.Geolocator.getCurrentPosition(
        locationSettings: geo.AndroidSettings(accuracy: geo.LocationAccuracy.high)
    );

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

    if (Platform.isIOS && appleController != null) {
      appleController!.animateCamera(ap.CameraUpdate.newLatLng(
          ap.LatLng(selectedLatitude, selectedLongitude)
      ));
    } else if (!Platform.isIOS && mapLibreController != null) {
      mapLibreController!.animateCamera(ml.CameraUpdate.newLatLngZoom(
          ml.LatLng(selectedLatitude, selectedLongitude), 16.0
      ));
    }
  }

  @override
  void onClose() {
    searchLocationController.dispose();
    destinationController.dispose();
    pickUpController.dispose();
    super.onClose();
  }
}