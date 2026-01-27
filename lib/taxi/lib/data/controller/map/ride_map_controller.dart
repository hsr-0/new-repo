import 'dart:async';
import 'dart:convert';
import 'dart:io'; // لتحديد نوع النظام
import 'dart:typed_data';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // لتحميل الصور

// --- مكتبات الخرائط ---
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as ap;

import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_icons.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_images.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/helper.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_color.dart';
import 'package:cosmetic_store/taxi/lib/environment.dart';
import '../../model/location/prediction.dart';

class RideMapController extends GetxController with GetSingleTickerProviderStateMixin {

  // --- متغيرات الحالة ---
  bool isMapReady = false;
  bool isLoading = false;
  bool isSearching = false;

  // --- الإحداثيات ---
  LatLng pickupLatLng = const LatLng(0, 0);
  LatLng destinationLatLng = const LatLng(0, 0);

  // --- بيانات السائق ---
  LatLng? _previousDriverLatLng;
  LatLng driverLatLng = const LatLng(0, 0);
  double driverRotation = 0.0;
  String driverAddress = 'جاري التحميل...';

  // ==========================================
  // 🤖 متغيرات Android (Mapbox)
  // ==========================================
  mb.MapboxMap? mapboxMap;
  mb.PointAnnotationManager? pointAnnotationManager;
  mb.PolylineAnnotationManager? polylineAnnotationManager;
  mb.PointAnnotation? driverAnnotation;

  // ==========================================
  // 🍎 متغيرات iOS (Apple Maps)
  // ==========================================
  ap.AppleMapController? appleController;
  Set<ap.Annotation> appleAnnotations = {};
  Set<ap.Polyline> applePolylines = {};

  // --- البيانات ---
  List<LatLng> polylineCoordinates = [];
  List<Prediction> predictionList = [];

  // --- الأنيميشن والصور ---
  late final AnimationController _animationController;

  // صور الأندرويد (Bytes)
  Uint8List? pickupIconBytes;
  Uint8List? destinationIconBytes;
  Uint8List? driverIconBytes;

  // صور الآيفون (BitmapDescriptor)
  ap.BitmapDescriptor? pickupIconApple;
  ap.BitmapDescriptor? destinationIconApple;
  ap.BitmapDescriptor? driverIconApple;

  @override
  void onInit() {
    super.onInit();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    loadCustomMarkerIcons();
  }

  @override
  void onClose() {
    _animationController.dispose();
    super.onClose();
  }

  // ===========================================================================
  // 1. إعداد الخرائط
  // ===========================================================================

