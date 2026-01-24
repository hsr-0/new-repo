import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
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

  // بيانات السائق
  LatLng? _previousDriverLatLng;
  LatLng driverLatLng = const LatLng(0, 0);
  double driverRotation = 0.0;
  String driverAddress = 'Loading...';

  // --- Mapbox Managers ---
  MapboxMap? mapboxMap;
  PointAnnotationManager? pointAnnotationManager;
  PolylineAnnotationManager? polylineAnnotationManager;
  PointAnnotation? driverAnnotation;

  // --- البيانات ---
  List<LatLng> polylineCoordinates = [];
  List<Prediction> predictionList = [];

  // --- الأنيميشن والصور ---
  late final AnimationController _animationController;
  Uint8List? pickupIcon;
  Uint8List? destinationIcon;
  Uint8List? driverIcon;

  @override
  void onInit() {
    super.onInit();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    setCustomMarkerIcon();
  }

  @override
  void onClose() {
    _animationController.dispose();
    super.onClose();
  }

  // ===========================================================================
  // 1. إعداد الخريطة
  // ===========================================================================
  Future<void> setMapController(MapboxMap map) async {
    mapboxMap = map;
    pointAnnotationManager = await mapboxMap?.annotations.createPointAnnotationManager();
    polylineAnnotationManager = await mapboxMap?.annotations.createPolylineAnnotationManager();
    isMapReady = true;

    if (pickupLatLng.latitude != 0 && destinationLatLng.latitude != 0) {
      loadMap(pickup: pickupLatLng, destination: destinationLatLng);
    }
  }

  // ===========================================================================
  // 2. البحث الهجين (Hybrid Search)
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
      final String myServerUrl = 'https://taxi.beytei.com/api/local-search?q=$query';
      final myResponse = await http.get(Uri.parse(myServerUrl)).timeout(const Duration(seconds: 2));

      if (myResponse.statusCode == 200) {
        final data = json.decode(myResponse.body);
        if (data['data'] != null) {
          combinedResults.addAll((data['data'] as List).map((e) => Prediction(
            placeId: e['id'].toString(),
            description: e['place_name'],
            lat: e['lat'],
            lng: e['lng'],
            structuredFormatting: StructuredFormatting(
                mainText: e['place_name'],
                secondaryText: "${e['city']} - محلي"
            ),
          )));
        }
      }
    } catch (e) {
      print("⚠️ Local Search Error");
    }

    try {
      String accessToken = Environment.mapKey;
      String country = "iq";
      String bbox = "38.7900,29.0600,48.7000,37.4000";

      String proximity = "";
      if (driverLatLng.latitude != 0) {
        proximity = "&proximity=${driverLatLng.longitude},${driverLatLng.latitude}";
      }

      final String mapboxUrl =
          'https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json'
          '?access_token=$accessToken'
          '&country=$country'
          '&bbox=$bbox'
          '$proximity'
          '&language=ar'
          '&limit=5';

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
                structuredFormatting: StructuredFormatting(
                  mainText: feature['text'],
                  secondaryText: feature['place_name'],
                )
            ));
          }
        }
      }
    } catch (e) {
      print("⚠️ Mapbox Search Error: $e");
    }

    predictionList = combinedResults;
    isSearching = false;
    update();
  }

  // ===========================================================================
  // 3. تحميل الخريطة والمسار
  // ===========================================================================
  void loadMap({required LatLng pickup, required LatLng destination, bool? isRunning = false}) async {
    pickupLatLng = pickup;
    destinationLatLng = destination;
    update();

    if (!isMapReady) return;

    await _drawStaticMarkers();
    await getRouteFromMapbox();
    fitPolylineBounds();
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

          await _drawPolyline();
        }
      }
    } catch (e) {
      print('🔴 [Error] Fetching route: $e');
    }

    isLoading = false;
    update();
  }

  Future<void> _drawPolyline() async {
    if (polylineAnnotationManager == null || polylineCoordinates.isEmpty) return;
    await polylineAnnotationManager!.deleteAll();
    List<Position> points = polylineCoordinates.map((e) => Position(e.longitude, e.latitude)).toList();
    var options = PolylineAnnotationOptions(
      geometry: LineString(coordinates: points),
      lineColor: MyColor.getPrimaryColor().value,
      lineWidth: 5.0,
      lineOpacity: 1.0,
      lineJoin: LineJoin.ROUND,
    );
    await polylineAnnotationManager!.create(options);
  }

  // ===========================================================================
  // ✅ التعديل المطلوب: إصلاح تضخم الأيقونات (Static Markers)
  // ===========================================================================
  Future<void> _drawStaticMarkers() async {
    if (pointAnnotationManager == null) return;

    await pointAnnotationManager!.deleteAll();
    driverAnnotation = null;

    List<PointAnnotationOptions> markers = [];

    if (pickupIcon != null) {
      markers.add(PointAnnotationOptions(
        geometry: Point(coordinates: Position(pickupLatLng.longitude, pickupLatLng.latitude)),
        image: pickupIcon!,
        iconSize: 0.18, // 🎯 تم تصغير الحجم ليكون متناسقاً
        iconAnchor: IconAnchor.BOTTOM,
      ));
    }

    if (destinationIcon != null) {
      markers.add(PointAnnotationOptions(
        geometry: Point(coordinates: Position(destinationLatLng.longitude, destinationLatLng.latitude)),
        image: destinationIcon!,
        iconSize: 0.18, // 🎯 تم تصغير الحجم ليكون متناسقاً
        iconAnchor: IconAnchor.BOTTOM,
      ));
    }

    await pointAnnotationManager!.createMulti(markers);
  }

  // ===========================================================================
  // 5. تحديث موقع السائق والأنيميشن
  // ===========================================================================
  void updateDriverLocation({required LatLng latLng, required bool isRunning}) {
    if (!isMapReady) return;

    if (driverLatLng.latitude == 0) {
      _previousDriverLatLng = latLng;
      driverLatLng = latLng;
      _drawDriverMarker(latLng, 0.0);
      getCurrentDriverAddress();
      return;
    }
    _animateMarker(latLng);
    getCurrentDriverAddress();
  }

  // ✅ التعديل المطلوب: إصلاح تضخم أيقونة السائق
  Future<void> _drawDriverMarker(LatLng position, double rotation) async {
    if (pointAnnotationManager == null || driverIcon == null) return;

    if (driverAnnotation != null) {
      try { await pointAnnotationManager!.delete(driverAnnotation!); } catch (e) {}
    }

    var options = PointAnnotationOptions(
      geometry: Point(coordinates: Position(position.longitude, position.latitude)),
      image: driverIcon!,
      iconSize: 0.15, // 🎯 حجم متناسق لأيقونة السائق (التكتك/السيارة)
      iconRotate: rotation,
      iconAnchor: IconAnchor.CENTER,
    );
    driverAnnotation = await pointAnnotationManager!.create(options);
  }

  void _animateMarker(LatLng newPosition) {
    if (driverAnnotation == null || pointAnnotationManager == null) {
      _drawDriverMarker(newPosition, driverRotation);
      return;
    }

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

      driverAnnotation!.geometry = Point(coordinates: Position(lng, lat));
      driverAnnotation!.iconRotate = rot;
      await pointAnnotationManager!.update(driverAnnotation!);

      driverLatLng = LatLng(lat, lng);
      driverRotation = rot;
    });

    _animationController.forward();
  }

  // ===========================================================================
  // 6. أدوات مساعدة (Helpers)
  // ===========================================================================

  void fitPolylineBounds() {
    if (polylineCoordinates.isEmpty || mapboxMap == null) return;
    List<Point> points = polylineCoordinates.map((e) => Point(coordinates: Position(e.longitude, e.latitude))).toList();
    MbxEdgeInsets padding = MbxEdgeInsets(top: 100, left: 50, bottom: 350, right: 50);
    mapboxMap!.cameraForCoordinates(points, padding, null, null).then((cameraOptions) {
      mapboxMap!.flyTo(cameraOptions, MapAnimationOptions(duration: 1500));
    });
  }

  Future<void> setCustomMarkerIcon() async {
    try {
      pickupIcon = await Helper.getBytesFromAsset(MyIcons.mapMarkerPickUpIcon, 120);
      destinationIcon = await Helper.getBytesFromAsset(MyIcons.mapMarkerIcon, 120);
      driverIcon = await Helper.getBytesFromAsset(MyImages.mapDriverMarker, 100);
      update();
    } catch (e) { print("🔴 Error loading icons: $e"); }
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