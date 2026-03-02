import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';

// استيراد الإحداثيات الأساسية التي يستخدمها باقي التطبيق
import 'package:latlong2/latlong.dart';

// --- مكتبات الخرائط ---
import 'package:maplibre_gl/maplibre_gl.dart' as ml; // للاندرويد
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as ap; // للآيفون

import 'package:cosmetic_store/taxi/lib/core/utils/my_icons.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_images.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_color.dart';
import '../../model/location/prediction.dart';

class RideMapController extends GetxController with GetSingleTickerProviderStateMixin {

  // --- متغيرات الحالة ---
  bool isMapReady = false;
  bool isLoading = false;
  bool isSearching = false;

  // --- الإحداثيات الأساسية (نستخدم LatLng المعتاد ليتوافق مع باقي الملفات) ---
  LatLng pickupLatLng = const LatLng(0, 0);
  LatLng destinationLatLng = const LatLng(0, 0);

  // --- بيانات السائق ---
  LatLng driverLatLng = const LatLng(0, 0);
  double driverRotation = 0.0;
  String driverAddress = 'جاري التحميل...';

  // ==========================================
  // 🤖 متغيرات الاندرويد (MapLibre / OpenFreeMap)
  // ==========================================
  ml.MaplibreMapController? mapLibreController;

  ml.Symbol? pickupSymbol;
  ml.Symbol? destSymbol;
  ml.Symbol? driverSymbol;
  ml.Line? routeLine;

  // ==========================================
  // 🍎 متغيرات iOS (Apple Maps)
  // ==========================================
  ap.AppleMapController? appleController;
  Set<ap.Annotation> appleAnnotations = {};
  Set<ap.Polyline> applePolylines = {};

  // --- البيانات والمسارات ---
  List<LatLng> polylineCoordinates = [];
  List<Prediction> predictionList = [];

  // --- الأنيميشن ---
  late final AnimationController _animationController;

  @override
  void onInit() {
    super.onInit();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
  }

  @override
  void onClose() {
    _animationController.dispose();
    super.onClose();
  }

  // ===========================================================================
  // 1. إعداد المتحكمات
  // ===========================================================================

  void setMapLibreController(ml.MaplibreMapController controller) {
    mapLibreController = controller;
    isMapReady = true;
    _checkInitialData();
  }

  void setAppleController(ap.AppleMapController controller) {
    appleController = controller;
    isMapReady = true;
    _checkInitialData();
  }

  void _checkInitialData() {
    if (pickupLatLng.latitude != 0 && destinationLatLng.latitude != 0) {
      loadMap(pickup: pickupLatLng, destination: destinationLatLng);
    }
  }

  // ===========================================================================
  // 2. تحميل الخريطة والمسار
  // ===========================================================================
  void loadMap({required LatLng pickup, required LatLng destination, bool? isRunning = false}) async {
    pickupLatLng = pickup;
    destinationLatLng = destination;
    update();

    if (!isMapReady) return;

    await _drawStaticMarkers();
    await getRouteFromOSRM();
    fitPolylineBounds();
  }

