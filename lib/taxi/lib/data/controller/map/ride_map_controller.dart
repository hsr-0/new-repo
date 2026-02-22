import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as ap;

import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';

// تأكد من مسارات ملفاتك
import 'package:cosmetic_store/taxi/lib/core/utils/my_icons.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_images.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_color.dart';
import '../../model/location/prediction.dart';

class RideMapController extends GetxController with GetSingleTickerProviderStateMixin {

  bool isMapReady = false;
  bool isLoading = false;

  LatLng pickupLatLng = const LatLng(0, 0);
  LatLng destinationLatLng = const LatLng(0, 0);

  LatLng? _previousDriverLatLng; // تم إبقاء المتغير لاستخدامه في الأنيميشن
  LatLng driverLatLng = const LatLng(0, 0);
  double driverRotation = 0.0;
  String driverAddress = 'جاري التحميل...';

  ml.MaplibreMapController? mapController;
  ap.AppleMapController? appleController;

  Set<ap.Annotation> appleAnnotations = {};
  Set<ap.Polyline> applePolylines = {};

  List<LatLng> polylineCoordinates = [];
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

  void setMapLibreController(ml.MaplibreMapController controller) {
    mapController = controller;
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

  Future<void> _setupMapIcons() async {
    if (mapController == null) return;
    try {
      await _addAssetImage(mapController!, "pickup", MyIcons.mapMarkerPickUpIcon);
      await _addAssetImage(mapController!, "destination", MyIcons.mapMarkerIcon);
      await _addAssetImage(mapController!, "driver", MyImages.mapDriverMarker);
    } catch (e) {
      debugPrint("🔴 Error loading icons: $e");
    }
  }

  Future<void> _addAssetImage(ml.MaplibreMapController controller, String name, String path) async {
    final ByteData bytes = await rootBundle.load(path);
    final Uint8List list = bytes.buffer.asUint8List();
    await controller.addImage(name, list);
  }

  void loadMap({required LatLng pickup, required LatLng destination, bool isRunning = false}) async {
    pickupLatLng = pickup;
    destinationLatLng = destination;
    update();

    if (!isMapReady) return;

    if (mapController != null) await _setupMapIcons();

    await _drawStaticMarkers();
    await getRouteFromPrivateServer();
    fitPolylineBounds();
  }

  Future<void> _drawStaticMarkers() async {
    if (Platform.isIOS) {
      appleAnnotations.clear();

      // ✅ تمت إزالة const من هنا
      appleAnnotations.add(ap.Annotation(
        annotationId: ap.AnnotationId('pickup'),
        position: ap.LatLng(pickupLatLng.latitude, pickupLatLng.longitude),
        icon: await ap.BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(size: Size(40, 40)),
            MyIcons.mapMarkerPickUpIcon
        ),
      ));

      // ✅ تمت إزالة const من هنا أيضاً
      appleAnnotations.add(ap.Annotation(
        annotationId: ap.AnnotationId('destination'),
        position: ap.LatLng(destinationLatLng.latitude, destinationLatLng.longitude),
        icon: await ap.BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(size: Size(40, 40)),
            MyIcons.mapMarkerIcon
        ),
      ));
      update();
    } else if (mapController != null) {
      await mapController!.clearSymbols();
      await mapController!.addSymbol(ml.SymbolOptions(
        geometry: ml.LatLng(pickupLatLng.latitude, pickupLatLng.longitude),
        iconImage: "pickup",
        iconSize: 0.8,
      ));
      await mapController!.addSymbol(ml.SymbolOptions(
        geometry: ml.LatLng(destinationLatLng.latitude, destinationLatLng.longitude),
        iconImage: "destination",
        iconSize: 0.8,
      ));
    }
  }

  Future<void> getRouteFromPrivateServer() async {
    if (!isMapReady) return;
    isLoading = true;
    update();

    try {
      final String url = 'https://maps.beytei.com/route/v1/driving/'
          '${pickupLatLng.longitude},${pickupLatLng.latitude};'
          '${destinationLatLng.longitude},${destinationLatLng.latitude}'
          '?geometries=geojson&overview=full';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final List coords = data['routes'][0]['geometry']['coordinates'];
          polylineCoordinates = coords.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
          await _drawPolylineUnified();
        }
      }
    } catch (e) {
      debugPrint('🔴 Route Error: $e');
    }
    isLoading = false;
    update();
  }

  Future<void> _drawPolylineUnified() async {
    if (polylineCoordinates.isEmpty) return;

    if (Platform.isIOS) {
      applePolylines.clear();
      // ✅ تمت إزالة const هنا
      applePolylines.add(ap.Polyline(
        polylineId: ap.PolylineId('route'),
        points: polylineCoordinates.map((e) => ap.LatLng(e.latitude, e.longitude)).toList(),
        color: MyColor.getPrimaryColor(),
        width: 5,
      ));
    } else if (mapController != null) {
      await mapController!.clearLines();
      await mapController!.addLine(ml.LineOptions(
        geometry: polylineCoordinates.map((e) => ml.LatLng(e.latitude, e.longitude)).toList(),
        lineColor: "#${MyColor.getPrimaryColor().value.toRadixString(16).padLeft(8, '0').substring(2)}",
        lineWidth: 5.0,
      ));
    }
    update();
  }

  void updateDriverLocation({required LatLng latLng, required bool isRunning}) {
    if (!isMapReady) return;

    if (driverLatLng.latitude == 0) {
      _previousDriverLatLng = latLng;
      driverLatLng = latLng;
      _updateDriverMarker(latLng, 0.0);
    } else {
      _animateDriverMarker(latLng);
    }
    getCurrentDriverAddress();
  }

  void _animateDriverMarker(LatLng newPos) {
    final oldPos = driverLatLng;
    _previousDriverLatLng = oldPos;
    _animationController.stop();
    _animationController.reset();

    final latTween = Tween<double>(begin: oldPos.latitude, end: newPos.latitude);
    final lngTween = Tween<double>(begin: oldPos.longitude, end: newPos.longitude);
    final rot = _getRotation(oldPos.latitude, oldPos.longitude, newPos.latitude, newPos.longitude);

    _animationController.addListener(() {
      final t = _animationController.value;
      driverLatLng = LatLng(latTween.transform(t), lngTween.transform(t));
      _updateDriverMarker(driverLatLng, rot);
    });
    _animationController.forward();
  }

  Future<void> _updateDriverMarker(LatLng pos, double rot) async {
    if (Platform.isIOS) {
      appleAnnotations.removeWhere((a) => a.annotationId.value == 'driver');
      // ✅ تمت إزالة const هنا
      appleAnnotations.add(ap.Annotation(
        annotationId: ap.AnnotationId('driver'),
        position: ap.LatLng(pos.latitude, pos.longitude),
        icon: await ap.BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(size: Size(35, 35)),
            MyImages.mapDriverMarker
        ),
      ));
      update();
    } else if (mapController != null) {
      await mapController!.addSymbol(ml.SymbolOptions(
        geometry: ml.LatLng(pos.latitude, pos.longitude),
        iconImage: "driver",
        iconRotate: rot,
        iconSize: 0.6,
      ));
    }
  }

  void fitPolylineBounds() {
    if (polylineCoordinates.isEmpty) return;

    if (Platform.isIOS && appleController != null) {
      double minLat = polylineCoordinates.map((e) => e.latitude).reduce(min);
      double maxLat = polylineCoordinates.map((e) => e.latitude).reduce(max);
      double minLng = polylineCoordinates.map((e) => e.longitude).reduce(min);
      double maxLng = polylineCoordinates.map((e) => e.longitude).reduce(max);

      appleController!.animateCamera(ap.CameraUpdate.newLatLngBounds(
        ap.LatLngBounds(southwest: ap.LatLng(minLat, minLng), northeast: ap.LatLng(maxLat, maxLng)),
        50.0,
      ));
    } else if (mapController != null) {
      mapController!.animateCamera(ml.CameraUpdate.newLatLngBounds(
        ml.LatLngBounds(
          southwest: ml.LatLng(polylineCoordinates.map((e)=>e.latitude).reduce(min), polylineCoordinates.map((e)=>e.longitude).reduce(min)),
          northeast: ml.LatLng(polylineCoordinates.map((e)=>e.latitude).reduce(max), polylineCoordinates.map((e)=>e.longitude).reduce(max)),
        ),
        bottom: 300, top: 50, left: 50, right: 50,
      ));
    }
  }

  Future<void> getCurrentDriverAddress() async {
    try {
      final List<Placemark> placeMark = await placemarkFromCoordinates(driverLatLng.latitude, driverLatLng.longitude);
      if(placeMark.isNotEmpty) {
        driverAddress = "${placeMark[0].street}, ${placeMark[0].subLocality}";
      }
    } catch (e) { debugPrint('Address Error: $e'); }
  }

  double _getRotation(double lat1, double lon1, double lat2, double lon2) {
    var dy = lat2 - lat1;
    var dx = cos(pi/180 * lat1) * (lon2 - lon1);
    return atan2(dy, dx) * 180 / pi;
  }
}