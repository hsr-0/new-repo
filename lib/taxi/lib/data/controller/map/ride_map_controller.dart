import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as ap;
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:cosmetic_store/taxi/lib/eco.dart';

import 'package:cosmetic_store/taxi/lib/core/utils/my_icons.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_images.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_color.dart';
import 'package:cosmetic_store/taxi/lib/presentation/packages/polyline_animation/polyline_animation_v1.dart';
import '../../model/location/prediction.dart';

class RideMapController extends GetxController with GetSingleTickerProviderStateMixin {

  bool isMapReady = false;
  bool isLoading = false;
  bool isSearching = false;
  int activeServiceId = 1;

  LatLng pickupLatLng = const LatLng(0, 0);
  LatLng destinationLatLng = const LatLng(0, 0);

  LatLng driverLatLng = const LatLng(0, 0);
  double driverRotation = 0.0;
  String driverAddress = 'جاري التحميل...';

  String? _currentRideId;

  ml.MapLibreMapController? mapLibreController;
  ml.Symbol? pickupSymbol;
  ml.Symbol? destSymbol;
  ml.Symbol? driverSymbol;

  ap.AppleMapController? appleController;
  Set<ap.Annotation> appleAnnotations = {};
  Set<ap.Polyline> applePolylines = {};

  List<LatLng> polylineCoordinates = [];
  List<Prediction> predictionList = [];

  late final AnimationController _animationController;
  final PolylineAnimator animator = PolylineAnimator();

  @override
  void onInit() {
    super.onInit();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
  }

  @override
  void onClose() {
    if (_currentRideId != null) {
      stopLiveTracking(_currentRideId!);
    }
    _animationController.dispose();
    animator.clearPolylines(mapLibreController);
    super.onClose();
  }

  void startLiveTracking(String rideId) {
    _currentRideId = rideId;
    if (_currentRideId != null) {
      pusher.unsubscribe(channelName: 'ride.$rideId');
    }
    print("🎧 [TRACKING] بدء الاستماع لموقع السائق للرحلة: $rideId");

    pusher.subscribe(
      channelName: 'ride.$rideId',
      onEvent: (PusherEvent event) {
        try {
          final eventData = event.data;
          if (eventData == null || eventData.isEmpty) return;

          final data = jsonDecode(eventData);
          double newLat = (data['latitude'] is num) ? (data['latitude'] as num).toDouble() : 0.0;
          double newLng = (data['longitude'] is num) ? (data['longitude'] as num).toDouble() : 0.0;

          if (newLat != 0.0 && newLng != 0.0) {
            print("🚗 [LIVE UPDATE] موقع جديد: $newLat, $newLng");
            updateDriverLocation(
              latLng: LatLng(newLat, newLng),
              isRunning: true,
            );
          }
        } catch (e) {
          print("❌ [ERROR] فشل في تحليل بيانات الموقع: $e");
        }
      },
    );
  }

