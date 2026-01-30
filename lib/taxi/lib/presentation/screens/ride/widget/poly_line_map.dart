import 'dart:async';
import 'dart:io'; // ✅ لتحديد النظام
import 'dart:typed_data';
import 'dart:ui' as ui; // ✅ لتصغير الصور للأندرويد

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

// --- مكتبات الخرائط ---
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
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
  // --- Android (Mapbox) Variables ---
  mb.MapboxMap? mapboxMap;
  mb.PolylineAnnotationManager? polylineAnnotationManager;
  mb.PointAnnotationManager? pointAnnotationManager;

  // --- iOS (Apple Maps) Variables ---
  ap.AppleMapController? appleController;
  Set<ap.Annotation> appleAnnotations = {};
  Set<ap.Polyline> applePolylines = {};

  // صور الآيفون
  ap.BitmapDescriptor? pickupIconApple;
  ap.BitmapDescriptor? destIconApple;

  bool isMapReady = false;

  @override
  void initState() {
    super.initState();
    if(Platform.isIOS) {
      _loadAppleIcons();
    }
  }

  // تحميل أيقونات أبل
  Future<void> _loadAppleIcons() async {
    pickupIconApple = await ap.BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(40, 40)), MyIcons.mapMarkerPickUpIcon);
    destIconApple = await ap.BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(40, 40)), MyIcons.mapMarkerIcon);
    setState(() {});
  }

  // ==========================================
  // 🤖 Android Mapbox Logic
  // ==========================================
  _onMapboxCreated(mb.MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
    try {
      polylineAnnotationManager = await mapboxMap.annotations.createPolylineAnnotationManager();
      pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
      setState(() => isMapReady = true);
      _updateMapUI(Get.find<RideMapController>());
    } catch (e) {
      print("🔴 Error creating annotation managers: $e");
    }
  }

  // ==========================================
  // 🍎 iOS Apple Maps Logic
  // ==========================================
  _onAppleMapCreated(ap.AppleMapController controller) {
    appleController = controller;
    setState(() => isMapReady = true);
    _updateMapUI(Get.find<RideMapController>());
  }

  // ==========================================
  // 🔄 Unified Update Logic
  // ==========================================
  Future<void> _updateMapUI(RideMapController controller) async {
    if (!isMapReady) return;

    // --- iOS Update ---
    if (Platform.isIOS) {
      _updateAppleUI(controller);
      return;
    }

    // --- Android Update ---
    if (mapboxMap == null) return;
    try {
      await polylineAnnotationManager?.deleteAll();
      await pointAnnotationManager?.deleteAll();

      // 1. رسم المسار
      if (controller.polylineCoordinates.isNotEmpty) {
        List<mb.Position> routePositions = controller.polylineCoordinates.map((e) {
          return mb.Position(e.longitude, e.latitude);
        }).toList();

        var polylineOptions = mb.PolylineAnnotationOptions(
          geometry: mb.LineString(coordinates: routePositions),
          lineColor: MyColor.primaryColor.value,
          lineWidth: 5.0,
          lineOpacity: 1.0,
        );
        await polylineAnnotationManager?.create(polylineOptions);

        // ضبط الكاميرا
        _fitCameraToBoundsUnified(controller.polylineCoordinates);
      }

      // 2. رسم الدبابيس
      await _drawMapboxMarkers(controller);

    } catch (e) { print("🔴 Error updating map UI: $e"); }
  }

  void _updateAppleUI(RideMapController controller) {
    setState(() {
      applePolylines.clear();
      appleAnnotations.clear();

      // 1. رسم المسار
      if (controller.polylineCoordinates.isNotEmpty) {
        applePolylines.add(ap.Polyline(
          polylineId: ap.PolylineId('route'),
          points: controller.polylineCoordinates.map((e) => ap.LatLng(e.latitude, e.longitude)).toList(),
          color: MyColor.primaryColor,
          width: 5,
        ));
        _fitCameraToBoundsUnified(controller.polylineCoordinates);
      }

      // 2. رسم الدبابيس
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

  // رسم دبابيس أندرويد (مع التصغير)
  Future<void> _drawMapboxMarkers(RideMapController controller) async {
    List<mb.PointAnnotationOptions> markers = [];

    if (controller.pickupLatLng.latitude != 0) {
      final icon = await _resizeImage(MyIcons.mapMarkerPickUpIcon, 120);
      markers.add(mb.PointAnnotationOptions(
        geometry: mb.Point(coordinates: mb.Position(controller.pickupLatLng.longitude, controller.pickupLatLng.latitude)),
        image: icon,
        iconSize: 1.0,
        iconAnchor: mb.IconAnchor.BOTTOM,
      ));
    }

    if (controller.destinationLatLng.latitude != 0) {
      final icon = await _resizeImage(MyIcons.mapMarkerIcon, 120);
      markers.add(mb.PointAnnotationOptions(
        geometry: mb.Point(coordinates: mb.Position(controller.destinationLatLng.longitude, controller.destinationLatLng.latitude)),
        image: icon,
        iconSize: 1.0,
        iconAnchor: mb.IconAnchor.BOTTOM,
      ));
    }

    if (markers.isNotEmpty && pointAnnotationManager != null) {
      await pointAnnotationManager!.createMulti(markers);
    }
  }

  // دالة تصغير الصور للأندرويد
  Future<Uint8List> _resizeImage(String path, int width) async {
    try {
      ByteData data = await rootBundle.load(path);
      ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
      ui.FrameInfo fi = await codec.getNextFrame();
      return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
    } catch (e) {
      final ByteData bytes = await rootBundle.load(path);
      return bytes.buffer.asUint8List();
    }
  }

  // ضبط حدود الكاميرا (Unified)
  void _fitCameraToBoundsUnified(List points) {
    if (points.isEmpty) return;

    if (Platform.isIOS && appleController != null) {
      // حساب الحدود للآيفون
      double minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
      for (var p in points) {
        // التعامل مع LatLng الخاص بـ Controller
        double lat = p.latitude;
        double lng = p.longitude;
        if (lat < minLat) minLat = lat;
        if (lat > maxLat) maxLat = lat;
        if (lng < minLng) minLng = lng;
        if (lng > maxLng) maxLng = lng;
      }
      appleController!.animateCamera(ap.CameraUpdate.newLatLngBounds(
          ap.LatLngBounds(southwest: ap.LatLng(minLat, minLng), northeast: ap.LatLng(maxLat, maxLng)),
          50.0
      ));
    }
    else if (mapboxMap != null) {
      // حساب الحدود للأندرويد
      List<mb.Point> mapboxPoints = points.map((e) => mb.Point(coordinates: mb.Position(e.longitude, e.latitude))).toList();
      mb.MbxEdgeInsets padding = mb.MbxEdgeInsets(top: 100, left: 50, bottom: 100, right: 50);
      mapboxMap!.cameraForCoordinates(mapboxPoints, padding, null, null).then((cameraOptions) {
        mapboxMap!.flyTo(cameraOptions, mb.MapAnimationOptions(duration: 1000));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<RideMapController>(
        builder: (controller) {
          final initialLat = (controller.pickupLatLng.latitude == 0) ? 32.5029 : controller.pickupLatLng.latitude;
          final initialLng = (controller.pickupLatLng.longitude == 0) ? 45.8219 : controller.pickupLatLng.longitude;

          if (isMapReady) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateMapUI(controller);
            });
          }

          return Stack(
            children: [
              // 🗺️ تبديل الخريطة
              Platform.isIOS
                  ? ap.AppleMap(
                initialCameraPosition: ap.CameraPosition(target: ap.LatLng(initialLat, initialLng), zoom: 14),
                onMapCreated: _onAppleMapCreated,
                annotations: appleAnnotations,
                polylines: applePolylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
              )
                  : mb.MapWidget(
                styleUri: mb.MapboxStyles.MAPBOX_STREETS,
                cameraOptions: mb.CameraOptions(
                  center: mb.Point(coordinates: mb.Position(initialLng, initialLat)),
                  zoom: 14.0,
                ),
                onMapCreated: _onMapboxCreated,
              ),

              // زر إعادة توسيط الكاميرا
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton(
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.center_focus_strong, color: Colors.black),
                  onPressed: () {
                    if(controller.polylineCoordinates.isNotEmpty && isMapReady) {
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
