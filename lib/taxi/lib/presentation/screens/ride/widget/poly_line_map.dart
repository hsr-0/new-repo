import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui; // 👈 مكتبة ضرورية جداً لعملية التصغير

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../core/utils/my_color.dart';
import '../../../../core/utils/my_icons.dart';
import '../../../../data/controller/map/ride_map_controller.dart';

class PolyLineMapScreen extends StatefulWidget {
  const PolyLineMapScreen({super.key});

  @override
  State<PolyLineMapScreen> createState() => _PolyLineMapScreenState();
}

class _PolyLineMapScreenState extends State<PolyLineMapScreen> {
  MapboxMap? mapboxMap;
  PolylineAnnotationManager? polylineAnnotationManager;
  PointAnnotationManager? pointAnnotationManager;

  bool isMapReady = false;

  _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;

    try {
      polylineAnnotationManager = await mapboxMap.annotations.createPolylineAnnotationManager();
      pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();

      setState(() {
        isMapReady = true;
      });

      // بمجرد إنشاء الخريطة، نقوم بتحديث الواجهة بالبيانات الموجودة في الكونترولر
      final controller = Get.find<RideMapController>();
      _updateMapUI(controller);

    } catch (e) {
      print("🔴 Error creating annotation managers: $e");
    }
  }

  Future<void> _updateMapUI(RideMapController controller) async {
    if (!isMapReady || mapboxMap == null) return;

    try {
      await polylineAnnotationManager?.deleteAll();
      await pointAnnotationManager?.deleteAll();

      // --- 1. رسم المسار (Polyline) ---
      if (controller.polylineCoordinates.isNotEmpty) {

        // تحويل الإحداثيات لرسم الخط
        List<Position> routePositions = controller.polylineCoordinates.map((e) {
          return Position(e.longitude, e.latitude);
        }).toList();

        // تحويل الإحداثيات لضبط الكاميرا
        List<Point> routePoints = routePositions.map((pos) {
          return Point(coordinates: pos);
        }).toList();

        var polylineOptions = PolylineAnnotationOptions(
          geometry: LineString(coordinates: routePositions),
          lineColor: MyColor.primaryColor.value,
          lineWidth: 5.0,
          lineOpacity: 1.0,
        );

        await polylineAnnotationManager?.create(polylineOptions);

        // ضبط الكاميرا لتشمل المسار بالكامل
        _fitCameraToBounds(routePoints);
      }

      // --- 2. رسم الدبابيس (Markers) ---
      await _drawMarkers(controller);

    } catch (e) {
      print("🔴 Error updating map UI: $e");
    }
  }

  Future<void> _drawMarkers(RideMapController controller) async {
    List<PointAnnotationOptions> markers = [];

    // ✅ رسم دبوس الانطلاق (Pickup)
    if (controller.pickupLatLng.latitude != 0) {
      // 🔥 استخدام دالة التصغير بدلاً من التحميل المباشر
      final icon = await _resizeImage(MyIcons.mapMarkerPickUpIcon, 120);

      markers.add(PointAnnotationOptions(
        geometry: Point(coordinates: Position(
            controller.pickupLatLng.longitude,
            controller.pickupLatLng.latitude
        )),
        image: icon,
        iconSize: 1.0, // سيظهر بحجم 120px لأننا صغرناه مسبقاً
        iconAnchor: IconAnchor.BOTTOM,
      ));
    }

    // ✅ رسم دبوس الوجهة (Destination)
    if (controller.destinationLatLng.latitude != 0) {
      // 🔥 استخدام دالة التصغير
      final icon = await _resizeImage(MyIcons.mapMarkerIcon, 120);

      markers.add(PointAnnotationOptions(
        geometry: Point(coordinates: Position(
            controller.destinationLatLng.longitude,
            controller.destinationLatLng.latitude
        )),
        image: icon,
        iconSize: 1.0,
        iconAnchor: IconAnchor.BOTTOM,
      ));
    }

    if (markers.isNotEmpty && pointAnnotationManager != null) {
      await pointAnnotationManager!.createMulti(markers);
    }
  }

  // 🔥🔥🔥 هذه هي الدالة الجديدة لتصغير الصور 🔥🔥🔥
  Future<Uint8List> _resizeImage(String path, int width) async {
    try {
      ByteData data = await rootBundle.load(path);
      ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
      ui.FrameInfo fi = await codec.getNextFrame();
      return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
    } catch (e) {
      print("🔴 Error resizing image: $e");
      // في حال الفشل، نعيد الصورة الأصلية كإجراء احتياطي
      final ByteData bytes = await rootBundle.load(path);
      return bytes.buffer.asUint8List();
    }
  }

  void _fitCameraToBounds(List<Point> points) {
    if (mapboxMap == null || points.isEmpty) return;

    MbxEdgeInsets padding = MbxEdgeInsets(top: 100, left: 50, bottom: 100, right: 50);

    mapboxMap!.cameraForCoordinates(
        points,
        padding,
        null,
        null
    ).then((cameraOptions) {
      mapboxMap!.flyTo(cameraOptions, MapAnimationOptions(duration: 1000));
    }).catchError((e) {
      print("🔴 Error fitting camera: $e");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<RideMapController>(
        builder: (controller) {
          final initialLat = (controller.pickupLatLng.latitude == 0) ? 32.5029 : controller.pickupLatLng.latitude;
          final initialLng = (controller.pickupLatLng.longitude == 0) ? 45.8219 : controller.pickupLatLng.longitude;

          // تحديث الخريطة عند أي تغيير في الكونترولر
          if (isMapReady) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateMapUI(controller);
            });
          }

          return Stack(
            children: [
              MapWidget(
                styleUri: MapboxStyles.MAPBOX_STREETS,
                cameraOptions: CameraOptions(
                  center: Point(coordinates: Position(initialLng, initialLat)),
                  zoom: 14.0,
                ),
                onMapCreated: _onMapCreated,
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
                      List<Point> points = controller.polylineCoordinates
                          .map((e) => Point(coordinates: Position(e.longitude, e.latitude)))
                          .toList();
                      _fitCameraToBounds(points);
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
