import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
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
  // 🆕 متغيرات جديدة لحفظ المسافة والوقت (مهم جداً لحساب السعر)
  // ===========================================================================
  double tripDistance = 0.0; // بالكيلومتر
  double tripDuration = 0.0; // بالدقائق

  MapboxMap? mapboxMap;
  PolylineAnnotationManager? polylineAnnotationManager;

  Future<void> setMapController(MapboxMap map) async {
    mapboxMap = map;
    polylineAnnotationManager = await mapboxMap?.annotations.createPolylineAnnotationManager();
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

    print("🚀 [Controller] جاري البحث عن: $locationName");

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

      print("✅ [Controller] عدد النتائج: ${finalResults.length}");
      allPredictions = finalResults;
      if (onSuccessCallback != null) onSuccessCallback();

    } catch (e, stacktrace) {
      print('🔴 [Controller] خطأ البحث: $e');
      print(stacktrace);
    } finally {
      isSearched = false;
      update();
    }
  }

  // ===========================================================================
  // ✅ دالة فتح الخريطة (Reverse Geocoding)
  // ===========================================================================
  Future<void> openMap(double latitude, double longitude) async {
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
        await _generateRoutePolyline();
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
  // 🗺️ وظائف رسم المسار + حساب السعر
  // ===========================================================================
  Future<void> _generateRoutePolyline() async {
    if (pickupLatlong.latitude == 0 || destinationLatlong.latitude == 0) return;

    print("🛣️ [Route] بدء طلب رسم المسار...");
    final points = await getPolylinePoints();
    polylineCoordinates = points;

    if (mapboxMap != null && polylineAnnotationManager == null) {
      polylineAnnotationManager = await mapboxMap!.annotations.createPolylineAnnotationManager();
    }

    generatePolyLineFromPoints(points);
    fitPolylineBounds(points);

    if (polylineAnnotationManager != null) {
      animator.animatePolyline(points, 'poly_anim', MyColor.colorYellow, MyColor.primaryColor, polylineAnnotationManager);
    }
  }

  // 🔴🔴🔴 التعديل الأهم هنا 🔴🔴🔴
  Future<List<LatLng>> getPolylinePoints() async {
    List<LatLng> points = [];
    String mapboxAccessToken = Environment.mapKey;

    try {
      final String url = 'https://api.mapbox.com/directions/v5/mapbox/driving/'
          '${pickupLatlong.longitude},${pickupLatlong.latitude};'
          '${destinationLatlong.longitude},${destinationLatlong.latitude}'
          '?geometries=geojson&overview=full&steps=true&access_token=$mapboxAccessToken';

      print("🚀 [Mapbox API] الرابط: $url");

      final response = await http.get(Uri.parse(url));

      print("📡 [Mapbox API] كود الاستجابة: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // 1. استخراج النقاط
        final List coordinates = data['routes'][0]['geometry']['coordinates'];
        points = coordinates.map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble())).toList();

        // 2. ✅ استخراج المسافة وحفظها (بالمتر -> كيلو)
        double meters = double.tryParse(data['routes'][0]['distance'].toString()) ?? 0.0;
        tripDistance = meters / 1000;

        // 3. ✅ استخراج الوقت وحفظه (بالثواني -> دقائق)
        double seconds = double.tryParse(data['routes'][0]['duration'].toString()) ?? 0.0;
        tripDuration = seconds / 60;

        print("🏁 [نتائج الرحلة] -----------------------");
        print("📏 المسافة: $tripDistance كيلومتر");
        print("⏱️ الوقت المتوقع: $tripDuration دقيقة");
        print("📍 عدد نقاط الرسم: ${points.length}");
        print("----------------------------------------");

      } else {
        print("🔥 [Mapbox Error] Response: ${response.body}");
      }
    } catch (e) {
      print("🔴 Route Error Exception: $e");
    }
    return points;
  }

  void generatePolyLineFromPoints(List<LatLng> coordinates) async {
    if (coordinates.isEmpty || polylineAnnotationManager == null) return;
    try {
      List<Position> routePositions = coordinates.map((e) => Position(e.longitude, e.latitude)).toList();
      var options = PolylineAnnotationOptions(
        geometry: LineString(coordinates: routePositions),
        lineColor: MyColor.getPrimaryColor().value,
        lineWidth: 5.0,
        lineOpacity: 0.5,
      );
      await polylineAnnotationManager!.create(options);
    } catch (e) { print("🔴 Draw Error: $e"); }
  }

  void fitPolylineBounds(List<LatLng> coords) {
    if (coords.isEmpty || mapboxMap == null) return;
    List<Point> points = coords.map((e) => Point(coordinates: Position(e.longitude, e.latitude))).toList();
    mapboxMap!.cameraForCoordinates(points, MbxEdgeInsets(top: 100, left: 50, bottom: 300, right: 50), null, null).then((cameraOptions) {
      mapboxMap!.flyTo(cameraOptions, MapAnimationOptions(duration: 1000));
    });
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
      animateMapCameraPosition(isFromEdit: isFromEdit);
    }
    _endLoading();
  }

  void _endLoading() { isLoading = false; isLoadingFirstTime = false; update(); }

  Future<void> pickLocation() async { await openMap(selectedLatitude, selectedLongitude); }

  void changeCurrentLatLongBasedOnCameraMove(double latitude, double longitude) {
    selectedLatitude = latitude;
    selectedLongitude = longitude;
    update();
  }

  void animateMapCameraPosition({bool isFromEdit = false}) {
    if (mapboxMap != null && selectedLatitude != 0) {
      mapboxMap!.flyTo(CameraOptions(center: Point(coordinates: Position(selectedLongitude, selectedLatitude)), zoom: 16.0), MapAnimationOptions(duration: 1000));
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