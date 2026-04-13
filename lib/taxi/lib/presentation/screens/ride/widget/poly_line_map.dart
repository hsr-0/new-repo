import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

// --- مكتبات الخرائط ---
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

class _PolyLineMapScreenState extends State<PolyLineMapScreen> with TickerProviderStateMixin {
  ml.MaplibreMapController? _freeMapController;
  bool isFreeMapStyleLoaded = false;

  // ✅ متغيرات لحفظ الماركرز والخطوط لمنع مسح الخريطة بالكامل
  ml.Line? _routeLine;
  ml.Symbol? _pickupMarker;
  ml.Symbol? _destMarker;

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
        const ImageConfiguration(size: Size(30, 30)), MyIcons.mapMarkerPickUpIcon);
    destIconApple = await ap.BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(30, 30)), MyIcons.mapMarkerIcon);
    if (mounted) setState(() {});
  }

  Future<void> _loadMapLibreIcons() async {
    if (_freeMapController == null) return;
    final ByteData pickupBytes = await rootBundle.load(MyIcons.mapMarkerPickUpIcon);
    await _freeMapController!.addImage('pickup_icon', pickupBytes.buffer.asUint8List());
    final ByteData destBytes = await rootBundle.load(MyIcons.mapMarkerIcon);
    await _freeMapController!.addImage('dest_icon', destBytes.buffer.asUint8List());
  }

  Future<void> _updateMapUI(RideMapController controller) async {
    if (!isMapReady) return;
    if (Platform.isIOS) {
      _updateAppleUI(controller);
    } else {
      _updateMapLibreUI(controller);
    }
  }

  void _updateAppleUI(RideMapController controller) {
    if (appleController == null) return;
    setState(() {
      applePolylines.clear();
      appleAnnotations.clear();

      if (controller.polylineCoordinates.isNotEmpty) {
        applePolylines.add(ap.Polyline(
          polylineId:  ap.PolylineId('route'),
          points: controller.polylineCoordinates.map((e) => ap.LatLng(e.latitude, e.longitude)).toList(),
          color: MyColor.primaryColor,
          width: 5,
          jointType: ap.JointType.round,
        ));
        _fitCameraToBoundsUnified(controller.polylineCoordinates);
      }

      if (controller.pickupLatLng.latitude != 0 && pickupIconApple != null) {
        appleAnnotations.add(ap.Annotation(
          annotationId:  ap.AnnotationId('pickup'),
          position: ap.LatLng(controller.pickupLatLng.latitude, controller.pickupLatLng.longitude),
          icon: pickupIconApple!,
        ));
      }

      if (controller.destinationLatLng.latitude != 0 && destIconApple != null) {
        appleAnnotations.add(ap.Annotation(
          annotationId:  ap.AnnotationId('dest'),
          position: ap.LatLng(controller.destinationLatLng.latitude, controller.destinationLatLng.longitude),
          icon: destIconApple!,
        ));
      }
    });
  }

  void _updateMapLibreUI(RideMapController controller) async {
    if (_freeMapController == null || !isFreeMapStyleLoaded) return;

    // ✅ مسح عناصر المسار القديمة فقط (للحفاظ على أيقونات السائقين)
    if (_routeLine != null) await _freeMapController!.removeLine(_routeLine!);
    if (_pickupMarker != null) await _freeMapController!.removeSymbol(_pickupMarker!);
    if (_destMarker != null) await _freeMapController!.removeSymbol(_destMarker!);

    if (controller.polylineCoordinates.isNotEmpty) {
      final List<ml.LatLng> line = controller.polylineCoordinates
          .map((e) => ml.LatLng(e.latitude, e.longitude))
          .toList();

      String hexColor = '#${MyColor.primaryColor.value.toRadixString(16).substring(2, 8)}';

      _routeLine = await _freeMapController!.addLine(ml.LineOptions(
        geometry: line,
        lineColor: hexColor,
        lineWidth: 5.0,
        lineOpacity: 1.0,
        // ✅ إذا استمر الخطأ في lineJoin، قم بحذف السطرين التاليين:
        // lineJoin: "round",
        // lineCap: "round",
      ));
      _fitCameraToBoundsUnified(controller.polylineCoordinates);
    }

    if (controller.pickupLatLng.latitude != 0) {
      _pickupMarker = await _freeMapController!.addSymbol(ml.SymbolOptions(
        geometry: ml.LatLng(controller.pickupLatLng.latitude, controller.pickupLatLng.longitude),
        iconImage: 'pickup_icon',
        iconSize: 0.25, // ✅ حجم صغير واحترافي
        iconAnchor: 'bottom', // مسمار الدبوس في الأسفل
      ));
    }

    if (controller.destinationLatLng.latitude != 0) {
      _destMarker = await _freeMapController!.addSymbol(ml.SymbolOptions(
        geometry: ml.LatLng(controller.destinationLatLng.latitude, controller.destinationLatLng.longitude),
        iconImage: 'dest_icon',
        iconSize: 0.25, // ✅ حجم صغير واحترافي
        iconAnchor: 'bottom',
      ));
    }
  }

  void _fitCameraToBoundsUnified(List points) {
    if (points.isEmpty) return;
    double minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    if (Platform.isIOS && appleController != null) {
      appleController!.animateCamera(ap.CameraUpdate.newLatLngBounds(
          ap.LatLngBounds(southwest: ap.LatLng(minLat, minLng), northeast: ap.LatLng(maxLat, maxLng)), 70.0));
    } else if (!Platform.isIOS && _freeMapController != null && isFreeMapStyleLoaded) {
      _freeMapController!.animateCamera(ml.CameraUpdate.newLatLngBounds(
          ml.LatLngBounds(southwest: ml.LatLng(minLat, minLng), northeast: ml.LatLng(maxLat, maxLng)),
          left: 70, right: 70, top: 70, bottom: 70));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<RideMapController>(
        builder: (controller) {
          // التخلص من موقع الكوت الافتراضي واستخدام موقع الزبون
          final initialLat = (controller.pickupLatLng.latitude == 0) ? 33.3152 : controller.pickupLatLng.latitude;
          final initialLng = (controller.pickupLatLng.longitude == 0) ? 44.3661 : controller.pickupLatLng.longitude;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (isMapReady) _updateMapUI(controller);
          });

          return Stack(
            children: [
              Platform.isIOS
                  ? ap.AppleMap(
                initialCameraPosition: ap.CameraPosition(target: ap.LatLng(initialLat, initialLng), zoom: 14),
                onMapCreated: (c) { appleController = c; setState(() => isMapReady = true); },
                annotations: appleAnnotations, polylines: applePolylines,
                myLocationEnabled: true, myLocationButtonEnabled: false,
              )
                  : ml.MapLibreMap(
                styleString: 'https://tiles.openfreemap.org/styles/liberty',
                initialCameraPosition: ml.CameraPosition(target: ml.LatLng(initialLat, initialLng), zoom: 14),
                onMapCreated: (c) { _freeMapController = c; setState(() => isMapReady = true); },
                onStyleLoadedCallback: () async {
                  isFreeMapStyleLoaded = true;
                  await _loadMapLibreIcons();
                  _updateMapUI(controller);
                },
                myLocationEnabled: true,
                myLocationRenderMode: ml.MyLocationRenderMode.normal,
              ),
              Positioned(
                bottom: 20, right: 20,
                child: FloatingActionButton(
                  mini: true, backgroundColor: Colors.white,
                  child: const Icon(Icons.center_focus_strong, color: Colors.black),
                  onPressed: () { if (controller.polylineCoordinates.isNotEmpty) _fitCameraToBoundsUnified(controller.polylineCoordinates); },
                ),
              )
            ],
          );
        },
      ),
    );
  }
}