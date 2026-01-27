import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

// --- مكتبات الخرائط ---
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as ap;

import 'package:geolocator/geolocator.dart' as geo;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_color.dart';
import 'package:cosmetic_store/taxi/lib/data/model/location/selected_location_info.dart';
import 'package:cosmetic_store/taxi/lib/environment.dart';
import 'package:cosmetic_store/taxi/lib/presentation/packages/polyline_animation/polyline_animation_v1.dart';

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
  // 🆕 متغيرات حفظ المسافة والوقت
  // ===========================================================================
  double tripDistance = 0.0; // بالكيلومتر
  double tripDuration = 0.0; // بالدقائق

  // ===========================================================================
  // 🤖 متغيرات Android (Mapbox)
  // ===========================================================================
  mb.MapboxMap? mapboxMap;
  mb.PolylineAnnotationManager? polylineAnnotationManager;

  // ===========================================================================
  // 🍎 متغيرات iOS (Apple Maps)
  // ===========================================================================
  ap.AppleMapController? appleController;
  Set<ap.Polyline> applePolylines = {};

  // ---------------------------------------------------------------------------

  // إعداد Mapbox (Android Only)
  Future<void> setMapController(mb.MapboxMap map) async {
    // حماية إضافية: لا تقم بتهيئة Mapbox إذا كنا على iOS
    if (Platform.isIOS) return;

    mapboxMap = map;
    try {
      polylineAnnotationManager = await mapboxMap?.annotations.createPolylineAnnotationManager();
    } catch (e) {
      print("⚠️ Error creating PolylineManager on Android: $e");
    }
  }

  // إعداد Apple Maps (iOS Only)
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

  final PolylineAnimator animator = PolylineAnimator();
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
  // ✅ دالة البحث
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

          double lat = 0.0;
          double lng = 0.0;

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
            finalResults.add(Prediction(
              description: description,
              placeId: item['id'].toString(),
              lat: lat,
              lng: lng,
            ));
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

  // ===========================================================================
  // ✅ دالة فتح الخريطة (Reverse Geocoding)
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
        // نمرر عكس isMapDrag لمنع إعادة ضبط الكاميرا أثناء السحب
        await _generateRoutePolyline(fitBounds: !isMapDrag);
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
      // هنا نحرك الكاميرا لأن المستخدم اختار من البحث (وليس سحباً)
      animateMapCameraPosition();

      allPredictions = [];
      update();
      return LatLng(lat, lng);
    } catch (e) {
      print("🔴 Error selection: ${e.toString()}");
      return null;
    }
  }

  // ===========================================================================
  // 🗺️ وظائف رسم المسار
  // ===========================================================================
  Future<void> _generateRoutePolyline({bool fitBounds = true}) async {
    if (pickupLatlong.latitude == 0 || destinationLatlong.latitude == 0) return;

    final points = await getPolylinePoints();
    polylineCoordinates = points;

    if (!Platform.isIOS && mapboxMap != null && polylineAnnotationManager == null) {
      try {
        polylineAnnotationManager = await mapboxMap!.annotations.createPolylineAnnotationManager();
      } catch (e) {
        print("⚠️ Failed to create polyline manager on Android: $e");
      }
    }

    _drawPolylineUnified(points);

    // التحقق من fitBounds قبل تحريك الكاميرا
    if (fitBounds) {
      fitPolylineBounds(points);
    }
  }

  // رسم المسار (Unified)
  void _drawPolylineUnified(List<LatLng> coordinates) async {
    if (coordinates.isEmpty) return;

    // --- iOS Logic ---
    if (Platform.isIOS) {
      applePolylines.clear();
      applePolylines.add(ap.Polyline(
        polylineId: ap.PolylineId('route'),
        points: coordinates.map((e) => ap.LatLng(e.latitude, e.longitude)).toList(),
        color: MyColor.getPrimaryColor(),
        width: 5,
        jointType: ap.JointType.round,
      ));
      update(); // تحديث الواجهة
      return;
    }

    // --- Android Logic ---
    if (Platform.isIOS) return;

    if (polylineAnnotationManager == null) return;
    try {
      await polylineAnnotationManager!.deleteAll();
      List<mb.Position> routePositions = coordinates.map((e) => mb.Position(e.longitude, e.latitude)).toList();
      var options = mb.PolylineAnnotationOptions(
        geometry: mb.LineString(coordinates: routePositions),
        lineColor: MyColor.getPrimaryColor().value,
        lineWidth: 5.0,
        lineOpacity: 0.6,
        lineJoin: mb.LineJoin.ROUND,
      );
      await polylineAnnotationManager!.create(options);
    } catch (e) { print("🔴 Draw Error: $e"); }
  }

  // جلب النقاط من API (مشترك)
  Future<List<LatLng>> getPolylinePoints() async {
    List<LatLng> points = [];
    String mapboxAccessToken = Environment.mapKey;

    try {
      final String url = 'https://api.mapbox.com/directions/v5/mapbox/driving/'
          '${pickupLatlong.longitude},${pickupLatlong.latitude};'
          '${destinationLatlong.longitude},${destinationLatlong.latitude}'
          '?geometries=geojson&overview=full&steps=true&access_token=$mapboxAccessToken';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final List coordinates = data['routes'][0]['geometry']['coordinates'];
        points = coordinates.map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble())).toList();

        double meters = double.tryParse(data['routes'][0]['distance'].toString()) ?? 0.0;
        tripDistance = meters / 1000;

        double seconds = double.tryParse(data['routes'][0]['duration'].toString()) ?? 0.0;
        tripDuration = seconds / 60;

      } else {
        print("🔥 [Mapbox Error] Response: ${response.body}");
      }
    } catch (e) {
      print("🔴 Route Error Exception: $e");
    }
    return points;
  }

  // ضبط حدود الكاميرا (Unified)
  void fitPolylineBounds(List<LatLng> coords) {
    if (coords.isEmpty) return;

    // --- iOS Logic ---
    if (Platform.isIOS) {
      if (appleController != null) {
        double minLat = 90.0; double maxLat = -90.0;
        double minLng = 180.0; double maxLng = -180.0;

        for (var point in coords) {
          if (point.latitude < minLat) minLat = point.latitude;
          if (point.latitude > maxLat) maxLat = point.latitude;
          if (point.longitude < minLng) minLng = point.longitude;
          if (point.longitude > maxLng) maxLng = point.longitude;
        }

        appleController!.animateCamera(ap.CameraUpdate.newLatLngBounds(
          ap.LatLngBounds(
            southwest: ap.LatLng(minLat, minLng),
            northeast: ap.LatLng(maxLat, maxLng),
          ),
          50.0, // padding
        ));
      }
      return;
    }

    // --- Android Logic (مع حماية Try-Catch) ---
    if (mapboxMap != null) {
      try {
        List<mb.Point> points = coords.map((e) => mb.Point(coordinates: mb.Position(e.longitude, e.latitude))).toList();
        mapboxMap!.cameraForCoordinates(points, mb.MbxEdgeInsets(top: 100, left: 50, bottom: 300, right: 50), null, null).then((cameraOptions) {
          mapboxMap!.flyTo(cameraOptions, mb.MapAnimationOptions(duration: 1000));
        });
      } catch (e) {
        print("⚠️ Mapbox FitBounds Error (Ignored): $e");
      }
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

    currentPosition = await geo.Geolocator.getCurrentPosition(locationSettings: geo.AndroidSettings(accuracy: geo.LocationAccuracy.high));

    if (currentPosition != null) {
      changeCurrentLatLongBasedOnCameraMove(currentPosition!.latitude, currentPosition!.longitude);

      // نحرك الكاميرا لأن هذا تحديد تلقائي للموقع (ليس سحباً)
      animateMapCameraPosition(isFromEdit: isFromEdit);
    }
    _endLoading();
  }

  void _endLoading() { isLoading = false; isLoadingFirstTime = false; update(); }

  // دالة الواجهة الرئيسية (pickLocation) تستقبل isMapDrag
  Future<void> pickLocation({bool isMapDrag = false}) async {
    await openMap(selectedLatitude, selectedLongitude, isMapDrag: isMapDrag);
  }

  void changeCurrentLatLongBasedOnCameraMove(double latitude, double longitude) {
    selectedLatitude = latitude;
    selectedLongitude = longitude;
    update();
  }

  // ✅✅ التعديل الأهم: إضافة Try-Catch هنا لمنع الانهيار ✅✅
  void animateMapCameraPosition({bool isFromEdit = false}) {
    if (selectedLatitude == 0) return;

    // --- iOS Logic ---
    if (Platform.isIOS) {
      if (appleController != null) {
        appleController!.animateCamera(ap.CameraUpdate.newLatLng(
            ap.LatLng(selectedLatitude, selectedLongitude)
        ));
      }
      return;
    }

    // --- Android Logic (With Crash Protection) ---
    if (mapboxMap != null) {
      try {
        mapboxMap!.flyTo(
            mb.CameraOptions(center: mb.Point(coordinates: mb.Position(selectedLongitude, selectedLatitude)), zoom: 16.0),
            mb.MapAnimationOptions(duration: 1000)
        );
      } catch (e) {
        // هذا هو الذي يمنع التطبيق من الانهيار إذا كانت القناة غير جاهزة
        print("⚠️ Mapbox Animation Error (Ignored): $e");
      }
    }
  }

  @override
  void onClose() {
    animator.dispose();
    searchLocationController.dispose();
    destinationController.dispose();
    pickUpController.dispose();
    super.onClose();
  }
}