  Future<void> _drawStaticMarkers() async {
    if (Platform.isIOS && appleController != null) {
      appleAnnotations.removeWhere((a) => a.annotationId.value == 'pickup' || a.annotationId.value == 'destination');

      final pickupIcon = await ap.BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(40, 40)), MyIcons.mapMarkerPickUpIcon);
      final destIcon = await ap.BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(40, 40)), MyIcons.mapMarkerIcon);

      appleAnnotations.add(ap.Annotation(
        annotationId: ap.AnnotationId('pickup'),
        position: ap.LatLng(pickupLatLng.latitude, pickupLatLng.longitude),
        icon: pickupIcon,
      ));
      appleAnnotations.add(ap.Annotation(
        annotationId: ap.AnnotationId('destination'),
        position: ap.LatLng(destinationLatLng.latitude, destinationLatLng.longitude),
        icon: destIcon,
      ));
    } else if (!Platform.isIOS && mapLibreController != null) {
      if (pickupSymbol != null) await mapLibreController!.removeSymbol(pickupSymbol!);
      if (destSymbol != null) await mapLibreController!.removeSymbol(destSymbol!);

      pickupSymbol = await mapLibreController!.addSymbol(ml.SymbolOptions(
        geometry: ml.LatLng(pickupLatLng.latitude, pickupLatLng.longitude),
        iconImage: 'pickup_icon',
        iconSize: 0.5,
      ));

      destSymbol = await mapLibreController!.addSymbol(ml.SymbolOptions(
        geometry: ml.LatLng(destinationLatLng.latitude, destinationLatLng.longitude),
        iconImage: 'dest_icon',
        iconSize: 0.5,
      ));
    }
    update();
  }

  Future<void> getRouteFromOSRM() async {
    if (!isMapReady) return;
    isLoading = true;
    update();

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
          polylineCoordinates = coords.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
          _drawPolylineUnified();
        }
      }
    } catch (e) {
      debugPrint('🔴 OSRM Route Error: $e');
    }

    isLoading = false;
    update();
  }

  Future<void> _drawPolylineUnified() async {
    if (polylineCoordinates.isEmpty) return;

    if (Platform.isIOS && appleController != null) {
      applePolylines.clear();
      applePolylines.add(ap.Polyline(
        polylineId: ap.PolylineId('route'),
        points: polylineCoordinates.map((e) => ap.LatLng(e.latitude, e.longitude)).toList(),
        color: MyColor.getPrimaryColor(),
        width: 5,
      ));
    } else if (!Platform.isIOS && mapLibreController != null) {
      if (routeLine != null) await mapLibreController!.removeLine(routeLine!);

      String hexColor = '#${MyColor.getPrimaryColor().value.toRadixString(16).substring(2, 8)}';

      routeLine = await mapLibreController!.addLine(ml.LineOptions(
        geometry: polylineCoordinates.map((e) => ml.LatLng(e.latitude, e.longitude)).toList(),
        lineColor: hexColor,
        lineWidth: 5.0,
      ));
    }
    update();
  }

  // ===========================================================================
  // 3. تحديث موقع السائق وحركته
  // ===========================================================================
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
    if (Platform.isIOS && appleController != null) {
      appleAnnotations.removeWhere((a) => a.annotationId.value == 'driver');

      final driverIcon = await ap.BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(35, 35)), MyImages.mapDriverMarker);

      appleAnnotations.add(ap.Annotation(
        annotationId: ap.AnnotationId('driver'),
        position: ap.LatLng(position.latitude, position.longitude),
        icon: driverIcon,
      ));
    } else if (!Platform.isIOS && mapLibreController != null) {
      if (driverSymbol == null) {
        driverSymbol = await mapLibreController!.addSymbol(ml.SymbolOptions(
          geometry: ml.LatLng(position.latitude, position.longitude),
          iconImage: 'driver_icon',
          iconSize: 0.5,
          iconRotate: rotation,
        ));
      } else {
        await mapLibreController!.updateSymbol(driverSymbol!, ml.SymbolOptions(
          geometry: ml.LatLng(position.latitude, position.longitude),
          iconRotate: rotation,
        ));
      }
    }
    update();
  }

  // ===========================================================================
  // 4. البحث (استخدام Nominatim المجاني)
  // ===========================================================================
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
    } catch (e) { debugPrint("⚠️ Nominatim Search Error: $e"); }

    predictionList = combinedResults;
    isSearching = false;
    update();
  }

  // ===========================================================================
  // 5. أدوات مساعدة
  // ===========================================================================

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
    } catch (e) { debugPrint('Address Error: $e'); }
    update();
  }

  double _getRotation(double lat1, double lon1, double lat2, double lon2) {
    var dy = lat2 - lat1;
    var dx = cos(pi/180 * lat1) * (lon2 - lon1);
    return atan2(dy, dx) * 180 / pi;
  }
}