  void stopLiveTracking(String rideId) {
    if (_currentRideId != null) {
      pusher.unsubscribe(channelName: 'ride.$rideId');
      _currentRideId = null;
    }
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  Future<void> loadVehicleImagesToMap() async {
    if (mapLibreController == null) return;
    try {
      final Uint8List carData = await getBytesFromAsset('assets/images/car.png', 100);
      await mapLibreController!.addImage("car_icon", carData);

      final Uint8List tuktukData = await getBytesFromAsset('assets/images/tuktuk.png', 100);
      await mapLibreController!.addImage("tuktuk_icon", tuktukData);
      print("✅ تم تحميل صور السيارات والتكتك بنجاح في ذاكرة الخريطة!");
    } catch(e) {
      print('❌ خطأ في تحميل صور المركبات: $e');
    }
  }

  void setMapLibreController(ml.MapLibreMapController controller) {
    mapLibreController = controller;
    isMapReady = true;
    loadVehicleImagesToMap();
    // ❌ تم إزالة _checkInitialData() لمنع التضارب مع PolyLineMapScreen
  }

  void setAppleController(ap.AppleMapController controller) {
    appleController = controller;
    isMapReady = true;
    // ❌ تم إزالة _checkInitialData() لمنع التضارب مع PolyLineMapScreen
  }

  // =========================================================================
  // 🔥 البديل الآمن لـ loadMap: تحديث البيانات فقط (الرسم مسؤولية PolyLineMapScreen)
  // =========================================================================
  void updateRideLocations({
    required LatLng pickup,
    required LatLng destination,
    bool isRunning = false,
  }) {
    pickupLatLng = pickup;
    destinationLatLng = destination;
    update();
    getRouteFromOSRM();
  }

  // 🔥 جلب المسار من OSRM وتخزينه في polylineCoordinates (بدون رسم)
  Future<void> getRouteFromOSRM() async {
    if (pickupLatLng.latitude == 0 || destinationLatLng.latitude == 0) return;
    try {
      final String url = 'https://router.project-osrm.org/route/v1/driving/'
          '${pickupLatLng.longitude},${pickupLatLng.latitude};'
          '${destinationLatLng.longitude},${destinationLatLng.latitude}'
          '?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final List coords = data['routes'][0]['geometry']['coordinates'];
          polylineCoordinates =
              coords.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
          print("🛣️ [Route] تم جلب المسار: ${polylineCoordinates.length} نقطة");
          update(); // 🔥 إشعار PolyLineMapScreen لرسم المسار
        }
      }
    } catch (e) {
      print('❌ [Route] خطأ في جلب المسار: $e');
    }
  }

  void updateDriverLocation({required LatLng latLng, required bool isRunning}) {
    if (!isMapReady) return;

    if (driverLatLng.latitude == 0) {
      driverLatLng = latLng;
      _updateDriverMarkerUnified(latLng, 0.0);
    } else {
      _animateMarkerUnified(latLng);
    }
    getCurrentDriverAddress();
  }

  void _animateMarkerUnified(LatLng newPosition) {
    final oldPosition = driverLatLng;
    _animationController.stop();
    _animationController.reset();
    _animationController.clearListeners();

    final latTween = Tween<double>(begin: oldPosition.latitude, end: newPosition.latitude);
    final lngTween = Tween<double>(begin: oldPosition.longitude, end: newPosition.longitude);
    final endRotation = _getRotation(oldPosition.latitude, oldPosition.longitude, newPosition.latitude, newPosition.longitude);

    _animationController.addListener(() {
      final t = _animationController.value;
      driverLatLng = LatLng(latTween.transform(t), lngTween.transform(t));
      driverRotation = endRotation;
      _updateDriverMarkerUnified(driverLatLng, endRotation);
    });

    _animationController.forward();
  }

  Future<void> _updateDriverMarkerUnified(LatLng position, double rotation) async {
    String iconName = (activeServiceId == 1) ? 'car_icon' : 'tuktuk_icon';
    String assetPath = (activeServiceId == 1) ? 'assets/images/car.png' : 'assets/images/tuktuk.png';

    if (Platform.isIOS && appleController != null) {
      appleAnnotations.removeWhere((a) => a.annotationId.value == 'driver');

      final driverIcon = await ap.BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(35, 35)), assetPath);

      appleAnnotations.add(ap.Annotation(
          annotationId:  ap.AnnotationId('driver'),
          position: ap.LatLng(position.latitude, position.longitude),
          icon: driverIcon));

    } else if (!Platform.isIOS && mapLibreController != null) {
      if (driverSymbol == null) {
        driverSymbol = await mapLibreController!.addSymbol(ml.SymbolOptions(
          geometry: ml.LatLng(position.latitude, position.longitude),
          iconImage: iconName,
          iconSize: 0.15,
          iconRotate: rotation,
        ));
      } else {
        await mapLibreController!.updateSymbol(
            driverSymbol!,
            ml.SymbolOptions(
              geometry: ml.LatLng(position.latitude, position.longitude),
              iconRotate: rotation,
              iconImage: iconName,
            ));
      }
    }
    update();
  }

  Future<void> searchLocation(String query) async {
    if (query.isEmpty) {
      predictionList.clear();
      update();
      return;
    }
    isSearching = true;
    update();
    List<Prediction> combinedResults = [];

    try {
      final String myServerUrl = 'https://taxi.beytei.com/api/local-search?q=$query';
      final myResponse = await http.get(Uri.parse(myServerUrl)).timeout(const Duration(seconds: 2));

      if (myResponse.statusCode == 200) {
        final data = json.decode(myResponse.body);
        if (data['data'] != null) {
          combinedResults.addAll((data['data'] as List).map((e) => Prediction(
            placeId: e['id'].toString(),
            description: e['place_name'],
            lat: double.tryParse(e['lat'].toString()) ?? 0.0,
            lng: double.tryParse(e['lng'].toString()) ?? 0.0,
            structuredFormatting: StructuredFormatting(
                mainText: e['place_name'],
                secondaryText: "${e['city']} - محلي"
            ),
          )));
        }
      }
    } catch (e) {}

    try {
      final String searchUrl = 'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5&countrycodes=iq';
      final response = await http.get(Uri.parse(searchUrl), headers: {'User-Agent': 'BeyteiApp'});

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        for (var item in data) {
          combinedResults.add(Prediction(
              placeId: item['place_id'].toString(),
              description: item['display_name'],
              lat: double.parse(item['lat']),
              lng: double.parse(item['lon']),
              structuredFormatting: StructuredFormatting(
                  mainText: item['name'] ?? "",
                  secondaryText: item['display_name']
              )
          ));
        }
      }
    } catch (e) {}

    predictionList = combinedResults;
    isSearching = false;
    update();
  }

  void fitPolylineBounds() {
    if (polylineCoordinates.isEmpty) return;

    double minLat = polylineCoordinates.map((e) => e.latitude).reduce(min);
    double maxLat = polylineCoordinates.map((e) => e.latitude).reduce(max);
    double minLng = polylineCoordinates.map((e) => e.longitude).reduce(min);
    double maxLng = polylineCoordinates.map((e) => e.longitude).reduce(max);

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

  Future<void> getCurrentDriverAddress() async {
    try {
      final List<Placemark> placeMark = await placemarkFromCoordinates(driverLatLng.latitude, driverLatLng.longitude);
      if(placeMark.isNotEmpty) {
        driverAddress = "${placeMark[0].street}, ${placeMark[0].subLocality}";
      }
    } catch (e) {}
    update();
  }

  double _getRotation(double lat1, double lon1, double lat2, double lon2) {
    var dy = lat2 - lat1;
    var dx = cos(pi/180 * lat1) * (lon2 - lon1);
    return atan2(dy, dx) * 180 / pi;
  }
}