  Future<void> setMapboxController(mb.MapboxMap map) async {
    mapboxMap = map;
    pointAnnotationManager = await mapboxMap?.annotations.createPointAnnotationManager();
    polylineAnnotationManager = await mapboxMap?.annotations.createPolylineAnnotationManager();
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
  // 2. تحميل الصور
  // ===========================================================================
  Future<void> loadCustomMarkerIcons() async {
    try {
      // تحميل للأندرويد
      pickupIconBytes = await Helper.getBytesFromAsset(MyIcons.mapMarkerPickUpIcon, 120);
      destinationIconBytes = await Helper.getBytesFromAsset(MyIcons.mapMarkerIcon, 120);
      driverIconBytes = await Helper.getBytesFromAsset(MyImages.mapDriverMarker, 100);

      // تحميل للآيفون
      pickupIconApple = await ap.BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(40, 40)), MyIcons.mapMarkerPickUpIcon);
      destinationIconApple = await ap.BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(40, 40)), MyIcons.mapMarkerIcon);
      driverIconApple = await ap.BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(35, 35)), MyImages.mapDriverMarker);

      update();
    } catch (e) {
      print("🔴 Error loading icons: $e");
    }
  }

  // ===========================================================================
  // 3. المنطق الموحد: تحميل الخريطة والمسار
  // ===========================================================================
  void loadMap({required LatLng pickup, required LatLng destination, bool? isRunning = false}) async {
    pickupLatLng = pickup;
    destinationLatLng = destination;
    update();

    if (!isMapReady) return;

    await _drawStaticMarkers();
    await getRouteFromMapbox();
    fitPolylineBounds(); // ✅ تم تعديل الاسم هنا ليطابق الدالة العامة
  }

  // رسم الدبابيس الثابتة
  Future<void> _drawStaticMarkers() async {
    // --- iOS Logic ---
    if (Platform.isIOS) {
      appleAnnotations.clear();

      if (pickupIconApple != null) {
        appleAnnotations.add(ap.Annotation(
          annotationId: ap.AnnotationId('pickup'), // ✅ بدون const
          position: ap.LatLng(pickupLatLng.latitude, pickupLatLng.longitude),
          icon: pickupIconApple!,
        ));
      }

      if (destinationIconApple != null) {
        appleAnnotations.add(ap.Annotation(
          annotationId: ap.AnnotationId('destination'), // ✅ بدون const
          position: ap.LatLng(destinationLatLng.latitude, destinationLatLng.longitude),
          icon: destinationIconApple!,
        ));
      }
      update();
      return;
    }

    // --- Android Logic ---
    if (pointAnnotationManager == null) return;
    await pointAnnotationManager!.deleteAll();
    driverAnnotation = null;

    List<mb.PointAnnotationOptions> markers = [];
    if (pickupIconBytes != null) {
      markers.add(mb.PointAnnotationOptions(
        geometry: mb.Point(coordinates: mb.Position(pickupLatLng.longitude, pickupLatLng.latitude)),
        image: pickupIconBytes!,
        iconSize: 1.0,
        iconAnchor: mb.IconAnchor.BOTTOM,
      ));
    }
    if (destinationIconBytes != null) {
      markers.add(mb.PointAnnotationOptions(
        geometry: mb.Point(coordinates: mb.Position(destinationLatLng.longitude, destinationLatLng.latitude)),
        image: destinationIconBytes!,
        iconSize: 1.0,
        iconAnchor: mb.IconAnchor.BOTTOM,
      ));
    }
    await pointAnnotationManager!.createMulti(markers);
  }

  Future<void> getRouteFromMapbox() async {
    if (!isMapReady) return;
    isLoading = true;
    update();

    try {
      String accessToken = Environment.mapKey;
      final String url =
          'https://api.mapbox.com/directions/v5/mapbox/driving/${pickupLatLng.longitude},${pickupLatLng.latitude};${destinationLatLng.longitude},${destinationLatLng.latitude}?overview=full&geometries=geojson&steps=true&access_token=$accessToken';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'].isNotEmpty) {
          final geometry = data['routes'][0]['geometry'];
          final coordinates = geometry['coordinates'] as List;

          polylineCoordinates = coordinates.map((coord) {
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();

          await _drawPolylineUnified();
        }
      }
    } catch (e) {
      print('🔴 [Error] Fetching route: $e');
    }

    isLoading = false;
    update();
  }

  Future<void> _drawPolylineUnified() async {
    if (polylineCoordinates.isEmpty) return;

    // --- iOS Logic ---
    if (Platform.isIOS) {
      applePolylines.clear();
      List<ap.LatLng> applePoints = polylineCoordinates
          .map((e) => ap.LatLng(e.latitude, e.longitude))
          .toList();

      applePolylines.add(ap.Polyline(
        polylineId: ap.PolylineId('route'), // ✅ بدون const
        points: applePoints,
        color: MyColor.getPrimaryColor(),
        width: 5,
        jointType: ap.JointType.round,
      ));
      update();
      return;
    }

    // --- Android Logic ---
    if (polylineAnnotationManager == null) return;
    await polylineAnnotationManager!.deleteAll();

    List<mb.Position> points = polylineCoordinates
        .map((e) => mb.Position(e.longitude, e.latitude))
        .toList();

    var options = mb.PolylineAnnotationOptions(
      geometry: mb.LineString(coordinates: points),
      lineColor: MyColor.getPrimaryColor().value,
      lineWidth: 5.0,
      lineOpacity: 1.0,
      lineJoin: mb.LineJoin.ROUND,
    );
    await polylineAnnotationManager!.create(options);
  }

  // ===========================================================================
  // 4. تحديث موقع السائق
  // ===========================================================================
  void updateDriverLocation({required LatLng latLng, required bool isRunning}) {
    if (!isMapReady) return;

    if (driverLatLng.latitude == 0) {
      _previousDriverLatLng = latLng;
      driverLatLng = latLng;
      _updateDriverMarkerUnified(latLng, 0.0);
    } else {
      _animateMarkerUnified(latLng);
    }
    getCurrentDriverAddress();
  }

  void _animateMarkerUnified(LatLng newPosition) {
    final oldPosition = _previousDriverLatLng ?? driverLatLng;
    _previousDriverLatLng = oldPosition;

    _animationController.stop();
    _animationController.reset();

    final latTween = Tween<double>(begin: oldPosition.latitude, end: newPosition.latitude);
    final lngTween = Tween<double>(begin: oldPosition.longitude, end: newPosition.longitude);
    final endRotation = _getRotation(oldPosition.latitude, oldPosition.longitude, newPosition.latitude, newPosition.longitude);
    final rotTween = Tween<double>(begin: driverRotation, end: endRotation);

    _animationController.addListener(() async {
      final t = _animationController.value;
      final lat = latTween.transform(t);
      final lng = lngTween.transform(t);
      final rot = rotTween.transform(t);

      _updateDriverMarkerUnified(LatLng(lat, lng), rot);

      driverLatLng = LatLng(lat, lng);
      driverRotation = rot;
    });

    _animationController.forward();
  }

  Future<void> _updateDriverMarkerUnified(LatLng position, double rotation) async {
    // --- iOS Logic ---
    if (Platform.isIOS) {
      appleAnnotations.removeWhere((a) => a.annotationId.value == 'driver');

      if (driverIconApple != null) {
        appleAnnotations.add(ap.Annotation(
          annotationId: ap.AnnotationId('driver'), // ✅ بدون const
          position: ap.LatLng(position.latitude, position.longitude),
          icon: driverIconApple!,
        ));
      }
      update();
      return;
    }

    // --- Android Logic ---
    if (pointAnnotationManager == null || driverIconBytes == null) return;

    if (driverAnnotation != null) {
      driverAnnotation!.geometry = mb.Point(coordinates: mb.Position(position.longitude, position.latitude));
      driverAnnotation!.iconRotate = rotation;
      await pointAnnotationManager!.update(driverAnnotation!);
    } else {
      var options = mb.PointAnnotationOptions(
        geometry: mb.Point(coordinates: mb.Position(position.longitude, position.latitude)),
        image: driverIconBytes!,
        iconSize: 0.8,
        iconRotate: rotation,
        iconAnchor: mb.IconAnchor.CENTER,
      );
      driverAnnotation = await pointAnnotationManager!.create(options);
    }
  }

  // ===========================================================================
  // 5. البحث
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

    // بحث محلي
    try {
      final String myServerUrl = 'https://taxi.beytei.com/api/local-search?q=$query';
      final myResponse = await http.get(Uri.parse(myServerUrl)).timeout(const Duration(seconds: 2));
      if (myResponse.statusCode == 200) {
        final data = json.decode(myResponse.body);
        if (data['data'] != null) {
          combinedResults.addAll((data['data'] as List).map((e) => Prediction(
            placeId: e['id'].toString(),
            description: e['place_name'],
            lat: double.tryParse(e['lat'].toString()),
            lng: double.tryParse(e['lng'].toString()),
            structuredFormatting: StructuredFormatting(mainText: e['place_name'], secondaryText: "${e['city']} - محلي"),
          )));
        }
      }
    } catch (e) { print("⚠️ Local Search Error"); }

    // بحث Mapbox
    try {
      String accessToken = Environment.mapKey;
      String bbox = "38.7900,29.0600,48.7000,37.4000";
      String proximity = driverLatLng.latitude != 0 ? "&proximity=${driverLatLng.longitude},${driverLatLng.latitude}" : "";
      final String mapboxUrl = 'https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json?access_token=$accessToken&country=iq&bbox=$bbox$proximity&language=ar&limit=5';

      final response = await http.get(Uri.parse(mapboxUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null) {
          for (var feature in data['features']) {
            combinedResults.add(Prediction(
                placeId: feature['id'],
                description: feature['place_name'],
                lat: feature['center'][1],
                lng: feature['center'][0],
                structuredFormatting: StructuredFormatting(mainText: feature['text'], secondaryText: feature['place_name'])
            ));
          }
        }
      }
    } catch (e) { print("⚠️ Mapbox Search Error: $e"); }

    predictionList = combinedResults;
    isSearching = false;
    update();
  }

  // ===========================================================================
  // 6. أدوات مساعدة (وحل مشكلة RideDetailsScreen)
  // ===========================================================================

  // ✅ تم تغيير الاسم ليكون عاماً (public) لحل مشكلة الصورة الثالثة
  void fitPolylineBounds() {
    if (polylineCoordinates.isEmpty) return;

    if (Platform.isIOS && appleController != null) {
      double minLat = 90.0; double maxLat = -90.0;
      double minLng = 180.0; double maxLng = -180.0;

      for (var point in polylineCoordinates) {
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
        50.0,
      ));
    }
    else if (mapboxMap != null) {
      List<mb.Point> points = polylineCoordinates.map((e) => mb.Point(coordinates: mb.Position(e.longitude, e.latitude))).toList();
      mb.MbxEdgeInsets padding = mb.MbxEdgeInsets(top: 100, left: 50, bottom: 350, right: 50);
      mapboxMap!.cameraForCoordinates(points, padding, null, null).then((cameraOptions) {
        mapboxMap!.flyTo(cameraOptions, mb.MapAnimationOptions(duration: 1500));
      });
    }
  }

  Future<void> getCurrentDriverAddress() async {
    try {
      final List<Placemark> placeMark = await placemarkFromCoordinates(
        driverLatLng.latitude, driverLatLng.longitude,
      );
      if(placeMark.isNotEmpty) {
        driverAddress = "${placeMark[0].street}, ${placeMark[0].subLocality}";
      }
    } catch (e) { print('Address Error: $e'); }
  }

  double _getRotation(double lat1, double lon1, double lat2, double lon2) {
    var dy = lat2 - lat1;
    var dx = cos(pi/180 * lat1) * (lon2 - lon1);
    var angle = atan2(dy, dx);
    return angle * 180 / pi;
  }
}