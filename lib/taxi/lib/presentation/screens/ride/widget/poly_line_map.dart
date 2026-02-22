import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

// ✅ استبدال Mapbox بـ MapLibre
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as ap;

import '../../../../core/utils/my_color.dart';
import '../../../../core/utils/my_icons.dart';
import '../../../../data/controller/map/ride_map_controller.dart';

class PolyLineMapScreen extends StatefulWidget {
  const PolyLineMapScreen({super.key});

  @override
  State<PolyLineMapScreen> createState() => _PolyLineMapScreenState();
}

class _PolyLineMapScreenState extends State<PolyLineMapScreen> {
  // --- Android (MapLibre) Variables ---
  ml.MaplibreMapController? maplibreController;

  // --- iOS (Apple Maps) Variables ---
  ap.AppleMapController? appleController;
  Set<ap.Annotation> appleAnnotations = {};
  Set<ap.Polyline> applePolylines = {};

  ap.BitmapDescriptor? pickupIconApple;
  ap.BitmapDescriptor? destIconApple;

  bool isMapReady = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      _loadAppleIcons();
    }
  }

  Future<void> _loadAppleIcons() async {
    pickupIconApple = await ap.BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(40, 40)), MyIcons.mapMarkerPickUpIcon);
    destIconApple = await ap.BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(40, 40)), MyIcons.mapMarkerIcon);
    setState(() {});
  }

  // ==========================================
  // 🤖 Android MapLibre Logic
  // ==========================================
  void _onMapLibreCreated(ml.MaplibreMapController controller) {
    maplibreController = controller;
    setState(() => isMapReady = true);
    // تحديث الواجهة فور الجاهزية
    _updateMapUI(Get.find<RideMapController>());
  }

  // ==========================================
  // 🍎 iOS Apple Maps Logic
  // ==========================================
  void _onAppleMapCreated(ap.AppleMapController controller) {
    appleController = controller;
    setState(() => isMapReady = true);
    _updateMapUI(Get.find<RideMapController>());
  }

  // ==========================================
  // 🔄 Unified Update Logic
  // ==========================================
  Future<void> _updateMapUI(RideMapController controller) async {
    if (!isMapReady) return;

    if (Platform.isIOS) {
      _updateAppleUI(controller);
      return;
    }

    // --- Android (MapLibre) Update ---
    if (maplibreController == null) return;
    try {
      // تنظيف الخريطة
      await maplibreController!.clearLines();
      await maplibreController!.clearSymbols();

      // 1. رسم المسار (Polyline)
      if (controller.polylineCoordinates.isNotEmpty) {
        List<ml.LatLng> routePoints = controller.polylineCoordinates
            .map((e) => ml.LatLng(e.latitude, e.longitude))
            .toList();

        await maplibreController!.addLine(
          ml.LineOptions(
            geometry: routePoints,
            lineColor: "#${MyColor.primaryColor.value.toRadixString(16).substring(2)}",
            lineWidth: 5.0,
            lineOpacity: 1.0,
          ),
        );
        _fitCameraToBoundsUnified(controller.polylineCoordinates);
      }

      // 2. رسم الدبابيس (Symbols)
      await _drawMapLibreMarkers(controller);
    } catch (e) {
      debugPrint("🔴 Error updating MapLibre UI: $e");
    }
  }

  void _updateAppleUI(RideMapController controller) {
    setState(() {
      applePolylines.clear();
      appleAnnotations.clear();

      if (controller.polylineCoordinates.isNotEmpty) {
        applePolylines.add(ap.Polyline(
          polylineId: ap.PolylineId('route'),
          points: controller.polylineCoordinates.map((e) => ap.LatLng(e.latitude, e.longitude)).toList(),
          color: MyColor.primaryColor,
          width: 5,
        ));
        _fitCameraToBoundsUnified(controller.polylineCoordinates);
      }

      if (controller.pickupLatLng.latitude != 0 && pickupIconApple != null) {
        appleAnnotations.add(ap.Annotation(
          annotationId: ap.AnnotationId('pickup'),
          position: ap.LatLng(controller.pickupLatLng.latitude, controller.pickupLatLng.longitude),
          icon: pickupIconApple!,
        ));
      }

      if (controller.destinationLatLng.latitude != 0 && destIconApple != null) {
        appleAnnotations.add(ap.Annotation(
          annotationId: ap.AnnotationId('dest'),
          position: ap.LatLng(controller.destinationLatLng.latitude, controller.destinationLatLng.longitude),
          icon: destIconApple!,
        ));
      }
    });
  }

  Future<void> _drawMapLibreMarkers(RideMapController controller) async {
    // رسم نقطة البداية
    if (controller.pickupLatLng.latitude != 0) {
      await maplibreController!.addSymbol(ml.SymbolOptions(
        geometry: ml.LatLng(controller.pickupLatLng.latitude, controller.pickupLatLng.longitude),
        iconImage: "pickup_marker", // يجب أن تكون الصور محملة في الستايل أو كـ Assets
        iconSize: 1.0,
      ));
    }
    // رسم نقطة النهاية
    if (controller.destinationLatLng.latitude != 0) {
      await maplibreController!.addSymbol(ml.SymbolOptions(
        geometry: ml.LatLng(controller.destinationLatLng.latitude, controller.destinationLatLng.longitude),
        iconImage: "dest_marker",
        iconSize: 1.0,
      ));
    }
  }

  void _fitCameraToBoundsUnified(List points) {
    if (points.isEmpty) return;

    if (Platform.isIOS && appleController != null) {
      double minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
      for (var p in points) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }
      appleController!.animateCamera(ap.CameraUpdate.newLatLngBounds(
          ap.LatLngBounds(southwest: ap.LatLng(minLat, minLng), northeast: ap.LatLng(maxLat, maxLng)),
          50.0));
    } else if (maplibreController != null) {
      // ضبط الكاميرا في MapLibre
      List<ml.LatLng> mlPoints = points.map((e) => ml.LatLng(e.latitude, e.longitude)).toList();

      // حساب الحدود يدوياً أو استخدام الكاميرا لعمل احتواء
      maplibreController!.animateCamera(ml.CameraUpdate.newLatLngBounds(
        _computeBounds(mlPoints),
        top: 100, left: 50, bottom: 100, right: 50,
      ));
    }
  }

  ml.LatLngBounds _computeBounds(List<ml.LatLng> points) {
    double minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return ml.LatLngBounds(southwest: ml.LatLng(minLat, minLng), northeast: ml.LatLng(maxLat, maxLng));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<RideMapController>(
        builder: (controller) {
          final initialLat = (controller.pickupLatLng.latitude == 0) ? 32.5029 : controller.pickupLatLng.latitude;
          final initialLng = (controller.pickupLatLng.longitude == 0) ? 45.8219 : controller.pickupLatLng.longitude;

          return Stack(
            children: [
              Platform.isIOS
                  ? ap.AppleMap(
                initialCameraPosition: ap.CameraPosition(target: ap.LatLng(initialLat, initialLng), zoom: 14),
                onMapCreated: _onAppleMapCreated,
                annotations: appleAnnotations,
                polylines: applePolylines,
                myLocationEnabled: true,
              )
                  : ml.MaplibreMap(
                styleString: "https://maps.beytei.com/styles/iraq-taxi-style/style.json",
                initialCameraPosition: ml.CameraPosition(target: ml.LatLng(initialLat, initialLng), zoom: 14.0),
                onMapCreated: _onMapLibreCreated,
                myLocationEnabled: true,
              ),

              // زر إعادة التركيز
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton(
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.center_focus_strong, color: Colors.black),
                  onPressed: () {
                    if (controller.polylineCoordinates.isNotEmpty && isMapReady) {
                      _fitCameraToBoundsUnified(controller.polylineCoordinates);
                    }
                  },
                ),
              )
            ],
          );
        },
      ),
    );
  }
}